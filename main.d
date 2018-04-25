import std.stdio;
import std.format;
import std.csv;
import std.algorithm;
import std.array;
import std.typecons;
import std.file;
import std.conv;
import std.datetime.stopwatch;

/**
* Macros:
*  DB_GRAPH = A DeBruijn graph as a 2D array where tab[i][j] is a value superior
*  to 0 if there is an edge labelled with this value between nodes i and j, and 
*  -1 if there is no edge between i and j.
*/

enum n_state = 2;
enum n_vois = 5;
enum n_nodes_debruijn = n_state ^^ (n_vois - 1);
enum n_nodes_injectivity = n_nodes_debruijn * n_nodes_debruijn;
enum n_voisinages = n_state ^^ n_vois;

alias Graph = int[n_nodes_debruijn][n_nodes_debruijn];
alias InjectivityGraph = int[n_nodes_injectivity][n_nodes_injectivity];
alias Edge = Tuple!(int,int);
alias Rule = int[n_voisinages];

Graph de_bruijn_graph;
Graph edges_order;
Graph s_edges;
InjectivityGraph injectivity_graph;
Edge[] order;

struct RulesList {
    int nb_state;
    int nb_vois;
    int nb_rules;
    ulong computation_time;
    
    Rule[] rules;

    this(size_t preallocated_size){
        rules = new int[n_voisinages][](preallocated_size);
        nb_state = n_state;
        nb_vois = n_vois;
        nb_rules = 0;
    }

    void addRule(Rule rule){
        nb_rules++;
        rules ~= rule;
    }
}

struct Stack(size_t size){
    int[size] t;
    int pos = 0;

    @property
    bool empty(){
        return pos == 0;
    }

    @property
    int pop(){
        return t[--pos];
    }

    void push(int x){
        t[pos++] = x;
    }
}

RulesList rules_list = void;

void main(string[] args){
    //pragma(msg, "number of states = ", n_state);
    //pragma(msg, "number of neighbours = ", n_vois);
    //pragma(msg, "number of DeBruijn nodes = ", n_nodes_debruijn);
    //pragma(msg, "number of neighbourhoods = ", n_voisinages);

    auto sw = StopWatch(AutoStart.no);

    // For each node represented by the digits x0x1...xN in base n_state
    // There is an edge to the node represented by the digits x1x2...j for
    // each j between 0 and (n_state -1).
    /*
    for(int i = 0; i < n_nodes_debruijn; i++){
        de_bruijn_graph[i][] = -1;
        for(int j = 0; j < n_state; j++){
            // 1. We multiply the number in base n_state by n_state to shift
            //  the digits from 1 to the left
            // 2. We add j to set the rightmost digit
            // 3. We apply module n_nodes_debruijn to "forget" the leftmost
            //  digit 
            de_bruijn_graph[i][((i * n_state) + j) % n_nodes_debruijn] = j;
        }
    }
    */

    //graphToDot(de_bruijn_graph, format("v%ds%d.dot", n_vois, n_state));

    /*
    maxCycleNodeOrder();
    graphToDot(edges_order, format("v%ds%d_order.dot", n_vois, n_state));
    orderToCSV(edges_order, format("v%ds%d_order.csv", n_vois, n_state));
    */

    // Énumération des réversibles
    // Récupération de l'ordre et initialisation des structures
    if(args.length == 1){
        auto order_file = File(format("v%ds%d_order.csv", n_vois, n_state), "r");
        order = order_file.byLine.joiner("\n").csvReader!(Tuple!(int,int)).array;
    }
    else {
        order = new Edge[](0);
        // Check for reversibles by setting only some edges, specified by a rule
        ulong rule = args[1].to!ulong;

        for(int i = 0; i < n_voisinages; i++){
            if((rule & 1) == 1){
                auto from = i >> 1;
                auto to = i & ((1 << (n_vois - 1)) - 1);

                order ~= tuple(from, to);
            }
            //writefln("%d -> %d", i, rule & 1);
            rule = rule >> 1;
        }
    }

    //writeln(order);

    //writefln("number of edges : %d", order.length);
    rules_list = RulesList(0);

    foreach(i; 0..n_nodes_debruijn){
        s_edges[i][] = -1;
    }

    // Énumération en elle-même
    sw.start(); // clock
    int stage = 0;

    int nb_rules = 0;
    while(stage != -1){
        int x = s_edges[order[stage][0]][order[stage][1]];
        x++;

        if(x == n_state){
            s_edges[order[stage][0]][order[stage][1]] = -1;
            stage--;
        }
        else{
            s_edges[order[stage][0]][order[stage][1]] = x;

            if( !isNonReversible(stage + 1) ){
                stage++;

                if(stage == order.length){

                    /* Comment this part when benchmarking */
                    nb_rules++;
                    //writeRule();

                    /* End of part to comment when benchmarking */
                    stage--;
                }
            }
        }

    }

    if(args.length == 1){
        writefln("nb de réversibles : %d", nb_rules);
    }
    else{
        writefln("%s;%d", args[1] ,nb_rules);
    }
    sw.stop();

    rules_list.computation_time = sw.peek.total!"seconds";

    //writefln("computation took %s", sw.peek);

    // The file is as follow : 
    //  - the number of states
    //  - the size of the neighborhood
    //  - the rules
    File f = File(format("v%ds%d.dat", n_vois, n_state), "w");
    f.write(n_state);
    f.write(n_vois);

    foreach(i; 0..rules_list.nb_rules){
        foreach(e; rules_list.rules[i]){
            f.write(e);
        }
    }
}


