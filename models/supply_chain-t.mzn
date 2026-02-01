
% ============================================================
% Supply Chain Network Optimization - MiniZinc Model
% Mathematical Formulation - Exact Match
% ============================================================

% -------------------- PARAMETERS --------------------

% Dimensions
int: I;  % Number of harbors
int: J;  % Number of potential warehouses
int: K;  % Number of stores

% Supply at each harbor (S_i)
array[1..I] of int: S;

% Demand at each store (D_k)
array[1..K] of int: D;

% Fixed cost of opening warehouse j (F_j)
array[1..J] of int: F;

% Capacity of warehouse j
array[1..J] of int: Cap;

% Transport cost C_ijk (from harbor i through warehouse j to store k)
array[1..I, 1..J, 1..K] of int: C;

% Warehouse constraints
int: N_min;
int: N_max;

% -------------------- DECISION VARIABLES --------------------

% X_ijk: Amount of flow from harbor i through warehouse j to store k
array[1..I, 1..J, 1..K] of var 0..max(S): X;

% Y_j: Binary variable (1 if warehouse j is opened, 0 otherwise)
array[1..J] of var 0..1: Y;

% -------------------- CONSTRAINTS --------------------

% Constraint 1: Demand satisfaction at each store
% Sum_i Sum_j X_ijk = D_k, for all k in K
constraint forall(k in 1..K)(
  sum(i in 1..I, j in 1..J)(X[i,j,k]) = D[k]
);

% Constraint 2: Supply limit at each harbor
% Sum_j Sum_k X_ijk <= S_i, for all i in I
constraint forall(i in 1..I)(
  sum(j in 1..J, k in 1..K)(X[i,j,k]) <= S[i]
);

% Constraint 3: Capacity constraint at each warehouse
% Sum_i Sum_k X_ijk <= Cap_j * Y_j, for all j in J
constraint forall(j in 1..J)(
  sum(i in 1..I, k in 1..K)(X[i,j,k]) <= Cap[j] * Y[j]
);

% Constraint 4: Number of warehouses constraint
% N_min <= Sum_j Y_j <= N_max
constraint sum(j in 1..J)(Y[j]) >= N_min;
constraint sum(j in 1..J)(Y[j]) <= N_max;

% -------------------- OBJECTIVE FUNCTION --------------------

% Minimize: Sum_i Sum_j Sum_k (C_ijk * X_ijk) + Sum_j (F_j * Y_j)
var int: transport_cost = sum(i in 1..I, j in 1..J, k in 1..K)(
  C[i,j,k] * X[i,j,k]
);

var int: setup_cost = sum(j in 1..J)(
  F[j] * Y[j]
);

var int: total_cost = transport_cost + setup_cost;

solve minimize total_cost;

% -------------------- OUTPUT --------------------

output [
  "========================================\n",
  "OPTIMAL SOLUTION\n",
  "========================================\n",
  "Total Cost: ", show(total_cost), "\n",
  "  Transport Cost: ", show(transport_cost), "\n",
  "  Setup Cost: ", show(setup_cost), "\n",
  "Number of Warehouses: ", show(sum(j in 1..J)(Y[j])), "\n",
  "\nOpened Warehouses:\n"
] ++
[
  if fix(Y[j]) = 1 then
    "  Warehouse " ++ show(j) ++
    " (Cap=" ++ show(Cap[j]) ++
    ", Cost=" ++ show(F[j]) ++
    ", Flow=" ++ show(sum(i in 1..I, k in 1..K)(fix(X[i,j,k]))) ++ ")\n"
  else "" endif
  | j in 1..J
] ++
["\nY = ", show(Y), "\n"];
