#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

// Set by raylib
uniform sampler2D texture0;
uniform vec4 colDiffuse;
// ---

uniform float seed;
uniform float stateResolution;

out vec4 finalColor;
