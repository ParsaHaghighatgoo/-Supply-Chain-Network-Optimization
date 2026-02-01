
% Supply Chain Network Optimization Model

% Parameters
int: n_harbors;
int: n_warehouses;
int: n_stores;
int: min_warehouses;
int: max_warehouses;
int: penalty_cost;

array[1..n_harbors] of int: supply;
array[1..n_stores] of int: demand;
array[1..n_warehouses] of int: warehouse_setup_cost;
array[1..n_warehouses] of int: warehouse_capacity;
array[1..n_harbors, 1..n_warehouses, 1..n_stores] of int: transport_cost;

% Distance matrix between warehouses (for minimum distance constraint)
array[1..n_warehouses, 1..n_warehouses] of int: warehouse_distances;
int: min_distance;

% Decision Variables
array[1..n_harbors, 1..n_warehouses, 1..n_stores] of var 0..10000: flow;
array[1..n_warehouses] of var 0..1: warehouse_open;
array[1..n_stores] of var 0..10000: shortage;

% Objective: Minimize total cost
var int: total_transport_cost = sum(i in 1..n_harbors, j in 1..n_warehouses, k in 1..n_stores)(
    transport_cost[i,j,k] * flow[i,j,k]
);

var int: total_setup_cost = sum(j in 1..n_warehouses)(
    warehouse_setup_cost[j] * warehouse_open[j]
);

var int: total_penalty = sum(k in 1..n_stores)(
    penalty_cost * shortage[k]
);

var int: total_cost = total_transport_cost + total_setup_cost + total_penalty;

% Constraints

% 1. Demand satisfaction (with shortage allowed)
constraint forall(k in 1..n_stores)(
    sum(i in 1..n_harbors, j in 1..n_warehouses)(flow[i,j,k]) + shortage[k] = demand[k]
);

% 2. Supply limits
constraint forall(i in 1..n_harbors)(
    sum(j in 1..n_warehouses, k in 1..n_stores)(flow[i,j,k]) <= supply[i]
);

% 3. Warehouse capacity (flow only if open)
constraint forall(j in 1..n_warehouses)(
    sum(i in 1..n_harbors, k in 1..n_stores)(flow[i,j,k]) <= warehouse_capacity[j] * warehouse_open[j]
);

% 4. Number of warehouses constraint
constraint sum(j in 1..n_warehouses)(warehouse_open[j]) >= min_warehouses;
constraint sum(j in 1..n_warehouses)(warehouse_open[j]) <= max_warehouses;

% 5. Minimum distance between warehouses
constraint forall(j1 in 1..n_warehouses, j2 in j1+1..n_warehouses)(
    warehouse_open[j1] + warehouse_open[j2] <= 1 \/ warehouse_distances[j1,j2] >= min_distance
);

% Solve
solve minimize total_cost;

% Output
output [
    "Total Cost: ", show(total_cost), "\n",
    "Transport Cost: ", show(total_transport_cost), "\n",
    "Setup Cost: ", show(total_setup_cost), "\n",
    "Penalty Cost: ", show(total_penalty), "\n",
    "Warehouses Open: ", show(sum(j in 1..n_warehouses)(warehouse_open[j])), "\n",
    "Warehouse Locations: ", show([j | j in 1..n_warehouses where warehouse_open[j] = 1]), "\n"
];
