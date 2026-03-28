include("../structures.jl")

function mine_declat(prefix_classes::Vector{VerticalItem}, minsup::Int, frequent_itemsets::Vector{VerticalItem})
    for i in 1:length(prefix_classes)
        item_a = prefix_classes[i]
        push!(frequent_itemsets, item_a)
        
        new_classes = Vector{VerticalItem}()
        
        for j in (i + 1):length(prefix_classes)
            item_b = prefix_classes[j]
            
            # d(ab) = d(b) \ d(a) (Lấy diffset của b trừ đi diffset của a)
            new_diffset = setdiff(item_b.diffset, item_a.diffset)
            
            # sup(ab) = sup(a) - |d(ab)|
            new_support = item_a.support - length(new_diffset)
            
            if new_support >= minsup
                new_items = vcat(item_a.items, item_b.items[end])
                push!(new_classes, VerticalItem(new_items, new_diffset, new_support))
            end
        end
        
        if !isempty(new_classes)
            mine_declat(new_classes, minsup, frequent_itemsets)
        end
    end
end

function run_declat(transactions::Vector{Vector{Int}}, minsup::Int)
    total_trans = length(transactions)
    item_tidsets = Dict{Int, BitSet}()
    
    # Quét DB để lấy TID set cho từng 1-itemset
    for (tid, transaction) in enumerate(transactions)
        for item in transaction
            if !haskey(item_tidsets, item)
                item_tidsets[item] = BitSet()
            end
            push!(item_tidsets[item], tid)
        end
    end
    
    all_tids = BitSet(1:total_trans)
    initial_classes = Vector{VerticalItem}()
    
    # Tính Diffset cho 1-itemset và lọc minsup
    for (item, tidset) in item_tidsets
        sup = length(tidset)
        if sup >= minsup
            diff = setdiff(all_tids, tidset)
            push!(initial_classes, VerticalItem([item], diff, sup))
        end
    end
    
    sort!(initial_classes, by = x -> x.support)
    frequent_itemsets = Vector{VerticalItem}()
    
    mine_declat(initial_classes, minsup, frequent_itemsets)
    return frequent_itemsets
end