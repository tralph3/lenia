package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math"

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

        camera.zoom = rl.Clamp(camera.zoom * scale_factor, 0.125, 64.0);
    }
}

main :: proc () {
    KERNEL_RADIUS :: 4
    KERNEL_PEAKS :: []f32 {0.3, 0.7, 0.2, 0, 0.9}
    MAIN_GRID_SIZE :: 100
    TIME_STEP: f32 : 100
    MU :: 0.35
    SIGMA :: 0.07

    grid := generate_main_grid_random(MAIN_GRID_SIZE, MAIN_GRID_SIZE)
    defer delete(grid.mat)

    kernel := generate_kernel(KERNEL_RADIUS, KERNEL_PEAKS)
    defer delete(kernel.mat)

    camera := rl.Camera2D {
        target = rl.Vector2 { 0, 0 },
        zoom = 1
    }

    cell_size: u32 = 10
    cell_gap: u32 = 0

    rl.InitWindow(800, 600, "Lenia")
    rl.SetTargetFPS(60)

    dt: f32 = 0
    run: bool = false

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()

        if rl.IsKeyPressed(.C) {
            run = !run
        } else if rl.IsKeyPressed(.G) || run {
            dt += 1 / TIME_STEP
            generate_next_grid_state(grid, kernel, dt, MU, SIGMA)
        } else if rl.IsKeyPressed(.R) {
            delete(grid.mat)
            dt = 0
            grid = generate_main_grid_random(grid.width, grid.height)
        }

        calculate_camera_position(&camera)

        rl.ClearBackground(rl.BLACK)

        rl.BeginMode2D(camera)
        for h in 0..<grid.height {
            for w in 0..<grid.width {
                elem := get_grid(grid, i32(w), i32(h))
                rl.DrawRectangle(i32(w * (cell_size + cell_gap)), i32(h * (cell_size + cell_gap)), i32(cell_size), i32(cell_size), rl.Fade(rl.RED, elem))
            }
        }
        rl.EndMode2D()

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
