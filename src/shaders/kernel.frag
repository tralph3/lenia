#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

// Set by raylib
uniform sampler2D texture0;
uniform vec4 colDiffuse;
// ---

uniform float radius;
uniform float alpha;
// float[] peaks <- array is generated on kernel load

out vec4 finalColor;

float test[] = float[](1.0, 0.0, 0.0, 1.0);

float getPolarDistance(vec2 pointA, vec2 pointB) {
    vec2 d = pointB - pointA;
    return sqrt(dot(d, d));
}

kernel_shell :: proc(polar_distance: f32, peaks: []f32, alpha: f32 = 4) -> f32 {
    rank: f32 = f32(len(peaks))  // number of peaks in the shell

    br: f32 = rank * polar_distance          // scaling the rank will
                                             // decide on what peak
                                             // the cell falls on,
                                             // depending on polar
                                             // distance

    index: int = int(math.floor(br)) // we get the whole part to get
                                     // the index
    if index == int(rank) {
        index -= 1              // prevents out of bounds access. this
                                // condition will meet when the polar
                                // distance is exactly one (matrix
                                // corners)
    }

    frac: f32 = br - math.floor(br) // we get the fractional part to
                                    // calculate the influence of the
                                    // cell according to the kernel
                                    // core function

    return peaks[index] * kernel_core_exponential(frac, alpha)
}

void main() {
    float dimension = radius * 2 + 1;  // ensure odd numbers to have a
                                       // central cell

    float dx = 1.0 / dimension;
    vec2 kernelCenter = vec2(dimension / 2.0 - 0.5, dimension / 2.0 - 0.5);
    vec2 curCoord = fragTexCoord * dimension;
    float polarDistance = getPolarDistance(curCoord, kernelCenter);
    float normalizedDistance = polarDistance * dx;
    float shellValue = kernelShell(normalizedDistance);

    finalColor = vec4(shellValue, 1.0);

    normalize??
}
