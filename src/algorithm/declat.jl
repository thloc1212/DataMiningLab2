include("../structures.jl")

using DataStructures

diff_length(d::SetDiffRep) = length(d.data)
diff_length(d::BitDiffRep) = count(d.data)

function diff_minus(a::SetDiffRep, b::SetDiffRep)
    return SetDiffRep(setdiff(a.data, b.data)) # dùng setdiff của Julia 
end

function diff_minus(a::BitDiffRep, b::BitDiffRep)
    return BitDiffRep(a.data .& .!b.data) # dùng công thức bitvector luon
end

# tạo những tập diffset ban đầu cho mỗi item đơn lẻ, dựa trên transaction ID chứa item đó

function singleton_diffset(::Type{SetDiffRep}, present_tids::Vector{Int}, total_trans::Int)
    all_tids = Set(1:total_trans)
    return SetDiffRep(setdiff(all_tids, Set(present_tids)))
end

function singleton_diffset(::Type{BitDiffRep}, present_tids::Vector{Int}, total_trans::Int)
    bits = trues(total_trans)
    @inbounds for tid in present_tids
        bits[tid] = false
    end
    return BitDiffRep(bits)
end

function support_from_parent(parent_support::Int, child_diff::AbstractDiffRep)
    return parent_support - diff_length(child_diff)
end

function build_initial_classes(transactions::Vector{Vector{Int}}, minsup::Int, ::Type{D}) where {D<:AbstractDiffRep}
    tidlists = DefaultDict{Int, Vector{Int}}(Vector{Int})

    for (tid, trx) in enumerate(transactions)
        for item in trx
            push!(tidlists[item], tid)
        end
    end

    classes = Vector{VerticalItem{D}}()
    for item in sort(collect(keys(tidlists)))
        supp = length(tidlists[item])
        supp < minsup && continue
        diff = singleton_diffset(D, tidlists[item], length(transactions))
        push!(classes, VerticalItem{D}([item], diff, supp))
    end

    sort!(classes, by = x -> (x.support, x.items))
    return classes
end

function mine_declat!(
    prefix_classes::Vector{VerticalItem{D}},
    minsup::Int,
    output::Vector{VerticalItem{D}}
) where {D<:AbstractDiffRep}

    n = length(prefix_classes)
    for i in 1:n
        xi = prefix_classes[i]
        push!(output, xi)

        children = Vector{VerticalItem{D}}()
        children_count = 0

        for j in (i + 1):n
            xj = prefix_classes[j]

            new_diff = diff_minus(xj.diffset, xi.diffset)
            new_support = support_from_parent(xi.support, new_diff)

            if new_support >= minsup
                # Reuse items vector instead of creating new one
                new_items = copy(xi.items)
                push!(new_items, xj.items[end])
                push!(children, VerticalItem{D}(new_items, new_diff, new_support))
                children_count += 1
            end
        end

        if children_count > 0
            mine_declat!(children, minsup, output)
        end
    end

    return output
end

function run_declat_baseline(transactions::Vector{Vector{Int}}, minsup::Int)
    init = build_initial_classes(transactions, minsup, SetDiffRep)
    out = Vector{VerticalItem{SetDiffRep}}()
    mine_declat!(init, minsup, out)
    sort!(out, by = x -> (length(x.items), x.items, x.support))
    return out
end

function run_declat_optimized(transactions::Vector{Vector{Int}}, minsup::Int)
    init = build_initial_classes(transactions, minsup, BitDiffRep)
    out = Vector{VerticalItem{BitDiffRep}}()
    mine_declat!(init, minsup, out)
    sort!(out, by = x -> (length(x.items), x.items, x.support))
    return out
end

function run_declat(transactions::Vector{Vector{Int}}, minsup::Int; mode::Symbol=:optimized)
    if mode === :baseline
        return run_declat_baseline(transactions, minsup)
    elseif mode === :optimized
        return run_declat_optimized(transactions, minsup)
    else
        error("mode phải là :baseline hoặc :optimized")
    end
end