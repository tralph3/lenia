#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

// Set by raylib
uniform sampler2D texture0;
uniform vec4 colDiffuse;
// ---

uniform float gridSize;
uniform float seed;

out vec4 finalColor;

// Based on https://thebookofshaders.com/10/
float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898 + seed, 78.233 + seed))) * (43758.5453123 + seed));
}

void main() {
    finalColor = vec4(vec3(random(fragTexCoord.xy)), 1.0);
}
