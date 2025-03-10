package main

import "core:math"
import "core:math/rand"

Grid :: struct {
    mat: []f32,
    width: u32,
    height: u32,
}

get_polar_distance :: proc (point_a, point_b: [2]u32) -> f32 {
    d := point_b - point_a
    return math.sqrt(f32(d.x * d.x + d.y * d.y))
}

set_grid :: proc (grid: Grid, x, y: i32, val: f32) {
    wrapped_x: u32 = u32(proper_mod(x, grid.width))
    wrapped_y: u32 = u32(proper_mod(y, grid.height))
    grid.mat[grid.width * wrapped_y + wrapped_x] = val
}

get_grid :: proc (grid: Grid, x, y: i32) -> f32 {
    wrapped_x: u32 = u32(proper_mod(x, grid.width))
    wrapped_y: u32 = u32(proper_mod(y, grid.height))
    return grid.mat[grid.width * wrapped_y + wrapped_x]
}

generate_main_grid_random :: proc (width: u32, height: u32) -> Grid {
    result := grid_new(width, height)

    for h in 0..<height {
        for w in 0..<width {
            set_grid(result, i32(w), i32(h), rand.float32())
        }
    }

    return result
}

grid_new :: proc (width, height: u32) -> Grid {
    return {
        mat = make([]f32, width * height),
        width = width,
        height = height,
    }
}

sigmoid :: proc (x: f32) -> f32 {
    return math.pow(math.e, x) / (1 + math.pow(math.e, x))
}

generate_next_grid_state :: proc (grid: Grid, kernel: Grid, dt, mu, sigma: f32) {
    values := grid_new(grid.width, grid.height)
    defer delete(values.mat)

    for h in 0..<grid.height {
        for w in 0 ..<grid.width {
            potential := get_cell_potential({w, h}, grid, kernel)
            growth := growth_mapping_polynomial(potential, mu, sigma)
            val := get_grid(grid, i32(w), i32(h))
            new_val := val + dt * growth
            new_val_clipped: f32 = min(max(new_val, 0), 1)
            set_grid(values, i32(w), i32(h), new_val_clipped)
        }
    }

    for h in 0..<grid.height {
        for w in 0 ..<grid.width {
            val := get_grid(values, i32(w), i32(h))
            set_grid(grid, i32(w), i32(h), val)
        }
    }
}
