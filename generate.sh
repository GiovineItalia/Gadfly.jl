#!/bin/sh

# Build static HTML versions of the Gadfly documentation.
#
# Documentation lives in the master branch, so we checkout that branch into a
# seperate directory, build the HTHL, copy it here and update.

#url=git://github.com/dcjones/Gadfly.jl.git
url=../Gadfly

gadfly=`julia -e 'println(julia_pkgdir())'`/Gadfly/bin/gadfly

run_gadfly() {
    infn=$1
    outfn=`echo $infn | sed 's/\.md$/.html/'`

    author=`git log -1 --format="%an" -- $infn`
    date=`git log -1 --format="%ad" -- $infn`

    $gadfly \
        --variable="author:$author" \
        --variable="date:$date" \
        --toc \
        --from=markdown \
        --to=html5 \
        --template=../../template.html \
        $infn > $outfn
}

git clone $url gadfly
pushd gadfly/doc
for fn in *.md
do
    echo gadfly $fn
    run_gadfly $fn
done
cp *.html ../..
cp *.svg ../..
popd
rm -rf gadfly

# TODO: automate removal of stale files?

