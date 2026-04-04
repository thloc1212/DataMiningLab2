include("../structures.jl")

using DataStructures

diff_length(d::SetDiffRep) = length(d.data)
diff_length(d::BitDiffRep) = count(d.data)

function diff_minus(a::SetDiffRep, b::SetDiffRep)
    return SetDiffRep(setdiff(a.data, b.data)) # dùng setdiff của Julia 
end

function diff_minus(a::BitDiffRep, b::BitDiffRep)
    n = length(a.data)
    result = BitVector(undef, n)

    @inbounds for i in 1:n
        result[i] = a.data[i] & !b.data[i]
    end

    return BitDiffRep(result)
end

# tạo những tập diffset ban đầu cho mỗi item đơn lẻ, dựa trên transaction ID chứa item đó

function singleton_diffset(::Type{SetDiffRep}, present_tids::Vector{Int}, total_trans::Int)
    present = Set(present_tids)
    diff = Set{Int}()

    for tid in 1:total_trans
        if !(tid in present)
            push!(diff, tid)
        end
    end

    return SetDiffRep(diff)
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
    items = collect(keys(tidlists))
    sort!(items)

    for item in items
        supp = length(tidlists[item])
        supp < minsup && continue
        diff = singleton_diffset(D, tidlists[item], length(transactions))
        push!(classes, VerticalItem{D}([item], diff, supp))
    end

    sort!(classes, by = x -> (x.support, x.items))
    return classes
end

function mine_declat!(
    prefix_classes::AbstractVector{VerticalItem{D}},
    minsup::Int,
    output::Vector{VerticalItem{D}}
) where {D<:AbstractDiffRep}

    n = length(prefix_classes)
    for i in 1:n
        @inbounds xi = prefix_classes[i]
        push!(output, xi)

        xi_support = xi.support
        xi_diffset = xi.diffset
        xi_items = xi.items
        xi_items_len = length(xi_items)

        max_children = n - i
        children = Vector{VerticalItem{D}}(undef, max_children)
        children_count = 0

        @inbounds for j in (i + 1):n
            xj = prefix_classes[j]

            new_diff = diff_minus(xj.diffset, xi_diffset)
            new_support = xi_support - diff_length(new_diff)

            if new_support >= minsup
                new_items = Vector{Int}(undef, xi_items_len + 1)

                copyto!(new_items, 1, xi_items, 1, xi_items_len)
                new_items[xi_items_len + 1] = xj.items[end]
                children_count += 1
                children[children_count] = VerticalItem{D}(new_items, new_diff, new_support)
            end
        end

        if children_count > 0
            if children_count == max_children
                mine_declat!(children, minsup, output)
            else
                mine_declat!(view(children, 1:children_count), minsup, output)
            end
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