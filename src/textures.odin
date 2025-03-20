package main

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

load_render_texture_with_format :: proc (width, height: i32, format: rl.PixelFormat) -> rl.RenderTexture2D {
    target: rl.RenderTexture2D

    target.id = rlgl.LoadFramebuffer(width, height)

    if (target.id > 0) {
        rlgl.EnableFramebuffer(target.id)

        target.texture = load_texture_with_format(width, height, format)

        target.depth.id = rlgl.LoadTextureDepth(width, height, true)
        target.depth.width = width
        target.depth.height = height
        target.depth.format = rl.PixelFormat(19)
        target.depth.mipmaps = 1

        rlgl.FramebufferAttach(
            target.id, target.texture.id, i32(rlgl.FramebufferAttachType.COLOR_CHANNEL0), i32(rlgl.FramebufferAttachTextureType.TEXTURE2D), 0)
        rlgl.FramebufferAttach(
            target.id, target.depth.id, i32(rlgl.FramebufferAttachType.DEPTH), i32(rlgl.FramebufferAttachTextureType.RENDERBUFFER), 0)

        if (rlgl.FramebufferComplete(target.id)) {
            rl.TraceLog(.INFO, "FBO: [ID %i] Framebuffer object created successfully", target.id)
        }

        rlgl.DisableFramebuffer()
    } else {
        rl.TraceLog(.WARNING, "FBO: Framebuffer object can not be created")
    }

    return target
}


load_texture_with_format :: proc (width, height: i32, format: rl.PixelFormat) -> rl.Texture2D {
    texture: rl.Texture2D

    texture.id = rlgl.LoadTexture(nil, width, height, i32(format), 1)
    texture.width = width
    texture.height = height
    texture.format = format
    texture.mipmaps = 1

    return texture
}
