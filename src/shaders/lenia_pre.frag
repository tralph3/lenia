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
