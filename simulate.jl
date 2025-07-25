using Random
using DataStructures
using Plots
using DataFrames
using CSV
function create_hypergraph(n, m, k; max_attempts=100)
    for attempt in 1:max_attempts
        edges = Set{Vector{Int}}()
        while length(edges) < m
            edge = sort(randperm(n)[1:k])  
            push!(edges, edge)
        end

        if is_fully_connected(collect(edges), n)
            return collect(edges)
        end
    end
    error("Failed to generate a fully connected hypergraph after $max_attempts attempts.")
end
function is_fully_connected(edges, n)
    uf = IntDisjointSets(n) 
    for edge in edges
        root = edge[1]
        for v in edge
            union!(uf, root, v)
        end
    end
    root = find_root(uf, 1)
    return all(find_root(uf, v) == root for v in 2:n)
end
function neighbor_get(n, k, edges)
    neighborhood = []  
    member = []        
    node_to_edges = [Vector{Vector{Int}}() for _ in 1:n]  

    for (idx, edge) in enumerate(edges)
        for v in edge
            push!(node_to_edges[v], edge)
        end
    end
    for i in 1:n
        neighbors_after = get_game_neighborinone(i, edges)
        b = Int(length(neighbors_after) / (k - 1))
        push!(neighborhood, neighbors_after)
        push!(member, b)
    end
    return neighborhood, member, node_to_edges
end
function get_game_neighborinone(center, edge_list)
    other_members = [filter(x -> x != center, arr) for arr in edge_list if center in arr]
    other_members = vcat(other_members...)
    return other_members
end
function get_game_neighbor1(center, edge_list)
    other_members = [arr for arr in edge_list if center in arr]
    return other_members
end
function calculate_payoffs(n, k, r, edges, strategies, ϕ, node_to_edges, β)
    payoffs = zeros(Float64, n)
    for center in 1:n
        sum_profit = 0.0
        is_cooperator = strategies[center] == 1
        for edge in node_to_edges[center]
        sum_c = sum(strategies[v] for v in edge)
        sum_d = k - sum_c
        profit=0
            if sum_d > ϕ
                if is_cooperator
                        profit=r*(sum_c+β*sum_d)-1
                else
                        profit = sum_c * r * (1 - β)
                end
            else
                if is_cooperator
                    profit = sum_c * r - 1
                else
                    profit = sum_c * r
                end
            end
            sum_profit += profit
            end
        payoffs[center] = sum_profit
    end
    return payoffs
end
function update_strategies(n, strategies, payoffs, neighborhood, member, p1)
    new_strategies = deepcopy(strategies)
    for i in 1:n
            neighbor = shuffle(neighborhood[i])[1]
            f_i = payoffs[i] / member[i]
            f_j = payoffs[neighbor] / member[neighbor]
            temp = 1 / (1 + ℯ^(-((f_j - f_i) / p1)))
            if rand() < temp
                new_strategies[i] = strategies[neighbor]
            end
    end
    return new_strategies
end
function run_simulation(n, m, k, r,ϕ, p1, step, β)
    edges = create_hypergraph(n, m, k)
    n_half = div(n, 2)
    strategies = vcat(zeros(Int,n_half ), ones(Int,n_half))
    payoffs = zeros(n)
    neighborhood, member,node_to_edges= neighbor_get(n, k, edges)
    cooperation_rates = zeros(step)
    cooperation_rates[1] = sum(strategies) / n
    for i in 1:step-1
        payoffs = calculate_payoffs(n, k, r, edges, strategies,ϕ, node_to_edges, β,)
        strategies = update_strategies(n, strategies, payoffs, neighborhood, member, p1)
        cooperation_rate = sum(strategies) / n
        cooperation_rates[i+1] = cooperation_rate
        if cooperation_rate <= 0.000 || cooperation_rate >= 0.999
            return cooperation_rates[i+1]
        end
    end
    return cooperation_rates[end]
end