bool isNonReversible(int stage){
    int[n_nodes_injectivity] deg_entrant;
    int[n_nodes_injectivity] deg_sortant;

    // Filling the injectivity graph
    foreach(i; 0..injectivity_graph.length){
        injectivity_graph[i][] = 0;
    }

    foreach(e; 0..stage){
        foreach(e_prime; 0..stage){
            if(s_edges[order[e][0]][order[e][1]] != s_edges[order[e_prime][0]][order[e_prime][1]]) continue;

            int i = order[e][0] * n_nodes_debruijn + order[e_prime][0];
            int j = order[e][1] * n_nodes_debruijn + order[e_prime][1];
            injectivity_graph[i][j] = 1;
            deg_entrant[j]++;
            deg_sortant[i]++;
        }
    }

    // Deleting all sinks from the graph
    auto s_sinks = Stack!n_nodes_injectivity();
    auto s_source = Stack!n_nodes_injectivity();

    foreach(i; 0..n_nodes_injectivity){
        if(deg_sortant[i] == 0)
            s_sinks.push(i);
        if(deg_entrant[i] == 0)
            s_source.push(i);
    }

    while(!s_sinks.empty){
        int i = s_sinks.pop;
        foreach(k; 0..n_nodes_injectivity){
            if(injectivity_graph[k][i] == 1){
                deg_sortant[k]--;
                if(deg_sortant[k] == 0){
                    s_sinks.push(k);
                }
            }
        }
    }

    while(!s_source.empty){
        int i = s_source.pop;
        foreach(k; 0..n_nodes_injectivity){
            if(injectivity_graph[i][k] == 1){
                deg_entrant[k]--;
                if(deg_entrant[k] == 0){
                    s_source.push(k);
                }
            }
        }
    }

    foreach(i; 0..n_nodes_debruijn){
        foreach(j; 0..n_nodes_debruijn){
            if(i != j){
                if(deg_entrant[i * n_nodes_debruijn + j] > 0 && deg_sortant[i * n_nodes_debruijn + j] > 0){
                    return true;
                }
            }
        }
    }
    return false;
}

void writeRule(){
    int[n_voisinages] rule;

    for(int i = 0; i < n_nodes_debruijn; i++){
        for(int j = 0; j < n_state; j++){
            rule[((i * n_state) + j)] = s_edges[i][((i * n_state) + j) % n_nodes_debruijn];
        }
    }

    rules_list.addRule(rule);
}


















