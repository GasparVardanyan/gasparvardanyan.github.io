#!/usr/bin/env bash

curr=$(git branch | \grep '^\*' | cut -f 2 -d ' ')
git checkout draft
git add .
git commit -m draft
git push -u origin draft
git checkout "$curr"
