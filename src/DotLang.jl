"""
Graphviz works with a special language for describing graphs called DOT.
The [documentation of Graphviz](https://graphviz.org/doc/info/lang.html)
describes the syntax for this language. This module helps generating
expressions in the DOT language programmatically.

This module defines a set of structs that match the different elements in
the DOT language. The `print(::IO, ::T)` method is used to provide
writers for each of these structs.

Graphviz supports many attributes. This module does not check for validity
of the attributes you give it.

The syntax of Graphviz is very liberal. It will accept a lot of varieties of
input. This module will encapsulate all IDs in double quotation marks.

Example:
"""
module DotLang

@enum GraphComponent c_graph c_node c_edge

const component_name = IdDict(
    c_graph => "graph",
    c_node => "node",
    c_edge => "edge"
)

Base.show(io :: IO, c :: GraphComponent) = print(io, component_name[c])

@enum CompassPt c_n c_ne c_e c_se c_s c_sw c_w c_nw c_c c_empty

const compass_symb = IdDict(
    c_n => "n", c_ne => "ne", c_e => "e", c_se => "se", c_s => "s",
    c_sw => "sw", c_w => "w", c_nw => "nw", c_c => "c", c_empty => "_"
)

Base.show(io :: IO, c :: CompassPt) = print(io, compass_symb[c])

abstract type Statement end

struct Subgraph <: Statement
    name :: Union{String, Nothing}
    stmt_lst :: Vector{Statement}
end

struct AList
    content :: IdDict{Symbol,String}
end

function Base.show(io :: IO, alst :: AList)
    for (k, v) in pairs(alst.content)
        print(io, k, "=\"", v, "\";")
    end
end

struct NodeId
    name :: String
    port :: Union{String,Nothing}
end

struct NodeStmt <: Statement
    id :: NodeId
    attr_list :: Vector{AList}
end

NodeOrSubgraph = Union{NodeId,Subgraph}

function Base.show(io :: IO, n :: NodeId)
    print(io, "\"", n.name, "\"")
    if !isnothing(n.port)
        print(io, n.port)
    end
end

function Base.show(io :: IO, n :: NodeStmt)
    print(io, n.id)
    for a in n.attr_list
        if !isempty(a.content)
            print(io, "[", a, "]")
        end
    end
end

struct EdgeStmt <: Statement
    is_directed :: Bool
    from :: Union{NodeId,Subgraph}
    to :: Vector{Union{NodeId,Subgraph}}
    attr_list :: Vector{AList}
end

function Base.show(io :: IO, e :: EdgeStmt)
    print(io, e.from)
    for n in e.to
        print(io, e.is_directed ? "->" : "--", n)
    end
    for a in e.attr_list
        if !isempty(a.content)
            print(io, "[", a, "]")
        end
    end
end

struct AttrStmt <: Statement
    component :: GraphComponent
    attr_list :: Vector{AList}
end

function Base.show(io :: IO, a :: AttrStmt)
    print(io, component_name[a.component])
    for attr in a.attr_list
        print(io, "[", attr, "]")
    end
end

struct IdentityStmt <: Statement
    first :: String
    second :: String
end

function Base.show(io :: IO, i :: IdentityStmt)
    print(io, i.first, "=\"", i.second, "\"")
end

function Base.show(io :: IO, s :: Subgraph)
    print(io, "subgraph ")
    if !isnothing(s.name)
        print(io, s.name, " ")
    end
    print(io, "{\n")
    for s in s.stmt_lst
        print(io, "  ", s, ";\n")
    end
    print(io, "}\n")
end

mutable struct Graph
    is_strict :: Bool
    is_directed :: Bool
    name :: Union{String, Nothing}
    stmt_list :: Vector{Statement}
end

function Base.show(io :: IO, g :: Graph)
    print(io, g.is_strict ? "strict " : "",
              g.is_directed ? "digraph " : "graph ",
              !isnothing(g.name) ? "\"$(g.name)\"" * " " : "",
              "{\n")
    for s in g.stmt_list
        print(io, "  ", s, ";\n")
    end
    print(io, "}")
end

"""
    graph(name = nothing; kwargs ...)

Create a `Graph` object for undirected graphs. Each of the keyword arguments
is added as a graph attribute.

```jldoctest
julia> graph("hello"; fontname="sans serif", bgcolor="#fff0e0") |>
       edge("a", "b")
graph "hello" {
  graph[bgcolor="#fff0e0";fontname="sans serif";];
  "a"--"b";
}
```
"""
function graph(name = nothing; kwargs ...)
    Graph(false, false, name, []) |> attr(c_graph; kwargs ...)
end

"""
    digraph(name = nothing; kwargs ...)

Create a `Graph` object for directed graphs.

```jldoctest
julia> digraph() |>
       edge("a", "b")
digraph {
  "a"->"b";
}
```
"""
function digraph(name = nothing; kwargs ...)
    Graph(false, true , name, []) |> attr(c_graph; kwargs ...)
end

"""Make a `Graph` object strict.

```jldoctest
julia> graph() |> strict
strict graph {
}
```
"""
strict(g :: Graph) = begin g.is_strict = true; g end

"""
Add node to a graph.

```jldoctest
julia> graph() |> node("Node"; fillcolor="red", fontcolor="white")
graph {
  "Node"[fillcolor="red";fontcolor="white";];
}
```
"""
function node(id::String, port::Union{String, Nothing} = nothing; kwargs ...)
    g -> begin push!(g.stmt_list, NodeStmt(NodeId(id, port), [AList(kwargs)])); g end
end

"""
Add an edge to a graph.

```jldoctest
julia> graph() |> edge("a", "b"; label="connect!")
graph {
  "a"--"b"[label="connect!";];
}
julia> digraph() |> edge("a", "b", "c"; label="direct!")
digraph {
  "a"->"b"->"c"[label="direct!";];
}
```
"""
function edge(from::String, to::String ...; kwargs ...)
    edge(NodeId(from, nothing), NodeOrSubgraph[NodeId(n, nothing) for n in to]; kwargs ...)
end

function edge(from::NodeOrSubgraph, to::Vector{NodeOrSubgraph}; kwargs ...)
    g -> begin push!(g.stmt_list, EdgeStmt(g.is_directed, from, to, [AList(kwargs)])); g end
end

function attr(comp::GraphComponent; attrs ...)
    isempty(attrs) && return (g -> g)
    g -> begin push!(g.stmt_list, AttrStmt(comp,[AList(IdDict(attrs))])); g end
end

"""
Add attributes to the graph. The `symb` argument must be one of
`[:graph, :node, :edge]`.
"""
function attr(symb::Symbol; attrs ...)
    c = IdDict(:graph => c_graph, :node => c_node, :edge => c_edge)[symb]
    attr(c; attrs...)
end

function subgraph(name=nothing; kwargs...)
    Subgraph(name, []) |> attr(c_graph; kwargs...)
end

"""
Run the `dot` command to save the graph to file.
"""
function save(g::Graph, filename::String; engine="dot", format="svg")
    open(pipeline(`dot -T$(format) -K$(engine)`, filename), "w", stdout) do io
        print(io, g)
    end
end

end