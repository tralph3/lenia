package main

import "core:math"
import "core:testing"

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

@(private="file")
is_kernel_core_function :: proc (t: ^testing.T, func: proc (f32) -> f32) {
    testing.expect_value(t, 0, int(func(0)))
    testing.expect_value(t, 0, int(func(1)))
    testing.expect_value(t, 1, int(func(0.5)))
}

@(test)
kernel_core_rectangular_is_kernel_core_function :: proc (t: ^testing.T) {
    is_kernel_core_function(t, kernel_core_rectangular)
}

@(test)
kernel_core_rectangular_gol_is_kernel_core_function :: proc (t: ^testing.T) {
    is_kernel_core_function(t, kernel_core_rectangular_gol)
}

// @(test)
// kernel_core_polynomial_is_kernel_core_function :: proc (t: ^testing.T) {
//     is_kernel_core_function(t, kernel_core_polynomial)
// }

// @(test)
// kernel_core_exponential_is_kernel_core_function :: proc (t: ^testing.T) {
//     is_kernel_core_function(t, kernel_core_exponential)
// }
