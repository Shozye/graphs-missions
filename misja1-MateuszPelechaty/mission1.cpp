#include <iostream>
#include <vector>
#include <random>
#include <deque>
#include <unordered_set>
#include <cmath>
#include <fstream>
#include <functional>
#include <algorithm>
#include<memory>

class Graph {
public:
    std::vector<std::vector<int>> edges;
    int n;

    // Static random number generator shared across all instances
    static std::random_device rd;
    static std::minstd_rand generator;

    // Constructor that accepts precomputed edges
    Graph(int n, const std::vector<std::pair<int, int>>& possible_edges) : n(n), possible_edges(possible_edges) {
        edges.resize(n);
    }

    void add_edge(int u, int v) {
        edges[u].push_back(v);
        edges[v].push_back(u);
    }

protected:
    std::vector<std::pair<int, int>> possible_edges;
};

// Initialize the static members
std::random_device Graph::rd;
std::minstd_rand Graph::generator(Graph::rd());

class UniformGraph : public Graph {
public:
    UniformGraph(int n, int m, const std::vector<std::pair<int, int>>& shared_edges) 
        : Graph(n, shared_edges) {
        generate_uniform_edges(m);
    }

    void generate_uniform_edges(int m) {
        if (m > possible_edges.size()) {
            std::cerr << "Error: m > possible_edges.size()\n";
            throw std::invalid_argument("Too many edges requested.");
        }

        std::shuffle(possible_edges.begin(), possible_edges.end(), generator);



        // Shuffle using Fisher-Yates and use shared possible_edges
        // fisher_yates_shuffle(m);

        // Add the first `m` edges after shuffling
        for (int i = 0; i < m; ++i) {
            add_edge(possible_edges[i].first, possible_edges[i].second);
        }
    }

private:
    void fisher_yates_shuffle(int limit) {
        limit = std::min(limit, static_cast<int>(possible_edges.size()));
        for (int i = 0; i < limit - 1; ++i) {
            std::uniform_int_distribution<int> dist(i, limit - 1);
            int random_index = dist(generator);
            std::swap(possible_edges[i], possible_edges[random_index]);
        }
    }
};

class BinomialGraph : public Graph {
public:
    BinomialGraph(int n, double p, const std::vector<std::pair<int, int>>& shared_edges) 
        : Graph(n, shared_edges) {
        generate_binomial_edges(p);
    }

    void generate_binomial_edges(double p) {
        static std::uniform_real_distribution<> dist(0.0, 1.0);

        for (const auto &edge : possible_edges) {
            if (dist(generator) < p) {
                add_edge(edge.first, edge.second);
            }
        }
    }
};

bool has_at_least_one_triangle(const Graph &g) {

    
    for (int v1 = 0; v1 < g.edges.size(); ++v1) {
        for (int v2 : g.edges[v1]) {
            for (int v3 = 0; v3 < g.edges.size(); ++v3) {
                if (std::find(g.edges[v3].begin(), g.edges[v3].end(), v1) != g.edges[v3].end() &&
                    std::find(g.edges[v3].begin(), g.edges[v3].end(), v2) != g.edges[v3].end()) {
                    return true;
                }
            }
        }
    }
    return false;
}

bool is_connected(const Graph &g) {
    std::deque<int> queue{0};
    std::unordered_set<int> visited{0};

    while (!queue.empty()) {
        int v = queue.front();
        queue.pop_front();
        for (int neighbor : g.edges[v]) {
            if (visited.find(neighbor) == visited.end()) {
                queue.push_back(neighbor);
                visited.insert(neighbor);
            }
        }
    }

    return visited.size() == g.n;
}

bool has_half_of_vertices_with_degree_4(const Graph &g) {
    int count = 0;
    for (const auto &edges : g.edges) {
        if (edges.size() >= 4) {
            count++;
        }
    }
    return count >= g.n / 2;
}

bool has_amount_edges_different_than_m(int m, const Graph &g) {
    int edge_count = 0;
    for (const auto &edges : g.edges) {
        edge_count += edges.size();
    }
    return m != edge_count / 2;
}

double binom_n_2(int n) {
    return n * (n - 1) / 2.0;
}

void main_loop() {
    

    std::vector<std::tuple<std::function<double(int)>, std::string, int>> possible_ms = {
        {[](int n) { return std::sqrt(n); }, "sqrt(n)", 500},
        {[](int n) { return n; }, "n", 800},
        {[](int n) { return 1.5 * n; }, "1.5n", 800},
        {[](int n) { return 2 * n; }, "2n", 800},
        {[](int n) { return 3 * n; }, "3n", 1200},
        {[](int n) { return n * std::log2(n); }, "n*log2(n)", 300},
    };

    std::string print_string;

    for (const auto &[possible_m, m_name, ns_max] : possible_ms) {
        std::vector<int> ns_tested = {5};
        for (int i = 10; i < ns_max + 11; i += 25) {
            ns_tested.push_back(i);
        }

        for (int n : ns_tested) {
            int m = static_cast<int>(possible_m(n));
            if (m > binom_n_2(n)) {
                continue;
            }
            double p = m / binom_n_2(n);

            std::vector<std::pair<int, int>> possible_edges;
            for (int u = 0; u < n; ++u) {
                for (int v = u + 1; v < n; ++v) {
                    possible_edges.emplace_back(u, v);
                }
            }

            std::vector<std::function<bool(const Graph &)>> features = {
                has_at_least_one_triangle,
                is_connected,
                has_half_of_vertices_with_degree_4,
                [m](const Graph &g) { return has_amount_edges_different_than_m(m, g); }
            };

            std::cout << "Doing tests for n=" << n << ", m=" << m << std::endl;

            std::vector<std::string> graph_types = {"uniform", "binomial"};

            const int AMOUNT_TESTS = 5000;
            for (const auto& graph_type : graph_types) {
                // Store results for each feature
                std::vector<double> feature_results(features.size(), 0.0);

                for (int i = 0; i < AMOUNT_TESTS; ++i) {
                    std::shared_ptr<Graph> graph;

                    if (graph_type == "uniform") {
                        graph = std::make_shared<UniformGraph>(n, m, possible_edges);
                    } else if (graph_type == "binomial") {
                        graph = std::make_shared<BinomialGraph>(n, p, possible_edges);
                    }
                    for (size_t j = 0; j < features.size(); ++j) {
                        feature_results[j] += features[j](*graph);
                    }
                }

                for (auto &result : feature_results) {
                    result /= AMOUNT_TESTS;
                }

                print_string += std::to_string(n) + " " + m_name + " " + graph_type + " ";
                for (double result : feature_results) {
                    print_string += std::to_string(result) + " ";
                }
                print_string += "\n";
            }
        }
    }

    std::ofstream file("data.txt");
    if (file.is_open()) {
        file << print_string;
        file.close();
    } else {
        std::cerr << "Unable to open file data.txt\n";
    }
}

int main() {
    main_loop();
    return 0;
}
