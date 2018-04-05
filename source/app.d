import std.stdio;
import std.format;
import std.csv;
import std.algorithm;
import std.array;
import std.typecons;
import std.file;

import msgpack;

/**
* Macros:
*  DB_GRAPH = A DeBruijn graph as a 2D array where tab[i][j] is a value superior
*  to 0 if there is an edge labelled with this value between nodes i and j, and 
*  -1 if there is no edge between i and j.
*/

alias Graph = int[][];
alias Edge = Tuple!(int,int);
alias Rule = int[];

struct RulesList {
    int n_state;
    int n_vois;
    int n_rules;

    Rule[] rules;

    this(int states, int vois){
        rules = new Rule[](0,0);
        n_state = states;
        n_vois = vois;
        n_rules = 0;
    }

    void addRule(Rule rule){
        n_rules++;
        rules ~= rule;
    }
}

RulesList rules_list = void;

void main(){
    enum n_state = 2;
    enum n_vois = 4;

    Graph edges_order;
    Graph g;

    g = createDeBruijn!(n_state, n_vois);

    edges_order = maxCycleNodeOrder(g);
    graphToDot(g, format("v%ds%d.dot", n_state, n_vois));
    graphToDot(edges_order, format("v%ds%d_order.dot", n_state, n_vois));
    orderToCSV(edges_order, format("v%ds%d_order.csv", n_state, n_vois));
    computeReversibles(g.length, format("v%ds%d_order.csv", n_state, n_vois), format("v%ds%d.dat", n_vois, n_state), n_state, n_vois);
}

void computeReversibles(ulong graph_size, string order_file_path, string result_file_path, int n_state, int n_vois){
    auto file = File(order_file_path, "r");
    auto order = file.byLine.joiner("\n").csvReader!(Tuple!(int,int)).array;

    rules_list = RulesList(n_state, n_vois); 

    Graph injectivity_graph = new int[][](graph_size ^^ 2, graph_size ^^ 2);
    Graph setted_edges = new int[][](graph_size, graph_size);
    bool[][] reachability_matrix = new bool[][](graph_size ^^ 2 , graph_size ^^ 2);

    foreach(i; 0..setted_edges.length){
        foreach(j; 0..setted_edges.length){
            setted_edges[i][j] = -1;
        }
    }

    enumerateReversible(setted_edges, order, 0, n_state, injectivity_graph, reachability_matrix);

    ubyte[] result = pack(rules_list);

    std.file.write(result_file_path, result);
}

void enumerateReversible(Graph setted_edges, Edge[] order, int stage, int n_state, Graph injectivity_graph, bool[][] reachability_matrix, int number_one_left = 4, int number_zero_left = 4){
    if(stage < order.length){
        foreach(i; 0..n_state){
            setted_edges[order[stage][0]][order[stage][1]] = i;

            if(!isNonReversible(setted_edges, injectivity_graph, reachability_matrix))
                enumerateReversible(setted_edges, order, stage+1, n_state, injectivity_graph, reachability_matrix);
        }

        setted_edges[order[stage][0]][order[stage][1]] = -1;

    }
    else{
        graphToDot(setted_edges, "exemple.dot");
        writeRule(setted_edges);
    }
}

void writeRule(Graph setted_edges){
    int n_nodes_debruijn = rules_list.n_state ^^ (rules_list.n_vois - 1);
    int[] rule;

    for(int i = 0; i < n_nodes_debruijn; i++){
        for(int j = 0; j < rules_list.n_state; j++){
            rule ~= setted_edges[i][((i * rules_list.n_state) + j) % n_nodes_debruijn];
        }
    }

    rules_list.addRule(rule);
}

bool isNonReversible(Graph setted_edges, Graph injectivity_graph, bool[][] reachability_matrix){
    foreach(i; 0..injectivity_graph.length){
        foreach(j; 0..injectivity_graph.length){
            injectivity_graph[i][j] = -1;
        }
    }

    foreach(i; 0..setted_edges.length){
        foreach(j; 0..setted_edges.length){
            foreach(i_prime; 0..setted_edges.length){
                foreach(j_prime; 0..setted_edges.length){
                    if(setted_edges[i][j] > -1 && setted_edges[i_prime][j_prime] > -1 && setted_edges[i][j] == setted_edges[i_prime][j_prime] && (i != i_prime || j != j_prime)){
                        injectivity_graph[i * setted_edges.length + i_prime][j * setted_edges.length + j_prime] = 0;
                    }
                }
            }
        }
    }

    auto reachability_matrix_p = reachabilityMatrix(injectivity_graph, reachability_matrix);

    foreach(i; 0..reachability_matrix.length){
        if(reachability_matrix_p[i][i]){
            return true;
        }
    }

    return false;

}

