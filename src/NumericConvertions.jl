# module NumConvertion

# export bin2fract, bin2uint, bin2sint, int2unsigned, int2signed2C, int2fixed,
#     float2fixed, bin2hex, hex2bin
       

"""
        bin2fract(bs)

    Takes the bitstring representing the fractional part (m) of a binary fixed
    point number of Qn.m type and returns its decimal value.

    julia> bin2fract("1")
    0.5

    julia> bin2fract("11")
    0.75
"""
function bin2fract(bs)
    fr = 0
    for i in eachindex(bs)
        if (bs[i] == '1')
            fr = fr + 2.0^-i
        else
            fr = fr
        end
        i = i + 1
    end
    fr
end


"""
        bin2uint(bs)

    Takes a bitstring and returns the value of the unsigned integer it
    reppresents.

    julia> bin2uint("111")
    7

    julia> bin2uint("01110")
    14

    """
function bin2uint(bs)
    parse(Int, bs, base = 2)
end


"""
        bin2sint(bs)

    Takes a bitstring (bs) and converts it in a signed integer.

    julia> bin2sint("10101110101010010101")
    -333163
"""
function bin2sint(bs)
    n = length(bs)
    if (bs[1] == '0')
        if (n == 1)
            res = 0
        else
            res = bin2uint(bs[2:end])
        end
    else
        nbs = bin2uint(bs) - 1
        nbs = int2unsigned(nbs, n)
        nbs = map(x -> (x=='0') ? '1' : '0', nbs)
        res = -bin2uint(nbs)
    end
    res
end



"""
        int2unsigned(x, n)

    Takes an unsigned integer x and and returns its n bit unsigned bitstring
    reppresentation.

    julia> int2unsigned(13, 4)
    "1101"
    """
function int2unsigned(x, n)
    @assert ((x >= 0) && (typeof(x) == Int64)) "Sign error (Overflow/Underflow): n must be an positive integer"
    a = join(digits(x, base=2, pad=n) |> reverse)
end


"""
        int2signed(x, n)

    Takes an integer x and and returns its n bit signed bitstring in tow's
    complement reppresentation.

    julia> int2signed(3, 4)
    "0011"

    julia> int2signed(-3, 4)
    "1101"
    """
function int2signed(x, n)
    @assert (x >= (-2^(n-1)) &&  x <= 2^(n-1)-1) "Out of range error (Overflow/Underflow): The allowed range for n=" *string(n)* " x ⋹ [-2^"*string(n-1)*", 2^"*string(n-1)*"-1]"

    if x >=0
        a = join(digits(x, base=2, pad=n-1) |> reverse)
        res = '0'*a
    else
        a = join(digits(abs(x), base=2, pad=n-1) |> reverse)
        na = map(x -> (x=='0') ? '1' : '0', a)
        yn = bin2uint(na) + 1
        a = join(digits(yn, base=2, pad=n-1) |> reverse)
        if abs(x) < 2^(n-1)
            res = '1'*a
        else
            res = a
        end
    end
    res
end


"""
        int2fixed(x, n, m)

    Takes an signed integer x converts its tows' complement bitstring (of length
    "n+m") representation in its fixed point Qn.m reppresentation.

    julia> int2fixed(3, 4, 5)
    0.09375

    julia> 3/2^5
    0.09375

    If one wants to approximate a floating point number in its closest Qn.m
    fixed point number, e.g.: y0 = 3.42857142857142855, n = 3, m = 6; y1 = y0 *
    2^m

    julia> y1 = y0 * 2^6
    219.42857142857142

    julia> int2fixed(219, 3, 6)
    3.421875

"""
function int2fixed(x, m, n)
    @assert (m>=1) "m must be m>= 1"
    a = int2signed(x, m+n)
    ym = bin2uint(a[1:m])
    yn = bin2fract(a[m+1:end])
    if (x<0)
        res = yn - ym
    else
        res = ym + yn
    end
end


