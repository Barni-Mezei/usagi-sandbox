-- Returns with a random floating point number in the givven range (inclusive)
function rand_float(min, max)
	return min + math.random() * (max - min)
end

-- Returns with a random item from the provided table
function rand_item(table)
	return table[math.random(1, #table)]
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

function dump(value, depth)
	local d = depth or 1
	local t = tostring(value)

	if type(value) == "nil" then io.write("\27[90mnil\27[m") end
	if type(value) == "number" then io.write(f("\27[36m%d\27[m", t)) end
	if type(value) == "string" then io.write(f("\27[33m\"%s\"\27[m", t)) end
	if type(value) == "boolean" then io.write(f("%s\27[m", value and "\27[32mtrue" or "\27[31mfalse")) end
	if type(value) == "function" then io.write(f("\27[90m%s()\27[m", t)) end
	if type(value) == "table" then
		local indent = string.rep("    ", d)
		local indent_small = string.rep("    ", d - 1)

		-- Empty table
		if next(value) == nil then
			io.write("{}")
		else
			io.write("{\n")
			for k, v in pairs(value) do
				if type(k) == "number" then
					io.write(f("%s\27[36m#%s\27[m = ", indent, tostring(k)))
				else
					io.write(indent..tostring(k).." = ")
				end

				dump(v, d + 1)

				io.write(",\n")
			end
			io.write(indent_small.."}")
		end
	end

	if d == 1 then io.write("\n") end
end

function screen_to_cell(grid_box, cell_size, screen_x, screen_y)
	local x = math.ceil((screen_x - grid_box.x +1) / cell_size)
	local y = math.ceil((screen_y - grid_box.y +1) / cell_size)

	if x < 1 or x > Settings.grid_width then return -1, -1 end

	return x, y
end

function cell_to_screen(grid_box, cell_size, cell_x, cell_y)
	local x = grid_box.x + (cell_x - 1) * cell_size
	local y = grid_box.y + (cell_y - 1) * cell_size
	return x, y
end

-- Calls the callback on each cell in the brush stroke
function foreach_brush(grid_box, grid, cell_size, cell_x, cell_y, radius, callback)
	if radius == 1 then
		local sx, sy = cell_to_screen(grid_box, cell_size, cell_x, cell_y)
		callback(cell_x, cell_y, sx, sy)
		return
	end

	-- Render the mouse cursor and the selected cell
	local csx, csy = cell_to_screen(grid_box, cell_size, cell_x, cell_y)

	for y = -radius, radius do
		for x = -radius, radius do
			if cell_x + x < 1 or cell_x + x > grid.width then goto continue_brush_render end
			if cell_y + y < 1 or cell_y + y > grid.height then goto continue_brush_render end

			local sx, sy = cell_to_screen(grid_box, cell_size, cell_x + x, cell_y + y)

			local d = util.vec_dist_sq({x = csx, y = csy}, {x = sx, y = sy})
			local max_d = ((radius-0.5) * cell_size) ^ 2

			if d > max_d then goto continue_brush_render end

			callback(cell_x + x, cell_y + y, sx, sy)

			::continue_brush_render::
		end
	end
end