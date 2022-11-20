using GraphvizDotLang: graph, edge, node, save, attr

g = graph(;layout="neato") |>
    attr(:node; shape="tripleoctagon", style="rounded,filled",
                fillcolor="darkolivegreen4",
                fontcolor="white") |>
    attr(:edge; len="1.4", penwidth="3") |>
    node("North"; label="Altstadt", pos="0,1", width="2", height="0.7") |>
    node("South"; label="Vorstadt", pos="0,-1", width="2", height="0.7") |>
    node("Center"; label="Kneiphof", pos="1,0") |>
    node("East"; label="Lomse", pos="2,0", height="1") |>
    edge("East", "South", "Center", "North") |>
    edge("East", "North", "Center", "South") |>
    edge("Center", "East")
save(g, "konigsberg.svg")
