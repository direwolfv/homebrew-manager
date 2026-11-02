# homebrew-manager

**This repo is public.** A small SwiftUI app (`Sources/HomebrewManager/`) that
shells out to `brew` for every action. `app/build.sh` wraps the release binary in
`Homebrew Manager.app`; the version and copyright live in its Info.plist, not in code.

## Commit messages

A one-line subject, a blank line, then **bullet points only — at most 10**. No paragraphs, no
trailers. More than 10 changes means grouping them, not a longer list.

## Gate

```sh
swift build
./app/build.sh
```
