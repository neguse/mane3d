/* Lua bindings for bc7enc_rdo */
#include "rdo_bc_encoder.h"  /* includes bc7enc.h and bc7decomp.h */

#include <cstdlib>
#include <cstring>
#include <vector>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

static bool g_bc7enc_initialized = false;

static void ensure_initialized() {
    if (!g_bc7enc_initialized) {
        bc7enc_compress_block_init();
        g_bc7enc_initialized = true;
    }
}

/* Calculate BC7 compressed size
 * bc7.calc_size(width, height) -> size_in_bytes
 */
static int l_calc_size(lua_State *L) {
    int width = (int)luaL_checkinteger(L, 1);
    int height = (int)luaL_checkinteger(L, 2);

    int blocks_x = (width + 3) / 4;
    int blocks_y = (height + 3) / 4;
    size_t size = (size_t)blocks_x * blocks_y * 16;

    lua_pushinteger(L, (lua_Integer)size);
    return 1;
}

/* Encode RGBA pixels to BC7
 * bc7.encode(pixels, width, height, opts) -> compressed, nil
 * bc7.encode(pixels, width, height, opts) -> nil, error_message
 *
 * opts (optional table):
 *   quality: 1-6 (default: 5)
 *   srgb: boolean (default: false)
 *   rdo_quality: 0.0-2.0, 0=disabled (default: 0)
 */
static int l_encode(lua_State *L) {
    ensure_initialized();

    size_t pixels_len;
    const char *pixels = luaL_checklstring(L, 1, &pixels_len);
    int width = (int)luaL_checkinteger(L, 2);
    int height = (int)luaL_checkinteger(L, 3);

    /* Validate input */
    size_t expected_size = (size_t)width * height * 4;
    if (pixels_len < expected_size) {
        lua_pushnil(L);
        lua_pushstring(L, "pixel data too small for given dimensions");
        return 2;
    }

    /* Parse options */
    int quality = 5;
    bool srgb = false;
    float rdo_lambda = 0.0f;

    if (lua_istable(L, 4)) {
        lua_getfield(L, 4, "quality");
        if (!lua_isnil(L, -1)) {
            quality = (int)lua_tointeger(L, -1);
            if (quality < 1) quality = 1;
            if (quality > 6) quality = 6;
        }
        lua_pop(L, 1);

        lua_getfield(L, 4, "srgb");
        if (!lua_isnil(L, -1)) {
            srgb = lua_toboolean(L, -1) != 0;
        }
        lua_pop(L, 1);

        lua_getfield(L, 4, "rdo_quality");
        if (!lua_isnil(L, -1)) {
            rdo_lambda = (float)lua_tonumber(L, -1);
            if (rdo_lambda < 0.0f) rdo_lambda = 0.0f;
            if (rdo_lambda > 10.0f) rdo_lambda = 10.0f;
        }
        lua_pop(L, 1);
    }

    int blocks_x = (width + 3) / 4;
    int blocks_y = (height + 3) / 4;
    size_t output_size = (size_t)blocks_x * blocks_y * 16;

    /* Use RDO encoder if rdo_lambda > 0 */
    if (rdo_lambda > 0.0f) {
        /* Create source image */
        utils::image_u8 source_image(width, height);
        const uint8_t *src = (const uint8_t *)pixels;
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                source_image(x, y).set(
                    src[(y * width + x) * 4 + 0],
                    src[(y * width + x) * 4 + 1],
                    src[(y * width + x) * 4 + 2],
                    src[(y * width + x) * 4 + 3]
                );
            }
        }

        /* Setup RDO encoder params */
        rdo_bc::rdo_bc_params params;
        params.m_dxgi_format = srgb ? DXGI_FORMAT_BC7_UNORM_SRGB : DXGI_FORMAT_BC7_UNORM;
        params.m_rdo_lambda = rdo_lambda;
        params.m_bc7_uber_level = quality;
        params.m_perceptual = srgb;
        params.m_status_output = false;

        /* Encode with RDO */
        rdo_bc::rdo_bc_encoder encoder;
        if (!encoder.init(source_image, params)) {
            lua_pushnil(L);
            lua_pushstring(L, "failed to initialize RDO encoder");
            return 2;
        }

        if (!encoder.encode()) {
            lua_pushnil(L);
            lua_pushstring(L, "RDO encoding failed");
            return 2;
        }

        const void *blocks = encoder.get_blocks();
        size_t blocks_size = encoder.get_total_blocks_size_in_bytes();
        lua_pushlstring(L, (const char *)blocks, blocks_size);
        return 1;
    }

    /* Simple block-by-block encoding */
    std::vector<uint8_t> output(output_size);

    bc7enc_compress_block_params comp_params;
    bc7enc_compress_block_params_init(&comp_params);
    comp_params.m_uber_level = quality - 1;  /* 0-5 range */
    if (srgb) {
        bc7enc_compress_block_params_init_perceptual_weights(&comp_params);
    } else {
        bc7enc_compress_block_params_init_linear_weights(&comp_params);
    }

    const uint8_t *src = (const uint8_t *)pixels;
    uint8_t *dst = output.data();

    for (int by = 0; by < blocks_y; by++) {
        for (int bx = 0; bx < blocks_x; bx++) {
            /* Extract 4x4 block with padding for edge blocks */
            color_rgba block[16];
            for (int py = 0; py < 4; py++) {
                for (int px = 0; px < 4; px++) {
                    int x = bx * 4 + px;
                    int y = by * 4 + py;
                    if (x >= width) x = width - 1;
                    if (y >= height) y = height - 1;
                    const uint8_t *p = src + (y * width + x) * 4;
                    block[py * 4 + px].m_c[0] = p[0];
                    block[py * 4 + px].m_c[1] = p[1];
                    block[py * 4 + px].m_c[2] = p[2];
                    block[py * 4 + px].m_c[3] = p[3];
                }
            }

            bc7enc_compress_block(dst, block, &comp_params);
            dst += 16;
        }
    }

    lua_pushlstring(L, (const char *)output.data(), output_size);
    return 1;
}

