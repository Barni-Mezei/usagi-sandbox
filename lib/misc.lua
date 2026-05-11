-- Returns with a random floating point number in the givven range (inclusive)
function rand_float(min, max)
	return min + math.random() * (max - min)
end

-- Returns the seconds, minutes and hours
function get_time(seconds)
	local s = seconds % 60
	local m = math.floor(seconds//60) % 60
	local h = math.floor(seconds//3600) % 24

	return s, m, h
end

-- Alias for string formatting
f = string.format
