# xc-resave

A `minimum` executable to make Xcode resave a xcodeproj.

## Why?
When we use [XcodeEditor](https://github.com/appsquickly/XcodeEditor) to modify a xcodeproj, the project is serialized in XML format property list, which generates a big git diff.

In this case we can manually modify the Xcode project in Xcode.app then manually undo the modification to make Xcode re-save the project file, then most of the diff will disappear.

This project is just to do that for you, forcing Xcode to re-save the project.

## Build

```bash
$ make
```

## Run

```bash
$ ./xc-resave /path/to/project.xcodeproj
```

## Credits
This project is inspired by [xcproj](https://github.com/0xced/xcproj).

## License

`xc-resave` is released under the MIT license. See [LICENSE](https://github.com/cezheng/xc-resave/blob/master/LICENSE) for details.
