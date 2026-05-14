---@diagnostic disable: inject-field, cast-local-type
---@diagnostic disable: return-type-mismatch

local grid = require("lib.grid")
local v = require("lib.vector")
local ui = require("lib.ui")

require("lib.misc")
require("lib.graphics")

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
	cell_size = 2,
}

Settings.cell_size = math.ceil(
	math.min(
		usagi.GAME_W / Settings.grid_width * 2,
		usagi.GAME_H / Settings.grid_height * 2
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
function _init()
	ui.init()

	-- Keep objects between reloads
	Pool = require("lib.pool")
	Pool.init()
	Pool.max_size = -1

	input.set_mouse_visible(false)

	-- Used for spatial hashing for the concrete and sand color variations
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

	-- Main grid (center)
	Grid_box = ui.create_box(0, 0, State.grid.width*Settings.cell_size, State.grid.height*Settings.cell_size)
	--Grid_box.fix_size = true
	--Grid_box.min_w = State.grid.width * Settings.cell_size
	--Grid_box.min_h = State.grid.height * Settings.cell_size
	ui.add_panel(Grid_box, 0, 0)

	-- Info labels (top right)
	---@diagnostic disable-next-line: missing-fields
	ui.add_panel({
		type = "list",
		axis = "y",
		h_align = -1,
		mx = 8,
		my = 8,
		children = {
			{
				type = "label",
				value_hook = "material",
				text = "",
				h_align = -1,
				w = 80,
			},
			{
				type = "label",
				value_hook = "brush",
				text = "",
				h_align = -1,
				w = 80,
			}
		}
	}, 1, -1)

	-- Pause label (top center)
	---@diagnostic disable-next-line: missing-fields
	ui.add_panel({
		type = "label",
		value_hook = "pause",
		text = "",
	}, 0, -1)
end

-- Simple render function replacement
function ui.render_item(item)
    if item.type == "label" then
        gfx.text(item.text, item.text_x, item.text_y, gfx.COLOR_WHITE)
    end
end


local function handle_controls()
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
				Grid_box, State.grid, Settings.cell_size,
				cx, cy, State.brush_size,
				function (cell_x, cell_y, screen_x, screen_y)
					grid.set_cell(State.grid, cell_x, cell_y, State.selected_material)
				end
			)
		end

		-- Right click to erase
		if input.mouse_held(input.MOUSE_RIGHT) then
			foreach_brush(
				Grid_box, State.grid, Settings.cell_size,
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
	cx, cy = screen_to_cell(Grid_box, Settings.cell_size, mx, my)

	-- Update the UI if the cursor is on screen
	if util.point_in_rect({x = mx, y = my}, {x = 0, y = 0, w = usagi.GAME_W, h = usagi.GAME_H}) then
		handle_controls()
	end

	-- Set hooks
	ui.set_hook("material", f("[ %s ]", Materials[State.selected_material].title))
	ui.set_hook("brush", f("Brush: %d", State.brush_size))
	ui.set_hook("pause", State.is_paused and "PAUSED" or "")

	ui.update(mx, my)

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

	-- Render UI
	ui.render()

	-- Render grid
	grid.foreach(State.grid, function (x, y, value)
		local sx, sy = cell_to_screen(Grid_box, Settings.cell_size, x, y)

		-- Use the Rng for coordinate hashing
		local r = Random.create_rng(y*Settings.grid_width*100 + x + value*4)

		gfx.rect_fill(
			sx, sy,
			Settings.cell_size, Settings.cell_size,
			r.rand_item(Materials[value].color)
		)
	end)

	-- Render brush preview and cursor
	if cx ~= -1 or cy ~= -1 then
		foreach_brush(
			Grid_box, State.grid, Settings.cell_size,
			cx, cy, State.brush_size,
			function (cell_x, cell_y, screen_x, screen_y)
				gfx.rect(screen_x, screen_y, Settings.cell_size, Settings.cell_size, gfx.COLOR_LIGHT_GRAY)
			end
		)
	end

	gfx.spr(2, mx - 8, my - 8)
end
