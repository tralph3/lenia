package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:thread"
import "core:os"
import "core:mem"

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
    KERNEL_RADIUS :: 5
    KERNEL_PEAKS :: []f32 {1, 1, 1, 1, 1, 1, 1, 1}
    MAIN_GRID_SIZE :: 300
    TIME_STEP: f32 : 0.9
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

    cell_size: i32 = 1
    cell_gap: i32 = 0

    rl.SetConfigFlags({.FULLSCREEN_MODE})
    rl.InitWindow(1920, 1080, "Lenia")
    rl.SetTargetFPS(60)

    grid_render_size: [2]i32 = { main_grid.width * (cell_size + cell_gap) - cell_gap, main_grid.height * (cell_size + cell_gap) - cell_gap}
    camera := rl.Camera2D {
        target = rl.Vector2 { f32(grid_render_size.x) / 2 - f32(rl.GetScreenWidth()) / 2, f32(grid_render_size.y) / 2 - f32(rl.GetScreenHeight()) / 2},
        zoom = 1
    }

    tmp_render_texture := rl.LoadRenderTexture(main_grid.width, main_grid.height)
    tmp_image := rl.LoadImageFromTexture(tmp_render_texture.texture)
    rl.ImageFormat(&tmp_image, .UNCOMPRESSED_GRAYSCALE)
    render_texture := rl.LoadTextureFromImage(tmp_image)

    rl.UnloadRenderTexture(tmp_render_texture)
    rl.UnloadImage(tmp_image)

    dt: f32 = 0
    run: bool = false
    swap_grid: bool = false

    grid_to_render := main_grid

    render_buffer := make([]u8, main_grid.width * main_grid.height)

    for !rl.WindowShouldClose() {
        swap_grid = !swap_grid

        rl.BeginDrawing()

        if rl.IsKeyPressed(.C) || bool(rl.GuiToggle(button_bounds(0), "Run", &run)) {
            run = !run
        } else if rl.IsKeyPressed(.R) || rl.GuiButton(button_bounds(2), "Reset simulation") {
            run = false
            delete(main_grid.mat)
            delete(back_grid.mat)
            main_grid, back_grid = generate_main_grid_random(main_grid.width, main_grid.height)
            grid_to_render = main_grid
        } else if rl.IsKeyPressed(.G) || run || rl.GuiButton(button_bounds(1), "Simulation step") {
            if !swap_grid {
                update_grid_state(&thread_pool, main_grid, back_grid, kernel, TIME_STEP, MU, SIGMA)
                grid_to_render = back_grid
            } else {
                update_grid_state(&thread_pool, back_grid, main_grid, kernel, TIME_STEP, MU, SIGMA)
                grid_to_render = main_grid
            }
        }

        calculate_camera_position(&camera)
        rl.ClearBackground(rl.BLACK)

        for val, index in grid_to_render.mat {
            render_buffer[index] = u8(val * 255)
        }

        data, _ := mem.slice_to_components(render_buffer)

        rl.UpdateTexture(render_texture, data)

        rl.BeginMode2D(camera)
        rl.DrawTexture(render_texture, 0, 0, rl.BLUE)
        rl.EndMode2D()

        rl.DrawFPS(0,0)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
