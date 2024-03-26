#version 460

float gridSize = 100.0;
float gridCellSize = 0.025;
vec4 gridColorThinLine = vec4(0.5, 0.5, 0.5, 1.0);
vec4 gridColorThickLine = vec4(0.0, 0.0, 0.0, 1.0);
const float gridMinPixelsBetweenCells = 2.0;

const vec3 grid_pos[4] = vec3[4](
	vec3(-1.0, 0.0, -1.0),
	vec3( 1.0, 0.0, -1.0),
	vec3( 1.0, 0.0,  1.0),
	vec3(-1.0, 0.0,  1.0)
);

const int grid_indices[6] = int[6](
	0, 1, 2, 2, 3, 0
);

layout(set = 0, binding = 0) uniform Camera {
    mat4 view;
    mat4 projection;
} camera;

// layout(location = 0) out vec2 gridUV;
// layout(location = 1) out vec3 cameraPos;

void main() {
    
    // vec3 worldPos = grid_pos[gl_VertexIndex];
    // vec4 clipPos = camera.projection * camera.view * vec4(worldPos, 1.0);
    // gl_Position = clipPos;
    
    // gridUV = worldPos.xz;
    // cameraPos = camera.view[3].xyz;
    
    // gl_PointSize = 1.0;

    gl_Position = vec4(grid_pos[grid_indices[gl_VertexIndex]], 1.0);
    
}