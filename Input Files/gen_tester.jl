
#### Generate input file for pomdp-solve software.
#### Syntax requirements can be found at https://www.pomdp.org/code/pomdp-file-spec.html
using LinearAlgebra
using Pipe
include("./util.jl")

#### Discount factor
# %f
discount = 0.99

#### Rewards
# [ reward, cost ]
# values =  "cost" # to minimize
values = "reward" # to maximize

#### States
# [ %d, <list-of-states> ]
# When an integer is given, the states are enumerated starting from 0
# Delimeters are white space
# states = 13
# Since pomdp-solver requires stationary parameters, time is considered as a state
# Hence each state consists of ΔNTCP, b, and t
ΔNTCP_states = 0:12
budget = 3
horizon = 4  # 4 decision epochs; not the pomdp-solve optional parameter
states = String[]
for t = 1:(horizon+1), b in budget:-1:0, ΔNTCP in ΔNTCP_states
    push!(states, "$(ΔNTCP)_$(b)_$t")
end
push!(states, "Forbidden")  # add dummy absorbing state for when replanning is not allowed
num_ΔNTCP_states = length(ΔNTCP_states)
num_budget_states = budget + 1
num_states = length(states)

#### Actions
# [ %d, <list-of-actions> ]
# When a list is given, the elements may be referred to by name or by 0-based indexing
actions = ["Replan", "Continue"]

#### Observations
# [ %d, <list-of-observations> ]
# Delimeters are white space
# An observation is observed after the state transitions
# Will assume states are ordered from best to worst, with high pain being worse than a high BMI drop
observations = String[]
levels = ["Low", "Med", "High"]
for pain_level in levels, bmi_level in levels
    push!(observations, "Pain-$(pain_level)___BMI-$(bmi_level)")
end
num_observations = length(observations)
# observations = [ "Pain-High___BMI-High", "Pain-High___BMI-Med", "Pain-High___BMI-Low", 
#     "Pain-Med___BMI-High", "Pain-Med___BMI-Med", "Pain-Med___BMI-Low",
#     "Pain-Low___BMI-High", "Pain-Low___BMI-Med", "Pain-Low___BMI-Low"]

#### Optional starting state 
# Since first decision epoch is at F10, the starting probabilities (at full budget and start of horizon) should be the following:
ΔNTCP_start_dist = [0.5, 0.13, 0.08, 0.11, 0.04, 0.04, 0.0, 0.02, 0.0, 0.0, 0.02, 0.02, 0.04]
# This corresponds to the states at the beginning
start_dist =[ΔNTCP_start_dist; zeros(num_states - num_ΔNTCP_states)]
# sanity_check_prob(ΔNTCP_start_dist)

#### State transition probabilities
## Replan, F0 to F10
# Replan isn't an option at time 0. The trans. prob. of Continue  at F0 correspond to the starting distribution
# of the POMDP (see starting state above)
## Replan, F10 to F15, table B.3
T_ΔNTCP_F10toF15_R = [
    0.88 0.0 0.12 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.88 0.0 0.12 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0
]
## Replan, F15 to F20, table B.4
T_ΔNTCP_F15toF20_R = [
    0.88 0.0 0.12 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0
]
## Replan, F20 to F25, table B.5
T_ΔNTCP_F20toF25_R = [
    0.88 0.0 0.12 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
]
## Replan, F25 to F30, table B.6
T_ΔNTCP_F25toF30_R = [
    0.88 0.0 0.12 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0
]

T_ΔNTCP_all_R = [T_ΔNTCP_F10toF15_R, T_ΔNTCP_F15toF20_R, T_ΔNTCP_F20toF25_R, T_ΔNTCP_F25toF30_R]

## Continue, F0 to F10, table B.1
# The trans. prob. of Continue at F0 correspond to the starting distribution of the POMDP (see starting state above)
## Continue, F10 to F15, table B.2
T_ΔNTCP_F10toF15_C = [
    0.88 0.0 0.12 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.25 0.75 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.5 0.33 0.17 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0;
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5 0.5
]
## Continue, F15 to F20, table B.2
T_ΔNTCP_F15toF20_C = copy(T_ΔNTCP_F10toF15_C)
## Continue, F20 to F25, table B.2
T_ΔNTCP_F20toF25_C = copy(T_ΔNTCP_F10toF15_C)
## Continue, F25 to F30, table B.2
T_ΔNTCP_F25toF30_C = copy(T_ΔNTCP_F10toF15_C)

T_ΔNTCP_all_C = [T_ΔNTCP_F10toF15_C, T_ΔNTCP_F15toF20_C, T_ΔNTCP_F20toF25_C, T_ΔNTCP_F25toF30_C]

