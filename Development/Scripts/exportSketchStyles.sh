#!/bin/bash

sketchFileName=$1
projectDirectory=$2
exportDirectory=$3
colorStyleTemplate=$4
textStyleTemplate=$5

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
.build/debug/StyleSync document.json $2 $3 $4 $5
rm document.json
cd ../..
