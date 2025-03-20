float growth_mapping(float potential) {
    float condition = float(potential >= mu - sigma && potential <= mu + sigma);
    return 2.0 * condition - 1.0;
}

// float growth_mapping(float potential) {
//     if (potential == 0.125 * 2.0) {
//         return 0.0;
//     } if (potential == 0.125 * 3.0) {
//         return 1.0;
//     } else {
//         return -1.0;
//     }
// }
