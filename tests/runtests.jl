include("../src/utils.jl")
include("../src/algorithm/declat.jl")
using Test

function to_pairs(res)
    Set((Tuple(x.items), x.support) for x in res)
end

@testset "dEclat correctness" begin
    datasets = [
        ("data/toy/test.txt", 2),
        ("data/toy/test.txt", 3),
        ("data/toy/case1.txt", 2),
        ("data/toy/case2.txt", 2),
        ("data/toy/case3.txt", 2),
    ]

    for (path, minsup) in datasets
        tx = read_spmf(path)
        base = run_declat(tx, minsup; mode=:baseline)
        opt = run_declat(tx, minsup; mode=:optimized)
        @test to_pairs(base) == to_pairs(opt)
    end
end