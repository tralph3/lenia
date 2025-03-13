package main

import rl "vendor:raylib"
import "core:os"
import "core:strings"

visual               := #load("shaders/visual.frag")

shader_pre           := #load("shaders/lenia_pre.frag")
shader_post          := #load("shaders/lenia_post.frag")

discretize_normal    := #load("shaders/discretize_normal.frag")
discretize_nullified := #load("shaders/discretize_nullified.frag")

growth_rectangular   := #load("shaders/growth_rectangular.frag")
growth_polynomial    := #load("shaders/growth_polynomial.frag")
growth_exponential   := #load("shaders/growth_exponential.frag")

shader_lenia_make :: proc (growth: GrowthFunctionType, discretize: bool) -> rl.Shader {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)

    strings.write_bytes(&builder, shader_pre)

    switch growth {
    case .Rectangular:
        strings.write_bytes(&builder, growth_rectangular)
    case .Polynomial:
        strings.write_bytes(&builder, growth_polynomial)
    case .Exponential:
        strings.write_bytes(&builder, growth_exponential)
    }

    if discretize {
        strings.write_bytes(&builder, discretize_normal)
    } else {
        strings.write_bytes(&builder, discretize_nullified)
    }

    strings.write_bytes(&builder, shader_post)

    shader, _ := strings.to_cstring(&builder)

    return rl.LoadShaderFromMemory(nil, shader)
}

shader_visual_make :: proc () -> rl.Shader {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)

    strings.write_bytes(&builder, visual)

    shader, _ := strings.to_cstring(&builder)

    return rl.LoadShaderFromMemory(nil, shader)
}
