include("utils.jl")
include("algorithm/declat.jl")
include("algorithm/association_rules.jl")

function main()
    opts = parse_cli(ARGS)

    if !haskey(opts, "--input") || !haskey(opts, "--minsup")
        println("Usage:")
        println("  julia --project src/main.jl --input data/toy/test.txt --minsup 2 [--output out.txt] [--mode baseline|optimized]")
        return
    end

    input_path = opts["--input"]
    minsup = parse(Int, opts["--minsup"])
    output_path = get(opts, "--output", "declat_output.txt")
    mode = Symbol(get(opts, "--mode", "optimized"))

    # Pre-allocate memory hint for large datasets
    println("Loading input: ", input_path)
    transactions = read_spmf(input_path)
    println("Input: ", input_path)
    println("Transactions: ", length(transactions))
    println("Minsup: ", minsup)
    println("Mode: ", mode)

    # Add memory hint and time the execution
    GC.gc()  # Force garbage collection before mining
    freq_items = @timed run_declat(transactions, minsup; mode=mode)
    result = freq_items.value

    write_spmf_itemsets(output_path, result)

    println("Frequent itemsets: ", length(result))
    println("Elapsed: ", round(freq_items.time, digits=6), " seconds")
    println("Output written to: ", output_path)

    for fi in Iterators.take(result, 10)
        println(join(fi.items, " "), " #SUP: ", fi.support)
    end

    rules = mine_association_rules(result, length(transactions), minconf=0.6)
    write_association_rules("output_rules.txt", rules)

    top_10_rules = rules[1:min(10, length(rules))]
    write_association_rules("output_10_rules.txt", top_10_rules)

    for r in top_10_rules
        println("{", join(r.lhs, ", "), "} => {", join(r.rhs, ", "),
            "} | supp=", round(r.support_rel, digits=4),
            " conf=", round(r.confidence, digits=4),
            " lift=", round(r.lift, digits=4))
    end
end

main()