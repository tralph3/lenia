float growth_mapping(float potential) {
    float condition = float(potential >= mu - sigma && potential <= mu + sigma);
    return 2.0 * condition - 1.0;
}
