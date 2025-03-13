package main

import "core:fmt"
import rl "vendor:raylib"

GUI_BUTTON_SIZE :: [2]f32 { 200, 60 }
GUI_BUTTON_OFFSET :: 10

GUI_ELEMENT_INDEX: int = 0

get_element_sizing :: proc () -> rl.Rectangle {
    return {
        GUI_BUTTON_OFFSET,
        GUI_BUTTON_OFFSET + f32(GUI_ELEMENT_INDEX) * (GUI_BUTTON_SIZE.y + GUI_BUTTON_OFFSET),
        GUI_BUTTON_SIZE.x, GUI_BUTTON_SIZE.y,
    }
}

draw_element :: proc (draw: proc ()) {
    draw()
    GUI_ELEMENT_INDEX += 1
}

draw_gui :: proc () {
    GUI_ELEMENT_INDEX = 0

    draw_element(proc () {
        rl.GuiToggle(get_element_sizing(), "Running", &SIMULATION_STATE.running)
    })
    draw_element(proc () {
        if rl.GuiButton(get_element_sizing(), "Reset") {
            lenia_reset(SIMULATION_STATE.lenia)
        }
    })
    draw_element(proc () {
        if rl.GuiButton(get_element_sizing(), "Step") {
            SIMULATION_STATE.running = false
            lenia_compute_simulation_step(SIMULATION_STATE.lenia)
        }
    })
}
