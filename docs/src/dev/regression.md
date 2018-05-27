```@meta
Author = "Ben Arthur"
```
# Regression Testing

Running `Pkg.test("Gadfly")` evaluates all of the files in
`Gadfly/test/testscripts`.  Any errors or warnings are printed to the REPL.  In
addition, the figures that are produced are put into either the `devel-output/`
or `master-output/` sub-directories.  Nominally, the former represents the
changes in a pull request while the latter are used for comparison.
Specifically, `runtests.jl` examines the currently checked out git commit, and
sets the output directory to `master-output/` if it is the HEAD of the master
branch or if it is detached.  Otherwise, it assumes you are at the tip of a
development branch and saves the figures to `devel-output/`.  After running the
tests on both of these branches, executing `compare_examples.jl` displays
differences between the new and old figures.  This script can dump a diff of
the files to the REPL, open both figures for manual comparison, and/or, for SVG
and PNG files, display a black and white figure highlighting the spatial
location of the differences.

So the automated regression analysis workflow is then as follows:

1. In a branch other than master,
2. develop your new feature or fix your old bug,
3. commit all your changes,
4. `Pkg.test("Gadfly")`,
5. checkout master,
6. `Pkg.test` again,
7. `Pkg.add("ArgParse")` and, for B&W images, Cairo, Fontconfig, Rsvg, and Images as well,
8. check for differences with `julia test/compare_examples.jl [--diff] [--two] [--bw] [-h] [filter]`.  For example, `julia test/compare_examples.jl --bw .js.svg` will show black and white images highlighting the differences between the svg test images.
