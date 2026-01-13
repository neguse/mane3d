/*
 * mane3d headless test runner
 *
 * Usage: mane3d-test <script.lua> [num_frames]
 *
 * Runs a Lua script for the specified number of frames (default: 10)
 * without creating a window or using real graphics APIs.
 *
 * Exit codes:
 *   0 - Success
 *   1 - Lua error during init/frame/cleanup
 *   2 - Script file not found
 *   3 - Usage error
 */
#include "sokol_gfx.h"
#include "sokol_time.h"
#include "sokol_log.h"

#include "mane3d_lua.h"

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef MANE3D_HAS_SHDC
extern void shdc_init(void);
extern void shdc_shutdown(void);
#endif

static lua_State *L = NULL;
static int g_error_count = 0;

static void extract_dir(const char *path, char *dir, size_t dir_size)
{
    strncpy(dir, path, dir_size - 1);
    dir[dir_size - 1] = '\0';
    char *last_sep = NULL;
    for (char *p = dir; *p; p++)
    {
        if (*p == '/' || *p == '\\')
            last_sep = p;
    }
    if (last_sep)
        *last_sep = '\0';
    else
        strcpy(dir, ".");
}

static int call_lua(const char *func)
{
    lua_getglobal(L, func);
    if (lua_isfunction(L, -1))
    {
        if (lua_pcall(L, 0, 0, 0) != LUA_OK)
        {
            fprintf(stderr, "[ERROR] %s(): %s\n", func, lua_tostring(L, -1));
            lua_pop(L, 1);
            g_error_count++;
            return -1;
        }
    }
    else
    {
        lua_pop(L, 1);
    }
    return 0;
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        fprintf(stderr, "Usage: %s <script.lua> [num_frames]\n", argv[0]);
        return 3;
    }

    const char *script = argv[1];
    int num_frames = (argc > 2) ? atoi(argv[2]) : 10;

    printf("[TEST] Running %s for %d frames\n", script, num_frames);

    /* Check file exists */
    FILE *f = fopen(script, "r");
    if (!f)
    {
        fprintf(stderr, "[ERROR] Script not found: %s\n", script);
        return 2;
    }
    fclose(f);

    /* Setup Lua */
    L = luaL_newstate();
    luaL_openlibs(L);

    char script_dir[512];
    extract_dir(script, script_dir, sizeof(script_dir));
    mane3d_lua_setup_path(L, script_dir);
    mane3d_lua_register_all(L);

#ifdef MANE3D_HAS_SHDC
    shdc_init();
#endif

    /* Load script */
    if (luaL_dofile(L, script) != LUA_OK)
    {
        fprintf(stderr, "[ERROR] Load: %s\n", lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }

    /* Initialize sokol (dummy backend - all calls are no-ops) */
    /* Initialize only sokol_gfx and sokol_time
     * sokol_gl and sokol_audio are initialized by Lua scripts as needed */
    sg_setup(&(sg_desc){
        .environment = {
            .defaults = {
                .color_format = SG_PIXELFORMAT_RGBA8,
                .depth_format = SG_PIXELFORMAT_DEPTH_STENCIL,
                .sample_count = 1,
            },
        },
        /* Disable validation for DUMMY backend - BC7 textures are not marked
         * as filterable in dummy backend's format table */
        .disable_validation = true,
        .logger.func = slog_func,
    });
    stm_setup();

    /* Run init */
    printf("[TEST] Calling init()\n");
    call_lua("init");

    /* Run frames */
    for (int i = 0; i < num_frames; i++)
    {
        if (call_lua("frame") != 0)
            break;
    }
    printf("[TEST] Ran %d frames\n", num_frames);

    /* Cleanup */
    printf("[TEST] Calling cleanup()\n");
    call_lua("cleanup");

#ifdef MANE3D_HAS_SHDC
    shdc_shutdown();
#endif
    /* sokol_gl and sokol_audio are shutdown by Lua scripts */
    sg_shutdown();
    lua_close(L);

    if (g_error_count > 0)
    {
        fprintf(stderr, "[FAIL] %d errors\n", g_error_count);
        return 1;
    }

    printf("[PASS] %s\n", script);
    return 0;
}
