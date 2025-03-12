#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform vec2 resolution;

uniform sampler2D kernel;
uniform vec2 kernelSize;

uniform float mu;
uniform float sigma;
uniform float alpha;
uniform float dt;

// Output fragment color
out vec4 finalColor;

float growth_mapping_polynomial(float potential) {
    if (potential >= (mu - 3.0 * sigma) && potential <= (mu + 3.0 * sigma)) {
        return 2.0 * pow(1.0 - pow(potential - mu, 2.0) / (9.0 * pow(sigma, 2.0)), alpha) - 1.0;
    } else {
        return -1.0;
    }
}

float get_potential() {
    float half_height = kernelSize.x * 0.5 - 0.5;
    float half_width = kernelSize.y * 0.5 - 0.5;

    float cell_x = fragTexCoord.x * resolution.x;
    float cell_y = fragTexCoord.y * resolution.y;

    float result = 0.0;

    for (float h = 0; h < kernelSize.y; h += 1.0) {
        for (float w = 0; w < kernelSize.x; w += 1.0) {
            vec2 grid_coord = vec2((cell_x + (half_width - w)) / resolution.x, (cell_y + (half_height - h)) / resolution.y);
            float grid_val = texture(texture0, grid_coord).r;
            float kernel_val = texture(kernel, vec2(w / kernelSize.x, h / kernelSize.y)).r;
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
    float new_val = clamp(cur_val + dt * growth, 0.0, 1.0);

    finalColor = vec4(new_val, new_val, new_val, 1);
}
