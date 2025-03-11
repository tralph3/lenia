package main

import "core:math"
import "core:math/rand"
import "core:mem"
import "core:thread"
import "core:sync"

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

generate_main_grid_random :: proc (width: i32, height: i32) -> (Grid, Grid) {
    grid := grid_new(width, height)
    back_grid := grid_new(width, height)

    for h in 0..<height {
        for w in 0..<width {
            set_grid(grid, w, h, rand.float32())
        }
    }

    grid_data, grid_len := mem.slice_to_components(grid.mat)
    back_data, _ := mem.slice_to_components(back_grid.mat)

    mem.copy(back_data, grid_data, grid_len * size_of(f32))

    return grid, back_grid
}

grid_new :: proc (width, height: i32) -> Grid {
    return {
        mat = make([]f32, width * height),
        width = width,
        height = height,
    }
}

sigmoid :: proc (x: f32) -> f32 {
    return math.pow(math.e, x) / (1 + math.pow(math.e, x))
}

UpdateCellArgs :: struct {
    cell_range: [2]i32,
    grid: Grid,
    back_grid: Grid,
    kernel: Grid,
    dt: f32,
    mu: f32,
    sigma: f32,
    wg: ^sync.Wait_Group,
}

update_cell_state_task :: proc (task: thread.Task) {
    args := (^UpdateCellArgs)(task.data)^

    for i in args.cell_range.x..<args.cell_range.y {
        y, x := math.divmod(i, args.grid.width)

        potential := get_cell_potential({x, y}, args.grid, args.kernel)
        growth := growth_mapping_polynomial(potential, args.mu, args.sigma)
        val := args.grid.mat[i]
        new_val := val + args.dt * growth
        new_val_clipped: f32 = min(max(new_val, 0), 1)
        args.back_grid.mat[i] = new_val_clipped
    }

    free(task.data)
    sync.wait_group_done(args.wg)
}

update_grid_state :: proc (thread_pool: ^thread.Pool, grid: Grid, back_grid: Grid, kernel: Grid, dt, mu, sigma: f32) {
    cell_range: i32 = 40
    task_count: i32 = i32(len(grid.mat)) / cell_range
    remainder := i32(len(grid.mat)) - cell_range * task_count

    wg := sync.Wait_Group {}

    for i in 0..<task_count {
        sync.wait_group_add(&wg, 1)
        data := new(UpdateCellArgs)
        data.cell_range = { cell_range * i, cell_range * i + cell_range }
        data.grid = grid
        data.back_grid = back_grid
        data.kernel = kernel
        data.dt = dt
        data.mu = mu
        data.sigma = sigma
        data.wg = &wg

        thread.pool_add_task(thread_pool, context.allocator, update_cell_state_task, data)
    }

    if remainder > 0 {
        sync.wait_group_add(&wg, 1)
        data := new(UpdateCellArgs)
        data.cell_range = { i32(len(grid.mat)) - remainder, i32(len(grid.mat)) }
        data.grid = grid
        data.back_grid = back_grid
        data.kernel = kernel
        data.dt = dt
        data.mu = mu
        data.sigma = sigma
        data.wg = &wg

        thread.pool_add_task(thread_pool, context.allocator, update_cell_state_task, data)
    }

    sync.wait_group_wait(&wg)
}
