struct Graph
  nv::Int64
  ne::Int64
  neighbours::Vector{Vector{Int64}}

  function Graph(nv::Int64, p::Float64)
    possible_edges::Vector = [(i, j) for i in 1:nv for j in i+1:nv]
    neighbours = [[] for _ in 1:nv]
    ne::Int64 = 0

    for edge in possible_edges
      if rand() < p
        (u, v) = edge
        push!(neighbours[u], v)
        push!(neighbours[v], u)
        ne += 1
      end
    end

    new(nv, ne, neighbours)
  end
end


function has_triangles(graph::Graph)::Bool
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  for u in 1:graph.nv
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
  for u in 1:graph.nv
    if isempty(neighbours[u])
      return true
    end
  end

  return false
end


function has_most_degrees_four(graph::Graph)
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  
  counter::Int64 = 0
  for u in 1:graph.nv
    if length(neighbours[u]) == 4
      counter += 1
    end
  end

  return counter >= graph.nv / 2
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

  return length(visited) == graph.nv
end


function get_avg_degree(graph::Graph)::Float64
  neighbours::Vector{Vector{Int64}} = graph.neighbours
  avg::Float64 = 0

  for i in 1:graph.nv
    avg += length(neighbours[i])
  end

  return avg / graph.nv
end


function is_tree(graph::Graph)::Bool
  return graph.ne == graph.nv - 1 && is_connected(graph)
end


function is_cyclic(graph::Graph)
  visited = falses(graph.nv)

  function dfs(v, parent)
    visited[v] = true
    for neighbor in graph.neighbours[v]
      if !visited[neighbor]
        if dfs(neighbor, v)
          return true
        end
      elseif neighbor != parent
        return true
      end
    end
    return false
  end

  for v in 1:graph.nv
    if !visited[v] && dfs(v, -1)
      return true
    end
  end
  return false
end


function is_bipartite(graph::Graph)
  colors = fill(-1, graph.nv)

  function dfs(v, color)
    colors[v] = color
    for neighbor in graph.neighbours[v]
      if colors[neighbor] == -1
        if !dfs(neighbor, 1 - color) # If the neighbor is uncolored, color it with the opposite color
          return false
        end
      elseif colors[neighbor] == color # If the neighbor has the same color, it's not bipartite
        return false
      end
    end
    return true # No conflicts found
  end

  for v in 1:graph.nv
    if colors[v] == -1 && !dfs(v, 0)
      return false
    end
  end
  return true
end


# https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
function has_a_bridge(graph::Graph)
  visited = falses(graph.nv )
  disc = fill(-1, graph.nv) # discovery time
  low = fill(-1, graph.nv) # first time the vertex v is reached
  parent = fill(-1, graph.nv) # parent vertices
  time = 0 # timer for discovery times

  function dfs(v)
    visited[v] = true
    disc[v] = low[v] = time
    time += 1
    for neighbor in graph.neighbours[v]
      if !visited[neighbor] # not discovered
        parent[neighbor] = v
        dfs(neighbor)
        low[v] = min(low[v], low[neighbor]) # track lowest possible time to reach v
        # If the lowest point reachable from neighbor is greater 
        # than discovery time of v, we found a bridge
        if low[neighbor] > disc[v]
          return true
        end
      elseif neighbor != parent[v]
        # If the neighbor is already visited and is not the parent, update low[v]
        low[v] = min(low[v], disc[neighbor])
      end
    end
    return false
  end

  for v in 1:graph.nv
    if disc[v] == -1 && dfs(v)
      return true
    end
  end

  return false
end


function is_petersen(graph::Graph)
  if graph.nv != 10 || graph.ne != 15
    return false
  end

  petersen_neighbours = [
    [1, 4, 5],
    [0, 2, 6],
    [1, 3, 7],
    [2, 4, 8],
    [0, 3, 9],
    [0, 7, 8],
    [1, 8, 9],
    [2, 5, 9],
    [3, 5, 6],
    [4, 6, 7] 
  ]

  for v in 1:10
    if sort(graph.neighbours[v]) != sort(petersen_neighbours[v])
      return false
    end
  end

  return true
end
