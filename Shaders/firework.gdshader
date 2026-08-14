shader_type canvas_item;


uniform vec2 mouse = vec2(0.0);
uniform vec2 resolution = vec2(1.0);

#define NUM_EXPLOSIONS 2.0
#define NUM_PARTICLES 64.0
#define inv_nparticels (4.0 / NUM_PARTICLES)
#define PI 3.1415926

float hash11(float t) {
    return fract(sin(t * 613.2) * 614.8);
}

vec2 hash12(float t) {
    return vec2(fract(sin(t * 213.3) * 314.8) - 0.5,
                fract(sin(t * 591.1) * 647.2) - 0.5);
}

vec2 hash12_polar(float t) {
    float o = fract(sin(t * 213.3) * 314.8) * PI * 2.0;
    float r = fract(sin(t * 591.1) * 647.2);
    return vec2(sin(o) * r, cos(o) * r);
}

float explosion(vec2 uv, float t) {
    float fract_t = fract(t);
    float floor_t = floor(t);
    float power = 0.3 + hash11(floor_t);
    float sparks = 0.0;

    for (float i = 0.0; i < NUM_PARTICLES; i++) {
        vec2 dir = hash12_polar(i * floor_t) * 1.0;
        float inv_d = 1.0 / (length(uv - dir * sqrt(fract_t)));
        float brightness = mix(0.3, 0.09, smoothstep(0.0, 0.1, fract_t))
            * (1.0 - (0.5 + 0.5 * hash11(i)) * fract_t);
        float sparkling = 0.5 + 0.5 * sin(t * 10.2 + floor_t * i);
        sparks += power * brightness * sparkling * inv_nparticels * inv_d;
    }

    return sparks;
}

void fragment() {
    vec2 uv = (UV - 0.5) * 2.0;
    uv.x *= SCREEN_PIXEL_SIZE.x > 0.0 ? (1.0 / SCREEN_PIXEL_SIZE.y) / (1.0 / SCREEN_PIXEL_SIZE.x) : 1.0;
    vec3 col = vec3(0.0);
	float time = TIME;
    for (float i = 0.0; i < NUM_EXPLOSIONS; i++) {
        float t = time * (0.3 + 0.4 * hash11(i)) + i / NUM_EXPLOSIONS;
        float fract_t = fract(t);
        float floor_t = floor(t);

        vec3 color = 0.7 + 0.3 * sin(vec3(0.34, 0.54, 0.43) * floor_t * i);
        vec2 center = hash12(i + 10.0 + 5.0 * floor_t);
        col += explosion(uv - center, t) * color;
    }

    col *= col / 0.9;
    COLOR = vec4(1.0 - exp2(-col), 1.0);
} 