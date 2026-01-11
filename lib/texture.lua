-- Texture loading utilities for mane3d
local gfx = require("sokol.gfx")
local gpu = require("lib.gpu")
local log = require("lib.log")
local stb = require("stb.image")

-- Optional bc7enc module
local bc7enc_ok, bc7enc = pcall(require, "bc7enc")
if not bc7enc_ok then bc7enc = nil end

local M = {}

-- Resolve path relative to script directory
-- Absolute paths (starting with / or X:) are returned as-is
---@param path string
---@return string
local function resolve_path(path)
    if path:match("^/") or path:match("^%a:") then
        return path
    end
    return path
end

-- Read entire file as binary
---@param path string file path
---@return string|nil data
local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

-- Write binary data to file
---@param path string file path
---@param data string binary data
---@return boolean success
local function write_file(path, data)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(data)
    f:close()
    return true
end

-- Get file modification time (returns nil if file doesn't exist)
---@param path string file path
---@return number|nil mtime modification time or nil
local function get_mtime(path)
    return stb.mtime(path)
end

-- Load raw image data from file (handles WASM fetch)
-- @param filename string: path to image file
-- @return width, height, channels, pixels or nil, error_message
function M.load_image_data(filename)
    local resolved = resolve_path(filename)

    -- Check if running in WASM (fetch_file is defined in main.c for Emscripten)
    ---@type fun(filename: string): string?
    local fetch_file = _G["fetch_file"]
    local w, h, ch, pixels
    if fetch_file then
        local data = fetch_file(resolved)
        if not data then
            return nil, "Failed to fetch: " .. resolved
        end
        w, h, ch, pixels = stb.load_from_memory(data, 4)
    else
        -- Native: load directly from filesystem
        w, h, ch, pixels = stb.load(resolved, 4)
    end
    return w, h, ch, pixels
end

-- Load texture from file using gpu wrappers (GC-safe)
---@param filename string path to image file (PNG, JPG, etc.)
---@param opts? table optional settings { filter_min, filter_mag, wrap_u, wrap_v }
---@return gpu.Image? img image resource (keep reference to prevent GC)
---@return gpu.View|string view_or_error view on success, error message on failure
---@return gpu.Sampler? smp sampler on success
function M.load(filename, opts)
    opts = opts or {}

    local w, h, ch, pixels = M.load_image_data(filename)
    if not w then
        return nil, h --[[@as string]] -- h contains error message
    end
    ---@cast h integer
    ---@cast ch integer
    ---@cast pixels string

    log.info("Loaded texture: " .. filename .. " (" .. w .. "x" .. h .. ")")

    -- Create image with gpu wrapper (GC-safe)
    local img = gpu.image(gfx.ImageDesc({
        width = w,
        height = h,
        pixel_format = gfx.PixelFormat.RGBA8,
        data = { mip_levels = { pixels } },
    }))

    if gfx.query_image_state(img.handle) ~= gfx.ResourceState.VALID then
        return nil, "Failed to create image"
    end

    -- Create view from image (required for binding)
    local view = gpu.view(gfx.ViewDesc({
        texture = { image = img.handle },
    }))

    -- Create sampler
    local smp = gpu.sampler(gfx.SamplerDesc({
        min_filter = opts.filter_min or gfx.Filter.LINEAR,
        mag_filter = opts.filter_mag or gfx.Filter.LINEAR,
        wrap_u = opts.wrap_u or gfx.Wrap.REPEAT,
        wrap_v = opts.wrap_v or gfx.Wrap.REPEAT,
    }))

    return img, view, smp
end

-- Load texture with BC7 compression support
-- If .bc7 file exists, use it directly. Otherwise, load PNG and convert to BC7.
---@param filename string path to image file (PNG, JPG, etc.)
---@param opts? table optional settings { filter_min, filter_mag, wrap_u, wrap_v, srgb, rdo_quality }
---@return gpu.Image? img image resource (keep reference to prevent GC)
---@return gpu.View|string view_or_error view on success, error message on failure
---@return gpu.Sampler? smp sampler on success
function M.load_bc7(filename, opts)
    opts = opts or {}

    -- If bc7enc not available, fall back to regular load
    if not bc7enc then
        return M.load(filename, opts)
    end

    -- Generate BC7 cache path
    local bc7_path = filename:gsub("%.[^.]+$", ".bc7")
    local resolved = resolve_path(filename)
    local resolved_bc7 = resolve_path(bc7_path)

    local w, h, compressed

    -- Check timestamps: use BC7 cache only if it's newer than source
    local src_mtime = get_mtime(resolved)
    local bc7_mtime = get_mtime(resolved_bc7)
    local use_cache = bc7_mtime and src_mtime and bc7_mtime >= src_mtime

    -- Try to load existing BC7 file if cache is valid
    if use_cache then
        local data = read_file(resolved_bc7)
        if data and #data >= 8 then
            -- BC7 file format: 4 bytes width, 4 bytes height, then compressed data
            w, h = string.unpack("<I4I4", data)
            compressed = data:sub(9)
            log.info("Loaded BC7 cache: " .. bc7_path .. " (" .. w .. "x" .. h .. ")")
        end
    end

    -- If no valid cache, load source and encode to BC7
    if not compressed then
        local ch, pixels
        w, h, ch, pixels = M.load_image_data(filename)
        if not w then
            return nil, h --[[@as string]]
        end
        ---@cast h integer
        ---@cast pixels string

        compressed = bc7enc.encode(pixels, w, h, {
            quality = 5,
            srgb = opts.srgb or false,
            rdo_quality = opts.rdo_quality or 0,
        })

        if not compressed then
            return nil, "BC7 encoding failed"
        end

        -- Save BC7 cache file
        local header = string.pack("<I4I4", w, h)
        write_file(resolved_bc7, header .. compressed)
        log.info("Saved BC7 cache: " .. bc7_path .. " (" .. w .. "x" .. h .. ")")
    end

    -- Upload BC7 to GPU
    local pixel_format = opts.srgb and gfx.PixelFormat.BC7_SRGBA or gfx.PixelFormat.BC7_RGBA
    local img = gpu.image(gfx.ImageDesc({
        width = w,
        height = h,
        pixel_format = pixel_format,
        data = { mip_levels = { compressed } },
    }))

    if gfx.query_image_state(img.handle) ~= gfx.ResourceState.VALID then
        return nil, "Failed to create BC7 image"
    end

    local view = gpu.view(gfx.ViewDesc({
        texture = { image = img.handle },
    }))

    local smp = gpu.sampler(gfx.SamplerDesc({
        min_filter = opts.filter_min or gfx.Filter.LINEAR,
        mag_filter = opts.filter_mag or gfx.Filter.LINEAR,
        wrap_u = opts.wrap_u or gfx.Wrap.REPEAT,
        wrap_v = opts.wrap_v or gfx.Wrap.REPEAT,
    }))

    return img, view, smp
end

return M
