$title Microsoft Azure Dynamic VM Placement & Resource Allocation

* -----------------------------------------------------------------------------
* Project: Azure Cloud Optimization under QoS, SLA, and Power Constraints
* Methodology: Multi-Period Mixed-Integer Programming (MIP)
* Objective: Minimize Total Cost (Active Server Power + VM Migration Overhead)
* -----------------------------------------------------------------------------

SETS
    i   Virtual Machines (Tenants)  / vm1*vm100 /
    j   Physical Nodes (Servers)    / node1*node20 /
    t   Time Periods (Hourly)       / t1*t24 /
    r   Resource Types              / cpu, memory, bandwidth / ;

PARAMETERS
    req(i,r,t)      Dynamic resource requirement of VM i for resource r at time t
    cap(j,r)        Capacity of physical node j for resource r
    pwr_idle(j)     Idle power consumption of node j (Watts)
    pwr_max(j)      Maximum power consumption of node j at 100% load
    mig_cost(i)     Penalty cost for migrating VM i (SLA degradation factor)
    qos_limit(j)    Maximum allowed utilization percentage to guarantee SLA ;

* --- Synthetic Azure Data Initialization (Ev3 & Dv4 Series Simulation) ---
req(i,'cpu',t)       = uniformInt(2, 32);
req(i,'memory',t)    = uniformInt(8, 128);
req(i,'bandwidth',t) = uniformInt(100, 1000);
cap(j,'cpu')         = 128;
cap(j,'memory')      = 512;
cap(j,'bandwidth')   = 10000;
pwr_idle(j)          = 150;
pwr_max(j)           = 400;
mig_cost(i)          = uniform(10, 50);
qos_limit(j)         = 0.85;  * 85% strict threshold for QoS guarantee

VARIABLES
    x(i,j,t)    1 if VM i is hosted on node j at time t (Binary)
    y(j,t)      1 if node j is powered ON at time t (Binary)
    m(i,t)      1 if VM i is migrated at time t (Binary)
    load(j,r,t) Total load on node j for resource r at time t
    Total_Cost  Objective function value (Power + Migration Penalty) ;

BINARY VARIABLES x, y, m;
POSITIVE VARIABLES load;

EQUATIONS
    assign_vm(i,t)        Every VM must be hosted exactly once per time period
    calc_load(j,r,t)      Calculate the aggregate resource load on each node
    capacity_qos(j,r,t)   Ensure load does not exceed SLA QoS capacity threshold
    detect_mig(i,j,t)     Detect if a VM changes its host node between periods
    obj_function          Minimize power consumption and migration SLA penalties ;

* --- Mathematical Formulation ---

assign_vm(i,t).. 
    sum(j, x(i,j,t)) =e= 1;

calc_load(j,r,t).. 
    load(j,r,t) =e= sum(i, req(i,r,t) * x(i,j,t));

* Strict QoS limit: Load must be <= 85% of capacity if the server is ON
capacity_qos(j,r,t).. 
    load(j,r,t) =l= (qos_limit(j) * cap(j,r)) * y(j,t);

* Migration detection: If x(i,j,t) != x(i,j,t-1), migration occurred
detect_mig(i,j,t)$(ord(t) > 1).. 
    m(i,t) =g= x(i,j,t) - x(i,j,t-1);

* Objective: Minimize Power (Idle + Dynamic) + Migration Penalties
obj_function.. 
    Total_Cost =e= sum((j,t), pwr_idle(j)*y(j,t) + (pwr_max(j)-pwr_idle(j))*(load(j,'cpu',t)/cap(j,'cpu'))) 
                 + sum((i,t), mig_cost(i) * m(i,t));

MODEL Azure_Dynamic_Placement /all/ ;

* --- Solver Configuration ---
OPTION MIP = CPLEX;
OPTION OPTCR = 0.01; * 1% Optimality gap for faster execution on complex models
OPTION RESLIM = 3600; * Time limit

SOLVE Azure_Dynamic_Placement USING MIP MINIMIZING Total_Cost ;

DISPLAY "Optimization Execution Completed.", Total_Cost.l, y.l, m.l;
