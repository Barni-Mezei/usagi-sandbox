---Same as `gfx.circ()` but it accepts a single table as a parameter, and an optional color
---If no color was provided it will attempt to get it from the table as well
function gfx.circ_t(circle, color) gfx.circ(circle.x, circle.y, circle.r, circle.color or color) end

---Same as `gfx.rect()` but it accepts a single table as a parameter, and an optional color
---If no color was provided it will attempt to get it from the table as well
function gfx.rect_t(rect, color) gfx.rect(rect.x, rect.y, rect.w, rect.h, rect.color or color) end

---Same as `gfx.rect_fill()` but it accepts a single table as a parameter, and an optional color
---If no color was provided it will attempt to get it from the table as well
function gfx.rect_fill_t(rect, color) gfx.rect_fill(rect.x, rect.y, rect.w, rect.h, rect.color or color) end

---Same as `gfx.line_t()` but it accepts two tables as two points, and an optional color
---If no color was provided it will attempt to get it from the first, then the second point table
function gfx.line_t(pointA, pointB, color) gfx.line(pointA.x, pointA.y, pointB.x, pointB.y, pointA.color or pointB.color or color) end

---Same as `gfx.rect()` but it draws the rectangle with a dotted line
function gfx.rect_dot(x, y, w, h, color)
    for dx = x, x + w, 2 do
        gfx.pixel(x + dx, y, color)
        gfx.pixel(x + dx, y + h, color)
    end

    for dy = y, y + h, 2 do
        gfx.pixel(x, y + dy, color)
        gfx.pixel(x + w,y + dy, color)
    end
end
