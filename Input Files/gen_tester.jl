
#### Generate input file for pomdp-solve software.
#### Syntax requirements can be found at https://www.pomdp.org/code/pomdp-file-spec.html

#### Discount factor
# %f
discount = 0.99

#### Rewards
# [ reward, cost ]
values =  "cost" # to minimize

#### States
# [ %d, <list-of-states> ]
# When an integer is given, the states are enumerated starting from 0
states = 13

#### Actions
# [ %d, <list-of-actions> ]
# When a list is given, the elements may be referred to by name or by 0-based indexing
actions = ["Replan", "Continue"]

#### Observations
# [ %d, <list-of-observations> ]
# Delimeters are white space
observations = String[]
levels = ["Low", "Med", "High"]
for bmi_level in levels, pain_level in levels
    push!(observations, "BMI_$(bmi_level)_Pain_$(pain_level)")
end
# observations = ["BMI_Low_Pain_Low", "BMI_Low_Pain_Med", "BMI_Low_Pain_High",
#     "BMI_Med_Pain_Low", "BMI_Med_Pain_Med", "BMI_Med_Pain_High",
#     "BMI_High_Pain_Low", "BMI_High_Pain_Med", "BMI_High_Pain_High"]

observation_intensities = [i*j for i = 1:0.5:2, j=1:3]

#### Optional starting state 
start_dist = [1.0; zeros(states-1)]
# start_include = [1,2,3,4]  # uniform distribution over these states

#### State transition probabilities
T = zeros(length(actions), states, states)
# Replan (table B.4 from Aim 1, F15 to F20)
T[1,:,:] = [
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
# Continue (table B.2 from Aim 1, F15 to F20)
T[2,:,:] = [
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

#### Observation probabilities
# O = 

#### Immediate Rewards
R = Dict("Replan" => zeros(states, states, length(observations)), "Continue" => zeros(states, states, length(observations)))
for s_start in Base.OneTo(states)
    R["Replan"][s_start,:,:] = [(s_end-s_start) * o for s_end = 1:states, o = observation_intensities]
end
R["Continue"] = 3 * copy(R["Replan"])

#### Horizon
horizon = 6

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
# cmd = `/Users/raulgarcia/Documents/pomdp-solve-5.5/src/pomdp-solve -pomdp ./Input\ Files/$filename -horizon $horizon`
# run(cmd)

