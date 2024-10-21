include("graph.jl")
import JSON
using Plots
using PlotlyBase: PlotConfig
using LaTeXStrings
ENV["GKSwstype"] = "100"
plotlyjs()

const NO_TRIES::Int64 = 10000
const PS::Vector{Float64} = [0.1, 0.3, 0.5, 0.7, 0.9]
const NS::Vector{Int64} = append!([1,2,5,10], [i for i in 15:5:100])

struct GraphPlotContext
  id::String
  metric_func::Base.Callable
  graph_title::String
  grpah_y_label::String
end

const METRICS::Vector{GraphPlotContext} = [
  GraphPlotContext(
    "is_connected",
    is_connected,
    L"\text{P(is connected) for graph}\ G_{n, p}",
    L"\text{P(is connected)}",
  ),
  GraphPlotContext(
    "has_isolated",
    has_isolated_vertices,
    L"\text{P(has isolated vertices) for graph}\ G_{n, p}",
    L"\text{P(has isolated vertices)}",
  ),
  GraphPlotContext(
    "has_triangles",
    has_triangles,
    L"\text{P(has triangles) for graph}\ G_{n, p}",
    L"\text{P(has triangles)}",
  ),
  GraphPlotContext(
    "four_degree",
    has_most_degrees_four,
    L"\text{P(has most degrees equal to 4) for graph}\ G_{n, p}",
    L"\text{P(has most degrees equal to 4)}",
  ),
  GraphPlotContext(
    "avg_degree",
    get_avg_degree,
    L"\text{Average degree for graph}\ G_{n, p}",
    L"\text{Average degree}",
  ),
  GraphPlotContext(
    "is_tree",
    is_tree,
    L"\text{P(is a tree) for graph}\ G_{n, p}",
    L"\text{P(is a tree)}",
  ),
  GraphPlotContext(
    "is_cyclic",
    is_cyclic,
    L"\text{P(contains a cycle) for graph}\ G_{n, p}",
    L"\text{P(contains a cycle)}",
  ),
  GraphPlotContext(
    "is_bipartite",
    is_bipartite,
    L"\text{P(is bipartite) for graph}\ G_{n, p}",
    L"\text{P(is bipartite)}",
  ),
  GraphPlotContext(
    "has_a_bridge",
    has_a_bridge,
    L"\text{P(has a bridge) for graph}\ G_{n, p}",
    L"\text{P(has a bridge)}",
  ),
  GraphPlotContext(
    "is_petersen",
    is_petersen,
    L"\text{P(is a Petersen graph) for graph}\ G_{n, p}",
    L"\text{P(is a Petersen graph)}",
  )
]


function generate_results()
  results::Dict = Dict()
  batch::Dict = Dict()
  for p in PS
    batch[p] = Dict()
    for n in NS
      batch[p][n] = [Graph(n, p) for _ in 1:NO_TRIES]
    end
  end

  for p in PS
    results[p] = Dict()
    for n in NS
      println("Processing n = $n, p = $p...")
      results[p][n] = Dict()
      for metric in METRICS
        results[p][n][metric.id] = 0.
      end
            
      for i in 1:NO_TRIES
        for metric in METRICS
          results[p][n][metric.id] += metric.metric_func(batch[p][n][i])
        end
      end
      
      for key in keys(results[p][n])
        results[p][n][key] /= NO_TRIES
      end
    end
  end

  dir::String = joinpath(@__DIR__, "./results/")
  if !isdir(dir)
    mkdir(dir)
  end

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
      title=metric.graph_title,
      xlabel=L"\text{Number of vertices}\ [n]",
      ylabel=metric.grpah_y_label,
      xticks=0:10:100,
      xtickfontsize=10,ytickfontsize=10,titlefontsize=12,
      xguidefontsize=10,yguidefontsize=10,legendfontsize=12
    )

    for p in PS
      x::Vector{Int64} = NS
      y::Vector{Float64} = [results[string(p)][string(n)][metric.id] for n in NS]

      plot!(
        x, y,
        label=latexstring("\$p = {$(p)}\$"),
        linewidth=3,
        config=PlotConfig(
          scrollZoom=true,
          displaylogo=false
        ),
        legend=:right,
        extra_plot_kwargs = KW(
          :include_mathjax => "cdn",
          :yaxis => KW(:automargin => true),
          :xaxis => KW(:domain => "auto")
        )
      )
    end # p

    save_path::String = "metric_$(metric.id)"
  
    println("> Saving plot in $(save_path).html")
  
    dir::String = joinpath(@__DIR__, "./results/plots/")
    (!isdir(dir)) && mkdir(dir)
    savefig(_plot, dir * "$(save_path).html")
  end # metric
end


function main(args::Array{String})
  generate_results()
  make_plots()
end


if abspath(PROGRAM_FILE) == @__FILE__
  main(ARGS)
end
