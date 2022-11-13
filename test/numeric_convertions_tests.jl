include("../src/NumericConvertions.jl")


@testset "Numeric convertion functions" begin
    a = "00101110101010010101"
    @test hex2bin(bin2hex(a)) == a 
    @test_throws AssertionError bin2hex(a*'0')
    @test_throws KeyError hex2bin("y")


    a = bin2fract("11101001011")
    @test a == 0.91162109375

    a = bin2sint("10101110101010010101")
    @test a == -333163
    a = bin2sint("00101110101010010101")
    @test a == 191125

    a = "00101110101010010101"
    @test a == int2unsigned(bin2uint("00101110101010010101"), length(a))

    a = 191125
    @test a == bin2uint(int2unsigned(191125, 21))

    @test_throws AssertionError int2signed(-33, 6)
    @test_throws AssertionError int2signed(32, 6)

    @test fixed2bin(-0.8125) == ("10011", 1, 4)
    @test fixed2bin(0.755) == ("011000001010001111010111000010100", 1, 32)

    @test float2fixed(-31.42857142857142855, 6, 8) == (-31.4296875, 0.0011160714285729512)

end


# # canali in linear
# chans = "HB2"
# # Ampiezza (Vpp) dei segnali: il segnale BFSK generato avvra' un'ampiezza 0-A
# A = 5.0
# fs = 10e3 # Hz
# T = 1.0 # sec
# t = 0:1/fs:T
# s = 2.49 .* sin.(2*pi*100 .*t) .+ 2.5
# dV = 5/2^18
# s = s ./ dV;
# s = floor.(Int, s);
# maximum(s)

# g = 

# S = int2unsigned.(s, 18);
# S = map(x -> '0'*x, S)
# ss = bin2sint.(S);

