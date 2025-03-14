package main

import "core:c"
import rl "vendor:raylib"
import "core:fmt"
import "core:math/rand"

Lenia :: struct {
    buffers: [2]rl.RenderTexture2D,
    buffer_index: int,
    kernel: rl.Texture2D,
    lenia_shader: rl.Shader,
    visual_shader: rl.Shader,
    parameters: SimulationParams,
    shader_param_locs: ShaderParamLocs,
}

ShaderParamLocs :: struct {
    grid_size: c.int,
    kernel: c.int,
    kernel_size: c.int,
    precision: c.int,
    mu: c.int,
    sigma: c.int,
    alpha: c.int,
    dt: c.int,
}

SimulationParams :: struct {
    kernel_radius: i32,
    kernel_peaks: [dynamic]f32,
    growth_function: GrowthFunctionType,
    precision: c.int,
    grid_size: c.float,
    time_step: c.float,
    mu: c.float,
    sigma: c.float,
    alpha: c.float,
}

GrowthFunctionType :: enum c.int {
    Rectangular,
    Polynomial,
    Exponential,
}

KernelCoreType :: enum c.int {
    Rectangular,
    RectangularGol,
    Polynomial,
    Exponential,
}

lenia_new :: proc (parameters: SimulationParams) -> Lenia {
    lenia := Lenia {
        parameters = parameters,
        buffer_index = 0,
    }

    lenia_init_render_buffers(&lenia)
    lenia_init_kernel(&lenia)
    lenia_load_shaders(&lenia)

    return lenia
}

lenia_destroy :: proc (lenia: ^Lenia) {
    rl.UnloadRenderTexture(lenia.buffers[0])
    rl.UnloadRenderTexture(lenia.buffers[1])
    rl.UnloadTexture(lenia.kernel)
    rl.UnloadShader(lenia.lenia_shader)
    rl.UnloadShader(lenia.visual_shader)
    delete(lenia.parameters.kernel_peaks)
}

lenia_get_default_params :: proc () -> SimulationParams {
    params := SimulationParams {
        kernel_radius = 5,
        precision = 1,
        growth_function = .Polynomial,
        grid_size = 1000,
        time_step = 1,
        mu = 0.35,
        sigma = 0.07,
        alpha = 4,
    }

    append(&params.kernel_peaks, 1)
    return params
}

lenia_compute_simulation_step :: proc (lenia: ^Lenia) {
    rl.BeginTextureMode(lenia.buffers[1 - lenia.buffer_index])
        rl.BeginShaderMode(lenia.lenia_shader)
            rl.SetShaderValueTexture(lenia.lenia_shader, lenia.shader_param_locs.kernel, lenia.kernel)
            rl.DrawTextureRec(lenia.buffers[lenia.buffer_index].texture,
                              { 0, 0, f32(lenia.parameters.grid_size), -f32(lenia.parameters.grid_size) }, { 0, 0 }, rl.WHITE)
        rl.EndShaderMode()
    rl.EndTextureMode()

    lenia.buffer_index = 1 - lenia.buffer_index
}

lenia_draw :: proc (lenia: ^Lenia) {
    rl.BeginShaderMode(lenia.visual_shader)
        rl.DrawTexture(lenia.buffers[lenia.buffer_index].texture, 0, 0, rl.WHITE)
    rl.EndShaderMode()
}

lenia_reset :: proc (lenia: ^Lenia) {
    lenia_fill_with_random_noise(lenia.buffers[0])
    lenia.buffer_index = 0
}

lenia_change_growth_function :: proc (lenia: ^Lenia, growth_function: GrowthFunctionType) {
    lenia.parameters.growth_function = growth_function
    lenia_load_shaders(lenia)
}

lenia_update_mu :: proc (lenia: ^Lenia, new_val: c.float) {
    if new_val == lenia.parameters.mu {
        return
    }
    lenia.parameters.mu = new_val
    lenia_update_shader_params(lenia)
}

lenia_update_sigma :: proc (lenia: ^Lenia, new_val: c.float) {
    if new_val == lenia.parameters.sigma {
        return
    }
    lenia.parameters.sigma = new_val
    lenia_update_shader_params(lenia)
}

lenia_update_alpha :: proc (lenia: ^Lenia, new_val: c.float) {
    if new_val == lenia.parameters.alpha {
        return
    }
    lenia.parameters.alpha = new_val
    lenia_update_shader_params(lenia)
}

lenia_update_dt :: proc (lenia: ^Lenia, new_val: c.float) {
    if new_val == lenia.parameters.time_step {
        return
    }
    lenia.parameters.time_step = new_val
    lenia_update_shader_params(lenia)
}

