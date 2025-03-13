package main

SimulationState :: struct {
    running: bool,
    lenia: ^Lenia,
}

SIMULATION_STATE: SimulationState = {
    running = false,
}
