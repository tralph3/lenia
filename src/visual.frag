#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main() {
    vec4 cur_col = texture(texture0, fragTexCoord);
    finalColor = mix(cur_col, fragColor, cur_col.r);
}
