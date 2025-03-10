package main

import "core:math"
import "core:fmt"

get_cell_potential :: proc (cell: [2]u32, grid: Grid, kernel: Grid) -> f32 {
    half_height: i32 = i32(kernel.height / 2)
    half_width: i32 = i32(kernel.width / 2)
    values := grid_new(kernel.width, kernel.height)

    for h in -half_height..=half_height {
        for w in -half_width..=half_width {
            coord: [2]i32 = {i32(cell.x) + w, i32(cell.y) + h}
            grid_val := get_grid(grid, coord.x, coord.y)
            kernel_coords: [2]i32 = {coord.x + half_width * 2, coord.y + half_height * 2}
            kernel_val := get_grid(kernel, kernel_coords.x, kernel_coords.y)
            weighted_value := grid_val * kernel_val
            set_grid(values, kernel_coords.x, kernel_coords.y, weighted_value)
        }
    }

    result := math.sum(values.mat)
    delete(values.mat)
    return result
}
