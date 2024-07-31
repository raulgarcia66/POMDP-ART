"""
Returns rows whose sums are not unity. 
"""
function sanity_check_prob(P::Matrix{T}; tol::Float64 = 1E-5) where T
    return @pipe filter(row_ind -> abs(sum(P[row_ind,:]) - 1.0) > tol, 1:size(P,1)) |> map(bad_row -> (bad_row, sum(P[bad_row,:])), _)
end

function sanity_check_prob(x::Vector{T}; tol::Float64 = 1E-5) where T
    if abs(sum(x) - 1.0) > tol
        println("Invalid probabilities")
    else
        println("Valid probabilities")
    end
end

# """
# Returns rows whose sums are not unity. 
# """
# function compute_row_sums(P::Matrix{T}) where T
#     return filter(tup -> tup[2] != 1.0, map(row_ind -> (row_ind, sum(P[row_ind,:])), 1:size(P,1)))
# end