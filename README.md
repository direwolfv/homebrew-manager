# Homebrew Manager

A small native macOS app for the Homebrew packages you already have installed: browse
formulae and casks, see what's outdated, upgrade or uninstall, and check details like
dependencies, caveats and license.

Personal tool. Not affiliated with or endorsed by Homebrew.

## Requirements

- macOS 14 or newer
- [Homebrew](https://brew.sh) in `/opt/homebrew` or `/usr/local`
- Xcode Command Line Tools (`xcode-select --install`)

## Run

```sh
swift run                # quick dev run, no app bundle
./app/build.sh           # builds "Homebrew Manager.app" in the repo root
open "Homebrew Manager.app"
```

## License

ISC — see [LICENSE](LICENSE).
