/* Sokol implementation - compiled once */
#define SOKOL_IMPL
#include "sokol_log.h"
#include "sokol_gfx.h"
#ifndef SOKOL_DUMMY_BACKEND
/* sokol_app requires a real windowing backend - skip for headless testing */
/* SOKOL_NO_ENTRY: Use sapp_run() instead of sokol_main() - Lua controls entry point */
#define SOKOL_NO_ENTRY
#include "sokol_app.h"
#include "sokol_glue.h"
#endif
#include "sokol_time.h"
#include "sokol_audio.h"
#include "sokol_gl.h"
#include "sokol_debugtext.h"
#include "sokol_shape.h"
