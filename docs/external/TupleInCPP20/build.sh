#!/usr/bin/env bash

echo building tuple-in-cpp20.pdf
pandoc tuple-in-cpp20.md -o tuple-in-cpp20.pdf --pdf-engine=xelatex --from=gfm --wrap=auto --columns=80 -H header.tex --pdf-engine-opt=-shell-escape --lua-filter minted-wrap.lua --no-highlight --toc
echo building tuple-in-cpp20\ SolarizedDark.pdf
pandoc tuple-in-cpp20.md -o tuple-in-cpp20\ SolarizedDark.pdf --pdf-engine=xelatex --from=gfm --wrap=auto --columns=80 -H header-solarized-dark.tex --pdf-engine-opt=-shell-escape --lua-filter minted-wrap.lua --no-highlight --toc
echo building tuple-in-cpp20\ SolarizedLight.pdf
pandoc tuple-in-cpp20.md -o tuple-in-cpp20\ SolarizedLight.pdf --pdf-engine=xelatex --from=gfm --wrap=auto --columns=80 -H header-solarized-light.tex --pdf-engine-opt=-shell-escape --lua-filter minted-wrap.lua --no-highlight --toc
