package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:thread"
import "core:os"

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
    KERNEL_RADIUS :: 5
    KERNEL_PEAKS :: []f32 {0.2, 0.8, 0.57}
    MAIN_GRID_SIZE :: 300
    TIME_STEP: f32 : 100
    MU :: 0.35
    SIGMA :: 0.07

    thread_pool := thread.Pool {}
    thread.pool_init(&thread_pool, context.allocator, os.processor_core_count())
    thread.pool_start(&thread_pool)

    main_grid, back_grid := generate_main_grid_random(MAIN_GRID_SIZE, MAIN_GRID_SIZE)
    defer delete(main_grid.mat)
    defer delete(back_grid.mat)

    kernel := generate_kernel(KERNEL_RADIUS, KERNEL_PEAKS)
    defer delete(kernel.mat)

    cell_size: i32 = 10
    cell_gap: i32 = 0

    rl.SetConfigFlags({.FULLSCREEN_MODE})
    rl.InitWindow(1920, 1080, "Lenia")
    rl.SetTargetFPS(60)

    grid_render_size: [2]i32 = { main_grid.width * (cell_size + cell_gap) - cell_gap, main_grid.height * (cell_size + cell_gap) - cell_gap}
    camera := rl.Camera2D {
        target = rl.Vector2 { f32(grid_render_size.x) / 2 - f32(rl.GetScreenWidth()) / 2, f32(grid_render_size.y) / 2 - f32(rl.GetScreenHeight()) / 2},
        zoom = 1
    }

    dt: f32 = 0
    run: bool = false
    swap_grid: bool = false

    grid_to_render := main_grid
    for !rl.WindowShouldClose() {
        swap_grid = !swap_grid

        rl.BeginDrawing()

        if rl.IsKeyPressed(.C) {
            run = !run
        } else if rl.IsKeyPressed(.G) || run {
            dt += 1 / TIME_STEP
            if !swap_grid {
                update_grid_state(&thread_pool, main_grid, back_grid, kernel, dt, MU, SIGMA)
                grid_to_render = back_grid
            } else {
                update_grid_state(&thread_pool, back_grid, main_grid, kernel, dt, MU, SIGMA)
                grid_to_render = main_grid
            }

        } else if rl.IsKeyPressed(.R) {
            delete(main_grid.mat)
            delete(back_grid.mat)
            dt = 0
            main_grid, back_grid = generate_main_grid_random(main_grid.width, main_grid.height)
        }

        calculate_camera_position(&camera)
        rl.ClearBackground(rl.BLACK)

        rl.BeginMode2D(camera)
        for h in 0..<main_grid.height {
            for w in 0..<main_grid.width {
                elem := get_grid(grid_to_render, w, h)

                rl.DrawRectangle(i32(w * (cell_size + cell_gap)), i32(h * (cell_size + cell_gap)), i32(cell_size), i32(cell_size), rl.Fade(rl.RED, elem))
            }
        }
        rl.EndMode2D()

        rl.DrawFPS(0,0)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
