float get_potential() {
    float half_height = floor(kernelSize * 0.5);
    float half_width = floor(kernelSize * 0.5);

    float cell_x = fragTexCoord.x * gridSize;
    float cell_y = fragTexCoord.y * gridSize;

    float result = 0.0;

    for (float h = 0; h < kernelSize; h += 1.0) {
        for (float w = 0; w < kernelSize; w += 1.0) {
            vec2 grid_coord = vec2((cell_x + (half_width - w)), (cell_y + (half_height - h))) / gridSize;
            float grid_val = texture(texture0, grid_coord).r;
            float kernel_val = texture(kernel, vec2(w, h) / kernelSize).r;
            float weighted_value = grid_val * kernel_val;
            result += weighted_value;
        }
    }

    return result;
}

void main() {
    float potential = get_potential();
    float growth = growth_mapping(potential);
    float cur_val = texture(texture0, fragTexCoord).r;
    float new_val = discretize(clamp(cur_val + dt * growth, 0.0, 1.0));

    finalColor = vec4(vec3(new_val), 1.0);
}
