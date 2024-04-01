#version 460

layout(location = 0) in vec3 fragCol;
layout(location = 1) in vec2 fragUV;
layout(location = 2) in vec3 fragNormal;

layout(set = 1, binding = 0) uniform Light {
    vec4 color;
    vec4 direction;
    float ambientIntensity;
    float diffuseIntensity;
} light;

layout(set = 2, binding = 0) uniform sampler2D textureSampler;

layout(location = 0) out vec4 outColor;

void main() {
    vec4 ambientColor = light.color * light.ambientIntensity;

    // A.B = |A| * |B| * cos(theta), since we normalize A and B, it is 1 * 1 * cos(theta) = cos(theta)
    vec3 lightDir = normalize(-light.direction.xyz);
    float diffuseFactor = max(dot(fragNormal, lightDir), 0.0f);
    vec4 diffuseColor = light.color * light.diffuseIntensity * diffuseFactor;

    outColor = texture(textureSampler, fragUV) * (ambientColor + diffuseColor);
}