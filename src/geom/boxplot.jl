
immutable BoxplotGeometry <: Gadfly.GeometryElement
end


const boxplot = BoxplotGeometry

element_aesthetics(::BoxplotGeometry) = [:x, :y, :color]

default_statistic(::BoxplotGeometry) = Gadfly.Stat.boxplot()

function render(geom::BoxplotGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.bar", aes,
                                     :lower_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)
    Gadfly.assert_aesthetics_equal_length("Geom.bar", aes,
                                     :lower_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.x = Float64[1]
    aes = inherit(aes, default_aes)

    aes_iter = zip(aes.lower_fence,
                   aes.lower_hinge,
                   aes.middle,
                   aes.upper_hinge,
                   aes.upper_fence,
                   aes.outliers,
                   cycle(aes.x),
                   cycle(aes.color.refs))

    forms = Compose.Form[]
    middle_forms = Compose.Form[]

    r = theme.default_point_size
    bw = 1.0cx - theme.boxplot_spacing

    # TODO: handle color non-nothing color

    for (lf, lh, mid, uh, uf, outliers, x, cref) in aes_iter
        c = aes.color.pool[cref]
        sc = theme.highlight_color(c) # stroke color
        mc = theme.middle_color(c) # middle color

        # Middle
        push!(middle_forms, compose(lines((x - 1/6, mid), (x + 1/6, mid)),
                                    linewidth(theme.middle_width), stroke(mc)))

        # Box
        push!(forms, compose(rectangle(x*cx - bw/2, lh, bw, uh - lh),
                            fill(c), stroke(sc),
                            linewidth(theme.highlight_width)))

        # Whiskers
        push!(forms, compose(lines((x, lh), (x, lf)),
                            linewidth(theme.line_width), stroke(sc)))

        push!(forms, compose(lines((x, uh), (x, uf)),
                            linewidth(theme.line_width), stroke(sc)))

        # Fences
        push!(forms, compose(lines((x - 1/6, lf), (x + 1/6, lf)),
                            linewidth(theme.line_width), stroke(sc)))

        push!(forms, compose(lines((x - 1/6, uf), (x + 1/6, uf)),
                            linewidth(theme.line_width), stroke(sc)))

        # Outliers
        if !isempty(outliers)
            push!(forms, compose(combine([circle(x, y, r) for y in outliers]...),
                                fill(c), stroke(sc)))
        end
    end

    compose(canvas(units_inherited=true),
            (canvas(units_inherited=true), combine(forms...)),
            (canvas(units_inherited=true, order=1), combine(middle_forms...)),
            svgclass("geometry"))
end


