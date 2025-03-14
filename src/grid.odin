package main

import "core:math"

Grid :: struct {
    mat: []f32,
    width: i32,
    height: i32,
}

get_polar_distance :: proc (point_a, point_b: [2]i32) -> f32 {
    d := point_b - point_a
    return math.sqrt(f32(d.x * d.x + d.y * d.y))
}

set_grid :: proc (grid: Grid, x, y: i32, val: f32) {
    wrapped_x: i32 = i32(proper_mod(x, grid.width))
    wrapped_y: i32 = i32(proper_mod(y, grid.height))
    grid.mat[grid.width * wrapped_y + wrapped_x] = val
}

get_grid :: proc (grid: Grid, x, y: i32) -> f32 {
    wrapped_x: i32 = i32(proper_mod(x, grid.width))
    wrapped_y: i32 = i32(proper_mod(y, grid.height))
    return grid.mat[grid.width * wrapped_y + wrapped_x]
}

grid_new :: proc (width, height: i32) -> Grid {
    return {
        mat = make([]f32, width * height),
        width = width,
        height = height,
    }
}
