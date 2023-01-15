local utf = require 'utf'

function test_1_octet()
    local code_units = utf.u32_to_u8(0x0020)
    assert(#code_units == 1)
    assert(code_units[1] == 0x0020)

    local code_point = utf.u8_to_u32(code_units)
    assert(code_point == 0x0020)
end

function test_2_octets()
    local code_units = utf.u32_to_u8(0x1FF)
    assert(#code_units == 2)
    assert(code_units[1] == 0xC7)
    assert(code_units[2] == 0xBF)

    local code_point = utf.u8_to_u32(code_units)
    assert(code_point == 0x1FF)
end

function test_3_octets()
    local code_units = utf.u32_to_u8(0x10FF)
    assert(#code_units == 3)
    assert(code_units[1] == 0xE1)
    assert(code_units[2] == 0x83)
    assert(code_units[3] == 0xBF)

    local code_point = utf.u8_to_u32(code_units)
    assert(code_point == 0x10FF)
end

function test_4_octets()
    local code_units = utf.u32_to_u8(0x1FFFF)
    assert(#code_units == 4)
    assert(code_units[1] == 0xF0)
    assert(code_units[2] == 0x9F)
    assert(code_units[3] == 0xBF)
    assert(code_units[4] == 0xBF)

    local code_point = utf.u8_to_u32(code_units)
    assert(code_point == 0x1FFFF)
end

function test_single_u16_code_unit()
    local code_units = utf.u32_to_u16(0x0020)
    assert(#code_units == 1)
    assert(code_units[1] == 0x0020)

    local code_point = utf.u16_to_u32(code_units)
    assert(code_point == 0x0020)
end

function test_surrogate_pair()
    local code_units = utf.u32_to_u16(0x1D405)
    assert(#code_units == 2)
    assert(code_units[1] == 0xD835)
    assert(code_units[2] == 0xDC05)

    local code_point = utf.u16_to_u32(code_units)
    assert(code_point == 0x1D405)
end

test_1_octet()
test_2_octets()
test_3_octets()
test_4_octets()
test_single_u16_code_unit()
test_surrogate_pair()