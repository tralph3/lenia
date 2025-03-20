#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

vec3 heatmap(float v) {
    v = clamp(v, 0.0, 1.0); // Ensure input stays in [0,1]

    // Adjust contrast to enhance mid-range details
    v = pow(v, 0.85);

    // Smoothly interpolate between color regions
    vec3 c1 = vec3(0.0, 0.0, 0.5);  // Dark Blue (Low)
    vec3 c2 = vec3(0.0, 0.5, 1.0);  // Light Blue
    vec3 c3 = vec3(0.0, 1.0, 1.0);  // Cyan
    vec3 c4 = vec3(1.0, 1.0, 0.0);  // Yellow
    vec3 c5 = vec3(1.0, 0.5, 0.0);  // Orange
    vec3 c6 = vec3(1.0, 0.0, 0.0);  // Red (High)

    vec3 color;
    if (v < 0.2) {
        color = mix(c1, c2, smoothstep(0.0, 0.2, v));
    } else if (v < 0.4) {
        color = mix(c2, c3, smoothstep(0.2, 0.4, v));
    } else if (v < 0.6) {
        color = mix(c3, c4, smoothstep(0.4, 0.6, v));
    } else if (v < 0.8) {
        color = mix(c4, c5, smoothstep(0.6, 0.8, v));
    } else {
        color = mix(c5, c6, smoothstep(0.8, 1.0, v));
    }

    return color;
}

void main() {
    float elevation = texture(texture0, fragTexCoord).r;
    elevation = pow(elevation, 1.5);

    vec3 color = heatmap(elevation);
    finalColor = vec4(color, 1.0);
}
