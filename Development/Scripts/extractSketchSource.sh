#!/bin/bash

name=$1

unzip "$name"
mv pages/* Development/SketchStyleExporter/SketchStyleExporter/SampleSketchSource/
mv document.json Development/SketchStyleExporter/SketchStyleExporter/SampleSketchSource/
rm meta.json
rm user.json
rm previews/*
rmdir previews
rmdir pages
