local utf = {}

-- UTF-8 <=> UTF-32
--
--    Code point in binary | Octec 1  Octec 2  Octec 3  Octec 4
--       00000000 0xxxxxxx | 0xxxxxxx
--       00000yyy yyxxxxxx | 110yyyyy 10xxxxxx
--       zzzzyyyy yyxxxxxx | 1110zzzz 10yyyyyy 10xxxxxx
-- uuuww zzzzyyyy yyxxxxxx | 11110uuu 10wwzzzz 10yyyyyy 10xxxxxx

function utf.u8_to_u32(code_units)
    -- TODO
end

function utf.u32_to_u8(code_point)
    -- TODO
end

-- UTF-8 <=> UTF-16

-- TODO: convenience function for UTF-8 => UTF-16
-- TODO: convenience function for UTF-16 => UTF-8

-- UTF-16 <=> UTF-32
--
-- Example:
--
-- U+1D405 MATHEMATICAL BOLD CAPITAL F
--
-- U+1D405 in binary: 000011101010000000101
-- u1 = 00001 | u2 = 110101 | u3 = 0000000101
-- u1 -= 1
--
-- 110110u1u2 = 1101100000110101 // U+D835, high surrogate
--   110111u3 = 1101110000000101 // U+DC05, low surrogate

local UTF_16_SINGLE_CODE_UNIT_LIMIT = 0xFFFF;
local UTF_16_U1_BIT_MASK = 0x1F; -- 0b1'1111
local UTF_16_U2_BIT_MASK = 0x3F; -- 0b11'1111
local UTF_16_U3_BIT_MASK = 0x3FF; -- 0b11'1111'1111
local UTF_16_U1_BIT_WIDTH = 5;
local UTF_16_U2_BIT_WIDTH = 6;
local UTF_16_U3_BIT_WIDTH = 10;
local UTF_16_HIGH_SURROGATE_PREFIX = 0x36 -- 0b11'0110;
local UTF_16_LOW_SURROGATE_PREFIX = 0x37 -- 0b11'0111;

function utf.u16_to_u32(code_units)
    local num_code_units = #code_units
    if (num_code_units == 1) then
        return code_units[1]
    end

    assert(num_code_units == 2,
           "This function can only handle single UTF-16 code units or UTF-16 surrogate pairs")

    local high_surrogate = code_units[1]
    assert(high_surrogate >> (UTF_16_U1_BIT_WIDTH - 1 + UTF_16_U2_BIT_WIDTH) == UTF_16_HIGH_SURROGATE_PREFIX,
           "High surrogate must start with the correct prefix")

    local low_surrogate = code_units[2]
    assert(low_surrogate >> UTF_16_U3_BIT_WIDTH == UTF_16_LOW_SURROGATE_PREFIX,
           "Low surrogate must start with the correct prefix")

    local u3 = low_surrogate & UTF_16_U3_BIT_MASK
    local u2 = high_surrogate & UTF_16_U2_BIT_MASK
    local u1 = (high_surrogate >> UTF_16_U2_BIT_WIDTH) & UTF_16_U1_BIT_MASK
    u1 = u1 + 1

    return (u1 << (UTF_16_U2_BIT_WIDTH + UTF_16_U3_BIT_WIDTH)) | (u2 << UTF_16_U3_BIT_WIDTH) | u3
end

function utf.u32_to_u16(code_point)
    if (code_point <= UTF_16_SINGLE_CODE_UNIT_LIMIT) then
        return { code_point }
    end

    local u1 = (code_point >> (UTF_16_U2_BIT_WIDTH + UTF_16_U3_BIT_WIDTH)) & UTF_16_U1_BIT_MASK
    u1 = u1 - 1
    local u2 = code_point >> UTF_16_U3_BIT_WIDTH & UTF_16_U2_BIT_MASK
    local u3 = code_point & UTF_16_U3_BIT_MASK

    local high_surrogate = (UTF_16_HIGH_SURROGATE_PREFIX << (UTF_16_U1_BIT_WIDTH - 1 + UTF_16_U2_BIT_WIDTH))
                           | (u1 << UTF_16_U2_BIT_WIDTH)
                           | u2
    local low_surrogate = (UTF_16_LOW_SURROGATE_PREFIX << UTF_16_U3_BIT_WIDTH) | u3

    return { high_surrogate, low_surrogate }
end

return utf