using Test

include("numeric_convertions_tests.jl")

@testset "Test arithmetic equalities" begin
    @test 1 + 1 == 2
end
