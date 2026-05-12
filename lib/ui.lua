---@diagnostic disable: inject-field, cast-local-type, undefined-field, param-type-mismatch
---@diagnostic disable: return-type-mismatch

---@class UI
---@field screen_box  UI.Box A box covering the whole screen
---@field panels      table  A table containing the top level UI items
---@field value_hooks table  A table that contains all value hooks and their current value
local M = {
    screen_box = {},
    panels = {},
    value_hooks = {},
}

---@class UI.Box
--- This is the basis of ALL other ui items! **Every item has these properties**
---@field type     string  The type of this element: "box"
---@field x        number  The X coordinate of the top-left corner of the box
---@field y        number  The Y coordinate of the top-left corner of the box
---@field w        number  The width of the box
---@field h        number  The height of the box
---@field min_w    number  The minimum allowed width of the box
---@field min_h    number  The minimum allowed height of the box
---@field max_w    number  The maximum allowed width of the box
---@field max_h    number  The maximum allowed height of the box
---@field mx       number  The outside margin of the box on the X axis
---@field my       number  The outside margin of the box on the Y axis
---@field fix_size boolean Toggles whenever to update the size of this item, relative to it's children
---@field children table   A list containing child items

---@class UI.Label
--- Same as UI.Box, but has some additional parameters for text rendering
---@field type       string The type of this element: "label"
---@field text       string  The text of the label
---@field value_hook string  A reference to an entry in the `value_hooks` table
---@field h_align    integer The horizontal alignment of the text inside the box (-1: left, 0: center, 1: right )
---@field v_align    integer The vertical alignment of the text inside the box   (-1: top,  0: center, 1: bottom)

---@class UI.List
--- Same as UI.Box, but has some additional parameters for aligning child items
---@field type    string  The type of this element: "list"
---@field axis    string  The axis to align items along (can be "x" or "y")
---@field gap     number  The gap between the items in this list
---@field h_align integer The horizontal alignment of the items inside the box (-1: left, 0: center, 1: right )
---@field v_align integer The vertical alignment of the items inside the box   (-1: top,  0: center, 1: bottom)



---Creates a box with the given parameters
---You can either supply a single partially completed table to this function,
---or fill in all of the the arguments (every one of the is optional except
---for the last one)
---@param x   number|UI.Box The X coordinate of the top-left corner of the box or
---a partially populated table
---@param y?  number       The Y coordinate of the top-left corner of the box
---@param w?  number       The width of the box
---@param h?  number       The height of the box
---@param mx? number       The outside margin of the box on the X axis
---@param my? number       The outside margin of the box on the Y axis
---@return UI.Box box      A new box with all of the necessary fields populated
function M.create_box(x, y, w, h, mx, my)
    local new_box = {
        type = "box",
        children = {},
        fix_size = false,
    }

    function new_box.add_child(item)
        table.insert(new_box.children, item)
    end

    if type(x) == "table" then
        new_box.x = x.x or 0
        new_box.y = x.y or 0
        new_box.w = x.w or 0
        new_box.h = x.h or 0
        new_box.min_w = x.min_w or 0
        new_box.min_h = x.min_h or 0
        new_box.max_w = x.max_w or 1000
        new_box.max_h = x.max_h or 1000
        new_box.mx = x.mx or 0
        new_box.my = x.my or 0
    else
        new_box.x = x or 0
        new_box.y = y or 0
        new_box.w = w or 0
        new_box.h = h or 0
        new_box.min_w = 0
        new_box.min_h = 0
        new_box.max_w = 1000
        new_box.max_h = 1000
        new_box.mx = mx or 0
        new_box.my = my or 0
    end

    return new_box
end

---Creates a new label from the provided string
---@param text     string|UI.Label The text to create a boundary around or a partially populated table
---@param v_align? integer The vertical alignment of the text inside the box   (-1: top,  0: center, 1: bottom)
---@param h_align? integer The horizontal alignment of the text inside the box (-1: left, 0: center, 1: right )
---@param value_hook? string The hook on which you can modify this label's text
---@return UI.Label label  A new box with the size of the provided text
function M.create_label(text, v_align, h_align, value_hook)
    local new_label = {}

    if type(text) == "table" then
        new_label = M.create_box(text)
        new_label.text = text.text or ""
        new_label.v_align = text.v_align or 0
        new_label.h_align = text.h_align or 0
    else
        local w, h = usagi.measure_text(text)
        new_label = M.create_box(0, 0, w, h)
        new_label.text = text or ""
        new_label.v_align = v_align or 0
        new_label.h_align = h_align or 0
    end

    new_label.type = "label"
    new_label.value_hook = value_hook or nil

    -- Create hook endpoint for this label
    if value_hook ~= nil then
        M.value_hooks[value_hook] = new_label.text
    end

    return new_label
