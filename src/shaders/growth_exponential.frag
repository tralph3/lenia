float growth_mapping(float potential) {
    return 2.0 * exp(- pow(potential - mu, 2.0) / (2.0 * pow(sigma, 2.0))) - 1.0;
}
