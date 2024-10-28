include("graph.jl")
import JSON
using PlotlyJS
using Printf

const NO_TRIES::Int64 = 2000
const PS::Vector{Float64} = [0.05i for i in 1:20]
const NS::Vector{Int64} = append!([1,2,3,5,7,10], [i for i in 15:5:100])

struct GraphPlotContext
  id::String
  metric_func::Base.Callable
  graph_title::Base.Callable
  graph_y_label::String
end

const METRICS::Vector{GraphPlotContext} = [
  GraphPlotContext(
    "is_connected",
    is_connected,
    function(n) "P(is connected) for n=$n" end,
    "P(is connected)"
  ),
  GraphPlotContext(
    "has_isolated",
    has_isolated_vertices,
    function(n) "P(has isolated vertices) for n=$n" end,
    "P(has isolated vertices)"
  ),
  GraphPlotContext(
    "has_triangles",
    has_triangles,
    function(n) "P(has triangles) for n=$n" end,
    "P(has triangles)"
  ),
  GraphPlotContext(
    "four_degree",
    has_most_degrees_four,
    function(n) "P(has most degrees equal to 4) for n=$n" end,
    "P(has most degrees equal to 4)"
  ),
  GraphPlotContext(
    "is_tree",
    is_tree,
    function(n) "P(is a tree) for n=$n" end,
    "P(is a tree)"
  ),
  GraphPlotContext(
    "is_cyclic",
    is_cyclic,
    function(n) "P(contains a cycle) for n=$n" end,
    "P(contains a cycle)"
  ),
  GraphPlotContext(
    "is_bipartite",
    is_bipartite,
    function(n) "P(is bipartite) for n=$n" end,
    "P(is bipartite)"
  ),
  GraphPlotContext(
    "has_a_bridge",
    has_a_bridge,
    function(n) "P(has a bridge) for n=$n" end,
    "P(has a bridge)"
  ),
  GraphPlotContext(
    "is_petersen",
    is_petersen,
    function(n) "P(is a Petersen graph) for n=$n" end,
    "P(is a Petersen graph)"
  )
]

function generate_results()
  results::Dict = Dict()
  batch::Dict = Dict()
  for n in NS
    batch[n] = Dict()
    for p in PS
      println("Generating graphs for n=$n, p=$p")
      batch[n][@sprintf "%.2f" p] = [Graph(n, p) for _ in 1:NO_TRIES]
    end
  end

  for n in NS
    results[n] = Dict()
    for p in PS
      p_key = @sprintf "%.2f" p
      println("Processing n = $n, p = $p_key...")
      results[n][p_key] = Dict()
      for metric in METRICS
        results[n][p_key][metric.id] = 0.
      end

      for i in 1:NO_TRIES
        for metric in METRICS
          results[n][p_key][metric.id] += metric.metric_func(batch[n][p_key][i])
        end
      end

      for res_key in keys(results[n][p_key])
        results[n][p_key][res_key] /= NO_TRIES
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

const PLAY_BUTTONS = [
  attr(
    label = "Play",
    method = "animate",
    args = [
      nothing,
      attr(
        fromcurrent = true,
        transition = (duration = 250),
        frame = (duration = 250, redraw = true),
      ),
    ],
  ),
  attr(
    label = "Pause",
    method = "animate",
    args = [
      [nothing],
      attr(
        mode = "immediate",
        fromcurrent = true,
        transition = (duration = 250),
        frame = (duration = 250, redraw = true),
      ),
    ],
  ),
]

const SLIDER = [
  attr(
    active=0,
    currentvalue=attr(
      prefix="n: "
    ),
    steps=[
      attr(
        method="animate",
        label=n,
        args=[
          ["frame_$n"],
          attr(
            mode="immediate",
            transition=attr(duration=0),
            frame=attr(duration=5, redraw=true),
          ),
        ],
      ) for n in NS
    ],
    pad=Dict(:t=>70)
  ),
]


function make_plots()
  results::Dict = JSON.parsefile("results/res.json")
  x = round.(PS; digits=2)

  for metric in METRICS
    trace = [
      scatter(
        x=x, y=[results[string(1)][@sprintf "%.2f" p][metric.id] for p in PS]
      )
    ]
    frames = PlotlyFrame[
      frame(
        data=[attr(
          y=[results[string(n)][@sprintf "%.2f" p][metric.id] for p in PS],
        )],
        layout=attr(
          title_text=metric.graph_title(n)
        ),
        name="frame_$n",
        traces=[0],
      )
      for n in NS
    ]

    layout = Layout(
      width=1200,
      height=800,
      margin_b=90,
      xaxis_range=[0.04, 1.01],
      xaxis_title="p",
      xaxis = attr(
        tickmode = "linear",
        tick0 = 0.0,
        dtick = 0.05
      ),
      yaxis_range=[-0.01, 1.01],
      yaxis_title=metric.graph_y_label,
      title_text=metric.graph_title(1),
      sliders=SLIDER,
      updatemenus=[
        attr(
          type="buttons",
          direction="left",
          showactive=true,
          xanchor="left",
          yanchor="top",
          x=0,
          y=0,
          pad=Dict(:t=>170),
          buttons=PLAY_BUTTONS
        )
      ],
    )
    _plot = Plot(trace, layout, frames)

    save_path::String = "metric_$(metric.id)"
    println("> Saving plot in $(save_path).html")

    dir::String = joinpath(@__DIR__, "./results/plots/")
    (!isdir(dir)) && mkdir(dir)
    savefig(_plot, dir * "$(save_path).html")
  end
end


function main(args::Array{String}=[])
  generate_results()
  make_plots()
end


if abspath(PROGRAM_FILE) == @__FILE__
  main(ARGS)
end
