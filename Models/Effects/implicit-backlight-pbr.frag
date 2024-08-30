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

uniform vec3 emissive_color;
uniform float emissive_threshold;
uniform float emissive_brightness;

const float DEFAULT_METALLIC  = 0.0;
const float DEFAULT_ROUGHNESS = 0.1;

// gbuffer_pack.glsl
void gbuffer_pack(vec3 normal, vec3 base_color, float metallic, float roughness,
                  float occlusion, vec3 emissive, uint mat_id);
// color.glsl
vec3 eotf_inverse_sRGB(vec3 srgb);

// logarithmic_depth.glsl
float logdepth_encode(float z);

vec3 calc_emissive(vec3 color)
{
    float brightness = (color.r + color.b + color.g) / 3.0;
    if (brightness >= emissive_threshold)
    {
        return emissive_color * emissive_brightness * (brightness - emissive_threshold) / (1.0 - emissive_threshold);
    }
    else
    {
        return vec3(0.0);
    }
}

void main()
{
    vec3 texel = vec3(0.5);
    vec2 position = fs_in.texcoord;

    if (position.x >= 0.0 && position.y >= 0.0 && position.x < 1.0 && position.y < 1.0) {
        texel = texture(color_tex, position).rgb;
    }

    vec3 color = eotf_inverse_sRGB(texel) * fs_in.material_color.rgb;
    vec3 emissive = calc_emissive(texel);
    vec3 N = normalize(fs_in.vertex_normal);

    gbuffer_pack(N, color, DEFAULT_METALLIC, DEFAULT_ROUGHNESS, 1.0, emissive, 3u);

    gl_FragDepth = logdepth_encode(fs_in.flogz);
}

