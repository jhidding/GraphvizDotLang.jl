# After an example by Costa Shulyupin
using GraphvizDotLang: digraph, edge, node, save, attr

colors = Dict(
    "orange"      => [],
    "deeppink"    => [],
    "purple"      => [],
    "deepskyblue" => [],
    "springgreen" => [],
    "yellowgreen" => [],
    "yellow"      => ["yellowgreen", "orange"],
    "red"         => ["orange", "yellow", "white", "magenta", "deeppink"],
    "magenta"     => ["purple", "deeppink"],
    "blue"        => ["deepskyblue", "cyan", "white", "magenta", "purple"],
    "cyan"        => ["springgreen", "deepskyblue"],
    "green"       => ["yellowgreen", "yellow", "white", "cyan", "springgreen"],
    "white"       => [])

white_text = Set(["blue", "green", "purple", "red", "magenta", "deeppink"])

g = digraph("Twelve_colors"; layout="neato", normalize="0", start="regular") |>
    attr(:node; shape="circle", style="filled", width = "1.5") |>
    attr(:edge; len="2")
    for (c, others) in colors
    g |> node(c; fillcolor=c, fontcolor=c ∈ white_text ? "white" : "black")
    for o in others
        g |> edge(c, o)
    end
end
save(g, "twelve_colors.svg"; engine="neato")