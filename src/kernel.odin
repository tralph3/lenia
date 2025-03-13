package main

import "core:math"
import "core:fmt"

generate_kernel :: proc (radius: i32, peaks: []f32, alpha: f32 = 4) -> Grid {
    diameter: i32 = radius * 2 + 1  // ensure odd numbers to have a
                                    // central cell

    kernel := grid_new(diameter, diameter)

    kernel_center: [2]i32 = {diameter / 2, diameter / 2}
    max_distance := get_polar_distance({0, 0}, kernel_center)
    for h in 0..<diameter {
        for w in 0..<diameter {
            polar_distance := min(1, get_polar_distance({w, h}, kernel_center) / max_distance)
            shell_value := kernel_shell(polar_distance, peaks, alpha)
            set_grid(kernel, i32(w), i32(h), 1)
        }
    }

    normalize_kernel(kernel)

    return kernel
}

kernel_core_exponential :: proc (polar_distance: f32, alpha: f32 = 4) -> f32 {
    return math.pow(math.e, (alpha - alpha / (4 * polar_distance * (1 - polar_distance))))
}

kernel_core :: proc (polar_distance: f32, alpha: f32 = 4) -> f32 {
    return math.pow((4 * polar_distance * (1 - polar_distance)), alpha)
}

kernel_shell :: proc(polar_distance: f32, peaks: []f32, alpha: f32 = 4) -> f32 {
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

    return peaks[index] * kernel_core_exponential(frac, alpha)
}

normalize_kernel :: proc (kernel: Grid) {
    total := math.sum(kernel.mat)

    for i in 0..<len(kernel.mat) {
        kernel.mat[i] /= total
    }
}
