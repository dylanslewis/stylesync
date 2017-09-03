#!/bin/bash

sketchFileName="Design/Sample.sketch"
projectDirectory="../StyleGuide/iOS"
exportDirectory="../StyleGuide/iOS/StyleGuide/GeneratedFiles/"
colorStyleTemplate="Sources/StyleSyncCore/Templates/ColorStyles/iOSSwift"
textStyleTemplate="Sources/StyleSyncCore/Templates/TextStyles/iOSSwift"
gitHubUsername="dylanslewis"
gitHubRepositoryName="StyleSync"
gitHubPersonalAccessToken="95aff974f0847d521e6fe5ab880aa1aae55d0c7d"

clear
unzip "$sketchFileName"
mv document.json Development/StyleSync/
rm meta.json
rm user.json
rm previews/*
rm pages/*
rmdir previews
rmdir pages

cd Development/StyleSync/
swift build
.build/debug/StyleSync document.json $projectDirectory $exportDirectory $colorStyleTemplate $textStyleTemplate $gitHubUsername $gitHubRepositoryName $gitHubPersonalAccessToken
rm document.json
cd ../..
