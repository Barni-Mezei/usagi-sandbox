---@diagnostic disable: cast-local-type

local ui = require("lib.ui")
local grid = require("lib.grid")
local v = require("lib.vector")

require("lib.misc")

--[[
TODO:

- chunked updating (quad tree?)

Materials:
- sand
- water
- wall
- acid
- wood
- fire
- black hole

]]

function _config()
	return {
		name = "Sandbox",
		game_id = "com.barni-07.sandbox",
		icon = 1,

		-- game_width = 640,
		-- game_height = 360,
	}
end

-- Mouse position
local mx, my = 0, 0
local cx, cy = 0, 0

Settings = {
	grid_width = 20,
	grid_height = 20,
}

Materials = {
	{
		title = "Air",
		color = {gfx.COLOR_DARK_BLUE},
	},
	{
		title = "Sand",
		color = {gfx.COLOR_YELLOW, gfx.COLOR_ORANGE},
	},
	{
		title = "Water",
		color = {gfx.COLOR_BLUE},
	},
	{
		title = "Concrete",
		color = {gfx.COLOR_DARK_GRAY, gfx.COLOR_LIGHT_GRAY},
	},
	{
		title = "Wood",
		color = {gfx.COLOR_BROWN},
	},
	{
		title = "Acid",
		color = {gfx.COLOR_GREEN},
	},
}

local function get_material_index(name)
	for i, m in ipairs(Materials) do
		if m.title == name then return i end
	end

	-- Default to sand
	return -1
end

function _init()
	-- Keep objects between reloads
	Pool = require("lib.pool")
	Pool.init()
	Pool.max_size = -1

	input.set_mouse_visible(false)

	State = {
		-- UI
		selected_material = 2,
		is_paused = false,
		brush_size = 3,

		grid = {},
		buffer = {},
	}

	-- Pre generate the grid and the back buffer
	State.grid   = grid.create_grid(Settings.grid_width, Settings.grid_height, get_material_index("Air"))
	State.buffer = grid.copy_grid(State.grid)
end

local function _update_ui()
	-- Single button controls
	if input.key_pressed(input.KEY_SPACE) then State.is_paused = not State.is_paused end

	if input.pressed(input.LEFT)  then State.selected_material = util.clamp(State.selected_material - 1, 2, #Materials) end
	if input.pressed(input.RIGHT) then State.selected_material = util.clamp(State.selected_material + 1, 2, #Materials) end

	-- Allow cell manipulation if the cursor is over the grid
	if cx ~= -1 or cy ~= -1 then
		-- Left click to place
		if input.mouse_held(input.MOUSE_LEFT) then
			grid.set_cell(State.grid, cx, cy, State.selected_material)
		end
	
		-- Right click to erase
		if input.mouse_held(input.MOUSE_RIGHT) then
			grid.set_cell(State.grid, cx, cy, get_material_index("Air"))
		end
	end

	return nil
end

function _update(dt)
	mx, my = input.mouse()

	-- Update the UI if the cursor is on screen
	if util.point_in_rect({x = mx, y = my}, {x = 0, y = 0, w = usagi.GAME_W, h = usagi.GAME_H}) then
		_update_ui()
	end
end

function _draw(dt)
	gfx.clear(gfx.COLOR_BLACK)

	local screen_box = ui.create_box(0, 0, usagi.GAME_W, usagi.GAME_H)

	local cell_size = math.floor(
		math.min(
			usagi.GAME_W / State.grid.width,
			usagi.GAME_H / State.grid.height
		)
	)

	local grid_box = ui.create_box(0, 0, State.grid.width * cell_size, State.grid.height * cell_size)
	grid_box = ui.align_box(grid_box, screen_box, 0, 0)

	-- Render grid
	grid.foreach(State.grid, function (x, y, value)
		local sx, sy = cell_to_screen(grid_box, cell_size, x, y)
		gfx.rect_fill(
			sx, sy,
			cell_size, cell_size,
			Materials[value].color[1]
		)
	end)


	-- Render UI
	--ui.draw_label(f("[ %s ]", menu_items[State.selected_menu].title), gfx.COLOR_WHITE, 0, -1, 1)

	if State.is_paused then
		local pause_label = ui.create_label("PAUSED", 0, 0)
		pause_label = ui.align_box(pause_label, screen_box, 0, -1)

		ui.render_item(pause_label, true)
	end

	-- Render debug stats
	--[[if usagi.IS_DEV then
		ui.draw_label(f("Pool size: %d", #pool.objects), gfx.COLOR_LIGHT_GRAY, 1, -1)
		ui.draw_label(f("clr: %s", (selection_reset and "true" or "false")), gfx.COLOR_LIGHT_GRAY, 1, -1, 1)
		ui.draw_label(f("B: %d", hovered_ball_index), gfx.COLOR_LIGHT_GRAY, 1, -1, 2)
		ui.draw_label(f("C: %d", hovered_constraint_index), gfx.COLOR_LIGHT_GRAY, 1, -1, 3)

		local s = ""
		for obj_index, _ in pairs(selected_balls) do
			s = s..tostring(obj_index)..", "
		end

		local s, m, h = get_time(util.round(usagi.elapsed))

		ui.draw_label(f("Time: %02d:%02d:%02d", h, m, s), gfx.COLOR_LIGHT_GRAY, 1, 1, -1)
		ui.draw_label(f("Delta: %.5f", dt), gfx.COLOR_LIGHT_GRAY, 1, 1, 0)
	end]]

	-- Render the mouse cursor
	cx, cy = screen_to_cell(grid_box, cell_size, mx, my)
	local sx, sy = cell_to_screen(grid_box, cell_size, cx, cy)
	gfx.rect(sx, sy, cell_size, cell_size, gfx.COLOR_LIGHT_GRAY)
	gfx.spr(2, mx - 8, my - 8)
end
