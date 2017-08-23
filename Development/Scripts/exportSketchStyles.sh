#!/bin/bash

sketchFileName=$1
projectDirectory=$2
exportDirectory=$3

unzip "$sketchFileName"
rm meta.json
rm user.json
rm previews/*
rm pages/*
rmdir previews
rmdir pages

Development/SketchStyleExporter/SketchStyleExporter/SketchStyleExporter document.json $2 $3
rm document.json
