#version 110
// CyberNeon Glitch shader (GLSL 1.10 / compatibility). Original. FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED.
// u_glitch: 0 = clean window, 1 = full glitch (RGB split, displaced slices, scanlines, cyan flashes).
uniform sampler2D sampler;
uniform vec4 modulation;
uniform float u_glitch;
varying vec2 texcoord0;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main()
{
    float g = clamp(u_glitch, 0.0, 1.0);
    float tick = floor(g * 14.0);                       // the slices jump 14 times during the animation
    vec2 uv = texcoord0;
    float band = floor(uv.y * 26.0);
    if (hash(band * 13.7 + tick * 7.1) > 0.6)
        uv.x += (hash(band + tick * 3.3) - 0.5) * 0.14 * g;
    float split = 0.014 * g;
    vec4 c = texture2D(sampler, uv);
    c.r = texture2D(sampler, uv + vec2(split, 0.0)).r;
    c.b = texture2D(sampler, uv - vec2(split, 0.0)).b;
    if (uv.x < 0.0 || uv.x > 1.0) c = vec4(0.0);
    c.rgb *= 1.0 - 0.22 * g * step(0.5, fract(texcoord0.y * 160.0));
    c.rgb += vec3(0.36, 0.93, 0.86) * 0.16 * g * step(0.82, hash(band * 3.1 + tick)) * c.a;
    gl_FragColor = c * modulation;
}
