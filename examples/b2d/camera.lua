-- camera.lua - 2D camera with pan/zoom support
local app = require("sokol.app")

local Camera = {}
Camera.__index = Camera

function Camera.new(opts)
    opts = opts or {}
    local self = setmetatable({
        center = {x = opts.center_x or 0, y = opts.center_y or 0},
        zoom = opts.zoom or 25,
        width = opts.width or 800,
        height = opts.height or 600,
        -- Mouse state
        dragging = false,
        drag_start_x = 0,
        drag_start_y = 0,
        drag_start_center = {x = 0, y = 0},
    }, Camera)
    return self
end

function Camera:resize(width, height)
    self.width = width
    self.height = height
end

function Camera:get_bounds()
    local aspect = self.width / self.height
    local hw = self.zoom * aspect * 0.5
    local hh = self.zoom * 0.5
    return {
        left = self.center.x - hw,
        right = self.center.x + hw,
        bottom = self.center.y - hh,
        top = self.center.y + hh,
    }
end

function Camera:screen_to_world(sx, sy)
    local b = self:get_bounds()
    local wx = b.left + (sx / self.width) * (b.right - b.left)
    local wy = b.top - (sy / self.height) * (b.top - b.bottom)
    return wx, wy
end

function Camera:world_to_screen(wx, wy)
    local b = self:get_bounds()
    local sx = ((wx - b.left) / (b.right - b.left)) * self.width
    local sy = ((b.top - wy) / (b.top - b.bottom)) * self.height
    return sx, sy
end

function Camera:on_event(ev)
    if ev.type == app.EventType.MOUSE_DOWN then
        if ev.mouse_button == app.Mousebutton.RIGHT then
            self.dragging = true
            self.drag_start_x = ev.mouse_x
            self.drag_start_y = ev.mouse_y
            self.drag_start_center = {x = self.center.x, y = self.center.y}
        end
    elseif ev.type == app.EventType.MOUSE_UP then
        if ev.mouse_button == app.Mousebutton.RIGHT then
            self.dragging = false
        end
    elseif ev.type == app.EventType.MOUSE_MOVE then
        if self.dragging then
            local dx = ev.mouse_x - self.drag_start_x
            local dy = ev.mouse_y - self.drag_start_y
            local b = self:get_bounds()
            local scale_x = (b.right - b.left) / self.width
            local scale_y = (b.top - b.bottom) / self.height
            self.center.x = self.drag_start_center.x - dx * scale_x
            self.center.y = self.drag_start_center.y + dy * scale_y
        end
    elseif ev.type == app.EventType.MOUSE_SCROLL then
        local zoom_factor = 1.1
        if ev.scroll_y > 0 then
            self.zoom = self.zoom / zoom_factor
        elseif ev.scroll_y < 0 then
            self.zoom = self.zoom * zoom_factor
        end
        -- Clamp zoom
        self.zoom = math.max(1, math.min(1000, self.zoom))
    elseif ev.type == app.EventType.RESIZED then
        self:resize(ev.window_width, ev.window_height)
    end
end

function Camera:reset(center_x, center_y, zoom)
    self.center.x = center_x or 0
    self.center.y = center_y or 0
    self.zoom = zoom or 25
end

return Camera
