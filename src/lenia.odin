package main

import "core:c"
import rl "vendor:raylib"
import "core:math/rand"

Lenia :: struct {
    buffers: [2]rl.RenderTexture2D,
    buffer_index: int,
    kernel: rl.Texture2D,
    kernel_shader: rl.Shader,
    grid_size: i32,
    max_kernel_value: f32,
    lenia_shader: rl.Shader,
    visual_shader: rl.Shader,
    filter: rl.TextureFilter,
    parameters: SimulationParams,
    shader_param_locs: ShaderParamLocs,
}

ShaderParamLocs :: struct {
    grid_size: c.int,
    kernel: c.int,
    kernel_size: c.int,
    max_kernel_val: c.int,
    state_resolution: c.int,
    mu: c.int,
    sigma: c.int,
    alpha: c.int,
    dt: c.int,
}

SimulationParams :: struct {
    spatial_resolution: i32,
    kernel_peaks: [dynamic]f32,
    kernel_core: KernelCoreType,
    growth_function: GrowthFunctionType,
    state_resolution: c.int,
    temporal_resolution: c.float,
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
        grid_size = 1000,
        filter = .POINT,
    }

    lenia_init(&lenia)

    return lenia
}

lenia_init :: proc (lenia: ^Lenia) {
    lenia_init_render_buffers(lenia)
    lenia_init_kernel(lenia)
    lenia_load_shaders(lenia)
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
        spatial_resolution = 13,
        state_resolution = 0,
        kernel_core = .Exponential,
        growth_function = .Exponential,
        temporal_resolution = 10,
        mu = 0.3,
        sigma = 0.045,
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
                              { 0, 0, f32(lenia.grid_size), -f32(lenia.grid_size) }, { 0, 0 }, rl.WHITE)
        rl.EndShaderMode()
    rl.EndTextureMode()

    lenia.buffer_index = 1 - lenia.buffer_index
}

lenia_draw :: proc (lenia: ^Lenia, origin: [2]f32) {
    draw_label({origin.x, origin.y, 0, 0}, "Main Grid")
    rl.SetTextureFilter(lenia.buffers[lenia.buffer_index].texture, lenia.filter)
    rl.BeginShaderMode(lenia.visual_shader)
        rl.DrawTexture(lenia.buffers[lenia.buffer_index].texture, i32(origin.x), i32(origin.y), rl.WHITE)
    rl.EndShaderMode()
    rl.SetTextureFilter(lenia.buffers[lenia.buffer_index].texture, .POINT)
    bounds := rl.Rectangle { origin.x - 110, origin.y, 100, 100 }
    draw_label(bounds, "Kernel")
    rl.BeginShaderMode(lenia.kernel_shader)
        rl.DrawTexturePro(lenia.kernel, {0, 0, f32(lenia.kernel.width), f32(lenia.kernel.height)}, bounds, rl.Vector2(0), 0, rl.WHITE)
    rl.EndShaderMode()
}

lenia_reset :: proc (lenia: ^Lenia) {
    lenia_fill_with_random_noise(lenia)
    lenia.buffer_index = 0
}

lenia_change_growth_function :: proc (lenia: ^Lenia, growth_function: GrowthFunctionType) {
    lenia.parameters.growth_function = growth_function
    lenia_load_shaders(lenia)
}

lenia_change_kernel_core :: proc (lenia: ^Lenia, kernel_core: KernelCoreType) {
    lenia.parameters.kernel_core = kernel_core
    lenia_init_kernel(lenia)
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
    lenia_init_kernel(lenia)
    lenia_update_shader_params(lenia)
}

lenia_update_temporal_resolution :: proc (lenia: ^Lenia, new_val: c.float) {
    if new_val == lenia.parameters.temporal_resolution {
        return
    }
    lenia.parameters.temporal_resolution = new_val
    lenia_update_shader_params(lenia)
}

lenia_update_state_resolution :: proc (lenia: ^Lenia, new_val: c.int) {
    if new_val == lenia.parameters.state_resolution {
        return
    }

    if (new_val == 0 && lenia.parameters.state_resolution != 0) ||
        (new_val != 0 && lenia.parameters.state_resolution == 0) {
            lenia.parameters.state_resolution = new_val
            lenia_load_shaders(lenia)
        } else {
            lenia.parameters.state_resolution = new_val
        }

    lenia_update_shader_params(lenia)
}

lenia_update_spatial_resolution :: proc (lenia: ^Lenia, new_val: i32) {
    if new_val == lenia.parameters.spatial_resolution || new_val < 1 {
        return
    }

    lenia.parameters.spatial_resolution = new_val
    lenia_init_kernel(lenia)
    lenia_update_shader_params(lenia)
}

lenia_toggle_texture_filtering :: proc (lenia: ^Lenia) {
    if lenia.filter == .POINT {
        lenia.filter = .BILINEAR
    } else {
        lenia.filter = .POINT
    }
}

lenia_update_params :: proc (lenia: ^Lenia, params: SimulationParams) {
    lenia.parameters = params
    lenia_init(lenia)
}