end

---Updates a label. Should be called after changing the label's text
---@param item UI.Label  The label to update
---@return UI.Label label The updated label
function M.update_label(item)
    if item.type ~= "label" then return item end

    -- Update text from the hook
    if item.value_hook ~= nil then
        item.text = tostring( M.value_hooks[item.value_hook] )
    end

    -- Update size
    if item.fix_size then
        local w, h = usagi.measure_text(item.text)

        item.w = w
        item.h = h
        item.min_w = w
        item.min_h = h
    end

    return item
end

---Updates the value of a hook
---@param value_hook string The ID of a value hook
---@param new_value  string The value to write into the hook
function M.set_hook(value_hook, new_value)
    M.value_hooks[value_hook] = new_value
end

---Returns with a value in a value hook
---@param value_hook string The ID of a value hook
---@return string|nil value The value stored at the specified value hook
function M.get_hook(value_hook)
    return M.value_hooks[value_hook]
end

---Creates a new list box
---@param axis     string|UI.List The axis to align items along (can be "x" or "y") or
---a partially popupated table
---@param gap?     number  The gap between the items in this list
---@param v_align? integer The vertical alignment of the items in the list   (-1: top,  0: center, 1: bottom)
---@param h_align? integer The horizontal alignment of the items in the list (-1: left, 0: center, 1: right )
---@return UI.List list    A new list container
function M.create_list(axis, gap, h_align, v_align)
    local new_list = {}

    if type(axis) == "table" then
        new_list = M.create_box(axis)
        new_list.axis = axis.axis or "x"
        new_list.gap = axis.gap or 0
        new_list.v_align = axis.v_align or 0
        new_list.h_align = axis.h_align or 0
    else
        new_list = M.create_box({})
        new_list.axis = axis or "x"
        new_list.gap = gap or 0
        new_list.v_align = v_align or 0
        new_list.h_align = h_align or 0
    end

    new_list.type = "list"
    return new_list
end

---Aligns a box inside a container box along 2 axis
---@param box    UI.Box|UI.Label The box to align inside the parent 
---@param parent UI.Box|UI.Label The container for the box 
---@param h_align? integer The horizontal alignment of the box (-1: left, 0: center, 1: right )
---@param v_align? integer The vertical alignment of the box   (-1: top,  0: center, 1: bottom)
---@return UI.Box|UI.Label box The box, aligned inside the parent 
function M.align_item(box, parent, h_align, v_align)
    local mx = box.mx or 0
    local my = box.my or 0

    local x = 0
    local y = 0
    local w = box.w + mx*2
    local h = box.h + my*2

    if v_align == 0 then x = parent.w/2 - w/2 end
    if v_align == 1 then x = parent.w - w end

    if h_align == 0 then y = parent.h/2 - h/2 end
    if h_align == 1 then y = parent.h - h end

    x += mx
    y += my

    local out = {
        x = parent.x + x,
        y = parent.y + y,
        w = box.w,
        h = box.h,
        mx = mx,
        my = my,
    }

    if box.text ~= nil then
        out.text = box.text
        out.v_align = box.v_align
        out.h_align = box.h_align
    end

    return out
end

---Renders a ui item on the screen
---@param item        table   The UI item to render (can be a box or a label) 
---@param debug_mode? boolean Render box outlines?
local function _render_item(item, debug_mode)

    -- Render label text
    if item.text ~= nil then
        local tw, th = usagi.measure_text(item.text)
        local tc = M.create_box({w = tw, h = th})
        tc = M.align_item(tc, item, 0, 0)

        if debug_mode then
            gfx.rect(tc.x, tc.y, tc.w, tc.h, gfx.COLOR_BLUE)
        end

        gfx.text(item.text, tc.x, tc.y, gfx.COLOR_WHITE)
    end

    if item ~= nil and debug_mode then
        -- Render margin
        gfx.rect(item.x - item.mx, item.y - item.my, item.w + item.mx*2, item.h + item.my*2, gfx.COLOR_LIGHT_GRAY)

        -- Render item boundary
        gfx.rect(item.x, item.y, item.w, item.h, gfx.COLOR_RED)
    end
end

---Merges the data from `new` into `original`, but  keeps the children and the type
---@param original UI.Box|UI.Label|UI.List The original item to merge into
---@param new      UI.Box|UI.Label|UI.List The item to merge the data from
---@return UI.Box|UI.Label|UI.List item    The merged item 
local function _merge_item(original, new)
    for k, v in pairs(new) do
        if original[k] == nil then
            original[k] = v
        end

        if k ~= "children" and k ~= "type" then
            original[k] = v
        end
    end

    return original
