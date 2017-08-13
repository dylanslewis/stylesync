#!/bin/bash

sketchFileName=$1
exportDirectory=$2

unzip "$sketchFileName"
rm meta.json
rm user.json
rm previews/*
rm pages/*
rmdir previews
rmdir pages

Development/SketchStyleExporter/SketchStyleExporter/SketchStyleExporter document.json $2
rm document.json
