include("graph.jl")
import JSON
using Plots
using LaTeXStrings
ENV["GKSwstype"] = "100"

const NO_TRIES::Int64 = 100
const PS::Vector{Float64} = [0.1, 0.3, 0.5, 0.7, 0.9]
const NS::Vector{Int64} = append!([1,2,5,10], [i for i in 15:5:100])

const METRICS::Vector = [
  ("is_connected", is_connected,
   "P(is connected) for graph $(L"G_{n, p}")"),
  ("has_isolated", has_isolated_vertices,
   "P(has isolated vertices) for graph $(L"G_{n, p}")"),
  ("has_triangles", has_triangles,
   "P(has triangles) for graph $(L"G_{n, p}")"),
  ("four_degree", has_most_degrees_four,
   "P(has most degrees equal to 4) for graph $(L"G_{n, p}")"),
  ("avg_degree", get_avg_degree,
   "Average degree for graph $(L"G_{n, p}")")
]



function generate_results()
  results::Dict = Dict()

  for p in PS
    results[p] = Dict()
    for n in NS
      println("Processing p = $p, n = $n...")
      results[p][n] = Dict()
      for metric in METRICS
        results[p][n][metric[1]] = 0.
      end
            
      for _ in 1:NO_TRIES
        graph::Graph = Graph(n, p)
        
        for metric in METRICS
          results[p][n][metric[1]] += metric[2](graph)
        end
      end
      
      for key in keys(results[p][n])
        results[p][n][key] /= NO_TRIES
      end
    end
  end

  dir::String = joinpath(@__DIR__, "./results/")
  (!isdir(dir)) && mkdir(dir)
  open("results/res.json", "w") do f
    JSON.print(f, results)
  end
end



function make_plots()
  results::Dict = JSON.parsefile("results/res.json")


  for metric in METRICS
    _plot = plot(
      [], [],
      primary=false,
      size=(800, 800),
      legend=:best,
      title=metric[3],
      xlabel="number of vertices [n]",
      ylabel="probability", # except the last one! (TODO)
      xticks=0:10:100,
      xtickfontsize=10,ytickfontsize=10,titlefontsize=12,
      xguidefontsize=10,yguidefontsize=10,legendfontsize=12
    )

    for p in PS
      x::Vector{Int64} = NS
      y::Vector{Float64} = [results[string(p)][string(n)][metric[1]] for n in NS]

      plot!(
        x, y,
        label="p = $p",
        linewidth=3,
      )
    end # p

    save_path::String = "metric_$(metric[1])"
  
    println("> Saving plot in $(save_path).svg")
  
    dir::String = joinpath(@__DIR__, "./results/plots/")
    (!isdir(dir)) && mkdir(dir)
    savefig(_plot, dir * "$(save_path).svg")
  end # metric
end



function main(args::Array{String})
  generate_results()
  make_plots()
end


if abspath(PROGRAM_FILE) == @__FILE__
  main(ARGS)
end
