const std = @import("std");

const ItunesResult = struct {
	results: []PodcastResult,
};

const PodcastResult = struct {
	feedUrl: []const u8,
};

pub fn main(init: std.process.Init) !void {
	const allocator = init.gpa;
	const io = init.io;
	var args = try std.process.Args.iterateAllocator(init.minimal.args, allocator);
	defer args.deinit();
	_ = args.skip();
	const first_url = args.next() orelse {
		std.debug.print("usage: podfeed <URL1> [<URL2>...]\n", .{});
		std.process.exit(1);
	};
	var stdout_buf: [256]u8 = undefined;
	var stdout = std.Io.File.stdout().writer(init.io, &stdout_buf);
	try processUrl(io, allocator, &stdout.interface, first_url);
	while (args.next()) |url| {
		try processUrl(io, allocator, &stdout.interface, url);
	}
	try stdout.interface.flush();
}

fn processUrl(io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer, url: []const u8) !void {
	const id = getPodcastId(url) catch |err| {
		if (err == error.NoPodcastId) {
			std.debug.print("podfeed: invalid URL {s}\n", .{ url });
			return;
		}
		return err;
	};
	const feed = getRealUrl(io, allocator, id) catch |err| {
		std.debug.print("podfeed: error for {s}: {s}\n", .{ url, @errorName(err) });
		return;
	};
	defer allocator.free(feed);
	try writer.print("{s}\n", .{ feed });
}

fn getPodcastId(url: []const u8) ![]const u8 {
	const slash = std.mem.lastIndexOf(u8, url, "/") orelse return error.NoPodcastId;
	var i: usize = slash + 1;
	while (i < url.len and !std.ascii.isDigit(url[i])) : (i += 1) {}
	if (i == url.len) return error.NoPodcastId;
	const start = i;
	while (i < url.len and std.ascii.isDigit(url[i])) : (i += 1) {}
	return url[start..i];
}

fn getRealUrl(io: std.Io, allocator: std.mem.Allocator, id: []const u8) ![]const u8 {
	const api_url = try std.fmt.allocPrint(allocator, "https://itunes.apple.com/lookup?id={s}&entity=podcast", .{ id });
	defer allocator.free(api_url);
	const uri = try std.Uri.parse(api_url);
	var client = std.http.Client{ .io = io, .allocator = allocator };
	defer client.deinit();
	var writer = std.Io.Writer.Allocating.init(allocator);
	defer writer.deinit();
	_ = try client.fetch(.{
		.location = .{ .uri = uri },
		.method = .GET,
		.response_writer = &writer.writer,
	});
	const json_raw = writer.written();
	const parsed = try std.json.parseFromSlice(ItunesResult, allocator, json_raw, .{
		.ignore_unknown_fields = true,
	});
	defer parsed.deinit();
	const result = try allocator.dupe(u8, parsed.value.results[0].feedUrl);
	return result;
}
