#version 460

vec3 gridPlane[6] = vec3[](
    vec3(1, 1, 0), vec3(-1, -1, 0), vec3(-1, 1, 0),
    vec3(-1, -1, 0), vec3(1, 1, 0), vec3(1, -1, 0)
);

layout(set = 0, binding = 0) uniform Camera {
    mat4 view;
    mat4 projection;
} camera;

layout(location = 0) out float near;
layout(location = 1) out float far;
layout(location = 2) out vec3 nearPoint;
layout(location = 3) out vec3 farPoint;
layout(location = 4) out mat4 view;
layout(location = 8) out mat4 projection;

vec3 unprojectPoint(float x, float y, float z, mat4 view, mat4 projection) {
    vec4 clipSpace = vec4(x, y, z, 1.0);
    vec4 eyeSpace = inverse(projection) * clipSpace;
    vec4 worldSpace = inverse(view) * eyeSpace;
    return worldSpace.xyz / worldSpace.w;
}

void main() {
    vec3 point = gridPlane[gl_VertexIndex];

    near = 0.1;
    far = 100.0;
    nearPoint = unprojectPoint(point.x, point.y, 0.0, camera.view, camera.projection).xyz;
    farPoint = unprojectPoint(point.x, point.y, 1.0, camera.view, camera.projection).xyz;
    view = camera.view;
    projection = camera.projection;

    gl_Position = vec4(point, 1.0);
}

