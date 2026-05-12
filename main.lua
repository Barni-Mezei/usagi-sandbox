---@diagnostic disable: inject-field, cast-local-type
---@diagnostic disable: return-type-mismatch

local ui = require("lib.ui")
local grid = require("lib.grid")
local v = require("lib.vector")

require("lib.misc")

--[[
TODO:

Updating cells:
- Generate new state into State.buffer
- then copyting buffer to the grid

cell updates -> material callback? (slow)

Materials:
- sand (falls, piles up)
- water (falls, flows)
- wall (static, acid can destroy it)
- acid (it's like water, but has a chance to destroy solids)
- wood (same as wall, but can be set on fire and is weaker towards acid)
- fire (spreads to nearby flammable cells, creates smoke)
- smoke (rises up)
- methane (like smoke, but is flammable)
- black hole (static, consumes everything)

Future:
- chunked updating (quad tree?)

]]

function _config()
	return {
		name = "Sandbox",
		game_id = "com.barni-07.sandbox",
		icon = 1,

		game_width = 640,
		game_height = 360,
	}
end

-- Mouse position
local mx, my = 0, 0
local cx, cy = 0, 0

Settings = {
	grid_width = 20,
	grid_height = 20,
	cell_size = 1,
}

Settings.cell_size = math.floor(
	math.min(
		usagi.GAME_W / Settings.grid_width,
		usagi.GAME_H / Settings.grid_height
	)
)

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

	return -1
end

-- UI stuff

local screen_box = {}
local grid_box = {}

local function _init_ui()
	screen_box = ui.create_box(0, 0, usagi.GAME_W, usagi.GAME_H)

	grid_box = ui.create_box(0, 0, State.grid.width * Settings.cell_size, State.grid.height * Settings.cell_size)
	grid_box = ui.align_item(grid_box, screen_box, 0, 0)
end

function _init()
	-- Keep objects between reloads
	Pool = require("lib.pool")
	Pool.init()
	Pool.max_size = -1

	input.set_mouse_visible(false)

	Random = require("lib.random")

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

	_init_ui()
end

local function _update_ui()
	-- Single button controls
	if input.key_pressed(input.KEY_SPACE) then State.is_paused = not State.is_paused end

	if input.pressed(input.LEFT)  then State.selected_material = util.clamp(State.selected_material - 1, 2, #Materials) end
	if input.pressed(input.RIGHT) then State.selected_material = util.clamp(State.selected_material + 1, 2, #Materials) end

	if input.pressed(input.UP)   then State.brush_size = util.clamp(State.brush_size + 1, 1, 5) end
	if input.pressed(input.DOWN) then State.brush_size = util.clamp(State.brush_size - 1, 1, 5) end


	-- Allow cell manipulation if the cursor is over the grid
	if cx ~= -1 or cy ~= -1 then
		-- Left click to place
		if input.mouse_held(input.MOUSE_LEFT) then
			foreach_brush(
				grid_box, State.grid, Settings.cell_size,
				cx, cy, State.brush_size,
				function (cell_x, cell_y, screen_x, screen_y)
					grid.set_cell(State.grid, cell_x, cell_y, State.selected_material)
				end
			)
		end
	
		-- Right click to erase
		if input.mouse_held(input.MOUSE_RIGHT) then
			foreach_brush(
				grid_box, State.grid, Settings.cell_size,
				cx, cy, State.brush_size,
				function (cell_x, cell_y, screen_x, screen_y)
					grid.set_cell(State.grid, cell_x, cell_y, get_material_index("Air"))
				end
			)
		end
	end

	return nil
end

function _update(dt)
	mx, my = input.mouse()
	cx, cy = screen_to_cell(grid_box, Settings.cell_size, mx, my)

	-- Update the UI if the cursor is on screen
	if util.point_in_rect({x = mx, y = my}, {x = 0, y = 0, w = usagi.GAME_W, h = usagi.GAME_H}) then
		_update_ui()
	end

	-- Update cells
	grid.foreach(State.grid, function (x, y, value)
		local cell = value

		if cell == get_material_index("Sand") then
			if grid.get_cell(State.grid, x, y + 1) == get_material_index("Air") then
				cell = get_material_index("Air")
			end
		end

		grid.set_cell(State.buffer, x, y, cell)
	end)

	-- Copy buffer
	State.grid = grid.copy_grid(State.buffer)
end

function _draw(dt)
	gfx.clear(gfx.COLOR_BLACK)

	-- Render grid
	grid.foreach(State.grid, function (x, y, value)
		local sx, sy = cell_to_screen(grid_box, Settings.cell_size, x, y)

		-- Use the Rng for coordinate hashing
		local r = Random.create_rng(y*Settings.grid_width*100 + x + value*4)

		gfx.rect_fill(
			sx, sy,
			Settings.cell_size, Settings.cell_size,
			r.rand_item(Materials[value].color)
		)
	end)

	-- Render UI
	local material_label = ui.create_label(f("[ %s ]", Materials[State.selected_material].title))
	material_label.mx = 4
	material_label = ui.align_item(material_label, screen_box, 1, -1)

	local brush_label = ui.create_label(f("Brush: %d", State.brush_size))
	brush_label.mx = 4
	brush_label = ui.align_item(brush_label, screen_box, 1, -1)
	brush_label.y += material_label.h

	ui.render_item(material_label)
	ui.render_item(brush_label)

	-- Pause text
	if State.is_paused then
		local pause_label = ui.create_label("PAUSED")
		pause_label.my += 8
		pause_label = ui.align_item(pause_label, screen_box, 0, -1)

		ui.render_item(pause_label)
	end

	-- Render brush preview and cursor
	if cx ~= -1 or cy ~= -1 then
		foreach_brush(
			grid_box, State.grid, Settings.cell_size,
			cx, cy, State.brush_size,
			function (cell_x, cell_y, screen_x, screen_y)
				gfx.rect(screen_x, screen_y, Settings.cell_size, Settings.cell_size, gfx.COLOR_LIGHT_GRAY)
			end
		)
	end

	gfx.spr(2, mx - 8, my - 8)
end
