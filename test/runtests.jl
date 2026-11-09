using Test
using Documenter
using GraphvizDotLang
using GraphvizDotLang: graph, digraph, strict, node, edge, attr, subgraph, save, HTML

dot(g) = sprint(print, g)

# Attribute order inside `[...]` follows `IdDict` iteration order, so for
# statements with more than one attribute we only check that each is present.
has_attr(s, k, v) = occursin("$k=$v;", s)

@testset "GraphvizDotLang" begin

@testset "graph headers" begin
    @test dot(graph()) == "graph {\n}"
    @test dot(digraph()) == "digraph {\n}"
    @test dot(graph() |> strict) == "strict graph {\n}"
    @test dot(digraph("G")) == "digraph \"G\" {\n}"
end

@testset "edges" begin
    @test dot(graph() |> edge("a", "b")) == "graph {\n  \"a\"--\"b\";\n}"
    @test dot(digraph() |> edge("a", "b", "c")) == "digraph {\n  \"a\"->\"b\"->\"c\";\n}"
    @test dot(digraph() |> edge("a", "b"; label="x")) ==
        "digraph {\n  \"a\"->\"b\"[label=\"x\";];\n}"
end

@testset "nodes and ports" begin
    @test dot(graph() |> node("a")) == "graph {\n  \"a\";\n}"
    @test dot(graph() |> node("a"; shape="box")) == "graph {\n  \"a\"[shape=\"box\";];\n}"
    @test dot(graph() |> node("a", ":p")) == "graph {\n  \"a\":p;\n}"
    @test dot(digraph() |> edge("a:p:n", "b")) == "digraph {\n  \"a\":p:n->\"b\";\n}"
end

@testset "attribute statements" begin
    @test dot(graph(rankdir="LR")) == "graph {\n  graph[rankdir=\"LR\";];\n}"
    @test dot(graph() |> attr(:node; shape="box")) == "graph {\n  node[shape=\"box\";];\n}"
    @test dot(graph() |> attr(:edge; len="2")) == "graph {\n  edge[len=\"2\";];\n}"
    # no attributes, no statement
    @test dot(graph() |> attr(:node)) == "graph {\n}"

    s = dot(graph(; fontname="sans serif", bgcolor="#fff0e0"))
    @test has_attr(s, "fontname", "\"sans serif\"")
    @test has_attr(s, "bgcolor", "\"#fff0e0\"")
end

@testset "HTML attributes" begin
    # Regression: v0.2.2 called `String` on every attribute value, which
    # threw a MethodError for `HTML` values.
    @test dot(graph() |> node("a"; label=HTML("<b>a</b>"))) ==
        "graph {\n  \"a\"[label=<<b>a</b>>;];\n}"
    @test dot(digraph() |> edge("a", "b"; label=HTML("<i>e</i>"))) ==
        "digraph {\n  \"a\"->\"b\"[label=<<i>e</i>>;];\n}"
    @test dot(graph() |> attr(:node; label=HTML("<u>n</u>"))) ==
        "graph {\n  node[label=<<u>n</u>>;];\n}"
    @test dot(graph(; label=HTML("<b>title</b>"))) ==
        "graph {\n  graph[label=<<b>title</b>>;];\n}"

    # mixing HTML and plain string values in one attribute list
    s = dot(graph() |> node("a"; label=HTML("<b>a</b>"), shape="record"))
    @test has_attr(s, "label", "<<b>a</b>>")
    @test has_attr(s, "shape", "\"record\"")

    # HTML wrapping a non-String AbstractString
    @test dot(graph() |> node("a"; label=HTML(SubString("x<b>a</b>", 2)))) ==
        "graph {\n  \"a\"[label=<<b>a</b>>;];\n}"
end

@testset "AbstractString arguments" begin
    sub(s) = SubString(s, 1)
    @test sub("a") isa SubString

    @test dot(graph() |> node(sub("a"); shape=sub("box"))) ==
        "graph {\n  \"a\"[shape=\"box\";];\n}"
    @test dot(graph() |> node(sub("a"), sub(":p"))) == "graph {\n  \"a\":p;\n}"
    @test dot(digraph() |> edge(sub("a"), sub("b"); label=sub("x"))) ==
        "digraph {\n  \"a\"->\"b\"[label=\"x\";];\n}"
    @test dot(digraph() |> edge(sub("a:p"), "b")) == "digraph {\n  \"a\":p->\"b\";\n}"
    @test dot(graph(; rankdir=sub("LR"))) == "graph {\n  graph[rankdir=\"LR\";];\n}"
    @test dot(graph() |> attr(:node; shape=sub("box"))) == "graph {\n  node[shape=\"box\";];\n}"

    # results of string operations are often SubStrings
    parts = split("a,b,c", ",")
    @test eltype(parts) <: SubString
    @test dot(digraph() |> edge(parts...)) == "digraph {\n  \"a\"->\"b\"->\"c\";\n}"
end

@testset "subgraphs" begin
    g = digraph()
    s = subgraph(g, "cluster_0"; label="c0")
    s |> edge("a", "b")
    @test dot(g) == """
        digraph {
          subgraph "cluster_0" {
          graph[label="c0";];
          "a"->"b";
        }
        ;
        }"""

    g = graph()
    subgraph(g, SubString("cluster_x", 1); label=HTML("<b>x</b>")) |> node("a")
    @test occursin("subgraph \"cluster_x\"", dot(g))
    @test occursin("graph[label=<<b>x</b>>;];", dot(g))
end

@testset "rendering through Graphviz" begin
    g = digraph() |>
        node("a"; label=HTML("<b>a</b>")) |>
        edge("a", "b"; label="x")
    @test occursin("<svg", sprint(show, MIME("image/svg"), g))
    png = Vector{UInt8}(sprint(show, MIME("image/png"), g))
    @test png[1:4] == UInt8[0x89, 'P', 'N', 'G']

    mktempdir() do dir
        file = joinpath(dir, "sub", "out.svg")
        save(g, SubString(file, 1))
        @test isfile(file)
        @test occursin("<svg", read(file, String))
    end
end

@testset "doctests" begin
    DocMeta.setdocmeta!(GraphvizDotLang, :DocTestSetup,
                        :(using GraphvizDotLang: graph, digraph, strict, node, edge);
                        recursive=true)
    doctest(GraphvizDotLang; manual=false)
end

end
