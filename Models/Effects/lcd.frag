#version 330 core

layout(location = 0) out vec4 out_gbuffer0;
layout(location = 1) out vec4 out_gbuffer1;
layout(location = 2) out vec4 out_gbuffer2;
layout(location = 3) out vec3 out_gbuffer3;

in VS_OUT {
    float flogz;
    vec2 texcoord;
    vec3 vertex_normal;
    vec4 material_color;
} fs_in;

uniform sampler2D color_tex;
uniform sampler2D dirt_tex;

uniform float Brightness;
uniform float Threshold;
uniform float DirtFactor;

const float DEFAULT_METALLIC  = 0.0;
const float DEFAULT_ROUGHNESS = 0.1;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);

// logarithmic_depth.glsl
float logdepth_encode(float z);

vec3 backlight(vec3 color)
{
    color.r = color.r * (1 - Threshold) + Threshold;
    color.g = color.g * (1 - Threshold) + Threshold;
    color.b = color.b * (1 - Threshold) + Threshold;
    return color;
}

void main()
{
    vec3 texel = vec3(0.5);
    vec2 position = fs_in.texcoord;

    if(position.x > 0.0 && position.y > 0.0 && position.x < 1.0 && position.y < 1.0) {
        texel = texture(color_tex, position).rgb;
        texel = backlight(texel);
    }
    // texel = mix(texel, vec3(1.0), DirtFactor * texture(dirt_tex, fs_in.texcoord).r);

    // vec3 color = eotf_inverse_sRGB(texel) * fs_in.material_color.rgb;
    vec3 color = vec3(Threshold);

    vec3 N = normalize(fs_in.vertex_normal);

    gbuffer_pack(N, color, DEFAULT_METALLIC, DEFAULT_ROUGHNESS, 1.0, texel * Brightness, 3u);

    gl_FragDepth = logdepth_encode(fs_in.flogz);
}
