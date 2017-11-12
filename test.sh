printf "import Files\n\nlet testResources = try! Folder(path: \"$PWD/Tests/StyleSyncTests/Resources\")\n" > Tests/StyleSyncTests/Resources/Resources.swift
swift build
swift test
