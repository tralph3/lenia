package main

import "core:math"
import "core:fmt"

get_cell_potential :: proc (cell: [2]i32, grid: Grid, kernel: Grid) -> f32 {
    half_height: i32 = i32(kernel.height / 2)
    half_width: i32 = i32(kernel.width / 2)
    values := make([]f32, kernel.width * kernel.height)

    for h in 0..<kernel.height {
        for w in 0..<kernel.width {
            grid_coord: [2]i32 = { cell.x + (half_width - w), cell.y + (half_height - h) }
            grid_val := get_grid(grid, grid_coord.x, grid_coord.y)
            kernel_val := get_grid(kernel, w, h)
            weighted_value := grid_val * kernel_val
            values[h * kernel.width + w] = weighted_value
        }
    }

    result := math.sum(values)
    delete(values)
    return result
}