/**
* Create the DeBruijn graph for a neighbourhood size and a number of states
* Params:
*  n_state = number of states
*  n_vois = size of the neighbourhood
* Returns: $(DB_GRAPH)
*/
Graph createDeBruijn(int n_state, int n_vois)(){
    enum n_nodes_debruijn = n_state ^^ (n_vois - 1);
    Graph graph = new int[][](n_nodes_debruijn, n_nodes_debruijn);
    
    // At first, there are no edges
    setGraph(graph, -1);

    // For each node represented by the digits x0x1...xN in base n_state
    // There is an edge to the node represented by the digits x1x2...j for
    // each j between 0 and (n_state -1).
    for(int i = 0; i < n_nodes_debruijn; i++){
        for(int j = 0; j < n_state; j++){
            // 1. We multiply the number in base n_state by n_state to shift
            //  the digits from 1 to the left
            // 2. We add j to set the rightmost digit
            // 3. We apply module n_nodes_debruijn to "forget" the leftmost
            //  digit 
            graph[i][((i * n_state) + j) % n_nodes_debruijn] = j;
        }
    }

    return graph;
}

/**
* From a DeBruijn graph, compute the order in which the values of the edges should be 
* setted to create a maximum of cycles in the earlier steps of reversible cellular 
* automata finding algorithm
* Params:
*   graph = $(DB_GRAPH)
* Returns: A graph where each edge is labelled with its order
*/
Graph maxCycleNodeOrder(Graph graph){
    // We will keep track of the edges whose values have already been setted in 
    // this graph, and their order
    Graph setted_edges = new int[][] (graph.length, graph.length);
    setGraph(setted_edges, -1);

    int edges_in_cyles = 0;
    int next_edge_to_add = 0;

    for(int csize = 1; csize <= graph.length; csize++){
        writefln("csize = %d and graph.length = %d", csize, graph.length);
        foreach(i; 0..csize+1){
            nCycle(graph, setted_edges, next_edge_to_add, edges_in_cyles, csize);
        }
    }

    foreach(i; 0..setted_edges.length){
        foreach(j; 0..setted_edges.length){
            if(graph[i][j] > -1 && setted_edges[i][j] == -1){
                setted_edges[i][j] = next_edge_to_add;
                next_edge_to_add++;
            }
        }
    }

    return setted_edges;
}

/**
* Tries to find a cycle of size n. 
*
* It works by trying each edge that hasn't yet been
* assigned an order and for each of them, trying to add (n-1) edges that haven't been
* assigned either. For each n-uplet of edges, we check if there is a new cycle by 
* comparing the number of edges in cycles before and after adding the n-uplet of edges
* 
* Params: 
*  db_graph = the graph containing the edges we have to order
*  setted_edges = the graph on the edges that have already been setted
*  next_edge_to_add = the number of the next edge we have to find
*  edges_in_cycles = the current number of edges in cycles 
*  edges_to_add = the size of the n-uplet of edges we have to add
*
* Returns: a boolean, true if the function has added one or more cycles of size n
*/
bool nCycle(Graph db_graph, Graph setted_edges, ref int next_edge_to_add, ref int edges_in_cycles, int edges_to_add, ulong starting_vertex = -1){
    bool changed = true;
    bool success = false;

    while(changed){
        changed = false;

        if(starting_vertex == -1){
            foreach(i; 0..setted_edges.length){
                foreach(j; 0..setted_edges.length){
                    if(db_graph[i][j] > -1 && setted_edges[i][j] == -1){
                        setted_edges[i][j] = next_edge_to_add;
                        next_edge_to_add++;

                        if(edges_to_add > 1){
                            bool next_edge_success = nCycle(db_graph, setted_edges, next_edge_to_add, edges_in_cycles, edges_to_add - 1, j);

                            if(next_edge_success){
                                changed = true; //
                                success = true;
                            }
                            else {
                                setted_edges[i][j] = -1;
                                next_edge_to_add--;
                            }
                        }
                        else{
                            int new_edges_in_cycles = nbEdgesInCycles(setted_edges);

                            if(new_edges_in_cycles > edges_in_cycles){
                                edges_in_cycles = new_edges_in_cycles;
                                changed = true;
                                success = true;
                            }
                            else{
                                setted_edges[i][j] = -1;
                                next_edge_to_add--;
                            }
                        }
                    }
                }
            }
        }
        else{
            foreach(i; 0..setted_edges.length){
                if(db_graph[starting_vertex][i] > -1 && setted_edges[starting_vertex][i] == -1){
                    setted_edges[starting_vertex][i] = next_edge_to_add;
                    next_edge_to_add++;

                    if(edges_to_add > 1){
                        bool next_edge_success = nCycle(db_graph, setted_edges, next_edge_to_add, edges_in_cycles, edges_to_add - 1, i);

                        if(next_edge_success){
                            changed = true;
                            success = true;
                        }
                        else{
                            setted_edges[starting_vertex][i] = -1;
                            next_edge_to_add--;
                        }
                    }
                    else{
                        int new_edges_in_cycles = nbEdgesInCycles(setted_edges);

                        if(new_edges_in_cycles > edges_in_cycles){
                            edges_in_cycles = new_edges_in_cycles;
                            changed = true;
                            success = true;
                        }
                        else{
                            setted_edges[starting_vertex][i] = -1;
                            next_edge_to_add--;
                        }
                    }
                }
            }
        }
    }

    return success;
}

