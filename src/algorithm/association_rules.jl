include("../structures.jl")

struct AssociationRule
    lhs::Vector{Int}
    rhs::Vector{Int}
    support_abs::Int
    support_rel::Float64
    confidence::Float64
    lift::Float64
end

# đổi itemset thành key để đưa vào Dict
itemset_key(items::Vector{Int}) = Tuple(sort(items))

# sinh tất cả tập con không rỗng và không phải toàn bộ tập
function nonempty_proper_subsets(items::Vector{Int})
    n = length(items)
    subsets = Vector{Vector{Int}}()

    if n <= 1
        return subsets
    end

    # mask từ 1 đến 2^n - 2
    for mask in 1:(2^n - 2)
        subset = Int[]
        @inbounds for i in 1:n
            if ((mask >> (i - 1)) & 1) == 1
                push!(subset, items[i])
            end
        end
        push!(subsets, subset)
    end

    return subsets
end

# lấy phần bù: items \ subset
function set_difference_items(items::Vector{Int}, subset::Vector{Int})
    subset_set = Set(subset)
    result = Int[]
    @inbounds for x in items
        if !(x in subset_set)
            push!(result, x)
        end
    end
    return result
end

# tạo bảng tra support từ frequent itemsets
function build_support_map(freq_itemsets)
    support_map = Dict{Tuple{Vararg{Int}}, Int}()

    for fi in freq_itemsets
        support_map[itemset_key(fi.items)] = fi.support
    end

    return support_map
end

# sinh toàn bộ luật kết hợp
function generate_association_rules(freq_itemsets, n_transactions::Int; minconf::Float64=0.0)
    support_map = build_support_map(freq_itemsets)
    rules = AssociationRule[]

    for fi in freq_itemsets
        items = sort(fi.items)
        length(items) < 2 && continue

        supp_xy_abs = fi.support
        supp_xy_rel = supp_xy_abs / n_transactions

        for lhs in nonempty_proper_subsets(items)
            rhs = set_difference_items(items, lhs)

            supp_x_abs = get(support_map, itemset_key(lhs), 0)
            supp_y_abs = get(support_map, itemset_key(rhs), 0)

            if supp_x_abs == 0 || supp_y_abs == 0
                continue
            end

            confidence = supp_xy_abs / supp_x_abs
            confidence < minconf && continue

            supp_y_rel = supp_y_abs / n_transactions
            lift = supp_y_rel == 0.0 ? 0.0 : confidence / supp_y_rel

            push!(rules, AssociationRule(
                sort(lhs),
                sort(rhs),
                supp_xy_abs,
                supp_xy_rel,
                confidence,
                lift
            ))
        end
    end

    return rules
end

# sắp xếp luật: lift giảm dần, confidence giảm dần, support giảm dần
function sort_rules!(rules::Vector{AssociationRule})
    sort!(rules, by = r -> (-r.lift, -r.confidence, -r.support_abs, r.lhs, r.rhs))
    return rules
end

# lấy top-k luật
function top_k_rules(rules::Vector{AssociationRule}, k::Int=10)
    k <= 0 && return AssociationRule[]
    return rules[1:min(k, length(rules))]
end

# ghi luật ra file
function write_association_rules(filepath::String, rules::Vector{AssociationRule})
    open(filepath, "w") do io
        for r in rules
            println(
                io,
                "{", join(r.lhs, " "), "} => {", join(r.rhs, " "),
                "} #SUP_ABS: ", r.support_abs,
                " #SUP: ", round(r.support_rel, digits=6),
                " #CONF: ", round(r.confidence, digits=6),
                " #LIFT: ", round(r.lift, digits=6)
            )
        end
    end
end

# hàm tiện để chạy full pipeline từ freq itemsets
function mine_association_rules(freq_itemsets, n_transactions::Int;
                                minconf::Float64=0.0,
                                topk::Union{Nothing,Int}=nothing)
    rules = generate_association_rules(freq_itemsets, n_transactions; minconf=minconf)
    sort_rules!(rules)

    if topk !== nothing
        return top_k_rules(rules, topk)
    end

    return rules
    
end