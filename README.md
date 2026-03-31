# podfeed

Fast podcast RSS feed URL extractor written in Zig. Converts iTunes podcast URLs to RSS feed URLs.

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
