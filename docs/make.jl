push!(LOAD_PATH,"../src/")

using Documenter, GraphvizDotLang

makedocs(sitename="GraphvizDotLang documentation")
deploydocs(
    repo = "github.com/jhidding/GraphvizDotLang.jl.git",
)