/*
 * mane3d headless test runner
 *
 * Usage: mane3d-test <script.lua> [num_frames] [timeout_sec]
 *        mane3d-test --sample <module.path> [timeout_sec]
 *
 * Runs a Lua script for the specified number of frames (default: 10)
 * without creating a window or using real graphics APIs.
 *
 * --sample mode: Runs a Box2D sample module (e.g., examples.b2d.samples.hello)
 *   - Loads the module via require()
 *   - Calls create_scene(), update(), and cleanup()
 *   - Each sample runs in isolation with its own timeout
 *
 * Exit codes:
 *   0 - Success
 *   1 - Lua error during init/frame/cleanup
 *   2 - Script file not found
 *   3 - Usage error
 *   124 - Timeout
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

#ifdef _WIN32
#include <windows.h>
#include <signal.h>
#endif

/* Box2D custom assert handler (suppress __debugbreak) */
#if defined(MANE3D_HAS_BOX2D)
#include "box2d/base.h"

static int custom_b2d_assert_handler(const char* condition, const char* fileName, int lineNumber)
{
    fprintf(stderr, "[B2D_ASSERT] %s:%d - %s\n", fileName, lineNumber, condition);
    fflush(stderr);
    return 0; /* 0 = skip B2_BREAKPOINT */
}
#endif

#ifdef _WIN32
/* Timeout thread for Windows */
static DWORD g_timeout_ms = 30000;

static DWORD WINAPI timeout_thread_func(LPVOID param)
{
    (void)param;
    Sleep(g_timeout_ms);
    fprintf(stderr, "[TIMEOUT] Test exceeded %lu ms time limit\n", g_timeout_ms);
    fflush(stderr);
    ExitProcess(124);
    return 0;
}

static void setup_windows_crash_handling(void)
{
    /* Suppress Windows error dialogs (assert, GPF, etc.) */
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
}

static void start_timeout_thread(DWORD timeout_ms)
{
    g_timeout_ms = timeout_ms;
    HANDLE hThread = CreateThread(NULL, 0, timeout_thread_func, NULL, 0, NULL);
    if (hThread)
    {
        CloseHandle(hThread);
    }
}
#endif

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
#ifdef _WIN32
    /* Layer 1: Suppress Windows error dialogs */
    setup_windows_crash_handling();
#endif

#if defined(MANE3D_HAS_BOX2D)
    /* Layer 2: Custom Box2D assert handler */
    b2SetAssertFcn(custom_b2d_assert_handler);
#endif

    if (argc < 2)
    {
        fprintf(stderr, "Usage: %s <script.lua> [num_frames] [timeout_sec]\n", argv[0]);
        fprintf(stderr, "       %s --sample <module.path> [timeout_sec]\n", argv[0]);
        return 3;
    }

    /* Check for --sample mode */
    int sample_mode = (strcmp(argv[1], "--sample") == 0);
    const char *script = sample_mode ? NULL : argv[1];
    const char *sample_module = sample_mode ? (argc > 2 ? argv[2] : NULL) : NULL;
    int num_frames = 10;
    int timeout_sec = 5; /* Shorter timeout for sample mode */

    if (sample_mode)
    {
        if (!sample_module)
        {
            fprintf(stderr, "Usage: %s --sample <module.path> [timeout_sec]\n", argv[0]);
            return 3;
        }
        timeout_sec = (argc > 3) ? atoi(argv[3]) : 5;
    }
    else
    {
        num_frames = (argc > 2) ? atoi(argv[2]) : 10;
        timeout_sec = (argc > 3) ? atoi(argv[3]) : 30;
    }

#ifdef _WIN32
    /* Layer 3: Timeout watchdog thread */
    start_timeout_thread((DWORD)timeout_sec * 1000);
#endif

    /* Setup Lua */
    L = luaL_newstate();
    luaL_openlibs(L);

    /* Initialize sokol (dummy backend - all calls are no-ops) */
    sg_setup(&(sg_desc){
        .environment = {
            .defaults = {
                .color_format = SG_PIXELFORMAT_RGBA8,
                .depth_format = SG_PIXELFORMAT_DEPTH_STENCIL,
                .sample_count = 1,
            },
        },
        .disable_validation = true,
        .logger.func = slog_func,
    });
    stm_setup();

    if (sample_mode)
    {
        /* Sample mode: run a single Box2D sample module */
        printf("[TEST] Running sample %s (timeout: %ds)\n", sample_module, timeout_sec);

        mane3d_lua_setup_path(L, ".");
        mane3d_lua_register_all(L);

        /* Run sample test inline */
        const char *sample_test_code =
            "local b2d = require('b2d')\n"
            "local sample_path = ...\n"
            "local mod = require(sample_path)\n"
            "local def = b2d.default_world_def()\n"
            "def.gravity = {0, -10}\n"
            "local world = b2d.create_world(def)\n"
            "if mod.create_scene then mod.create_scene(world) end\n"
            "if mod.update then\n"
            "  for i = 1, 10 do mod.update(world, 1/60) end\n"
            "end\n"
            "for i = 1, 60 do b2d.world_step(world, 1/60, 4) end\n"
            "if mod.cleanup then mod.cleanup() end\n"
            "b2d.destroy_world(world)\n";

        if (luaL_loadstring(L, sample_test_code) != LUA_OK)
        {
            fprintf(stderr, "[ERROR] Load sample test code: %s\n", lua_tostring(L, -1));
            lua_close(L);
            sg_shutdown();
            return 1;
        }

        lua_pushstring(L, sample_module);
        if (lua_pcall(L, 1, 0, 0) != LUA_OK)
        {
            fprintf(stderr, "[ERROR] Sample %s: %s\n", sample_module, lua_tostring(L, -1));
            lua_close(L);
            sg_shutdown();
            return 1;
        }

        sg_shutdown();
        lua_close(L);
        printf("[PASS] %s\n", sample_module);
        return 0;
    }

    /* Script mode */
    printf("[TEST] Running %s for %d frames (timeout: %ds)\n", script, num_frames, timeout_sec);

    /* Check file exists */
    FILE *f = fopen(script, "r");
    if (!f)
    {
        fprintf(stderr, "[ERROR] Script not found: %s\n", script);
        lua_close(L);
        sg_shutdown();
        return 2;
    }
    fclose(f);

    /* Setup arg table for script arguments */
    lua_createtable(L, argc - 2, 1);
    lua_pushstring(L, script);
    lua_rawseti(L, -2, 0);
    for (int i = 2; i < argc; i++)
    {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i - 1);
    }
    lua_setglobal(L, "arg");

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
        sg_shutdown();
        return 1;
    }

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
