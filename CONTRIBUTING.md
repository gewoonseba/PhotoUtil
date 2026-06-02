# Contributing

Thanks for considering a contribution to PhotoUtil.

## Local Setup

1. Install Xcode 26.5 or newer.
2. Open `Package.swift` in Xcode.
3. Build and run the `PhotoUtil` scheme.

## Verification

Run the core behavior checks before opening a pull request:

```sh
swift run PhotoUtilChecks
```

## Scope

The initial utility focuses on SD cards and cameras that mount as filesystem volumes. Direct camera import over ImageCaptureCore and additional photo workflow tools can be added separately.
