---@class Random
local M = {}

---Creates a new random number generator with the given seed
---@param seed? number The seed for the new random number generator
---@return Random.Rng rng A new seeded random number generator
function M.create_rng(seed)
    local a, c = 1664525, 1013904223
    local m32, m_int = 2^32, 2^53
    local mix_mul = 0xff51afd7ed558ccd

    -- Ensure seed -> 64-bit state (use two 32-bit halves)
    seed = seed or os.time()
    local state_lo = (seed * 1103515245 + 12345) % m32
    local state_hi = (seed * 214013 + 2531011) % m32

    ---Modifies the state (upper and lower 32 bits)
    local function lcg_step()
        state_lo = (a * state_lo + c) % m32
        state_hi = (214013 * state_hi + 2531011) % m32
    end

    ---Performs a **xorshift** (`x ^= x >> 12; x ^= x << 25; x ^= x >> 27`)
    local function xor64_mul(hi, lo)
        local function bxor(x, y) return x ~ y end

        local x1 = bxor(hi, (hi >> 12))
        x1 = bxor(x1, (x1 << 25) & 0xFFFFFFFF)
        x1 = bxor(x1, (x1 >> 27))
        local r_hi = ((x1 * (mix_mul & 0xFFFFFFFF)) >> 32) & 0xFFFFFFFF

        local x2 = bxor(lo, (lo >> 12))
        x2 = bxor(x2, (x2 << 25) & 0xFFFFFFFF)
        x2 = bxor(x2, (x2 >> 27))
        local r_lo = (x2 * (mix_mul & 0xFFFFFFFF)) & 0xFFFFFFFF

        
        -- final multiply (64-bit multiply approximated by mixing halves)
        return r_hi, r_lo
    end

    ---Generates a new pseudo random value and modifies the rng state
    ---@return number state The new state of the random number generator
    local function next_raw()
        -- Update the state
        lcg_step()

        local out_hi, out_lo = xor64_mul(state_hi, state_lo)

        -- Compose a 53-bit value from hi and lo (take top 21 bits of hi and top 32 of lo)
        local top_hi = out_hi & 0x1FFFFF -- 21 bits
        local value53 = top_hi * 2 ^ 32 + out_lo

        return value53
    end


    ---@class Random.Rng
	local rng = {}

    ---Modifies the seed for the random number generator
    ---@param s number The new seed
	function rng.set_seed(s)
        if s == nil then return end
        state_lo = (s * 1103515245 + 12345) % m32
        state_hi = (s * 214013 + 2531011) % m32
	end

    ---Returns with the next raw 32-bit value
    ---@return integer number A pseudo random 32-bit integer
	function rng.next()
		return next_raw()
	end

    ---Returns with the next float value in the rage [0; 1] (inclusive)
    ---@return integer number A pseudo random number
	function rng.rand()
		return next_raw() / m_int
	end

    ---Returns with a random number from the range [`min`, `max`] (inclusive)
    ---@param min number The lower boundary of the interval
    ---@param max number The upper boundary of the interval
    ---@return number number A pseudo random number from the given range
    function rng.rand_float(min, max)
		local mn = min or 0
		local mx = max or 1

        local r = rng.rand() * (mx - mn + 1) + mn

		return math.min(r, mx)
	end

    ---Returns with a random integer from the range [`min`, `max`] (inclusive)
    ---@param min integer The lower boundary of the interval
    ---@param max integer The upper boundary of the interval
    ---@return integer number A pseudo random integer from the given range
    function rng.rand_int(min, max)
		local mn = min or 0
		local mx = max or 1

        local r = math.floor(rng.rand() * (mx - mn + 1)) + mn

        return math.min(r, mx)
	end

    ---Returns with an element from `table`
    ---@param table table A simple indexed lua table
    ---@return any item An element from the table
    function rng.rand_item(table)
		local i = math.floor(rng.rand() * (#table + 1)) + 1
        return table[math.min(i, #table)]
	end

	return rng
end

return M