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
    KERNEL_RADIUS :: 5
    KERNEL_PEAKS :: []f32 {1, 1, 1, 1, 1, 1, 1, 1}
    MAIN_GRID_SIZE :: 300
    TIME_STEP: c.float = 0.9
    MU: c.float = 0.35
    SIGMA: c.float = 0.07
    ALPHA: c.float = 4.0

    rl.SetConfigFlags({.FULLSCREEN_MODE, .WINDOW_RESIZABLE})
    rl.InitWindow(1920, 1080, "Lenia")
    rl.SetTargetFPS(60)

    simulation_fps: f64 = 60

    kernel := generate_kernel(KERNEL_RADIUS, KERNEL_PEAKS, ALPHA)
    kernel_image := rl.GenImageColor(kernel.width, kernel.height, rl.WHITE)

    for h in 0..<kernel.height {
        for w in 0..<kernel.width {
            kernel_val := get_grid(kernel, w, h)
            rl.ImageDrawPixel(&kernel_image, w, h, { u8(kernel_val * 255), 0, 0, 255 })
        }
    }
    kernel_tex := rl.LoadTextureFromImage(kernel_image)
    rl.UnloadImage(kernel_image)

    camera := rl.Camera2D {
        target = rl.Vector2 {
            f32(MAIN_GRID_SIZE) / 2 - f32(rl.GetScreenWidth()) / 2,
            f32(MAIN_GRID_SIZE) / 2 - f32(rl.GetScreenHeight()) / 2
        },
        zoom = 1
    }

    dt: f32 = 0
    run: bool = false

    buffers: [2]rl.RenderTexture = {
        rl.LoadRenderTexture(MAIN_GRID_SIZE, MAIN_GRID_SIZE),
        rl.LoadRenderTexture(MAIN_GRID_SIZE, MAIN_GRID_SIZE),
    }

    rl.SetTextureWrap(buffers[0].texture, .REPEAT)
    rl.SetTextureWrap(buffers[1].texture, .REPEAT)

    noise_image := rl.GenImagePerlinNoise(MAIN_GRID_SIZE, MAIN_GRID_SIZE, 0, 0, 5)
    rl.UpdateTexture(buffers[0].texture, noise_image.data)
    rl.UnloadImage(noise_image)

    shader := rl.LoadShader(nil, "src/shader.fs")
    resolution := rl.Vector2 { MAIN_GRID_SIZE, MAIN_GRID_SIZE }

    resolution_loc := rl.GetShaderLocation(shader, "resolution")
    rl.SetShaderValue(shader, resolution_loc, &resolution, .VEC2)

    kernel_loc := rl.GetShaderLocation(shader, "kernel")

    kernel_size := rl.Vector2 { c.float(kernel.width), c.float(kernel.height) }
    kernel_size_loc := rl.GetShaderLocation(shader, "kernelSize")
    rl.SetShaderValue(shader, kernel_size_loc, &kernel_size, .VEC2)

    mu_loc := rl.GetShaderLocation(shader, "mu")
    rl.SetShaderValue(shader, mu_loc, &MU, .FLOAT)

    sigma_loc := rl.GetShaderLocation(shader, "sigma")
    rl.SetShaderValue(shader, sigma_loc, &SIGMA, .FLOAT)

    alpha_loc := rl.GetShaderLocation(shader, "alpha")
    rl.SetShaderValue(shader, alpha_loc, &ALPHA, .FLOAT)

    dt_loc := rl.GetShaderLocation(shader, "dt")
    rl.SetShaderValue(shader, dt_loc, &TIME_STEP, .FLOAT)

    buffer_index := 0

    simulation_frame_time: f64 = 1 / simulation_fps
    last_time := time.now()
    for !rl.WindowShouldClose() {
        calculate_camera_position(&camera)

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.BeginMode2D(camera)
                rl.DrawTexture(buffers[buffer_index].texture, 0, 0, rl.WHITE)
            rl.EndMode2D()
            rl.DrawFPS(0,0)
        rl.EndDrawing()

        if (time.duration_seconds(time.since(last_time)) >= simulation_frame_time) {
            rl.BeginTextureMode(buffers[1 - buffer_index])
                rl.BeginShaderMode(shader)
                    rl.SetShaderValueTexture(shader, kernel_loc, kernel_tex)
                    rl.DrawTextureRec(buffers[buffer_index].texture, { 0, 0, MAIN_GRID_SIZE, -MAIN_GRID_SIZE }, { 0, 0 }, rl.WHITE)
                rl.EndShaderMode()
            rl.EndTextureMode()

            buffer_index = 1 - buffer_index
            last_time = time.now()
        }
    }

    rl.CloseWindow()
}
