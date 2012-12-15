
Heres the plan:
Merge the stuff in transform.jl into scale.jl. All scales need to give a f and
finv function.



* Discrete scales.
* More default guides.
* A means by which statistics can modify guides. (For example, Stat.histogram
  should be able to set the y-axis label.)
* Document things.
* Handle NaN and Inf gracefully.
* Correct behavior for Lines geometry with non-nothing color aesthetic.
* Facets. (Some thought is required to avoid something gross. Should facets be
  geometries that embed an entire plot?)



