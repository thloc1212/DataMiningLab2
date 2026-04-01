
abstract type AbstractDiffRep end

struct SetDiffRep <: AbstractDiffRep
    data::Set{Int}
end

struct BitDiffRep <: AbstractDiffRep
    data::BitVector
end

struct VerticalItem{D<:AbstractDiffRep}
    items::Vector{Int}
    diffset::D  # Lưu các Transaction ID KHÔNG chứa item này
    support::Int
end

Base.length(d::SetDiffRep) = length(d.data)
Base.length(d::BitDiffRep) = count(d.data)

Base.isempty(d::SetDiffRep) = isempty(d.data)
Base.isempty(d::BitDiffRep) = !any(d.data)