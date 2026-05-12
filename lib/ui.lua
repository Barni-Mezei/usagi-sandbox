---@diagnostic disable: inject-field, cast-local-type, undefined-field, param-type-mismatch
---@diagnostic disable: return-type-mismatch

---@class UI
---@field screen_box UI.Box A box covering the whole screen
---@field panels     table  A table containing the top level UI items
local M = {
    screen_box = {},
    panels = {},
}

---@class UI.Box
---@field type     string The type of this element: "box"
---@field x        number The X coordinate of the top-left corner of the box
---@field y        number The Y coordinate of the top-left corner of the box
---@field w        number The width of the box
---@field h        number The height of the box
---@field mx       number The outside margin of the box on the X axis
---@field my       number The outside margin of the box on the Y axis
---@field children table  A list containing child items

---@class UI.Label
--- Same as UI.Box, but has some additional parameters for text rendering
---@field type    string The type of this element: "label"
---@field text    string  The text of the label
---@field h_align integer The horizontal alignment of the text inside the box (-1: left, 0: center, 1: right )
---@field v_align integer The vertical alignment of the text inside the box   (-1: top,  0: center, 1: bottom)

---@class UI.List
--- Same as UI.Box, but has some additional parameters for aligning child items
---@field type    string The type of this element: "list"
---@field axis    string  The axis to align items along (can be "x" or "y")
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
    }

    if type(x) == "table" then
        new_box.x = x.x or 0
        new_box.y = x.y or 0
        new_box.w = x.w or 0
        new_box.h = x.h or 0
        new_box.mx = x.mx or 0
        new_box.my = x.my or 0
    else
        new_box.x = x or 0
        new_box.y = y or 0
        new_box.w = w or 0
        new_box.h = h or 0
        new_box.mx = mx or 0
        new_box.my = my or 0
    end

    return new_box
end

---Creates a new label from the provided string
---@param text     string|UI.Label The text to create a boundary around or a partially populated table
---@param v_align? integer The vertical alignment of the text inside the box   (-1: top,  0: center, 1: bottom)
---@param h_align? integer The horizontal alignment of the text inside the box (-1: left, 0: center, 1: right )
---@return UI.Label label  A new box with the size of the provided text
function M.create_label(text, v_align, h_align)
    local new_label = {}

    if type(text) == "table" then
        new_label = M.create_box(text.x, text.y, text.w, text.h, text.mx, text.my)
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
    return new_label
end

---Updates a label. Should be called after changing the label's text
---@param label UI.Label  The label to update
---@return UI.Label label The updated label
function M.update_label(label)
    local w, h = usagi.measure_text(label.text)

    label.w = w
    label.h = h

    return label
end

---Creates a new list box
---@param w        number|UI.List The width of the list container or
---a partially popupated table
---@param h?       number  The height of the list container
---@param axis?    string  The axis to align items along (can be "x" or "y")
---@param v_align? integer The vertical alignment of the items in the list   (-1: top,  0: center, 1: bottom)
---@param h_align? integer The horizontal alignment of the items in the list (-1: left, 0: center, 1: right )
---@return UI.List list    A new list container
function M.create_list(w, h, axis, h_align, v_align)
    local new_list = {}

    if type(w) == "table" then
        new_list = M.create_box(w.x, w.y, w.w, w.h, w.mx, w.my)
        new_list.axis = w.axis or "x"
        new_list.v_align = w.v_align or 0
        new_list.h_align = w.h_align or 0
    else
        new_list = M.create_box(0, 0, w, h)
        new_list.axis = axis or "x"
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
function M.render_item(item, debug_mode)
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

    if debug_mode then
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
function M.merge_item(original, new)
    local out = original

    for k, v in pairs(new) do
        if k ~= "children" and k ~= "type" then
            out[k] = v
        end
    end

    return out
end

---Fills in the default values for each item in the provided item and it's children
---@param item UI.Box|UI.Label|UI.List  The item to initialise
---@return UI.Box|UI.Label|UI.List item The initialised item
function M.initialise(item)
    if item.type == "box" then item = M.merge_item(item, M.create_box(item)) end
    if item.type == "label" then item = M.merge_item(item, M.create_label(item)) end
    if item.type == "list" then item = M.merge_item(item, M.create_list(item)) end

    -- Iterate over all children
    if item.children ~= nil then
        for i, n in ipairs(item.children) do
            item.children[i] = M.initialise(n)
        end
    end

    return item
end

function M.init()
    -- Create screen box
    M.screen_box = M.create_box(0, 0, usagi.GAME_W, usagi.GAME_H, 0, 0)

    M.panels = {}
end

function M.render(debug_mode) end
function M.update(mouse_x, mouse_y) end

---Appends a new panel into the UI
---@param item UI.Box|UI.Label|UI.List The insode of the panel
---@param h_align? integer The horizontal alignment of this panel rin the screen (-1: left, 0: center, 1: right )
---@param v_align? integer The vertical alignment of this panel rin the screen   (-1: top,  0: center, 1: bottom)
function M.set_panel(item, h_align, v_align)
    table.insert(M.panels, {
        type = "panel",
        h_align = h_align or -1,
        v_align = v_align or -1,
        item = M.initialise(item),
    })
end

return M
