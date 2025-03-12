package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:thread"
import "core:os"
import "core:mem"
import "core:time"
import "core:c"

calculate_camera_position :: proc (camera: ^rl.Camera2D) {
    if (rl.IsMouseButtonDown(.LEFT)) {
        delta := rl.GetMouseDelta()
        delta = delta * -1.0/camera.zoom
        camera.target += delta
    }

    wheel := rl.GetMouseWheelMove()
    if (wheel != 0) {
        mouseWorldPos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera^)
        camera.offset = rl.GetMousePosition()
        camera.target = mouseWorldPos
        scale_factor := 1 + (0.25 * abs(wheel))

        if (wheel < 0) {
            scale_factor = 1 / scale_factor
        }

        camera.zoom = rl.Clamp(camera.zoom * scale_factor, 0.125, 128.0);
    }
}

button_bounds :: proc (index: int) -> rl.Rectangle {
    button_spacing: f32 = 60
    return { 10, 10 + button_spacing * f32(index), 100, 40}
}

main :: proc () {
    rl.SetConfigFlags({.FULLSCREEN_MODE, .WINDOW_RESIZABLE})
    rl.InitWindow(1920, 1080, "Lenia")
    rl.SetTargetFPS(60)

    simulation_fps: f64 = 60

    lenia := lenia_new(lenia_get_default_params())

    camera := rl.Camera2D {
        target = rl.Vector2 {
            f32(lenia.parameters.grid_size) / 2 - f32(rl.GetScreenWidth()) / 2,
            f32(lenia.parameters.grid_size) / 2 - f32(rl.GetScreenHeight()) / 2
        },
        zoom = 1
    }

    simulation_frame_time: f64 = 1 / simulation_fps
    last_time := time.now()
    for !rl.WindowShouldClose() {
        calculate_camera_position(&camera)

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.BeginMode2D(camera)
                lenia_draw(&lenia)
            rl.EndMode2D()
            rl.DrawFPS(0,0)
        rl.EndDrawing()

        if (time.duration_seconds(time.since(last_time)) >= simulation_frame_time) {
            lenia_compute_simulation_step(&lenia)
            last_time = time.now()
        }
    }

    rl.CloseWindow()
}
