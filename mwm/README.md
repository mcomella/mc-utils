# MWM: macOS Window Manager
This macOS window manager responds to hard-coded keyboard shortcuts to resize the focused window into thirds, halves, & two-thirds on either the left or the right of the screen and to resize it to fullscreen.

## Building
To build a debug build, open with Xcode and build. Each time you build, you'll have to re-add it as an accessibility app: you may be able to work around this with https://stackoverflow.com/a/72312500/2219998.

To build a release build, cd into the directory of this README file and run:
```
xcodebuild
```

## Usage
To set up, you probably want to:
- Build a release build
- Copy the `.app` into an Applications directory (and optionally clean the build directory)
- In order for the app to monitor for global keyboard shortcuts and resize arbitrary windows, it needs the macOS Accessibility permission: System Preferences -> Security & Privacy -> Privacy -> Accessibility, hit the + and add the app.
- Add the app as a Login item

At the time of writing, the keyboard shortcuts are:
- ctrl + option + left: once to left 1/3, twice to left 1/2
  - same for right
- ctrl + option + down: once to left 2/3s
  - up for right
- ctrl + option + enter: fullscreen
