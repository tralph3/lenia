package main

import "core:math"

kernel_core_rectangular :: proc (polar_distance: f32) -> f32 {
    return f32(int(polar_distance >= 0.25 && polar_distance <= 0.75))
}

kernel_core_rectangular_gol :: proc (polar_distance: f32) -> f32 {
    condition_one := f32(int(polar_distance >= 0.25 && polar_distance <= 0.75))
    condition_two := f32(int(polar_distance >= 0 && polar_distance < 0.25))
    return condition_one + 0.5 * condition_two
}

kernel_core_polynomial :: proc (polar_distance, alpha: f32) -> f32 {
    return math.pow((4 * polar_distance * (1 - polar_distance)), alpha)
}

kernel_core_exponential :: proc (polar_distance, alpha: f32) -> f32 {
    return math.exp(alpha - alpha / (4 * polar_distance * (1 - polar_distance)))
}
