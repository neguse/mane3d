/*
 * box2d_task.c - Simple serial task system for Box2D
 *
 * Box2D 3.x uses a task system for parallel physics simulation.
 * This provides a simple single-threaded implementation that runs
 * tasks serially. For multi-threaded physics, replace this with
 * a proper thread pool implementation.
 */
#include <box2d/box2d.h>
#include <lua.h>
#include <lauxlib.h>

/* Serial task implementation - runs tasks immediately on the calling thread */
static void* b2d_enqueue_task(b2TaskCallback* task, int itemCount, int minRange,
                               void* taskContext, void* userContext)
{
    (void)minRange;
    (void)userContext;

    if (task && itemCount > 0)
    {
        /* Run the task serially with workerIndex=0 */
        task(0, itemCount, 0, taskContext);
    }
    return NULL;
}

static void b2d_finish_task(void* taskPtr, void* userContext)
{
    /* Nothing to do for serial execution */
    (void)taskPtr;
    (void)userContext;
}

/* Get default world definition with serial task system configured */
b2WorldDef b2d_default_world_def(void)
{
    b2WorldDef def = b2DefaultWorldDef();
    def.enqueueTask = b2d_enqueue_task;
    def.finishTask = b2d_finish_task;
    def.workerCount = 1;
    def.userTaskContext = NULL;
    return def;
}

/*
 * Helper function to create revolute joint directly from Lua
 * Usage: joint_id = b2d.create_revolute_joint_at(world, bodyA, bodyB, pivot, options)
 * pivot = {x, y} in world coordinates
 * options = { enableMotor=bool, motorSpeed=float, maxMotorTorque=float, ... }
 */
int l_b2d_create_revolute_joint_at(lua_State *L)
{
    b2WorldId* world_ptr = (b2WorldId*)luaL_checkudata(L, 1, "b2d.WorldId");
    b2BodyId* bodyA_ptr = (b2BodyId*)luaL_checkudata(L, 2, "b2d.BodyId");
    b2BodyId* bodyB_ptr = (b2BodyId*)luaL_checkudata(L, 3, "b2d.BodyId");

    /* Read pivot point {x, y} */
    luaL_checktype(L, 4, LUA_TTABLE);
    lua_rawgeti(L, 4, 1);
    float px = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
    lua_rawgeti(L, 4, 2);
    float py = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
    b2Vec2 pivot = {px, py};

    /* Create joint definition */
    b2RevoluteJointDef def = b2DefaultRevoluteJointDef();
    def.base.bodyIdA = *bodyA_ptr;
    def.base.bodyIdB = *bodyB_ptr;
    /* Convert world pivot to local coordinates for each body */
    def.base.localFrameA.p = b2Body_GetLocalPoint(*bodyA_ptr, pivot);
    def.base.localFrameB.p = b2Body_GetLocalPoint(*bodyB_ptr, pivot);
    /* Ensure rotation is identity */
    def.base.localFrameA.q = b2Rot_identity;
    def.base.localFrameB.q = b2Rot_identity;

    /* Read options table if provided */
    if (lua_istable(L, 5)) {
        lua_getfield(L, 5, "enableMotor");
        if (!lua_isnil(L, -1)) def.enableMotor = lua_toboolean(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "motorSpeed");
        if (!lua_isnil(L, -1)) def.motorSpeed = (float)lua_tonumber(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "maxMotorTorque");
        if (!lua_isnil(L, -1)) def.maxMotorTorque = (float)lua_tonumber(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "enableSpring");
        if (!lua_isnil(L, -1)) def.enableSpring = lua_toboolean(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "hertz");
        if (!lua_isnil(L, -1)) def.hertz = (float)lua_tonumber(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "dampingRatio");
        if (!lua_isnil(L, -1)) def.dampingRatio = (float)lua_tonumber(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "enableLimit");
        if (!lua_isnil(L, -1)) def.enableLimit = lua_toboolean(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "lowerAngle");
        if (!lua_isnil(L, -1)) def.lowerAngle = (float)lua_tonumber(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, 5, "upperAngle");
        if (!lua_isnil(L, -1)) def.upperAngle = (float)lua_tonumber(L, -1);
        lua_pop(L, 1);
    }

    /* Create the joint */
    b2JointId result = b2CreateRevoluteJoint(*world_ptr, &def);

    /* Return as userdata */
    b2JointId* ud = (b2JointId*)lua_newuserdatauv(L, sizeof(b2JointId), 0);
    *ud = result;
    luaL_setmetatable(L, "b2d.JointId");
    return 1;
}
