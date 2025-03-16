package main

import "core:math"
import rl "vendor:raylib"
import "core:fmt"

kernel_make :: proc (radius: i32, peaks: []f32, kernel_core_type: KernelCoreType, alpha: f32 = 4) -> rl.Texture2D {
    dimensions: i32 = radius * 2 + 1  // ensure odd numbers to have a
                                      // central cell
    dx: f32 = 1 / f32(radius)
    kernel_matrix := make([]f32, dimensions * dimensions)
    defer delete(kernel_matrix)

    kernel_center: [2]i32 = { dimensions / 2, dimensions / 2 }

    for h in 0..<dimensions {
        for w in 0..<dimensions {
            polar_distance := min(get_euclidean_distance({w, h}, kernel_center) * dx, 1)
            shell_value := kernel_shell(polar_distance, peaks, kernel_core_type, alpha)
            kernel_matrix[dimensions * h + w] = shell_value
        }
    }

    normalize_kernel(kernel_matrix)

    return kernel_matrix_to_render_texture(kernel_matrix, dimensions)
}

@(private="file")
kernel_shell :: proc(polar_distance: f32, peaks: []f32, kernel_core_type: KernelCoreType, alpha: f32 = 4) -> f32 {
    rank: f32 = f32(len(peaks))  // number of peaks in the shell

    br: f32 = rank * polar_distance          // scaling the rank will
                                             // decide on what peak
                                             // the cell falls on,
                                             // depending on polar
                                             // distance

    index: int = int(math.floor(br)) // we get the whole part to get
                                     // the index
    if index == int(rank) {
        index -= 1              // prevents out of bounds access. this
                                // condition will meet when the polar
                                // distance is exactly one (matrix
                                // corners)
    }

    frac: f32 = br - math.floor(br) // we get the fractional part to
                                    // calculate the influence of the
                                    // cell according to the kernel
                                    // core function
    switch kernel_core_type {
    case .Rectangular:
        return peaks[index] * kernel_core_rectangular(frac)
    case .RectangularGol:
        return peaks[index] * kernel_core_rectangular_gol(frac)
    case .Polynomial:
        return peaks[index] * kernel_core_polynomial(frac, alpha)
    case .Exponential:
        return peaks[index] * kernel_core_exponential(frac, alpha)
    }

    return -1
}

@(private="file")
kernel_matrix_to_render_texture :: proc (kernel_matrix: []f32, dimensions: i32) -> rl.Texture2D {
    kernel_image := rl.GenImageColor(dimensions, dimensions, rl.RED)
    defer rl.UnloadImage(kernel_image)

    for h in 0..<dimensions {
        for w in 0..<dimensions {
            val := kernel_matrix[dimensions * h + w]
            rl.ImageDrawPixel(&kernel_image, w, h, { u8(val * 1000 * 255), 0, 0, 255})
        }
    }

    return rl.LoadTextureFromImage(kernel_image)
}

@(private="file")
get_euclidean_distance :: proc (point_a, point_b: [2]i32) -> f32 {
    d := point_b - point_a
    return math.sqrt(f32(d.x * d.x + d.y * d.y))
}

@(private="file")
normalize_kernel :: proc (kernel_matrix: []f32) {
    total := math.sum(kernel_matrix)

    for i in 0..<len(kernel_matrix) {
        kernel_matrix[i] /= total
    }
}
