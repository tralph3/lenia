float discretize(float val) {
    float step = 1.0 / P;
    return round(val * P) * step;
}
