
% Bonus Part: Supply Chain with Single Assignment

% Parameters
int: n_harbors;
int: n_warehouses;
int: n_stores;
int: min_warehouses;
int: max_warehouses;
int: penalty_cost;  % Accept but don't use (for compatibility)

array[1..n_harbors] of int: supply;
array[1..n_stores] of int: demand;
array[1..n_warehouses] of int: warehouse_setup_cost;
array[1..n_warehouses] of int: warehouse_capacity;  % Accept but don't use (infinite capacity)
array[1..n_harbors, 1..n_warehouses, 1..n_stores] of int: transport_cost;
array[1..n_warehouses, 1..n_warehouses] of int: warehouse_distances;
int: min_distance;

% Decision Variables
array[1..n_harbors] of var 1..n_warehouses: harbor_assignment;
array[1..n_stores] of var 1..n_warehouses: store_assignment;
array[1..n_warehouses] of var 0..1: warehouse_open;

% Helper: Flow matrix (for cost calculation)
array[1..n_harbors, 1..n_warehouses, 1..n_stores] of var 0..100000: flow;

% Objective: Minimize total cost
var int: total_transport_cost = sum(i in 1..n_harbors, j in 1..n_warehouses, k in 1..n_stores)(
    transport_cost[i, j, k] * flow[i, j, k]
);

var int: total_setup_cost = sum(j in 1..n_warehouses)(
    warehouse_setup_cost[j] * warehouse_open[j]
);

var int: total_cost = total_transport_cost + total_setup_cost;

% Constraints

% 1. Harbors can only assign to open warehouses
constraint forall(i in 1..n_harbors)(
    warehouse_open[harbor_assignment[i]] = 1
);

% 2. Stores can only be served by open warehouses
constraint forall(k in 1..n_stores)(
    warehouse_open[store_assignment[k]] = 1
);

% 3. Flow only happens through assigned warehouse
constraint forall(i in 1..n_harbors, j in 1..n_warehouses, k in 1..n_stores)(
    if harbor_assignment[i] != j \/ store_assignment[k] != j then
        flow[i, j, k] = 0
    else
        true
    endif
);

% 4. Each harbor sends all its supply through its assigned warehouse
constraint forall(i in 1..n_harbors)(
    sum(k in 1..n_stores where store_assignment[k] = harbor_assignment[i])(
        flow[i, harbor_assignment[i], k]
    ) = supply[i]
);

% 5. Each store receives all its demand from its assigned warehouse
constraint forall(k in 1..n_stores)(
    sum(i in 1..n_harbors where harbor_assignment[i] = store_assignment[k])(
        flow[i, store_assignment[k], k]
    ) = demand[k]
);

% 6. Number of warehouses constraint
constraint sum(j in 1..n_warehouses)(warehouse_open[j]) >= min_warehouses;
constraint sum(j in 1..n_warehouses)(warehouse_open[j]) <= max_warehouses;

% 7. Minimum distance between warehouses
constraint forall(j1 in 1..n_warehouses, j2 in j1+1..n_warehouses)(
    warehouse_open[j1] + warehouse_open[j2] <= 1 \/ warehouse_distances[j1,j2] >= min_distance
);

% Note: No capacity constraint - warehouses have infinite capacity in bonus part

% Solve
solve minimize total_cost;

% Output
output [
    "Total Cost: ", show(total_cost), "\n",
    "Transport Cost: ", show(total_transport_cost), "\n",
    "Setup Cost: ", show(total_setup_cost), "\n",
    "Penalty Cost: 0\n",
    "Warehouses Open: ", show(sum(j in 1..n_warehouses)(warehouse_open[j])), "\n",
    "Warehouse Locations: ", show([j | j in 1..n_warehouses where warehouse_open[j] = 1]), "\n",
    "Harbor Assignments: ", show(harbor_assignment), "\n",
    "Store Assignments: ", show(store_assignment), "\n"
];
