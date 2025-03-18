package main

SimulationState :: struct {
    running: bool,
    lenia: Lenia,
    fps: i32,
    panning: bool,
    can_pan: bool,
}

SIMULATION_STATE: SimulationState = {
    running = false,
    panning = false,
    can_pan = true,
    fps = 60,
}
