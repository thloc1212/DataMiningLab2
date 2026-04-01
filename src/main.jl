include("utils.jl")
include("algorithm/declat.jl")

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

    transactions = read_spmf(input_path)
    println("Input: ", input_path)
    println("Transactions: ", length(transactions))
    println("Minsup: ", minsup)
    println("Mode: ", mode)

    freq_items = @timed run_declat(transactions, minsup; mode=mode)
    result = freq_items.value

    write_spmf_itemsets(output_path, result)

    println("Frequent itemsets: ", length(result))
    println("Elapsed: ", round(freq_items.time, digits=6), " seconds")
    println("Output written to: ", output_path)

    for fi in Iterators.take(result, 10)
        println(join(fi.items, " "), " #SUP: ", fi.support)
    end
end

main()