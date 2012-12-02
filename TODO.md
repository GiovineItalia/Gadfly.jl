
* A simpler, terser user-facing interface. Make this dependent on DataFrames.
  That is, input should always be a data fram.
* Discrete scale.
* Document things.
* Handle NaN and Inf gracefully.
* Correct behavior for Lines geometry with non-nothing color aesthetic.
* Facets. (Some thought is required to avoid something gross. Should facets be
  geometries that embed an entire plot?)
* Consider moving each element type to its own namespace, so one would write
  Geom.histogram, instead of geom_histogram, for example.