@(private="file")
lenia_update_shader_params :: proc (lenia: ^Lenia) {
    grid_size: c.float = c.float(lenia.grid_size)
    kernel_width: c.float = c.float(lenia.kernel.width)
    state_resolution: c.float = c.float(lenia.parameters.state_resolution)
    dt: c.float = c.float(1 / lenia.parameters.temporal_resolution)

    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.kernel_size, &kernel_width, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.grid_size, &grid_size, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.state_resolution, &state_resolution, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.mu, &lenia.parameters.mu, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.sigma, &lenia.parameters.sigma, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.alpha, &lenia.parameters.alpha, .FLOAT)
    rl.SetShaderValue(lenia.lenia_shader,  lenia.shader_param_locs.dt, &dt, .FLOAT)
    rl.SetShaderValue(lenia.kernel_shader, lenia.shader_param_locs.max_kernel_val, &lenia.max_kernel_value, .FLOAT)
}

@(private="file")
lenia_set_shader_param_locs :: proc (lenia: ^Lenia) {
    lenia.shader_param_locs.kernel           = rl.GetShaderLocation(lenia.lenia_shader,  "kernel")
    lenia.shader_param_locs.max_kernel_val   = rl.GetShaderLocation(lenia.kernel_shader, "maxKernelVal")
    lenia.shader_param_locs.kernel_size      = rl.GetShaderLocation(lenia.lenia_shader,  "kernelSize")
    lenia.shader_param_locs.grid_size        = rl.GetShaderLocation(lenia.lenia_shader,  "gridSize")
    lenia.shader_param_locs.state_resolution = rl.GetShaderLocation(lenia.lenia_shader,  "stateResolution")
    lenia.shader_param_locs.mu               = rl.GetShaderLocation(lenia.lenia_shader,  "mu")
    lenia.shader_param_locs.sigma            = rl.GetShaderLocation(lenia.lenia_shader,  "sigma")
    lenia.shader_param_locs.alpha            = rl.GetShaderLocation(lenia.lenia_shader,  "alpha")
    lenia.shader_param_locs.dt               = rl.GetShaderLocation(lenia.lenia_shader,  "dt")
}

@(private="file")
lenia_fill_with_random_noise :: proc (lenia: ^Lenia) {
    random_shader := shader_random_make(lenia.parameters.state_resolution > 0)
    buffer := lenia.buffers[0]

    seed := c.float(rand.float32() - 0.5)
    seed_loc := rl.GetShaderLocation(random_shader, "seed")
    rl.SetShaderValue(random_shader, seed_loc, &seed, .FLOAT)

    state_resolution: c.float = c.float(lenia.parameters.state_resolution)
    state_resolution_loc := rl.GetShaderLocation(random_shader, "stateResolution")
    rl.SetShaderValue(random_shader, state_resolution_loc, &state_resolution, .FLOAT)

    rl.BeginTextureMode(buffer)
        rl.BeginShaderMode(random_shader)
            rl.DrawTexture(buffer.texture, 0, 0, rl.WHITE)
        rl.EndShaderMode()
    rl.EndTextureMode()

    rl.UnloadShader(random_shader)
}

@(private="file")
lenia_init_render_buffers :: proc (lenia: ^Lenia) {
    if lenia.grid_size == lenia.buffers[0].texture.width {
        return
    }

    rl.UnloadRenderTexture(lenia.buffers[0])
    rl.UnloadRenderTexture(lenia.buffers[1])

    lenia.buffers = {
        load_render_texture_with_format(i32(lenia.grid_size), i32(lenia.grid_size), .UNCOMPRESSED_R32),
        load_render_texture_with_format(i32(lenia.grid_size), i32(lenia.grid_size), .UNCOMPRESSED_R32),
    }

    rl.SetTextureWrap(lenia.buffers[0].texture, .REPEAT)
    rl.SetTextureFilter(lenia.buffers[0].texture, .POINT)

    rl.SetTextureWrap(lenia.buffers[1].texture, .REPEAT)
    rl.SetTextureFilter(lenia.buffers[1].texture, .POINT)

    lenia_fill_with_random_noise(lenia)
}

@(private="file")
lenia_load_shaders :: proc (lenia: ^Lenia) {
    rl.UnloadShader(lenia.lenia_shader)
    rl.UnloadShader(lenia.visual_shader)

    lenia.kernel_shader = shader_kernel_make()
    lenia.lenia_shader  = shader_lenia_make(lenia.parameters.growth_function, lenia.parameters.state_resolution > 0)
    lenia.visual_shader = shader_visual_make()

    lenia_set_shader_param_locs(lenia)
    lenia_update_shader_params(lenia)
}

@(private="file")
lenia_init_kernel :: proc (lenia: ^Lenia) {
    rl.UnloadTexture(lenia.kernel)

    lenia.kernel, lenia.max_kernel_value = kernel_new(
        lenia.parameters.spatial_resolution, lenia.parameters.kernel_peaks[:], lenia.parameters.kernel_core, lenia.parameters.alpha)
}