# Collect into a dictionary for ease of access
T_ΔNTCP_all = Dict("Replan" => T_ΔNTCP_all_R, "Continue" => T_ΔNTCP_all_C)

# Create master matrix
T = zeros(length(actions), num_states, num_states)

## Place prob matrices into the master matrix
for a_ind in eachindex(actions)
    println("\nAction: $(actions[a_ind])")
    for t = 1:horizon
        println("Time = $t")
        # b serves as a counter here
        if actions[a_ind] == "Replan"
            for b = 1:num_budget_states-1
                row_indices = ((t-1)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t-1)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
                col_indices = ((t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states +1):((t)*num_budget_states*num_ΔNTCP_states +(b+1)*num_ΔNTCP_states)
                println("\trow indices: $row_indices")
                println("\tcol indices: $col_indices")
                T[a_ind, row_indices, col_indices] = T_ΔNTCP_all[actions[a_ind]][t] # copy(T_ΔNTCP_F10toF15_R)
            end
        elseif actions[a_ind] == "Continue"
            for b = 1:num_budget_states
                row_indices = ((t-1)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t-1)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
                col_indices = ((t)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
                println("\trow indices: $row_indices")
                println("\tcol indices: $col_indices")
                T[a_ind, row_indices, col_indices] = T_ΔNTCP_all[actions[a_ind]][t] # copy(T_ΔNTCP_F10toF15_C)
            end
        end
    end
end

## Add absorbing probabilities
# Whenever the budget is 0 and action is Replan, transition to the absorbing state
for t = 1:horizon
    ind_start = (t-1)*num_ΔNTCP_states*num_budget_states + (num_budget_states-1)*num_ΔNTCP_states + 1
    ind_end = (t-1)*num_ΔNTCP_states*num_budget_states + (num_budget_states)*num_ΔNTCP_states
    println("Range: $ind_start:$ind_end")
    println("States: $(states[ind_start:ind_end])")
    T[1, ind_start:ind_end, end] .= 1.0  # last state is the absorbing state
end
# Recursion of the absorbing state
T[1,end,end] = 1.0
T[2,end,end] = 1.0

## Add identity probabilities at horizon+1 for both actions
range = horizon *num_ΔNTCP_states *num_budget_states +1:(horizon+1) *num_ΔNTCP_states *num_budget_states
T[1,range, range] = I(num_ΔNTCP_states*num_budget_states)
T[2,range, range] = I(num_ΔNTCP_states*num_budget_states)

# Check if probabilities are valid
bad_rows_R = sanity_check_prob(T[1,:,:])
bad_rows_C = sanity_check_prob(T[2,:,:])

# Write transition matrix to an excel file (with labels)
# TODO: 


#### Observation probabilities
# TODO: 
# An observation is observed after the state transitions
# O: <action> : <end-state> : <observation> %f
# O: <action> : <end-state>
# %f %f ... %f

# TODO: Give meaning values
observation_intensities = [i*j for i = 1:0.5:2, j=1:3]  # matrix

# Create master matrix
O = zeros(length(actions), num_states, num_observations)
O_sub = zeros(num_ΔNTCP_states, num_observations)
# Will assume the probabilities are independent of budget and time (may consider time dependence)
# The worse a ΔNTCP state, the likelier for a worse observation
# Will assume states are ordered from best to worse, with high pain being worse than a high BMI drop
# Replan should have larger probabilities of going to better states than Continue

# Weights of likeliness and length of their blocks in the prob. matrix
w_h = 4 # prob: highest
# block_length_h = 4
w_m = w_h / 2 # prob: medium
# block_length_h = 2
w_l = 1 # prob: least
# block_length_h = 3

## Replan
# TODO: Fix this to reflect replanning (increase prob toward betters states)
O_sub = [
    1/6 1/6 1/6 1/6 1/12 1/12 1/12 1/24 1/24;
    1/6 1/6 1/6 1/6 1/12 1/12 1/12 1/24 1/24;
    1/6 1/6 1/6 1/6 1/12 1/12 1/12 1/24 1/24;
    5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65 5/65;
    5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65 5/65;
    5/65 5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65;
    5/65 5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65;
    5/65 5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65;
    1/25 2/25 2/25 2/25 4/25 4/25 4/25 4/25 2/25;
    1/25 2/25 2/25 2/25 4/25 4/25 4/25 4/25 2/25;
    1/24 1/24 1/12 1/12 1/12 1/6 1/6 1/6 1/6;
    1/24 1/24 1/12 1/12 1/12 1/6 1/6 1/6 1/6;
    1/24 1/24 1/12 1/12 1/12 1/6 1/6 1/6 1/6
]
# bad_rows_R = sanity_check_prob(O_sub)
## Continue
O_sub = [
    1/6 1/6 1/6 1/6 1/12 1/12 1/12 1/24 1/24;
    1/6 1/6 1/6 1/6 1/12 1/12 1/12 1/24 1/24;
    1/6 1/6 1/6 1/6 1/12 1/12 1/12 1/24 1/24;
    5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65 5/65;
    5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65 5/65;
    5/65 5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65;
    5/65 5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65;
    5/65 5/65 5/65 8/52 8/52 8/52 8/52 5/65 5/65;
    1/25 2/25 2/25 2/25 4/25 4/25 4/25 4/25 2/25;
    1/25 2/25 2/25 2/25 4/25 4/25 4/25 4/25 2/25;
    1/24 1/24 1/12 1/12 1/12 1/6 1/6 1/6 1/6;
    1/24 1/24 1/12 1/12 1/12 1/6 1/6 1/6 1/6;
    1/24 1/24 1/12 1/12 1/12 1/6 1/6 1/6 1/6
]


#### Immediate Rewards
# TODO: 
R = Dict("Replan" => zeros(states, states, length(observations)), "Continue" => zeros(states, states, length(observations)))
for s_start in Base.OneTo(states)
    R["Replan"][s_start,:,:] = [(s_end-s_start) * o for s_end = 1:states, o = observation_intensities]
end
R["Continue"] = 3 * copy(R["Replan"])

##########################################################################
#### Write to file

filename = "tester.POMDP"
full_path = joinpath(pwd(), "Input Files", "$filename")
f = open(full_path, "w")
write(f, "# Dummy input file to test pomdp-solve\n")
write(f,"# TODO: Add budget to state\n# TODO: Create meaningful observation probabilities\n\n")

#### The first five line must be these (can be in a different order though)

#### Discount factor
write(f, "discount: $discount\n")

#### Rewards
write(f, "values: $values\n")

#### States
write(f, "states: $states\n")
# write(f, "states = ")

#### Actions
write(f, "actions: ")
for act in actions
    write(f, "$act ")
end
write(f, "\n")

#### Observations
write(f, "observations: ")
for obs in observations
    write(f, "$obs ")
end
write(f, "\n\n")

flush(f)

#= After the initial five lines and optional starting state, the specifications of transition probabilities, 
observation probabilities and rewards appear. These specifications may appear in any order and can be intermixed.
Any probabilities or rewards not specified in the file are assumed to be zero. 
You may also specify a particular probability or reward more than once. The definition that appears last in the file 
is the one that will take affect. This is convenient for specifying exceptions to a more general specification. =#

#### Starting belief state
write(f, "start: ")
foreach(s_prob -> write(f, "$s_prob "), start_dist)
write(f, "\n\n")
# write(f, "start include: ")
# foreach(s -> write(f, "$s "), start_include)

#### State transition probabilities
# write(f, "T: ")
# write(f, "...")
# for a in actions
#     write(f, "T: $(a)\nuniform\n\n")
# end
# for a in eachindex(actions), s_start in Base.OneTo(states)
#     write(f, "T: $(actions[a]) : $(s_start-1)\n")
#     for s_end in Base.OneTo(states)
#         write(f, "$(T[a,s_start,s_end]) ")
#     end
#     write(f, "\n\n")
# end
for a in eachindex(actions)
    write(f, "T: $(actions[a])\n")
    for s_start in Base.OneTo(states)
        for s_end in Base.OneTo(states)
            write(f, "$(T[a,s_start,s_end]) ")
        end
        write(f, "\n")
    end
    write(f, "\n")
end

#### Observation probabilities
# write(f, "O: ")
# write(f, "...")
for a in actions
    write(f, "O: $(a)\nuniform\n\n")
end

#### Immediate rewards
# write(f, "R: ")
# write(f, "...")
for action in actions, s_start in Base.OneTo(states)
    write(f, "R: $action : $(s_start-1)\n")
    for s_end in Base.OneTo(states)
        for o in eachindex(observations)
            write(f, "$(R[action][s_start,s_end,o]) ")
        end
        write(f, "\n")
    end
    write(f, "\n")
end

close(f)

##########################################################################
#### Execute pomdp-solve via command line
# cmd = `/Users/raulgarcia/Documents/pomdp-solve-5.5/src/pomdp-solve -pomdp ./Input\ Files/$filename`
# run(cmd)

