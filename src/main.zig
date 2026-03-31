const std = @import("std");

const ItunesResult = struct {
	results: []PodcastResult,
};

const PodcastResult = struct {
	feedUrl: []const u8,
};

pub fn main() !void {
	const allocator = std.heap.page_allocator;
	const args = try std.process.argsAlloc(allocator);
	defer std.process.argsFree(allocator, args);
	if (args.len == 1) {
		std.debug.print("usage: podfeed <URL1> [<URL2>...]\n", .{});
		std.process.exit(1);
	}
	var stdout_buf: [256]u8 = undefined;
	var stdout = std.fs.File.stdout().writer(&stdout_buf);
	for (args[1..]) |itunes_url| {
		const id = getPodcastId(itunes_url) catch |err| switch (err) {
			error.NoPodcastId => {
				std.debug.print("podfeed: invalid URL {s}\n", .{ itunes_url });
				continue;
			},
		};
		const feed = getRealUrl(allocator, id) catch |err| {
			std.debug.print("podfeed: error gotten for {s}: {s}\n", .{ itunes_url, @errorName(err) });
			continue;
		};
		try stdout.interface.print("{s}\n", .{ feed });
	}
	try stdout.interface.flush();
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

fn getRealUrl(allocator: std.mem.Allocator, id: []const u8) ![]const u8 {
	const api_url = try std.fmt.allocPrint(allocator, "https://itunes.apple.com/lookup?id={s}&entity=podcast", .{ id });
	defer allocator.free(api_url);
	const uri = try std.Uri.parse(api_url);
	var client = std.http.Client{ .allocator = allocator };
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
