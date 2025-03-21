// When the kernel is normalized, the values within are very
// small. This shader scales these values So they can be better
// appreciated when rendered on screen.
#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

// Set by raylib
uniform sampler2D texture0;
uniform vec4 colDiffuse;
// ----------

uniform float maxKernelVal;

out vec4 finalColor;

void main() {
    finalColor = texture(texture0, fragTexCoord) / maxKernelVal;
}
