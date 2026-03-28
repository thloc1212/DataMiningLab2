function read_spmf(filepath::String)
    transactions = Vector{Vector{Int}}()
    
    open(filepath, "r") do file
        for line in eachline(file)
            parts = split(strip(line))
            if isempty(parts) continue end
            
            # Chuyển các string thành số nguyên (Int)
            itemset = parse.(Int, parts)
            push!(transactions, itemset)
        end
    end
    return transactions
end