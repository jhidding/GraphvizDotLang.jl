push!(LOAD_PATH,"../src/")

using Documenter, DotLang

makedocs(sitename="DotLang documentation")
deploydocs(
    repo = "github.com/jhidding/DotLang.jl.git",
)