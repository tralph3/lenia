float discretize(float val) {
    float step = 1.0 / stateResolution;
    return round(val * stateResolution) * step;
}
