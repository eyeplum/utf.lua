local utf = {}

local CODE_POINT_LIMIT = 0x10FFFF

-- UTF-8 <=> UTF-32
--
--    Code point in binary | Octet 1  Octet 2  Octet 3  Octet 4
--       00000000 0xxxxxxx | 0xxxxxxx
--       00000yyy yyxxxxxx | 110yyyyy 10xxxxxx
--       zzzzyyyy yyxxxxxx | 1110zzzz 10yyyyyy 10xxxxxx
-- uuuww zzzzyyyy yyxxxxxx | 11110uuu 10wwzzzz 10yyyyyy 10xxxxxx

local UTF_8_ONE_CODE_UNIT_LIMIT = 0x7F -- 0b111'1111
local UTF_8_TWO_CODE_UNIT_LIMIT = 0x7FF -- 0b111'1111'1111
local UTF_8_THREE_CODE_UNIT_LIMIT = 0xFFFF -- 0b1111'1111'1111'1111
local UTF_8_TWO_CODE_UNIT_PREFIX = 0x6 -- 0b110
local UTF_8_THREE_CODE_UNIT_PREFIX = 0xE -- 0b1110
local UTF_8_FOUR_CODE_UNIT_PREFIX = 0x1E -- 0b1'1110
local UTF_8_FOLLOWING_CODE_UNIT_PREFIX = 0x2 -- 0b10

function utf.u8_to_u32(code_units)
    local num_code_units = #code_units
    if (num_code_units == 1) then
        assert(code_units[1] <= UTF_8_ONE_CODE_UNIT_LIMIT)
        return code_units[1]
    elseif (num_code_units == 2) then
        assert(code_units[1] >> 5 == UTF_8_TWO_CODE_UNIT_PREFIX)
        assert(code_units[2] >> 6 == UTF_8_FOLLOWING_CODE_UNIT_PREFIX)

        local y = code_units[1] & 0x1F -- 0b1'1111
        local x = code_units[2] & 0x3F -- 0b11'1111

        local code_point = (y << 6) | x
        return code_point
    elseif (num_code_units == 3) then
        assert(code_units[1] >> 4 == UTF_8_THREE_CODE_UNIT_PREFIX)
        assert(code_units[2] >> 6 == UTF_8_FOLLOWING_CODE_UNIT_PREFIX)
        assert(code_units[3] >> 6 == UTF_8_FOLLOWING_CODE_UNIT_PREFIX)

        local z = code_units[1] & 0xF -- 0b1111
        local y = code_units[2] & 0x3F -- 0b11'1111
        local x = code_units[3] & 0x3F -- 0b11'1111

        local code_point = (z << 12) | (y << 6) | x
        return code_point
    else
        assert(num_code_units == 4,
                "The maximum UTF-8 code units to be converted to a UTF-32 code point is 4, however "
                        .. num_code_units .. " code units is provided")

        assert(code_units[1] >> 3 == UTF_8_FOUR_CODE_UNIT_PREFIX)
        assert(code_units[2] >> 6 == UTF_8_FOLLOWING_CODE_UNIT_PREFIX)
        assert(code_units[3] >> 6 == UTF_8_FOLLOWING_CODE_UNIT_PREFIX)
        assert(code_units[4] >> 6 == UTF_8_FOLLOWING_CODE_UNIT_PREFIX)

        local u = code_units[1] & 0x7 -- 0b111
        local w = (code_units[2] >> 4) & 0x3 -- 0b11
        local z = code_units[2] & 0xF -- 0b1111
        local y = code_units[3] & 0x3F -- 0b11'1111
        local x = code_units[4] & 0x3F -- 0b11'1111

        local code_point = (u << 18) | (w << 16) | (z << 12) | (y << 6) | x
        return code_point
    end
end

function utf.u32_to_u8(code_point)
    if (code_point <= UTF_8_ONE_CODE_UNIT_LIMIT) then
        return { code_point }
    elseif (code_point <= UTF_8_TWO_CODE_UNIT_LIMIT) then
        local x = code_point & 0x3F -- 0b11'1111
        local y = (code_point >> 6) & 0x1F -- 0b1'1111

        local octet1 = (UTF_8_TWO_CODE_UNIT_PREFIX << 5) | y;
        local octet2 = (UTF_8_FOLLOWING_CODE_UNIT_PREFIX << 6) | x;

        return { octet1, octet2 }
    elseif (code_point <= UTF_8_THREE_CODE_UNIT_LIMIT) then
        local x = code_point & 0x3F -- 0b11'1111
        local y = (code_point >> 6) & 0x3F -- 0b11'1111
        local z = (code_point >> 12) & 0xF -- 0b1111

        local octet1 = (UTF_8_THREE_CODE_UNIT_PREFIX << 4) | z;
        local octet2 = (UTF_8_FOLLOWING_CODE_UNIT_PREFIX << 6) | y;
        local octet3 = (UTF_8_FOLLOWING_CODE_UNIT_PREFIX << 6) | x;

        return { octet1, octet2, octet3 }
    else
        assert(code_point <= CODE_POINT_LIMIT,
                "The maximum Unicode code point is " .. " " .. CODE_POINT_LIMIT ..
                        ", but the specified code point is " .. code_point)

        local x = code_point & 0x3F -- 0b11'1111
        local y = (code_point >> 6) & 0x3F -- 0b11'1111
        local z = (code_point >> 12) & 0xF -- 0b1111
        local w = (code_point >> 16) & 0x3 -- 0b11
        local u = (code_point >> 18) & 0x7 -- 0b111

        local octet1 = (UTF_8_FOUR_CODE_UNIT_PREFIX << 3) | u;
        local octet2 = (UTF_8_FOLLOWING_CODE_UNIT_PREFIX << 6) | (w << 4) | z;
        local octet3 = (UTF_8_FOLLOWING_CODE_UNIT_PREFIX << 6) | y;
        local octet4 = (UTF_8_FOLLOWING_CODE_UNIT_PREFIX << 6) | x;

        return { octet1, octet2, octet3, octet4 }
    end
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

local UTF_16_SINGLE_CODE_UNIT_LIMIT = 0xFFFF
local UTF_16_U1_BIT_MASK = 0x1F -- 0b1'1111
local UTF_16_U2_BIT_MASK = 0x3F -- 0b11'1111
local UTF_16_U3_BIT_MASK = 0x3FF -- 0b11'1111'1111
local UTF_16_U1_BIT_WIDTH = 5
local UTF_16_U2_BIT_WIDTH = 6
local UTF_16_U3_BIT_WIDTH = 10
local UTF_16_HIGH_SURROGATE_PREFIX = 0x36 -- 0b11'0110
local UTF_16_LOW_SURROGATE_PREFIX = 0x37 -- 0b11'0111

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
    assert(code_point <= CODE_POINT_LIMIT,
            "The maximum Unicode code point is " .. " " .. CODE_POINT_LIMIT ..
                    ", but the specified code point is " .. code_point)

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