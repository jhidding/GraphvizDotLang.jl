using DotLang: digraph, edge, node, save, attr, subgraph

g = digraph("G")
cluster0 = subgraph(g, "cluster_0"; label="process #1", style="filled", color="lightgray") |>
    attr(:node; style="filled", color="white") |>
    edge(("a$i" for i in 0:3)...)
cluster1 = subgraph(g, "cluster_1"; label="process #2", color="blue") |>
    attr(:node; style="filled") |>
    edge(("b$i" for i in 0:3)...)
g |>
    edge("start", "a0") |>
    edge("start", "b0") |>
    edge("a1", "b3") |>
    edge("b2", "a3") |>
    edge("a3", "a0") |>
    edge("a3", "end") |>
    edge("b3", "end") |>
    node("start"; shape="Mdiamond") |>
    node("end"; shape="Msquare")
save(g, "clusters.svg")
