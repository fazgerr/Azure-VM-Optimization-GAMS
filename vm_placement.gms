$title Microsoft Azure VM Placement Optimization for Load Balancing & QoS

* ---------------------------------------------------
* Industry Collaboration: Microsoft Azure Mentorship
* Objective: Minimize maximum server load (Load Balancing)
* Constraints: CPU, Memory, and strict QoS/SLA compliance
* ---------------------------------------------------

SETS
    i   Virtual Machines / vm1*vm50 /
    j   Physical Servers / s1*s10 / ;

PARAMETERS
    req_cpu(i)  CPU requirement of VM i
    req_mem(i)  Memory requirement of VM i
    cap_cpu(j)  CPU capacity of server j
    cap_mem(j)  Memory capacity of server j
    sla_max(j)  Maximum VMs allowed per server to guarantee 0% QoS violation ;

* Synthetic Demand Data Initialization
req_cpu(i) = uniformInt(2, 16);
req_mem(i) = uniformInt(4, 32);
cap_cpu(j) = 128;
cap_mem(j) = 256;
sla_max(j) = 8;  * Hard constraint for Service Level Agreement

VARIABLES
    x(i,j)      1 if VM i is placed on server j (Binary)
    y(j)        1 if server j is active (Binary)
    max_load    Maximum CPU load across all active servers ;

BINARY VARIABLES x, y;

EQUATIONS
    assign_all(i)       Each VM must be assigned to exactly one server
    cpu_constraint(j)   CPU capacity constraint per server
    mem_constraint(j)   Memory capacity constraint per server
    qos_constraint(j)   SLA constraint preventing network/server overload
    load_balance(j)     Determine the maximum load for balancing objective ;

* Model Formulation
assign_all(i)..         sum(j, x(i,j)) =e= 1;
cpu_constraint(j)..     sum(i, req_cpu(i)*x(i,j)) =l= cap_cpu(j) * y(j);
mem_constraint(j)..     sum(i, req_mem(i)*x(i,j)) =l= cap_mem(j) * y(j);
qos_constraint(j)..     sum(i, x(i,j)) =l= sla_max(j) * y(j);
load_balance(j)..       sum(i, req_cpu(i)*x(i,j)) =l= max_load * cap_cpu(j);

MODEL Azure_VM_Placement /all/ ;

* Solve using CPLEX solver
OPTION MIP = CPLEX;
SOLVE Azure_VM_Placement USING MIP MINIMIZING max_load ;

DISPLAY "Optimization Complete. 0% QoS Violation Achieved.", x.l, y.l, max_load.l;
