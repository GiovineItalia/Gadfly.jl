using .TerminalExtensions

function putatend(idisplay, display::iTerm2.InlineDisplay)
  iterm2display = splice!(Base.Multimedia.displays, idisplay)
  push!(Base.Multimedia.displays, iterm2display)
  true
end
putatend(idisplay, display) = false

for (idisplay, display) in enumerate(Base.Multimedia.displays)
  putatend(idisplay, display) && break
end

function display(d::iTerm2.InlineDisplay, p::Union{Plot,Compose.Context})
    draw(PNG(), p)
    print("\r")
end
