#!/bin/bash
# test_samples.sh - Run all Box2D sample tests with timeout
# Each sample runs in a separate process with a 5 second timeout

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EXE="$PROJECT_DIR/build/dummy-debug/mane3d-test.exe"
TEST_SCRIPT="examples/b2d/test_single_sample.lua"
TIMEOUT_SEC=5

# List of samples to test
SAMPLES=(
    hello
    single_box
    vertical_stack
    circle_stack
    tilted_stack
    capsule_stack
    cliff
    arch
    double_domino
    confined
    card_house
    circle_impulse
    restitution
    friction
    compound_shapes
    rounded
    ellipse
    chain_shape
    conveyor_belt
    explosion
    offset_shapes
    tangent_speed
    modify_geometry
    chain_link
    shape_filter
    body_type
    sleep
    weeble
    pivot
    bad_body
    mixed_locks
    set_velocity
    wake_touching
    ray_cast
    overlap
    shape_distance
    cast_world
    distance_joint
    motor_joint
    prismatic_joint
    revolute_joint
    wheel_joint
    ball_and_chain
    bridge
    door
    motion_locks
    bad_steiner
    barrel
    body_move
    bounce_house
    breakable_joint
    cantilever
)

cd "$PROJECT_DIR"

if [ ! -f "$EXE" ]; then
    echo "ERROR: $EXE not found. Run build first."
    exit 1
fi

echo "Box2D Sample Tests (timeout: ${TIMEOUT_SEC}s per test)"
echo "========================================"

passed=0
failed=0
failed_list=()

for sample in "${SAMPLES[@]}"; do
    printf "[TEST] %-30s ... " "$sample"

    # Run with timeout
    output=$(timeout $TIMEOUT_SEC "$EXE" "$TEST_SCRIPT" "$sample" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        echo "TIMEOUT"
        failed=$((failed + 1))
        failed_list+=("$sample (timeout)")
    elif [ $exit_code -ne 0 ]; then
        # Extract error message
        error_msg=$(echo "$output" | grep -E "^FAIL" | head -1)
        if [ -z "$error_msg" ]; then
            error_msg="exit code $exit_code"
        fi
        echo "$error_msg"
        failed=$((failed + 1))
        failed_list+=("$sample")
    else
        echo "OK"
        passed=$((passed + 1))
    fi
done

echo ""
echo "========================================"
echo "Results: $passed passed, $failed failed"
echo "========================================"

if [ $failed -gt 0 ]; then
    echo "Failed samples:"
    for name in "${failed_list[@]}"; do
        echo "  - $name"
    done
    exit 1
else
    echo "All samples passed!"
    exit 0
fi
