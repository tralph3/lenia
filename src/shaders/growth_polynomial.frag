float growth_mapping(float potential) {
    float condition = float(potential >= (mu - 3.0 * sigma) && potential <= (mu + 3.0 * sigma));
    return 2.0 * condition * pow(1.0 - pow(potential - mu, 2.0) / (9.0 * pow(sigma, 2.0)), alpha) - 1.0;
}
