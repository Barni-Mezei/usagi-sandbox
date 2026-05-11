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

function screen_to_cell(grid_box, cell_size, screen_x, screen_y)
	local x = math.ceil((screen_x - grid_box.x) / cell_size)
	local y = math.ceil((screen_y - grid_box.y) / cell_size)

	if x < 1 or x > Settings.grid_width then return -1, -1 end

	return x, y
end

function cell_to_screen(grid_box, cell_size, cell_x, cell_y)
	local x = grid_box.x + (cell_x - 1) * cell_size
	local y = grid_box.y + (cell_y - 1) * cell_size
	return x, y
end