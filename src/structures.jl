struct VerticalItem
    items::Vector{Int}
    diffset::BitSet     # Lưu các Transaction ID KHÔNG chứa item này
    support::Int
end