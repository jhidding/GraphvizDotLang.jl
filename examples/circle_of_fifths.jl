using GraphvizDotLang: digraph, edge, node, attr, HTML, save
using Printf: @sprintf

a_freq = 440.0
note_names = [
    "c", "c♯", "d", "d♯", "e", "f", "f♯", "g", "g♯", "a", "a♯", "b"
]
note_values = Dict(n => i for (i, n) in enumerate(note_names))

function equal_tempered(note)
    a_freq * 2^((note_values[note] - note_values["a"]) / 12)
end

g = digraph(label="The Circle of Fifths and 12 tone equal temperament",
            layout="neato", start="regular", rankdir="LR") |>
    attr(:node; shape="record", style="rounded") |>
    attr(:edge; len="1.2")
for (i, n) in enumerate(note_names)
    et_freq = equal_tempered(n)
    g |>
        node(n; label=HTML(@sprintf "<b>%s</b> | %4.1fHz" n et_freq)) |>
        edge(n, note_names[(i + 6) % 12 + 1])
end
save(g, "circle_of_fifths.svg")
