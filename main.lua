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

Settings = {
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

	--input.set_mouse_visible(false)

	State = {
		-- UI
		selected_material = 2,
		is_paused = false,
		brush_size = 3,

		grid = {},
		buffer = {},
	}

	-- Pre generate the grid and the back buffer
	State.grid   = grid.create_grid(usagi.GAME_W/10, usagi.GAME_H/10, get_material_index("Air"))
	State.buffer = grid.copy_grid(State.grid)
end

local function _update_ui()
	-- Single button controls
	if input.key_pressed(input.KEY_SPACE) then State.is_paused = not State.is_paused end

	if input.pressed(input.LEFT)  then State.selected_material = util.clamp(State.selected_material - 1, 2, #Materials) end
	if input.pressed(input.RIGHT) then State.selected_material = util.clamp(State.selected_material + 1, 2, #Materials) end
	
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
	gfx.clear(gfx.COLOR_DARK_BLUE)

	-- Render objects
	pool.foreach(function (obj, i)
		if obj.render == nil then return end
		if obj.type == "ball" then return end
		obj:render()
	end)

	-- Render balls on top
	pool.foreach_type("ball", function (obj, i)
		if obj.render == nil then return end
		obj:render(hovered_ball_index == i, selected_balls[i])
	end)

	-- Render selection
	local area = get_menu_data("select")
	if area.active then
		gfx.rect(
			area.x,
			area.y,
			area.w,
			area.h,
			gfx.COLOR_BLUE
		)
	end

	-- Render move offset
	local move = get_menu_data("move")
	if move.mode == "snap" then
		for obj_index, _ in pairs(selected_balls) do
			gfx.circ_fill(
				pool.objects[obj_index].x + move.dx,
				pool.objects[obj_index].y + move.dy,
				2,
				gfx.COLOR_LIGHT_GRAY
			)
		end
	end


	-- Render info a bout the selected ball
	if State.stat_selected ~= -1 then
		local ball = pool.objects[State.stat_selected]

		ui.draw_label(f("Ball info:"),                                    gfx.COLOR_WHITE, -1, 1, -5)
		ui.draw_label(f("Index: %d", State.stat_selected),                gfx.COLOR_WHITE, -1, 1, -4)
		ui.draw_label(f("Pinned: %s", ball.pinned and "true" or "false"), gfx.COLOR_WHITE, -1, 1, -3)

		-- Draw velocity
		local scale = 4
		gfx.line(ball.x, ball.y, ball.x + ball.vx*scale, ball.y, gfx.COLOR_RED)
		gfx.line(ball.x, ball.y, ball.x, ball.y + ball.vy*scale, gfx.COLOR_GREEN)
		gfx.line(ball.x, ball.y, ball.x + ball.vx*scale, ball.y + ball.vy*scale, gfx.COLOR_LIGHT_GRAY)
	end




	-- Render UI
	ui.draw_label(f(
		"%db + %dc = %d",
		State.ball_count,
		State.constraint_count,
		State.ball_count+State.constraint_count
	), gfx.COLOR_WHITE, 0, -1)
	ui.draw_label(f("[ %s ]", menu_items[State.selected_menu].title), gfx.COLOR_WHITE, 0, -1, 1)
	if State.is_paused then
		ui.draw_label("PAUSED", gfx.COLOR_LIGHT_GRAY, 0, -1, 2)
	end

	-- Render toolbar
	local offset = #menu_items / 2

	for i, item in pairs(menu_items) do
		local box = ui.get_box_repeat({w = usagi.SPRITE_SIZE + 4, h = usagi.SPRITE_SIZE + 4}, 0, 1, -offset + i - 1)

		if State.selected_menu == i then
			gfx.spr(4, box.x, box.y)
		else
			gfx.spr(3, box.x, box.y)
		end

		gfx.spr(item.sprite, box.x, box.y)
	end

	-- Render debug stats
	if usagi.IS_DEV then
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
	end

	-- Render the mouse cursor
	local mx, my = input.mouse()
	gfx.spr(2, mx - 8, my - 8)
end