/* Decode BC7 to RGBA pixels
 * bc7.decode(compressed, width, height) -> pixels, nil
 * bc7.decode(compressed, width, height) -> nil, error_message
 */
static int l_decode(lua_State *L) {
    size_t compressed_len;
    const char *compressed = luaL_checklstring(L, 1, &compressed_len);
    int width = (int)luaL_checkinteger(L, 2);
    int height = (int)luaL_checkinteger(L, 3);

    int blocks_x = (width + 3) / 4;
    int blocks_y = (height + 3) / 4;
    size_t expected_size = (size_t)blocks_x * blocks_y * 16;

    if (compressed_len < expected_size) {
        lua_pushnil(L);
        lua_pushstring(L, "compressed data too small for given dimensions");
        return 2;
    }

    size_t output_size = (size_t)width * height * 4;
    std::vector<uint8_t> output(output_size);

    const uint8_t *src = (const uint8_t *)compressed;
    uint8_t *dst = output.data();

    for (int by = 0; by < blocks_y; by++) {
        for (int bx = 0; bx < blocks_x; bx++) {
            bc7decomp::color_rgba block[16];
            if (!bc7decomp::unpack_bc7(src, block)) {
                lua_pushnil(L);
                lua_pushstring(L, "failed to decode BC7 block");
                return 2;
            }

            /* Copy block to output with clipping for edge blocks */
            for (int py = 0; py < 4; py++) {
                for (int px = 0; px < 4; px++) {
                    int x = bx * 4 + px;
                    int y = by * 4 + py;
                    if (x < width && y < height) {
                        uint8_t *p = dst + (y * width + x) * 4;
                        p[0] = block[py * 4 + px].r;
                        p[1] = block[py * 4 + px].g;
                        p[2] = block[py * 4 + px].b;
                        p[3] = block[py * 4 + px].a;
                    }
                }
            }

            src += 16;
        }
    }

    lua_pushlstring(L, (const char *)output.data(), output_size);
    return 1;
}

static const luaL_Reg bc7enc_funcs[] = {
    {"encode", l_encode},
    {"decode", l_decode},
    {"calc_size", l_calc_size},
    {NULL, NULL}
};

extern "C" int luaopen_bc7enc(lua_State *L) {
    luaL_newlib(L, bc7enc_funcs);
    return 1;
}
