function open_file(filename)
    if is_apple()
        run(`open $(filename)`)
    elseif is_linux() || is_bsd()
        run(`xdg-open $(filename)`)
    elseif is_windows()
        run(`$(ENV["COMSPEC"]) /c start $(filename)`)
    else
        warn("Showing plots is not supported on OS $(string(Compat.KERNEL))")
    end
end

