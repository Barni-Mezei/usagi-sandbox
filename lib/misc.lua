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

---Prints the provided value to the console, using formatting
---@param value any The value to print to the console
---@param advanced? boolean if this flag is set, then functions, threads and user data wil be shown as well.
---@param max_depth? integer The maximum allowed depth
---@param depth? integer The current depth in the printing process
function dump(value, advanced, max_depth, depth)
	local a = advanced or false
	local d = depth or 1
	local md = max_depth or 10
	local t = tostring(value)

	if type(value) == "nil" then io.write("\27[90mnil\27[m") end
	if type(value) == "number" then io.write(f("\27[36m%d\27[m", t)) end
	if type(value) == "string" then io.write(f("\27[33m\"%s\"\27[m", t)) end
	if type(value) == "boolean" then io.write(f("%s\27[m", value and "\27[32mtrue" or "\27[31mfalse")) end
	if type(value) == "function" then io.write(f("\27[90m%s()\27[m", t)) end
	if type(value) == "userdata" then io.write(f("\27[90m%s()\27[m", t)) end
	if type(value) == "thread" then io.write(f("\27[90m%s()\27[m", t)) end
	if type(value) == "table" then
		-- Do not go deeper than the max allowed depth
		if d > md then
			io.write("{ \27[35m...\27[m }")
			return
		end

		local indent = string.rep("    ", d)
		local indent_small = string.rep("    ", d - 1)

		-- Empty table
		if next(value) == nil then
			io.write("{}")
		else
			io.write("{\n")
			for k, v in pairs(value) do
				-- Skip advanced data types if the advanced flag is set to false
				if (type(v) == "function" or type(v) == "userdata" or type(v) == "thread") and not a then
					goto continue_dump_loop
				end

				if type(k) == "number" then
					io.write(f("%s\27[36m#%s\27[m = ", indent, tostring(k)))
				else
					io.write(indent..tostring(k).." = ")
				end

				dump(v, a, md, d + 1)

				io.write(",\n")

				::continue_dump_loop::
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
