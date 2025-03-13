package main

import rl "vendor:raylib"
import "core:os"
import "core:strings"

shader_lenia_make :: proc (growth: GrowthFunctionType, discretize: bool) -> rl.Shader {
    builder := strings.builder_make()

    shader_pre, _ := os.read_entire_file("src/shaders/lenia_pre.frag")
    shader_post, _ := os.read_entire_file("src/shaders/lenia_post.frag")

    strings.write_bytes(&builder, shader_pre)

    bytes: []byte
    switch growth {
    case .Rectangular:
        bytes, _ = os.read_entire_file("src/shaders/growth_rectangular.frag")
    case .Polynomial:
        bytes, _ = os.read_entire_file("src/shaders/growth_polynomial.frag")
    case .Exponential:
        bytes, _ = os.read_entire_file("src/shaders/growth_exponential.frag")
    }
    strings.write_bytes(&builder, bytes)
    delete(bytes)

    if discretize {
        bytes, _ = os.read_entire_file("src/shaders/discretize_normal.frag")
    } else {
        bytes, _ = os.read_entire_file("src/shaders/discretize_nullified.frag")
    }
    strings.write_bytes(&builder, bytes)
    delete(bytes)

    strings.write_bytes(&builder, shader_post)

    shader, _ := strings.to_cstring(&builder)

    delete(shader_pre)
    delete(shader_post)

    return rl.LoadShaderFromMemory(nil, shader)
}
