#!/bin/bash

shopt -s extglob
cd docs

if [[ $1 == "clean" ]]
then
    rm -rf gen
else
    if [[ ! -f node_modules/.bin/docco ]]
    then
        npm install docco
    fi

    $(npm bin)/docco *.md --output gen --layout linear

    cd gen
    python -m http.server
fi
