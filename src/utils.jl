function read_spmf(filepath::String)::Vector{Vector{Int}}
    transactions = Vector{Vector{Int}}()

    open(filepath, "r") do io
        for line in eachline(io)
            s = strip(line)
            isempty(s) && continue
            startswith(s, "#") && continue

            items = sort!(unique(parse.(Int, split(s))))
            push!(transactions, items)
        end
    end

    return transactions
end

function write_spmf_itemsets(filepath::String, itemsets)
    open(filepath, "w") do io
        for fi in itemsets
            println(io, join(fi.items, " "), " #SUP: ", fi.support)
        end
    end
end

function normalize_itemsets!(itemsets)
    sort!(itemsets, by = x -> (length(x.items), x.items, x.support))
    return itemsets
end

function parse_cli(args::Vector{String})
    opts = Dict{String,String}()
    i = 1
    while i <= length(args)
        if startswith(args[i], "--")
            key = args[i]
            if i == length(args) || startswith(args[i+1], "--")
                opts[key] = "true"
                i += 1
            else
                opts[key] = args[i+1]
                i += 2
            end
        else
            i += 1
        end
    end
    return opts
end