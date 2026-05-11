---@diagnostic disable: inject-field
---@diagnostic disable: return-type-mismatch

---@class UI
local M = {}

---@class UI.Box
---@field x  number The X coordinate of the top-left corner of the box
---@field y  number The Y coordinate of the top-left corner of the box
---@field w  number The width of the box
---@field h  number The height of the box
---@field mx number The outside margin of the box on the X axis
---@field my number The outside margin of the box on the Y axis

---@class UI.Label
--- Same as UI.Box, but has some additional parameters for text rendering
---@field text    string  The text of the label
---@field v_align integer The vertical alignment of the text inside the box   (-1: top,  0: center, 1: bottom)
---@field h_align integer The horizontal alignment of the text inside the box (-1: left, 0: center, 1: right )



---Creates a box with the given parameters
---You can either supply a single partially completed table to this function,
---or fill in all of the the arguments (every one of the is optional except
---for the last one)
---@param x   number|table The X coordinate of the top-left corner of the box or
---a partially popupated table
---@param y?  number       The Y coordinate of the top-left corner of the box
---@param w?  number       The width of the box
---@param h?  number       The height of the box
---@param mx? number       The outside margin of the box on the X axis
---@param my? number       The outside margin of the box on the Y axis
---@return UI.Box box      A new box with all of the necessary fields populated
function M.create_box(x, y, w, h, mx, my)
    -- Empty box
    if x == nil then
        return {
            x = 0,
            y = 0,
            w = 0,
            h = 0,
            mx = 0,
            my = 0,
        }
    end

    -- Box from the first parameter
    if type(x) == "table" then
        return {
            x = x.x or 0,
            y = x.y or 0,
            w = x.w or 0,
            h = x.h or 0,
            mx = x.mx or 0,
            my = x.my or 0,
        }
    end
    
    -- Box from all of the parameters
    return {
        x = x or 0,
        y = y or 0,
        w = w or 0,
        h = h or 0,
        mx = mx or 0,
        my = my or 0,
    }
end

---Creates a new label from the provided string
---@param text     string  The text to create a boundary around
---@param v_align? integer The vertical alignment of the text inside the box   (-1: top,  0: center, 1: bottom)
---@param h_align? integer The horizontal alignment of the text inside the box (-1: left, 0: center, 1: right )
---@return UI.Label label  A new box with the size of the provided text
function M.create_label(text, v_align, h_align)
    local w, h = usagi.measure_text(text)

    local new_label = M.create_box(0, 0, w, h)
    new_label.text = text
    new_label.v_align = 0
    new_label.h_align = 0

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

---Aligns a box inside a container box along 2 axis
---@param box     table   The box to align inside the parent 
---@param parent  table   The container for the box 
---@param v_align integer The vertical alignment of the box   (-1: top,  0: center, 1: bottom)
---@param h_align integer The horizontal alignment of the box (-1: left, 0: center, 1: right )
---@return UI.Box box     The box, aligned inside the parent 
function M.align_box(box, parent, v_align, h_align)
    local mx = box.mx or 0
    local my = box.mx or 0

    local x = 0
    local y = 0
    local w = parent.w + mx*2
    local h = parent.h + my*2

    if v_align == 0 then x = parent.w/2 - w/2 end
    if v_align == 1 then x = parent.w - w end

    if h_align == 0 then y = parent.h/2 - h/2 end
    if h_align == 1 then y = parent.h - h end

    x += mx
    y += my

    return {
        x = x,
        y = y,
        w = box.w,
        h = box.h,
        mx = mx,
        my = my,
    }
end

---Renders a ui item on the screen
---@param item        table   The UI item to render (can be a box or a label) 
---@param debug_mode? boolean Render box outlines?
function M.render_item(item, debug_mode)
    -- Render label text
    if item.text ~= nil then
        local tw, th = usagi.measure_text(item.text)
        local text_container = M.create_box({w = tw, h = th})

        local text_container = M.align_box(text_container, item, item.v_align, item.h_align)
        gfx.text(item.text, text_container.x, text_container.y, gfx.COLOR_WHITE)
    end

    if debug_mode then
        -- Render margin
        gfx.rect(item.x - item.mx, item.y - item.my, item.w + item.mx*2, item.h + item.my*2, gfx.COLOR_LIGHT_GRAY)
    
        -- Render item boundary
        gfx.rect(item.x, item.y, item.w, item.h, gfx.COLOR_RED)
    end
end

return M
