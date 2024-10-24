module GraphvizDotLang

using Base.Filesystem: dirname, mkpath
using Graphviz_jll

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
    is_directed :: Bool
    stmt_list :: Vector{Statement}
end

"""
    HTML(html::String)

Any HTMLish label should be wrapped into a HTML struct, so that we know
to change the quotation marks from double quotes to angled brackets.
"""
struct HTML
    html :: String
end

AListDict = IdDict{Symbol, Union{String,HTML}}
struct AList
    content :: IdDict{Symbol,Union{String,HTML}}
end

AList(x::IdDict{Symbol,String}) = AList(convert(IdDict{Symbol, Union{String,HTML}}, x))

function Base.show(io :: IO, alst :: AList)
    for (k, v) in pairs(alst.content)
        value_repr = v isa HTML ? "<$(v.html)>" : "\"$v\""
        print(io, "$k=$value_repr;")
    end
end

struct NodeId
    name :: String
    port :: Union{String,Nothing}
end

function NodeId(expr::String)
    components = split(expr, ":")
    name = components[1]
    port = length(components) > 1 ?
        join(":" * c for c in  components[2:end]) :
        nothing
    NodeId(name, port)
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

function Base.show(io::IO, a::AttrStmt)
    print(io, component_name[a.component])
    for attr in a.attr_list
        print(io, "[", attr, "]")
    end
end

struct IdentityStmt <: Statement
    first :: String
    second :: String
end

function Base.show(io::IO, i::IdentityStmt)
    print(io, i.first, "=\"", i.second, "\"")
end

function Base.show(io::IO, s::Subgraph)
    print(io, "subgraph ",
              !isnothing(s.name) ? "\"$(s.name)\" " : "",
              "{\n")
    for s in s.stmt_list
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

function Base.show(io::IO, g::Graph)
    print(io, g.is_strict ? "strict " : "",
              g.is_directed ? "digraph " : "graph ",
              !isnothing(g.name) ? "\"$(g.name)\" " : "",
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

"""
    strict

Make a `Graph` object strict.

```jldoctest
julia> graph() |> strict
strict graph {
}
```
"""
strict(g :: Graph) = begin g.is_strict = true; g end

"""
    node(id::String, port::Union{String,Nothing}=nothing; kwargs...)

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
    edge(from::String, to::String ...; kwargs ...)

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
    edge(NodeId(from), NodeOrSubgraph[NodeId(n) for n in to]; kwargs ...)
end

function attr(comp::GraphComponent; attrs ...)
    isempty(attrs) && return (g -> g)
    g -> begin push!(g.stmt_list, AttrStmt(comp,[AList(attrs)])); g end
end

function edge(from::NodeOrSubgraph, to::Vector{NodeOrSubgraph}; kwargs ...)
    g -> begin push!(g.stmt_list, EdgeStmt(g.is_directed, from, to, [AList(kwargs)])); g end
end

"""
    attr(symb::Symbol; attrs...)

Add attributes to the graph. The `symb` argument must be one of
`[:graph, :node, :edge]`.
"""
function attr(symb::Symbol; attrs ...)
    c = IdDict(:graph => c_graph, :node => c_node, :edge => c_edge)[symb]
    attr(c; attrs...)
end

"""
    subgraph(parent::Union{Graph,Subgraph}, name=nothing; kwargs...)

Create new subgraph. Returns the subgraph.
"""
function subgraph(g::Union{Graph,Subgraph}, name=nothing; kwargs...)
    s =  Subgraph(name, g.is_directed, []) |> attr(c_graph; kwargs...)
    push!(g.stmt_list, s)
    s
end

"""
    save(g::Graph, filename::String; engine="dot", format="svg")

Run the `dot` command to save the graph to file. Creates the containing directory
if it doesn't already exist.
"""
function save(g::Graph, filename::String; engine="dot", format="svg")
    mkpath(dirname(filename))
    open(pipeline(`$(Graphviz_jll.dot()) -T$(format) -K$(engine)`, filename), "w", stdout) do io
        print(io, g)
    end
end

"""
    show(io::IO, mime::MIME"image/svg", g::Graph)

Show the graph as an SVG.
"""
function Base.show(io::IO, mime::MIME"image/svg", g::Graph)
    open(pipeline(`$(Graphviz_jll.dot()) -Tsvg`, io), "w", stdout) do dot_in
        print(dot_in, g)
    end
end

"""
    show(io::IO, mime::MIME"image/png", g::Graph)

Show the graph as an SVG.
"""
function Base.show(io::IO, mime::MIME"image/png", g::Graph)
    open(pipeline(`$(Graphviz_jll.dot()) -Tpng`, io), "w", stdout) do dot_in
        print(dot_in, g)
    end
end

end