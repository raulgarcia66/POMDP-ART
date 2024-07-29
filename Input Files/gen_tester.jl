
#### Generate input file for pomdp-solve software.
#### Syntax requirements can be found at https://www.pomdp.org/code/pomdp-file-spec.html
using LinearAlgebra
using Pipe
include("./util.jl")

#### Discount factor
# %f
discount = 0.99

#### Min/Max
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
# Will assume observations are ordered from best to worst, with high pain being worse than a high BMI drop
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
# THIS IS NOT A DECISION EPOCH
# Replan isn't an option at time 0. The trans. prob. of Continue at F0 correspond to the starting distribution
# of the POMDP (see starting state dist. above)
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
# THIS IS NOT A DECISION EPOCH
# The trans. prob. of Continue at F0 correspond to the starting distribution of the POMDP (see starting state dist. above)
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
T = zeros(length(actions), num_states, num_states);

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
                # println("\trow indices: $row_indices")
                # println("\tcol indices: $col_indices")
                T[a_ind, row_indices, col_indices] = T_ΔNTCP_all[actions[a_ind]][t] # copy(T_ΔNTCP_F10toF15_R)
            end
        elseif actions[a_ind] == "Continue"
            for b = 1:num_budget_states
                row_indices = ((t-1)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t-1)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
                col_indices = ((t)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
                # println("\trow indices: $row_indices")
                # println("\tcol indices: $col_indices")
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
# bad_rows_R = sanity_check_prob(T[1,:,:])
# bad_rows_C = sanity_check_prob(T[2,:,:])

# Write state transition matrix to an excel file (with labels)
# TODO


#### Observation probabilities
# An observation is observed after the state transitions, hence depends on the new state
# O: <action> : <end-state> : <observation> %f
# O: <action> : <end-state>
# %f %f ... %f

# Create master observation probability matrix
O = zeros(length(actions), num_states, num_observations)
O_sub = zeros(num_ΔNTCP_states, num_observations)
# Will assume the observation probabilities are independent of budget and time (may consider time dependence)
# The worse a ΔNTCP state, the likelier for a worse observation
# Will assume observations are ordered from best to worse, with high pain being worse than a high BMI drop

# Observation probabilities should be independent of the action, what matters is the new state
# The action influences the state transition probabilities
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
# bad_rows = sanity_check_prob(O_sub) # currently has some rounding issues, hopefully will not break the solver

# ## For formulaic constuction of observation probabilities
# # Weights of likeliness and length of their blocks in the prob. matrix
# w_h = 4 # prob: highest
# # block_length_h = 4
# w_m = w_h / 2 # prob: medium
# # block_length_h = 2
# w_l = 1 # prob: least
# # block_length_h = 3

# TODO: Verify probabilities are in the correct places and any values made up do not alter the POMDP

## Replan
for t = 1:horizon
    for b = 1:num_budget_states-1
        ind_start = (t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states +1
        ind_end = (t)*num_budget_states*num_ΔNTCP_states +(b+1)*num_ΔNTCP_states
        O[1,ind_start:ind_end,:] = O_sub

        # foreach(i -> println("$(states[i])"), ind_start:ind_end)
    end
end
## Continue
for t = 1:horizon
    for b = 1:num_budget_states
        ind_start = (t)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1
        ind_end = (t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states
        O[2,ind_start:ind_end,:] = O_sub

        # foreach(i -> println("$(states[i])"), ind_start:ind_end)
    end
end

# When in the forbidden state, arbitrarily observe the worst observation with prob. 1 (shouldn't matter)
O[1,end,end] = 1.0
O[2,end,end] = 1.0

# Take care of observations of states that can't be reached
# They are any state with t=1 (for both actions) and any state with a budget of 3 at a time ≥ 2 (for Replan)
# Have these states arbitrarily observe the last observation (shouldn't matter)
## Case 1: t = 1
for b = 1:num_budget_states
    ind_start = (b-1)*num_ΔNTCP_states +1
    ind_end = (b)*num_ΔNTCP_states
    O[1,ind_start:ind_end,end] .= 1.0
    O[2,ind_start:ind_end,end] .= 1.0

    # foreach(i -> println("$(states[i])"), ind_start:ind_end)
end
## Case t ≥ 2 for Replan
for t = 2:horizon+1
    for b = 1:1
        ind_start = (t-1)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1
        ind_end = (t-1)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states
        O[1,ind_start:ind_end,end] .= 1.0

        # foreach(i -> println("$(states[i])"), ind_start:ind_end)
    end
end

# bad_rows_R = sanity_check_prob(O[1,:,:])
# foreach(tup -> println("$(states[tup[1]])"), bad_rows_R)
# foreach(tup -> println("$(states[tup[1]]) --- $(tup[2])"), bad_rows_R)

# bad_rows_C = sanity_check_prob(O[2,:,:])
# foreach(tup -> println("$(states[tup[1]])"), bad_rows_C)
# foreach(tup -> println("$(states[tup[1]]) --- $(tup[2])"), bad_rows_C)

# Write observation probability matrix to an excel file (with labels)
# TODO


#### Immediate Rewards
R = Dict("Replan" => zeros(num_states, num_states, num_observations), "Continue" => zeros(num_states, num_states, num_observations))
# Rewards across ΔNTCP states
# TODO: Need to address forbidden state still
R_NTCP = [-(s_end - s_start) for s_start ∈ ΔNTCP_states, s_end ∈ ΔNTCP_states]
# Recall we are assuming observations are ordered from best to worst, with high pain being worse than a high BMI drop
# The observation_intensities are to scale the rewards by the severity of the observation
observation_intensities = [i for i = num_observations:-1:1] # we are maximizing so decreasing values
# If we prefer rewards be independent of the observation (hence, no scaling necessary)
observation_intensities = [1 for _ = 1:num_observations]

## Replan
for t = 1:horizon
    for b = 1:num_budget_states-1
        row_indices = ((t-1)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t-1)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
        col_indices = ((t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states +1):((t)*num_budget_states*num_ΔNTCP_states +(b+1)*num_ΔNTCP_states)
        # println("\trow indices: $row_indices")
        # println("\tcol indices: $col_indices")
        for obs in observation_intensities
            R["Replan"][row_indices, col_indices, obs] = R_NTCP * obs
        end
    end
end
## Continue
for t = 1:horizon
    for b = 1:num_budget_states
        row_indices = ((t-1)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t-1)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
        col_indices = ((t)*num_budget_states*num_ΔNTCP_states +(b-1)*num_ΔNTCP_states +1):((t)*num_budget_states*num_ΔNTCP_states +(b)*num_ΔNTCP_states)
        # println("\trow indices: $row_indices")
        # println("\tcol indices: $col_indices")
        for obs in observation_intensities
            R["Continue"][row_indices, col_indices, obs] = R_NTCP * obs
        end
    end
end

# Whenever the budget is 0 and action is Replan, give a big negative to reward to prevent this
for t = 1:horizon
    ind_start = (t-1)*num_ΔNTCP_states*num_budget_states + (num_budget_states-1)*num_ΔNTCP_states + 1
    ind_end = (t-1)*num_ΔNTCP_states*num_budget_states + (num_budget_states)*num_ΔNTCP_states
    # println("Range: $ind_start:$ind_end")
    # println("States: $(states[ind_start:ind_end])")

    # Reward is the same for any state and observation transitioning to the absorbing state (end)
    R["Replan"][ind_start:ind_end, end,:] .= -1000.0
end

# Rewards at the absorbing state (value shouldn't matter)
R["Replan"][end,end,:] .= 0.0
R["Continue"][end,end,:] .= 0.0

# Rewards at horizon + 1 (value shoulnd't matter)
range = horizon *num_ΔNTCP_states *num_budget_states +1:(horizon+1) *num_ΔNTCP_states *num_budget_states
R["Replan"][range, range,:] .= zeros(num_ΔNTCP_states*num_budget_states, num_ΔNTCP_states*num_budget_states);
R["Continue"][range, range,:] .= zeros(num_ΔNTCP_states*num_budget_states, num_ΔNTCP_states*num_budget_states);

##########################################################################
#### Write to file

filename = "tester.POMDP"
# filename = "tester-obs_indep_rewards.POMDP"
full_path = joinpath(pwd(), "Input Files", "$filename")
f = open(full_path, "w")
write(f, "# Describe this instance here\n")

#### The first five line must be these (can be in a different order though)

#### Discount factor
write(f, "discount: $discount\n")

#### Rewards
write(f, "values: $values\n")

#### States
write(f, "states: $num_states\n")

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
    for s_start in Base.OneTo(num_states)
        for s_end in Base.OneTo(num_states)
            write(f, "$(T[a,s_start,s_end]) ")
        end
        write(f, "\n")
    end
    write(f, "\n")
end

#### Observation probabilities
# write(f, "O: ")
# write(f, "...")
for a in eachindex(actions)
    write(f, "O: $(actions[a])\n")
    for s_end in Base.OneTo(num_states)
        for o in Base.OneTo(num_observations)
            write(f, "$(O[a,s_end,o]) ")
        end
        write(f, "\n")
    end
    write(f, "\n")
end
# for a in actions
#     write(f, "O: $(a)\nuniform\n\n")
# end

#### Immediate rewards
# write(f, "R: ")
# write(f, "...")
for action in actions, s_start in Base.OneTo(num_states)
    write(f, "R: $action : $(s_start-1)\n")
    for s_end in Base.OneTo(num_states)
        for o in Base.OneTo(num_observations)
            write(f, "$(R[action][s_start,s_end,o]) ")
        end
        write(f, "\n")
    end
    write(f, "\n")
end

close(f)

##########################################################################
#### Execute pomdp-solve via command line
filename = "tester-obs_indep_rewards.POMDP"

# cmd = `/Users/raulgarcia/Documents/pomdp-solve-5.5/src/pomdp-solve -pomdp Input\ Files/$filename`
# run(cmd)

time_limit = 60  # seconds
cmd = `/Users/raulgarcia/Documents/pomdp-solve-5.5/src/pomdp-solve -pomdp Input\ Files/$filename -time_limit $time_limit`
run(cmd)

max_iter = 5
cmd = `/Users/raulgarcia/Documents/pomdp-solve-5.5/src/pomdp-solve -pomdp Input\ Files/$filename -horizon $max_iter`
run(cmd)
