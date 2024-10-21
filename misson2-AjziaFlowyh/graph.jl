mutable struct Graph
  n::Int64
  neighbours::Vector{Vector{Int64}}

  function Graph(n::Int64, p::Float64)
    possible_edges::Vector = [(i, j) for i in 1:n for j in i+1:n]
    neighbours = [[] for _ in 1:n]

    for edge in possible_edges
      if rand() < p
        (u, v) = edge
        push!(neighbours[u], v)
        push!(neighbours[v], u)
      end
    end

    new(n, neighbours)
  end
end


function has_triangles(graph::Graph)::Bool
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  for u in 1:graph.n
    _neighbours = neighbours[u]
    for v in _neighbours, w in neighbours[v]
      if w in _neighbours
        return true
      end
    end
  end

  return false
end


function has_isolated_vertices(graph::Graph)::Bool
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  for u in 1:graph.n
    if isempty(neighbours[u])
      return true
    end
  end

  return false
end


function has_most_degrees_four(graph::Graph)
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  
  counter::Int64 = 0
  for u in 1:graph.n
    if length(neighbours[u]) == 4
      counter += 1
    end
  end

  return counter >= graph.n / 2
end


function is_connected(graph::Graph)::Bool
  neighbours::Vector{Vector{Int64}} = graph.neighbours

  visited::Vector{Int64} = [1]
  queue::Vector{Int64} = [1]

  while !isempty(queue)
    u::Int64 = popfirst!(queue)
    
    for v in neighbours[u]
      if !(v in visited)
        push!(visited, v)
        push!(queue, v)
      end
    end
  end

  return length(visited) == graph.n
end


function get_avg_degree(graph::Graph)::Float64
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  avg::Float64 = 0

  for i in 1:graph.n
    avg += length(neighbours[i])
  end

  return avg / graph.n
end