/**
* Calculate the number of edges that are part of a cycle
* 
* Params:
*  graph = a graph
* 
* Returns: the number of edges that are part of a cycle
*/
int nbEdgesInCycles(Graph graph){
    int nbEdgesInCycles = 0;

    auto reachability_matrix = reachabilityMatrix(graph);

    foreach(i; 0..graph.length){
        foreach(j; 0..graph.length){
            if(graph[i][j] > -1 && reachability_matrix[j][i] == true){
                nbEdgesInCycles++;
            }
        }
    }

    return nbEdgesInCycles;
}



unittest{
    // A graph where no edges are in cycles
    Graph graphWithoutCycles = [[-1, -1, -1], [-1, -1, -1], [-1, -1, -1]];
    assert(nbEdgesInCycles(graphWithoutCycles) == 0);

    // A graph where all the edges are in cycles
    Graph graphWithCycles = [[0, 0, -1], [0, 0, 0], [0, -1, -1]];
    assert(nbEdgesInCycles(graphWithCycles) == 6);

    // A graph where some of the edges are in cycles
    Graph graphWithSomeCycles = [[0, 0, -1], [0, 0, 0], [-1, -1, -1]];
    assert(nbEdgesInCycles(graphWithSomeCycles) == 4);    
}

/**
* Creates a matrix of reachability for a given graph. the case (i,j) of
* this matrix is true if there is a path from the node i to the node j
* in the graph
* Params:
*  g = a graph
* 
* Returns: a reachability matrix as a 2D-array of booleans 
*/
bool[][] reachabilityMatrix(Graph g, bool[][] reachability_matrix = null){    
    if(reachability_matrix is null)
        reachability_matrix = new bool[][](g.length, g.length);

    // If there is an edge from i to j, j is reachable from i
    foreach(i; 0 .. g.length){
        foreach(j; 0 .. g.length){
            if(g[i][j] > -1){
                reachability_matrix[i][j] = true; 
            }
            else{
                reachability_matrix[i][j] = false;
            }
        }
    }

    bool changed = true;

    // For every couple of vertices (i,j) , we try to find another vertice k
    // such that there is a path from i to k and a path from k to j. If we 
    // found one, there is a path from i to j
    while(changed){
        changed = false;

        foreach(i; 0 .. g.length){
            foreach(j; 0 .. g.length){
                if(!reachability_matrix[i][j]){
                    foreach(k; 0 .. g.length){
                        if(reachability_matrix[i][k] && reachability_matrix[k][j]){
                            reachability_matrix[i][j] = true;
                            changed = true;
                        }
                    }
                }
            }
        }
    }

    return reachability_matrix;
}

unittest{
    Graph g = [[-1, -1], [-1, -1]];
    assert(reachabilityMatrix(g) == [[false, false], [false, false]]);

    g = [[0, 0], [-1, -1]];
    assert(reachabilityMatrix(g) == [[true, true], [false, false]]);
}

/**
* A function that sets every edge of a graph to a value
* Params:
*   g = a Graph
*   value = an integer value
*/
void setGraph(Graph g, int value){
    for(int i = 0; i < g.length; i++){
        for(int j = 0; j < g.length; j++){
            g[i][j] = value;
        }
    }
}

void orderToCSV(Graph order, string path){
    auto f = File(path, "w");

    foreach(edge; 0..order.length^^2){
        foreach(i; 0..order.length){
            foreach(j; 0..order.length){
                if(order[i][j] == edge)
                    f.writefln("%d,%d", i, j);
            }
        }
    }
}

/**
* Write a DeBruijn graph in the DOT language
* Params:
*  base = the base in which the nodes should be displayed. If not specified,
*         the nodes are displayed in base 10
*  graph = $(DB_GRAPH)
*  path = path of the dot file
*/
void graphToDot(int base = 0)(Graph graph, string path){
    auto f = File(path, "w");

    f.writeln("digraph DeBruijn {");

    for(int i = 0; i < graph.length; i++){
        for(int j = 0; j < graph.length; j++){
            if(graph[i][j] >= 0){
                static if(base > 0){
                    import std.conv;
                    f.writefln("\t%s -> %s [label=%d]", to!string(i, base), to!string(j, base), graph[i][j]);
                }
                else {
                    f.writefln("\t%d -> %d [label=%d]", i, j, graph[i][j]);
                }
            }
        }
    }

    f.writeln("}");
}