"""
        fixed2bin(fxd)

    Converts a floating point number in a fixed point number of Qm.n notation
    "(fp, m, n)" with a precision of the fractional part (m) up to 32.

    Ref: https://www.allaboutcircuits.com/technical-articles/fixed-point-\
         representation-the-q-format-and-addition-examples/

    julia> fixed2bin(3.25)
    ("01101", 3, 2)

    julia> fixed2bin(-1.25)
    ("1011", 2, 2)

    julia> fixed2bin(-3.875)
    ("100001", 3, 3)

    julia> fixed2bin(-0.8125)
    ("10011", 1, 4)

    julia> fixed2bin(0.75)
    ("011", 1, 2)

    fixed2bin(0.755)
    ("011000001010001111010111000010100", 1, 32)
"""
function fixed2bin(fxd)
    if (fxd < 0)
        s = "1"
        qm = abs(Int(ceil(fxd)))
    else
        s = "0"
        qm = abs(floor(Int, fxd))
    end
    @assert (qm<=2^32) "ERROR: fxd must be fxd<=2^32."
    m = 0
    for i = 0:32
        if (qm <= 2.0^i)
            m = i
            break
        end
    end
    
    bs = ""
    qn = abs(fxd)-qm
    
    ym = int2unsigned(qm, m)
    bs = bs * ym
    
    n = 0
    for i = 1:32
        if (qn == 0)
            break
        elseif (qn - 2.0^-i == 0.0)
            bs = bs * '1'
            n = i
            break
        elseif (qn - 2.0^-i > 0.0)
            qn = qn - 2.0^-i
            bs = bs * '1'
            n = i
        elseif (qn - 2.0^-i < 0.0)
            bs = bs * '0'
            n = i
        else
            n = i
            break
        end
    end

    if (fxd < 0)
        bs = map(x -> (x=='0') ? '1' : '0', bs)
        bs = int2unsigned(bin2uint(bs) + 1, m+n)
    end
    m = m+1
    bs = s * bs
    return (bs, m, n)
end


"""
        float2fixed(flt, n, m)
    
    Takes a floating point number "flt" and approximates it to its closest Qn.m
    fixed point reppresentation.
    Appart from the approximation, it returns the approximation error too, in a
    tuple fashion: (apprx, err)

    julia> float2fixed(3.42857142857142855, 3, 6)
    (3.421875, 0.006696428571428381)

    julia> float2fixed(-31.42857142857142855, 6, 8)
    (-31.4296875, 0.0011160714285729512)
"""
function float2fixed(flt, n, m)
    res = flt * 2^m
    res = Int(round(res))
    res = int2fixed(res, n, m)
    err = flt - res
    return (res, err)
end



"""
        bin2hex(bs)

    Takes a bitstring (bs) of a multiple of 4 length (max 64) and and returns
    its hexadecimal (base 16) reppresentation.

    bin2hex("00101110101010010101")
    "2EA95"
"""
function bin2hex(bs)
    n = length(bs)
    @assert (n%4==0) "ERROR: Bit string length must be a multiple of 4."
    b16_dict = Dict( join(digits(b, base=2, pad=4) |> reverse) =>
        string(b, base=16) for b in 0:15)
    lb = Integer(n/4)
    hs = ""
    for i in 0:lb-1
        hs = hs * uppercase(b16_dict[bs[i*4+1:(i+1)*4]])
    end
    hs
end


"""
        hex2bin(hex)

    Takes a hexadecimal number (hex) and returns its bit string
    reppresentation. Accepts upper case and lower case letters.

    hex2bin("2ea95"), hex2bin("2EA95")
    "00101110101010010101"
"""
function hex2bin(hex)
    n = length(hex)
    b16_dict = Dict(
        uppercase(
            string(b, base=16)) =>
            join(digits(b, base=2, pad=4) |> reverse) for b in 0:15)
    lb = Integer(n*4)
    hs = ""
    for i in 1:n
        hs = hs*b16_dict[uppercase(string(hex[i]))]
    end
    hs
end

# end
