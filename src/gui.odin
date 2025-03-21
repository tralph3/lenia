package main

import "core:fmt"
import rl "vendor:raylib"
import "core:c"
import "core:strings"
import "core:math"

GUI_ELEMENT_SIZE :: [2]f32 { 250, 40 }
GUI_ELEMENT_OFFSET :: 20

GUI_ELEMENT_INDEX: int = 0

GUI_STATUS_BAR_HEIGHT: f32 : 20

GUI_SIM_FPS_EDIT_MODE: c.bool = false
GUI_SPATIAL_RESOLUTION_EDIT_MODE: c.bool = false
GUI_STATE_RESOLUTION_EDIT_MODE: c.bool = false
GUI_TEMPORAL_RESOLUTION_EDIT_MODE: c.bool = false
GUI_GROWTH_EDIT_MODE: c.bool = false
GUI_KERNEL_EDIT_MODE: c.bool = false

GUI_FILTERING_ENABLED: c.bool = false

get_element_bounds :: proc () -> rl.Rectangle {
    return {
        GUI_ELEMENT_OFFSET,
        GUI_ELEMENT_OFFSET + f32(GUI_ELEMENT_INDEX) * (GUI_ELEMENT_SIZE.y + GUI_ELEMENT_OFFSET),
        GUI_ELEMENT_SIZE.x, GUI_ELEMENT_SIZE.y,
    }
}

draw_label :: proc(bounds: rl.Rectangle, label: cstring) {
    font := rl.GuiGetFont()
    rl.DrawText(label, i32(bounds.x), i32(bounds.y) - 10, font.baseSize, rl.WHITE)
}

draw_element :: proc (draw: proc ()) {
    draw()
    GUI_ELEMENT_INDEX += 1
}

