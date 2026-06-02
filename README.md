# PhotoUtil

PhotoUtil is a native macOS SwiftUI app for common photo workflow utilities.

The first utility is RAW import: importing photos from an SD card or connected camera volume, then organizing them by capture date.

## Features

- Select a removable source volume or any source folder.
- Select a destination directory.
- Scan RAW files before importing.
- Organize files by capture date using `YYYY/MM`.
- Rename imported files as `YYYY-MM-DD-<original_name>`.
- Detect destination duplicates before import.
- Skip or overwrite duplicate files.

The app reads capture dates from image metadata when available, then falls back to file creation or modification date.

## Run

```sh
swift run PhotoUtil
```

You can also open `PhotoUtil.xcodeproj` in Xcode and build the `PhotoUtil` scheme.

## Install Locally

Build and install `PhotoUtil.app` from Terminal:

```sh
scripts/install-local.sh
```

The script installs into `/Applications` when writable, otherwise it falls back to `~/Applications`.

## Build a local app bundle

```sh
chmod +x scripts/build-app.sh
scripts/build-app.sh release
```

The generated app is written to `outputs/PhotoUtil.app`.

## Package a Release Zip

```sh
scripts/package-release.sh
```

The release archive is written to `dist/PhotoUtil-0.1.0-macOS.zip`.

## Verify core import behavior

```sh
swift run PhotoUtilChecks
```

## License

PhotoUtil is released under the MIT License.
