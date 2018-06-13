<p align="center">
    <img src="Design/Logo.png" width="480" max-width="90%" alt="stylesync" />
</p>

<p align="center">
    <a href="https://travis-ci.org/dylanslewis/stylesync/branches">
        <img src="https://img.shields.io/travis/dylanslewis/stylesync/master.svg" alt="Travis status" />
    </a>
    <img src="https://img.shields.io/badge/Swift-4.1-orange.svg" />
    </a>
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
    <a href="https://twitter.com/dylanslewis">
        <img src="https://img.shields.io/badge/contact-@dylanslewis-blue.svg?style=flat" alt="Twitter: @dylanslewis" />
    </a>
</p>

Welcome to **stylesync**, a command line tool that extracts text and colour styles from a [Sketch](https://www.sketchapp.com/) document, and generates **native** code for your project's **platform**, **language** and **style**.

# Why?

> A unified design system is essential to building better and faster; better because a cohesive experience is more easily understood by our users, and faster because it gives us a common language to work with.

<p align="right" data-meta="karri_saarinen_airbnb">
<b>Karri Saarinen, <a href="https://airbnb.design/building-a-visual-language/">Airbnb</a></b>
</p>


A design system is vital resource for any product that values a consistent experience for users across platforms. Unfortunately maintaining a design system in code is a cumbersome process, since changes may be subtle and the time required for developers to maintain styles is not always respected by businesses. Tools like Zeplin allow a one off export, but don’t help with maintainability and often lead to design debt.

**stylesync** automates the generation and maintenance of a design system in code, using *your* project's preferred code style.

This means your Sketch file can be a **single source of truth** for your brand’s identity, created and maintained by designers, leaving developers to get on with the actual implementation of interfaces using these styles.

# Features

## Template-based exports

**stylesync** exports code based on templates, which means you can export code that matches your project's platform, language and style.

The template files look very similar to the exported code, except placeholder values are denoted using a simple templating language, *e.g.* `<#=hex#>`. The [Templates README](https://github.com/dylanslewis/stylesync/blob/master/Sources/StyleSyncCore/Templates/README.md) contains more information on templates, with links to some examples.

## Continuous integration

**stylesync** works best when used as part of a [CI system](https://en.wikipedia.org/wiki/Continuous_integration). The tool can branch, commit, push and raise pull requests for any changes that occur, showing a clear breakdown in the pull request's [description](https://github.com/dylanslewis/stylesync/pull/10). This makes sure your styles are always up to date with the latest version of your design system.

## Project maintenance

Style names can change, so in addition to updating your style guide code, **stylesync** also updates any references to those styles anywhere in your project. This makes sure your project doesn't break as a result of changes made by designers.

## Deprecation

No project is completely up to date with the designs, and there might come a time when a style is removed from the design system but still exists in your project. **stylesync** handles this gracefully by keeping the removed style in code, but deprecating it so you can start thinking about removing it. Once **stylesync** finds no more references to the deprecated style, it will be removed from the generated code.

# Installation

You can install `stylesync` using the [Swift Package Manager](https://github.com/apple/swift-package-manager):
```
$ git clone https://github.com/dylanslewis/stylesync.git
$ cd stylesync
$ swift build -c release -Xswiftc -static-stdlib
$ cp -f .build/release/stylesync /usr/local/bin/stylesync
```

# How to use

Before using **stylesync**, you’ll need to create a **text style template** and **color style template**. The [Templates README](https://github.com/dylanslewis/stylesync/blob/master/Sources/StyleSyncCore/Templates/README.md) contains information on how to create a template, and links to some examples.

After creating your template, you can run `stylesync` from your project’s root directory and you’ll be taken through a set up wizard. Once completed, a `stylesyncConfig.json` file will be saved, so next time you can simply run `stylesync`.

# Sample project

`TODO: Add speed run video`

See `stylesync` in action in this [small sample project](https://github.com/dylanslewis/stylesync-styleguide-ios), which showcases a design system in a simple iOS app. It’s already set up with templates and a `stylesyncConfig.json` file, so you can just run `stylesync` to see how it works!

# Contributions

A tool that improves collaboration between designers and developers should be available to everyone for free, which is why **stylesync** is open source.

If you find a bug or want to add an interesting feature, feel free to [raise an issue](https://github.com/dylanslewis/stylesync/issues/new) or [submit a pull request](https://github.com/dylanslewis/stylesync/compare).

Just note that you'll need to run `swift build` to install the dependancies if you want to use the Xcode project.

# License

**stylesync** is available under the MIT license. See the [`LICENSE`](LICENSE) file for more information.
