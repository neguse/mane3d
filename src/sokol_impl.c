/* Sokol implementation - compiled once */
#define SOKOL_IMPL
#include "sokol_log.h"
#include "sokol_gfx.h"
#ifndef SOKOL_DUMMY_BACKEND
/* sokol_app requires a real windowing backend - skip for headless testing */
#include "sokol_app.h"
#include "sokol_glue.h"
#endif
#include "sokol_time.h"
#include "sokol_audio.h"
#include "sokol_gl.h"
#include "sokol_debugtext.h"
#include "sokol_shape.h"
