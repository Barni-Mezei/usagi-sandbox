---@diagnostic disable: undefined-field

---@class Grid
local M = {}

---@class Grid.Grid 
---@field width   integer The width of the grid (number of cells)
---@field height  integer The height of the grid (number of cells)
---@field default any     The default value of a cell in the grid
---**Grid values are stored in a row-first table!** So getting a
---cell's value is like so: `grid[y][x]`
---The Grid is a table that has `height` number of 1-based keys,
---where each key has a value, that is another similar table but
---with `width` number of keys instead. Each item in the second table
---is a cell in the grid.



---Creates a new grid instance (a 2d matrix made out of table of tables)
---@param width   number  The width of the grid (number of cells)
---@param height  number  The height of the grid (number of cells)
---@param default any     The default value of a cell in the grid
---@return Grid.Grid grid A new grid object
function M.create_grid(width, height, default)
    local d = default or 0
    local w = width or 1
    local h = height or 1

    local grid = {
        width = w,
        height = h,
        default = d,
    }

    for y = 1, h do
        local line = {}
        for x = 1, w do line[x] = d end
        grid[y] = line
    end

    return grid
end

---Creates a copy of the provided grid  
---**This function does not copy the grid cell values, so table references will remain!**
---@param grid Grid.Grid  The grid to copy
---@return Grid.Grid grid The copy of `grid`
function M.copy_grid(grid)
    local out = {}

    for y, line in ipairs(grid) do
        local out_line = {} 
        for x, value in ipairs(line) do
            out_line[x] = value
        end
        out[y] = out_line
    end

    return out
end

---Retrieves a cell value from the grid. Cell coordinates start from the top left
---@param grid     Grid.Grid The grid to get the value from
---@param x        number    The X coordinate of the cell (1 based)
---@param y        number    The Y coordinate of the cell (1 based)
---@param fallback any       The value to fall back to, when the cell was not found
---@return any value         The cell value in the grid or `fallback` if
---the cell was not found
function M.get_cell(grid, x, y, fallback)
    if grid[y] == nil then return fallback or false end
    if grid[y][x] == nil then return fallback or false end

    return grid[y][x]
end

---Modifies a cell in the grid. Cell coordinates start from the top left
---@param grid  Grid.Grid The grid to modify
---@param x     number    The X coordinate of the cell (1 based)
---@param y     number    The Y coordinate of the cell (1 based)
---@param value any       The value to replace the cell to (If no value is
---provided, the cell will be set to the grid default value)
---@return      boolean   Operation result (false if the cell was not in the grid)
function M.set_cell(grid, x, y, value)
    if grid[y] == nil then return false end
    if grid[y][x] == nil then return false end

    grid[y][x] = value or grid.default or 0

    return true
end

---Iterates over all cells in a grid
---@param grid     Grid.Grid The grid to iterate over
---@param callback function  This function gets called on every cell, and
---has the following values passed to it:
--- - `x`     **integer**: The X coordinate of the current cell
--- - `y`     **integer**: The Y coordinate of the current cell
--- - `value` **any**:     The value of the current cell
---If the function returns something, the cell value will be overwritten with it
function M.foreach(grid, callback)
    for y, line in ipairs(grid) do
        for x, value in ipairs(line) do
            grid[y][x] = callback(x, y, value) or grid[y][x] or grid.default
        end
    end
end

return M
