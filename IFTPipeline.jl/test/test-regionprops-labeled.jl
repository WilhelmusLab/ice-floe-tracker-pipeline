@testset "regionprops-labeled.jl" begin
    println("-------------------------------------------------")
    println("-------------- regionprops (labaled) Tests ----------------")

    img1 = Int[
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   # row  1
        0 1 1 0 2 2 2 0 3 3 3 3 0 0 0 0   #      2
        0 1 1 0 2 2 2 0 3 3 3 3 0 0 0 0   #      3
        0 0 0 0 0 2 2 0 3 3 3 3 0 0 0 0   #      4
        0 0 0 0 0 0 0 0 3 3 3 0 0 0 0 0   #      5
        0 4 4 4 4 5 0 0 0 0 0 0 0 0 0 0   #      6
        0 4 5 5 5 5 0 0 0 0 0 0 0 0 0 0   #      7
        0 4 5 5 0 0 0 0 0 0 0 0 0 0 0 0   #      8
        0 4 4 4 4 4 0 0 0 0 0 0 0 0 0 0   #      9
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     10
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     11
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     12
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     13
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     14
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     15
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   #     16
    # col
    #   1 2 3 4 5 6 7 8 9 a b c d e f g

    ]

    props = DataFrame(label=Int[], min_row=Int[], min_col=Int[], max_row=Int[], max_col=Int[])
    push!(props, (1, 1, 1, 4, 4))  
    push!(props, (2, 1, 4, 5, 8))
    push!(props, (3, 1, 8, 6, 13))
    push!(props, (4, 5, 1, 10, 7))
    push!(props, (5, 5, 1, 10, 7))

    @info props[1, :]

    # cropfloe
    @test cropfloe(floesimg=img1, min_row=1, min_col=1, max_row=4, max_col=4, label=1) == [
        0 0 0 0
        0 1 1 0
        0 1 1 0
        0 0 0 0
    ]

    @test cropfloe(floesimg=img1, min_row=1, min_col=4, max_row=5, max_col=8, label=2) == [
        0 0 0 0 0
        0 1 1 1 0
        0 1 1 1 0
        0 0 1 1 0
        0 0 0 0 0
    ]

    @test cropfloe(floesimg=img1, min_row=1, min_col=8, max_row=6, max_col=13, label=3) == [
        0 0 0 0 0 0
        0 1 1 1 1 0
        0 1 1 1 1 0
        0 1 1 1 1 0
        0 1 1 1 0 0
        0 0 0 0 0 0          
    ]

    @test cropfloe(floesimg=img1, min_row=5, min_col=1, max_row=10, max_col=7, label=4) == [
        0 0 0 0 0 0 0
        0 1 1 1 1 0 0
        0 1 0 0 0 0 0
        0 1 0 0 0 0 0
        0 1 1 1 1 1 0
        0 0 0 0 0 0 0        
    ]
    
    @test cropfloe(floesimg=img1, min_row=5, min_col=1, max_row=10, max_col=7, label=5) == [
        0 0 0 0 0 0 0
        0 0 0 0 0 1 0
        0 0 1 1 1 1 0
        0 0 1 1 0 0 0
        0 0 0 0 0 0 0 
        0 0 0 0 0 0 0        
    ]


end
