using GraphvizDotLang: digraph, node, edge, attr, HTML, save

g = digraph(bgcolor="beige", rankdir="LR", ranksep="1") |>
        attr(:edge; fontname="Cantarell") |>
        attr(:node; shape="circle", style="filled,wedged") |>
        node("start"; label="", fillcolor="red:green:blue") |>
        node("end"; label="", fillcolor="cyan:magenta:yellow") |>
        edge("start", "end"; label="invert!")

save(g, ARGS[1])

