package main

import "core:fmt"
import rl "vendor:raylib"
import "core:c"
import "core:strings"
import "core:math"

GUI_ELEMENT_SIZE :: [2]f32 { 200, 40 }
GUI_ELEMENT_OFFSET :: 20

GUI_ELEMENT_INDEX: int = 0

GUI_STATUS_BAR_HEIGHT: f32 : 20

GUI_SIM_FPS_EDIT_MODE: c.bool = false
GUI_PRECISION_EDIT_MODE: c.bool = false
GUI_GROWTH_EDIT_MODE: c.bool = false

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
    // in case it was locked in the previous frame
    rl.GuiUnlock()

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
        draw_label(bounds, "Precision")

        precision := SIMULATION_STATE.lenia.parameters.precision
        if bool(rl.GuiSpinner(bounds, "", &precision,
                              0, 100, GUI_PRECISION_EDIT_MODE)) {
            GUI_PRECISION_EDIT_MODE = !GUI_PRECISION_EDIT_MODE
        }

        lenia_update_precision(&SIMULATION_STATE.lenia, precision)
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
        draw_label(bounds, rl.TextFormat("Sigma (Growth Radius): %2.2f", SIMULATION_STATE.lenia.parameters.sigma))

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

    // prevent panning the camera when the mouse is on top of gui
    // elements
    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rl.Rectangle {
        GUI_ELEMENT_OFFSET, GUI_ELEMENT_OFFSET,
        GUI_ELEMENT_SIZE.x, GUI_ELEMENT_OFFSET + f32(GUI_ELEMENT_INDEX) * (GUI_ELEMENT_SIZE.y + GUI_ELEMENT_OFFSET),
    }) {
        rl.GuiLock()
    }

    rl.GuiStatusBar(
        {
            0, f32(rl.GetRenderHeight()) - GUI_STATUS_BAR_HEIGHT,
            f32(rl.GetRenderWidth()), GUI_STATUS_BAR_HEIGHT,
        },
        "SPACE - Run/stop simulation | R - Restart simulation | S - Do single simulation step | Hold LEFT SHIFT on sliders to snap to whole numbers")
}