draw_gui :: proc () {
    if SIMULATION_STATE.panning {
        rl.GuiLock()
    } else {
        rl.GuiUnlock()
    }

    GUI_ELEMENT_INDEX = 0

    draw_element(proc () {
        if rl.IsKeyPressed(.SPACE) {
            SIMULATION_STATE.running = !SIMULATION_STATE.running
        }
        rl.GuiToggle(get_element_bounds(), "Running", &SIMULATION_STATE.running)
    })

    draw_element(proc () {
        if rl.GuiButton(get_element_bounds(), "Reset") || rl.IsKeyPressed(.R) {
            lenia_reset(&SIMULATION_STATE.lenia)
            SIMULATION_STATE.running = false
        }
    })

    draw_element(proc () {
        if rl.GuiButton(get_element_bounds(), "Step") || rl.IsKeyPressed(.S) {
            SIMULATION_STATE.running = false
            lenia_compute_simulation_step(&SIMULATION_STATE.lenia)
        }
    })

    draw_element(proc () {
        prev_state := GUI_FILTERING_ENABLED

        bounds := get_element_bounds()
        draw_label(bounds, "Enable Bilinear Filtering")
        rl.GuiCheckBox(bounds, "", &GUI_FILTERING_ENABLED)

        if prev_state != GUI_FILTERING_ENABLED {
            lenia_toggle_texture_filtering(&SIMULATION_STATE.lenia)
        }
    })

    // provides spacing
    draw_element(proc () {})

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, "Simulation FPS")

        if bool(rl.GuiSpinner(bounds, "", &SIMULATION_STATE.fps, 1, 60, GUI_SIM_FPS_EDIT_MODE)) {
            GUI_SIM_FPS_EDIT_MODE = !GUI_SIM_FPS_EDIT_MODE
        }
    })

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, "Spatial Resolution")

        spatial_resolution := SIMULATION_STATE.lenia.parameters.spatial_resolution
        if bool(rl.GuiSpinner(bounds, "", &spatial_resolution,
                              1, 100, GUI_SPATIAL_RESOLUTION_EDIT_MODE)) {
            GUI_SPATIAL_RESOLUTION_EDIT_MODE = !GUI_SPATIAL_RESOLUTION_EDIT_MODE
        }

        lenia_update_spatial_resolution(&SIMULATION_STATE.lenia, spatial_resolution)
    })

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, "State Resolution")

        state_resolution := SIMULATION_STATE.lenia.parameters.state_resolution
        if bool(rl.GuiSpinner(bounds, "", &state_resolution,
                              0, 100, GUI_STATE_RESOLUTION_EDIT_MODE)) {
            GUI_STATE_RESOLUTION_EDIT_MODE = !GUI_STATE_RESOLUTION_EDIT_MODE
        }

        lenia_update_state_resolution(&SIMULATION_STATE.lenia, state_resolution)
    })

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, "Temporal Resolution")

        temporal_resolution := i32(SIMULATION_STATE.lenia.parameters.temporal_resolution)
        if bool(rl.GuiSpinner(bounds, "", &temporal_resolution,
                              1, 10000, GUI_TEMPORAL_RESOLUTION_EDIT_MODE)) {
            GUI_TEMPORAL_RESOLUTION_EDIT_MODE = !GUI_TEMPORAL_RESOLUTION_EDIT_MODE
        }

        lenia_update_temporal_resolution(&SIMULATION_STATE.lenia, f32(temporal_resolution))
    })

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, rl.TextFormat("Alpha: %2.2f", SIMULATION_STATE.lenia.parameters.alpha))

        alpha := SIMULATION_STATE.lenia.parameters.alpha
        rl.GuiSlider(bounds, "", "", &alpha, 0.1, 20.0)

        if rl.IsKeyDown(.LEFT_SHIFT) && rl.CheckCollisionPointRec(rl.GetMousePosition(), bounds) && rl.IsMouseButtonDown(.LEFT) {
            alpha = math.round(alpha)
        }

        lenia_update_alpha(&SIMULATION_STATE.lenia, alpha)
    })

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, rl.TextFormat("Mu (Growth Center): %2.2f", SIMULATION_STATE.lenia.parameters.mu))

        mu := SIMULATION_STATE.lenia.parameters.mu
        rl.GuiSlider(bounds, "", "", &mu, 0.0, 1.0)

        if rl.IsKeyDown(.LEFT_SHIFT) && rl.CheckCollisionPointRec(rl.GetMousePosition(), bounds) && rl.IsMouseButtonDown(.LEFT) {
            mu = math.round(mu)
        }

        lenia_update_mu(&SIMULATION_STATE.lenia, mu)
    })

    draw_element(proc () {
        bounds := get_element_bounds()
        draw_label(bounds, rl.TextFormat("Sigma (Growth Radius): %2.3f", SIMULATION_STATE.lenia.parameters.sigma))

        sigma := SIMULATION_STATE.lenia.parameters.sigma
        rl.GuiSlider(bounds, "", "", &sigma, 0.0, 1.0)

        if rl.IsKeyDown(.LEFT_SHIFT) && rl.CheckCollisionPointRec(rl.GetMousePosition(), bounds) && rl.IsMouseButtonDown(.LEFT) {
            sigma = math.round(sigma)
        }

        lenia_update_sigma(&SIMULATION_STATE.lenia, sigma)
    })

    draw_element(proc () {
        // TODO: cleanup this crap
        types: [dynamic]string
        for type in GrowthFunctionType {
            append(&types, fmt.tprint(type))
        }

        str := strings.join(types[:], ";")
        cstr := strings.clone_to_cstring(str)

        bounds := get_element_bounds()
        draw_label(bounds, "Growth Function")

        selected := c.int(SIMULATION_STATE.lenia.parameters.growth_function)
        if rl.GuiDropdownBox(bounds, cstr, &selected, GUI_GROWTH_EDIT_MODE) {
            GUI_GROWTH_EDIT_MODE = !GUI_GROWTH_EDIT_MODE
            if !GUI_GROWTH_EDIT_MODE {
                lenia_change_growth_function(&SIMULATION_STATE.lenia, GrowthFunctionType(selected))
            }
        }

        delete(str)
        delete(cstr)
        delete(types)
    })

    draw_element(proc () {
        // TODO: cleanup this crap
        types: [dynamic]string
        for type in KernelCoreType {
            append(&types, fmt.tprint(type))
        }

        str := strings.join(types[:], ";")
        cstr := strings.clone_to_cstring(str)

        bounds := get_element_bounds()
        draw_label(bounds, "Kernel Core")

        selected := c.int(SIMULATION_STATE.lenia.parameters.kernel_core)
        if rl.GuiDropdownBox(bounds, cstr, &selected, GUI_KERNEL_EDIT_MODE) {
            GUI_KERNEL_EDIT_MODE = !GUI_KERNEL_EDIT_MODE
            if !GUI_KERNEL_EDIT_MODE {
                lenia_change_kernel_core(&SIMULATION_STATE.lenia, KernelCoreType(selected))
            }
        }

        delete(str)
        delete(cstr)
        delete(types)
    })

    rl.GuiStatusBar(
        {
            0, f32(rl.GetRenderHeight()) - GUI_STATUS_BAR_HEIGHT,
            f32(rl.GetRenderWidth()), GUI_STATUS_BAR_HEIGHT,
        },
        "SPACE - Run/stop simulation | R - Restart simulation | S - Do single simulation step | Hold LEFT SHIFT on sliders to snap to whole numbers")

    // prevent panning the camera when the mouse is on top of gui
    // elements
    if !SIMULATION_STATE.panning && rl.CheckCollisionPointRec(rl.GetMousePosition(), rl.Rectangle {
        GUI_ELEMENT_OFFSET, GUI_ELEMENT_OFFSET,
        GUI_ELEMENT_SIZE.x, GUI_ELEMENT_OFFSET + f32(GUI_ELEMENT_INDEX) * (GUI_ELEMENT_SIZE.y + GUI_ELEMENT_OFFSET),
    }) {
        SIMULATION_STATE.can_pan = false
    } else {
        SIMULATION_STATE.can_pan = true
    }
}