lenia_update_precision :: proc (lenia: ^Lenia, new_val: c.int) {
    if new_val == lenia.parameters.precision {
        return
    }

    if (new_val == 0 && lenia.parameters.precision != 0) ||
        (new_val != 0 && lenia.parameters.precision == 0) {
            lenia.parameters.precision = new_val
            lenia_load_shaders(lenia)
        } else {
            lenia.parameters.precision = new_val
        }

    lenia_update_shader_params(lenia)
}

@(private="file")
lenia_update_shader_params :: proc (lenia: ^Lenia) {
    kernel_width := f32(lenia.kernel.width)
    precision: c.float = c.float(lenia.parameters.precision)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.kernel_size, &kernel_width, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.grid_size, &lenia.parameters.grid_size, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.precision, &precision, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.mu, &lenia.parameters.mu, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.sigma, &lenia.parameters.sigma, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.alpha, &lenia.parameters.alpha, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader, lenia.shader_param_locs.dt, &lenia.parameters.time_step, .FLOAT)
}

@(private="file")
lenia_set_shader_param_locs :: proc (lenia: ^Lenia) {
    lenia.shader_param_locs.kernel      = rl.GetShaderLocation(lenia.lenia_shader, "kernel")
    lenia.shader_param_locs.kernel_size = rl.GetShaderLocation(lenia.lenia_shader, "kernelSize")
    lenia.shader_param_locs.grid_size   = rl.GetShaderLocation(lenia.lenia_shader, "gridSize")
    lenia.shader_param_locs.precision   = rl.GetShaderLocation(lenia.lenia_shader, "P")
    lenia.shader_param_locs.mu          = rl.GetShaderLocation(lenia.lenia_shader, "mu")
    lenia.shader_param_locs.sigma       = rl.GetShaderLocation(lenia.lenia_shader, "sigma")
    lenia.shader_param_locs.alpha       = rl.GetShaderLocation(lenia.lenia_shader, "alpha")
    lenia.shader_param_locs.dt          = rl.GetShaderLocation(lenia.lenia_shader, "dt")
}

@(private="file")
lenia_fill_with_random_noise :: proc (buffer: rl.RenderTexture2D) {
    random_shader := shader_random_make()

    seed := c.float(rand.float32() - 0.5)
    seed_loc := rl.GetShaderLocation(random_shader, "seed")
    rl.SetShaderValue(random_shader, seed_loc, &seed, .FLOAT)

    rl.BeginTextureMode(buffer)
        rl.BeginShaderMode(random_shader)
            rl.DrawTexture(buffer.texture, 0, 0, rl.WHITE)
        rl.EndShaderMode()
    rl.EndTextureMode()

    rl.UnloadShader(random_shader)
}

@(private="file")
lenia_init_render_buffers :: proc (lenia: ^Lenia) {
    lenia.buffers = {
        rl.LoadRenderTexture(i32(lenia.parameters.grid_size), i32(lenia.parameters.grid_size)),
        rl.LoadRenderTexture(i32(lenia.parameters.grid_size), i32(lenia.parameters.grid_size)),
    }

    rl.SetTextureWrap(lenia.buffers[0].texture, .REPEAT)
    rl.SetTextureWrap(lenia.buffers[1].texture, .REPEAT)

    lenia_fill_with_random_noise(lenia.buffers[0])
}

@(private="file")
lenia_load_shaders :: proc (lenia: ^Lenia) {
    rl.UnloadShader(lenia.lenia_shader)
    rl.UnloadShader(lenia.visual_shader)

    lenia.lenia_shader  = shader_lenia_make(lenia.parameters.growth_function, lenia.parameters.precision > 0)
    lenia.visual_shader = shader_visual_make()

    lenia_set_shader_param_locs(lenia)
    lenia_update_shader_params(lenia)
}

@(private="file")
lenia_init_kernel :: proc (lenia: ^Lenia) {
    kernel := generate_kernel(lenia.parameters.kernel_radius, lenia.parameters.kernel_peaks[:], lenia.parameters.alpha)
    kernel_image := rl.GenImageColor(kernel.width, kernel.height, rl.WHITE)

    for h in 0..<kernel.height {
        for w in 0..<kernel.width {
            kernel_val := get_grid(kernel, w, h)
            rl.ImageDrawPixel(&kernel_image, w, h, { u8(kernel_val * 255), 0, 0, 255 })
        }
    }

    lenia.kernel = rl.LoadTextureFromImage(kernel_image)
    delete(kernel.mat)
    rl.UnloadImage(kernel_image)
}
