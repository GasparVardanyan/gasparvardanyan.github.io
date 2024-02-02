#!/bin/sh

git submodule update --init --recursive
git submodule update --remote --merge

hugo

# find -L public -name '.git' | xargs rm -rf

# this is for removing everything but thumbnails:
# rm -rf public/wallpapers/img/{themes,wallpapers}/.git
# find public/wallpapers/img -type f -not -regex ".*q100_box_smart1.*" -exec rm {} \;
# find public/wallpapers/img -type d -depth -exec rmdir {} 2>/dev/null \;

# # but now thumbnails are embedded as base64 urls, so delete everything
# rm -rf public/wallpapers/img/{themes,wallpapers}
