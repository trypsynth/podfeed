# podfeed

Fast podcast RSS feed URL extractor written in Zig. Converts iTunes podcast URLs to RSS feed URLs.

## Download

Get the file for your system from the [latest release](https://github.com/trypsynth/podfeed/releases/latest). Builds are available for Windows, macOS and Linux, on x64 and ARM64.

## Usage

```sh
podfeed <URL1> [<URL2>...]
```

Takes one or more iTunes podcast URLs and outputs their RSS feed URLs to stdout.

## Build

```sh
zig build --release=small
```

## License

This project is licensed under the [MIT license](LICENSE).
