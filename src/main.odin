package main

import rl "vendor:raylib"
import "core:time"

calculate_camera_position :: proc (camera: ^rl.Camera2D) {
    if SIMULATION_STATE.can_pan && (rl.IsMouseButtonDown(.LEFT)) {
        SIMULATION_STATE.panning = true

        delta := rl.GetMouseDelta()
        delta = delta * -1.0/camera.zoom
        camera.target += delta
    } else {
        SIMULATION_STATE.panning = false
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

        camera.zoom = rl.Clamp(camera.zoom * scale_factor, 0.125, 128.0)
    }
}

main :: proc () {
    rl.SetConfigFlags({.FULLSCREEN_MODE, .WINDOW_RESIZABLE})
    rl.InitWindow(0, 0, "Lenia")
    rl.SetTargetFPS(60)

    SIMULATION_STATE.lenia = lenia_new(lenia_get_default_params())
    lenia := &SIMULATION_STATE.lenia

    camera := rl.Camera2D {
        target = rl.Vector2 {
            f32(lenia.parameters.grid_size) / 2 - f32(rl.GetScreenWidth()) / 2,
            f32(lenia.parameters.grid_size) / 2 - f32(rl.GetScreenHeight()) / 2,
        },
        zoom = 1,
    }

    last_time := time.now()
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.BeginMode2D(camera)
                lenia_draw(lenia)
            rl.EndMode2D()
            draw_gui()
            rl.DrawFPS(0,0)
        rl.EndDrawing()

        calculate_camera_position(&camera)

        if (SIMULATION_STATE.running && time.duration_seconds(time.since(last_time)) >= 1 / f64(SIMULATION_STATE.fps)) {
            lenia_compute_simulation_step(lenia)
            last_time = time.now()
        }
    }

    lenia_destroy(lenia)
    rl.CloseWindow()
}