/**
* From a DeBruijn graph, compute the order in which the values of the edges should be 
* setted to create a maximum of cycles in the earlier steps of reversible cellular 
* automata finding algorithm
* Params:
*   graph = $(DB_GRAPH)
* Returns: A graph where each edge is labelled with its order
*/  
void maxCycleNodeOrder(){
    // We will keep track of the edges whose values have already been setted in 
    // this graph, and their order
    int[][] setted_edges = new int[][] (n_nodes_debruijn, n_nodes_debruijn);
    setGraph(setted_edges, -1);

    int edges_in_cyles = 0;
    int next_edge_to_add = 0;

    for(int csize = 1; csize <= n_nodes_debruijn; csize++){
        writefln("csize = %d and graph.length = %d", csize, n_nodes_debruijn);
        foreach(i; 0..csize+1){
            nCycle(setted_edges, next_edge_to_add, edges_in_cyles, csize);
        }
    }

    foreach(i; 0..setted_edges.length){
        foreach(j; 0..setted_edges.length){
            if(de_bruijn_graph[i][j] > -1 && setted_edges[i][j] == -1){
                setted_edges[i][j] = next_edge_to_add;
                next_edge_to_add++;
            }
        }
    }

    foreach(i; 0..n_nodes_debruijn){
        foreach(j; 0..n_nodes_debruijn){
            edges_order[i][j] = setted_edges[i][j];
        }
    }
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

bool nCycle(int[][] setted_edges, ref int next_edge_to_add, ref int edges_in_cycles, int edges_to_add, ulong starting_vertex = -1){
    bool changed = true;
    bool success = false;

    while(changed){
        changed = false;

        if(starting_vertex == -1){
            foreach(i; 0..setted_edges.length){
                foreach(j; 0..setted_edges.length){
                    if(de_bruijn_graph[i][j] > -1 && setted_edges[i][j] == -1){
                        setted_edges[i][j] = next_edge_to_add;
                        next_edge_to_add++;

                        if(edges_to_add > 1){
                            bool next_edge_success = nCycle(setted_edges, next_edge_to_add, edges_in_cycles, edges_to_add - 1, j);

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
                if(de_bruijn_graph[starting_vertex][i] > -1 && setted_edges[starting_vertex][i] == -1){
                    setted_edges[starting_vertex][i] = next_edge_to_add;
                    next_edge_to_add++;

                    if(edges_to_add > 1){
                        bool next_edge_success = nCycle(setted_edges, next_edge_to_add, edges_in_cycles, edges_to_add - 1, i);

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
int nbEdgesInCycles(int[][] graph){
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
bool[][] reachabilityMatrix(int[][] g, bool[][] reachability_matrix = null){    
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
void setGraph(int[][] g, int value){
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
    writefln("writing %s", path);
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

// Write injectivity graph
void injectivityToDot(int[n_nodes_injectivity][n_nodes_injectivity] inj, string path){
    auto f = File(path, "w");

    f.writeln("digraph injectivity {");

    foreach(i; 0..n_nodes_debruijn){
        foreach(j; 0..n_nodes_debruijn){
            f.writefln(`    n%s [shape=record][label="{%s|%s}"];`, i * n_nodes_debruijn + j, i, j);
        }
    }

    foreach(i; 0..n_nodes_debruijn){
        foreach(j; 0..n_nodes_debruijn){
            foreach(i_prime; 0..n_nodes_debruijn){
                foreach(j_prime; 0..n_nodes_debruijn){
                    if(inj[i * n_nodes_debruijn + i_prime][j * n_nodes_debruijn + j_prime] == 1){
                        f.writefln("\tn%s -> n%s;", i * n_nodes_debruijn + i_prime, j * n_nodes_debruijn + j_prime);
                    }
                }
            }
        }
    }
    f.writeln("}");
}