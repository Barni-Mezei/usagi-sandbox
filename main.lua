---@diagnostic disable: inject-field, cast-local-type
---@diagnostic disable: return-type-mismatch

local ui = require("lib.ui")
require("lib.misc")

function _config()
	return {
		name = "UI test",
		game_id = "com.barni-07.ui-test",
		icon = 1,

		-- game_width = 640,
		-- game_height = 360,
	}
end

-- Mouse position
local mx, my = 0, 0

function _init()
	ui.init()

	local tree = {
		type = "list",
		axis = "y",
		children = {
			{
				type = "label",
				text = "Line 1",
			},
			{
				type = "label",
				text = "Line 2",
			}
		}
	}

	-- Add left panel
	ui.set_panel(tree, -1, -1)

	dump(ui)
	os.exit()
end

function _update(dt)
	mx, my = input.mouse()

	ui.update(mx, my)
end

function _draw(dt)
	gfx.clear(gfx.COLOR_BLACK)

	ui.render(true)
end