end

---Fills in the default values in the provided item
---@param item UI.Box|UI.Label|UI.List  The item to initialise
---@return UI.Box|UI.Label|UI.List item The initialised item
function M.initialise(item)
    if item.type == "panel" then
        local p = M.create_box(item)
        p.type = "panel"
        item = _merge_item(item, p)
    end
    if item.type == "box" then
        local b = M.create_box(item)
        item = _merge_item(item, b)
    end
    if item.type == "label" then
        item = _merge_item(item, M.create_label(item))
        item = M.update_label(item)
    end
    if item.type == "list" then item = _merge_item(item, M.create_list(item)) end

    -- Iterate over all children
    if item.children ~= nil then
        for i, child in ipairs(item.children) do
            item.children[i] = M.initialise(child)
        end
    end

    return item
end

---Appends a new panel into the UI
---@param item UI.Box|UI.Label|UI.List A tree of UI items, which can be partially filled
---@param h_align? integer The horizontal alignment of this panel rin the screen (-1: left, 0: center, 1: right )
---@param v_align? integer The vertical alignment of this panel rin the screen   (-1: top,  0: center, 1: bottom)
function M.set_panel(item, h_align, v_align)
    local new_panel = {
        type = "panel",
        h_align = h_align or -1,
        v_align = v_align or -1,
        children = {item},
    }

    table.insert(M.panels, M.initialise(new_panel))
end

--
--  Main methods
--

function M.init()
    -- Create screen box
    M.screen_box = M.create_box(0, 0, usagi.GAME_W, usagi.GAME_H)
    M.screen_box.mx = 0
    M.screen_box.my = 0
    M.screen_box.min_w = usagi.SPRITE_SIZE
    M.screen_box.min_h = usagi.SPRITE_SIZE
    M.screen_box.max_w = usagi.GAME_W
    M.screen_box.max_h = usagi.GAME_H

    -- Panel continer
    M.panels = {}
end

local function _render_loop(item, debug_mode)
    local d = debug_mode or false

    -- Iterate over all children
    if item.children ~= nil then
        for _, child in ipairs(item.children) do
            _render_loop(child, d)
        end
    end

    _render_item(item, d)
end

function M.render(debug_mode)
    for _, panel in pairs(M.panels) do
        _render_loop(panel, debug_mode)
    end

    _render_item(M.screen_box, debug_mode)
end

local function _size_update_loop(item)
    -- Iterate over all children and update them
    for i, child in ipairs(item.children) do
        item.children[i] = _size_update_loop(child)
    end

    if item.type == "box" then
        item.w = math.max(item.min_w, item.w)
        item.h = math.max(item.min_h, item.h)

        for _, child in pairs(item.children) do
            item.w = math.min(item.w, child.w + child.mx * 2)
            item.h = math.min(item.h, child.h + child.my * 2)
        end
    end

    if item.type == "label" then
        item = M.update_label(item)
    end

    if item.type == "list" then
        item.w, item.h = 0, 0

        if item.axis == "x" then
            for _, child in pairs(item.children) do
                item.w += child.w + child.mx*2 + item.gap
                item.h = math.max(item.h, child.h)
            end

            item.w -= item.gap
        end

        if item.axis == "y" then
            for _, child in pairs(item.children) do
                item.w = math.max(item.w, child.w)
                item.h += child.h + child.my*2 + item.gap
            end

            item.h -= item.gap
        end
    end

    -- Constrain item sizes
    item.w = math.min(math.max(item.w, item.min_w), item.max_w)
    item.h = math.min(math.max(item.h, item.min_h), item.max_h)

    return item
end

local function _position_update_loop(item, parent_x, parent_y)
    local px = parent_x or 0
    local py = parent_y or 0

    -- Apply margin offset
    item.x = px + item.mx
    item.y = py + item.my

    -- Iterate over all children and update them
    local dpx = px + item.mx
    local dpy = py + item.my

    for i, child in ipairs(item.children) do
        item.children[i] = _position_update_loop(child, dpx, dpy)

        if item.type == "list" then
            if item.axis == "x" then
                dpx += child.w + child.mx*2 + item.gap
            end

            if item.axis == "y" then
                dpy += child.h + child.my*2 + item.gap
            end
        end
    end

    if item.type == "box" then end
    if item.type == "label" then end


    return item
end

function M.update(mouse_x, mouse_y)
    -- Calculate element sizes
    for _, panel in pairs(M.panels) do
        _size_update_loop(panel)
    end

    -- Calculate item positions
    for _, panel in pairs(M.panels) do
        _position_update_loop(panel, M.screen_box.x, M.screen_box.y)
    end
end



return M
