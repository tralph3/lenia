package main

SimulationState :: struct {
    running: bool,
    lenia: Lenia,
    fps: i32,
}

SIMULATION_STATE: SimulationState = {
    running = false,
    fps = 60,
}
