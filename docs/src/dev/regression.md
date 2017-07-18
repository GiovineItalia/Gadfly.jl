```@meta
Author = "Ben Arthur"
```
# Regression Testing

Running `Pkg.test("Gadfly")` evaluates all of the files in
`Gadfly/test/testscripts`.  Any errors or warnings are printed to the REPL.  In
addition, the figures that are produced are put into either the `gennedoutput/`
or `cachedoutput/` sub-directories.  Nominally, the former represents the
changes in a pull request while the latter are used for comparison.
Specifically, `runtests.jl` examines the currently checkout out git commit, and
sets the output directory to `cachedoutput/` if it is the HEAD of the master
branch or if it is detached.  Otherwise, it assumes you are at the tip of a
development branch and saves the figures to `gennedoutput/`.  After evaluating
all the test scripts, `runtests.jl` checks to see if both of the output
directories are not empty.  If so, `compare_examples.jl` is called, and any
differences between the new and old figures will be displayed in the REPL and
the browser.

So the automated regression analysis workflow is then as follows:

1. In a branch other than master,
2. develop your new feature or fix your old bug,
3. commit all your changes,
4. `Pkg.test("Gadfly")`,
5. checkout master,
6. `Pkg.test` again,
7. check that any of the reported differences are as intended.
