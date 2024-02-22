#version 450

layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 col;

layout(set = 0, binding = 0) uniform Camera {
    mat4 view;
    mat4 projection;
} camera;

layout(set = 0, binding = 1) uniform UBO {
    mat4 model;
} ubo;

layout(location = 0) out vec3 fragCol;

void main() {
    gl_Position = camera.projection * camera.view * ubo.model * vec4(pos, 1.0);
    // gl_Position = vec4(pos, 1.0);
    fragCol = col;
}