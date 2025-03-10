package main

import "core:math"

// black box bullshitery
growth_mapping_polynomial :: proc (potential, growth_center, growth_width: f32, alpha: f32 = 4) -> f32 {
    if potential >= (growth_center - 3.0 * growth_width) && potential <= (growth_center + 3.0 * growth_width) {
        return 2.0 * math.pow(1.0 - math.pow(potential - growth_center, 2.0) / (9.0 * math.pow(growth_width, 2.0)), alpha) - 1.0
    } else {
        return -1.0
    }
}
