#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

// Set by raylib
uniform sampler2D texture0;
uniform vec4 colDiffuse;
// ---

uniform float gridSize;
uniform sampler2D kernel;
uniform float kernelSize;
uniform float mu;
uniform float sigma;
uniform float alpha;
uniform float dt;
uniform float P;

out vec4 finalColor;

float discretize(float val) {
    float step = 1.0 / P;
    return round(val * P) * step;
}

float growth_mapping_polynomial(float potential) {
    float condition = float(potential >= (mu - 3.0 * sigma) && potential <= (mu + 3.0 * sigma));
    return 2.0 * condition * pow(1.0 - pow(potential - mu, 2.0) / (9.0 * pow(sigma, 2.0)), alpha) - 1.0;
}

float get_potential() {
    float half_height = kernelSize * 0.5 - 0.5;
    float half_width = kernelSize * 0.5 - 0.5;

    float cell_x = fragTexCoord.x * gridSize;
    float cell_y = fragTexCoord.y * gridSize;

    float result = 0.0;

    for (float h = 0; h < kernelSize; h += 1.0) {
        for (float w = 0; w < kernelSize; w += 1.0) {
            vec2 grid_coord = vec2((cell_x + (half_width - w)) / gridSize, (cell_y + (half_height - h)) / gridSize);
            float grid_val = texture(texture0, grid_coord).r;
            float kernel_val = texture(kernel, vec2(w / kernelSize, h / kernelSize)).r;
            float weighted_value = grid_val * kernel_val;
            result += weighted_value;
        }
    }

    return result;
}

void main() {
    float potential = get_potential();
    float growth = growth_mapping_polynomial(potential);
    float cur_val = texture(texture0, fragTexCoord).r;
    float new_val = discretize(clamp(cur_val + dt * growth, 0.0, 1.0));

    finalColor = vec4(new_val, new_val, new_val, 1.0);
}
