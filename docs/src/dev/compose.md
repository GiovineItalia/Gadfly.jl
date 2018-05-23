```@meta
Author = "Ben Arthur"
```
# Relationship with Compose.jl

Gadfly and Compose are tightly intertwined.  As such, if you want to checkout
the master branch of Gadfly to get the latest features and bug fixes, you'll
likely also need to checkout Compose.

Moreover, if you're a contributor, you should probably tag releases of Gadfly
and Compose simultaneously, and ideally submit a single PR to METADATA containing
both.  It is for this reason that neither uses
[attobot](https://github.com/attobot/attobot), as it has no mechanism to do
this.
