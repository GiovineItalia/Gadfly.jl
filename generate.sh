#!/bin/sh

# Build static HTML versions of the Gadfly documentation.
#
# Documentation lives in the master branch, so we checkout that branch into a
# seperate directory, build the HTHL, copy it here and update.

#url=git://github.com/dcjones/Gadfly.jl.git
url=../Gadfly

gadfly=`julia -e 'println(julia_pkgdir())'`/Gadfly/bin/gadfly

git clone $url gadfly
pushd gadfly/doc
$gadfly \
    --toc \
    --from=markdown \
    --to=html5 \
    --template=../../template.html \
    overview.md > overview.html
cp *.html ../..
cp *.svg ../..
popd
rm -rf gadfly
git add *.html *.svg

# TODO: automate removal of stale files?

