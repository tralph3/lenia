// Based on https://thebookofshaders.com/10/
float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898 + seed, 78.233 + seed))) * (43758.5453123 + seed));
}

void main() {
    finalColor = vec4(discretize(random(fragTexCoord.xy)), vec2(0), 1.0);
}
