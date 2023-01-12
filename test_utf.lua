local utf = require 'utf'

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

test_single_u16_code_unit()
test_surrogate_pair()