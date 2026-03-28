include("utils.jl")
include("algorithm/declat.jl")

function main()
    if length(ARGS) < 2
        println("Cách chạy: julia src/main.jl <đường_dẫn_file> <minsup>")
        return
    end
    
    filepath = ARGS[1]
    minsup = parse(Int, ARGS[2])
    
    println("Đang đọc dữ liệu từ: ", filepath)
    transactions = read_spmf(filepath)
    println("Tổng số giao dịch: ", length(transactions))
    
    println("Đang chạy dEclat với minsup = ", minsup)
    
    @time freq_items = run_declat(transactions, minsup)
    
    println("\n=== KẾT QUẢ ===")
    println("Tìm thấy $(length(freq_items)) tập phổ biến.")
    println("5 kết quả đầu tiên:")
    for item in first(freq_items, 5)
        println("Itemset: ", join(item.items, " "), " | Support: ", item.support)
    end
end

main()