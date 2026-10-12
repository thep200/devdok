// Hue-keyed glow: only pixels whose hue matches the editor's function color
// emit a halo, so function/method names glow while the rest of the text
// stays crisp. Keyed on hue (not exact color) so anti-aliased glyph edges,
// which are the text color mixed with the gray background, still match.

// --- CONFIGURATION ---
const float TARGET_HUE = 269.0; // hue of the function color (#d2a8ff), degrees
const float HUE_RANGE = 12.0; // half-width of the accepted hue window, degrees (narrow: string quotes at hue ~283 must stay out)
const float MIN_SAT = 0.12; // rejects gray/white pixels
const float MIN_VAL = 0.78; // pixels this bright emit at full strength (function text)
// Dimmer pixels of the same hue (the nvim jump-bump rings, which are the
// function color blended into the background) emit a weaker glow.
const float DIM_MIN_VAL = 0.25; // below this nothing emits
const float DIM_GLOW = 0.3; // strength relative to full; 0.0 turns the ring glow off
const float RADIUS = 9.0; // halo radius in pixels
const float INTENSITY = 1.5; // halo strength
const float JITTER = 1.0; // 0.0 disables the per-pixel pattern rotation

// --- CONSTANTS ---
const int SAMPLES = 16; // texture reads per pixel; the main cost of this shader
// Rotation by the golden angle (2.39996323 rad), precomputed so the loop
// needs no trigonometry
const mat2 GOLDEN_ROTATION = mat2(-0.73736888, 0.67549029, -0.67549029, -0.73736888);

// Returns (hue in degrees, saturation, value)
vec3 rgbToHsv(vec3 c) {
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float delta = maxC - minC;

    float hue = 0.0;
    if (delta > 0.0001) {
        if (maxC == c.r) {
            hue = mod((c.g - c.b) / delta, 6.0);
        } else if (maxC == c.g) {
            hue = (c.b - c.r) / delta + 2.0;
        } else {
            hue = (c.r - c.g) / delta + 4.0;
        }
        hue *= 60.0;
    }
    float sat = maxC > 0.0001 ? delta / maxC : 0.0;
    return vec3(hue, sat, maxC);
}

// How strongly a pixel emits glow, 0.0 to 1.0
float emitMask(vec3 color) {
    vec3 hsv = rgbToHsv(color);
    float hueDist = abs(hsv.x - TARGET_HUE);
    hueDist = min(hueDist, 360.0 - hueDist);

    float hueMatch = 1.0 - smoothstep(HUE_RANGE * 0.5, HUE_RANGE, hueDist);
    float satMatch = smoothstep(MIN_SAT, MIN_SAT * 2.0, hsv.y);
    float brightMatch = smoothstep(MIN_VAL - 0.1, MIN_VAL + 0.1, hsv.z);
    float dimMatch = smoothstep(DIM_MIN_VAL - 0.08, DIM_MIN_VAL + 0.08, hsv.z);
    float valMatch = max(brightMatch, DIM_GLOW * dimMatch);
    return hueMatch * satMatch * valMatch;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 invRes = 1.0 / iResolution.xy;
    vec4 base = texture(iChannel0, fragCoord * invRes);

    // Per-pixel rotation of the sample pattern: with few taps a fixed pattern
    // shows up as faint shifted copies of the text; rotating it per pixel
    // turns those copies into a smooth-looking halo.
    float startAngle = JITTER * 6.2831853 *
            fract(52.9829189 * fract(dot(fragCoord, vec2(0.06711056, 0.00583715))));
    vec2 dir = vec2(cos(startAngle), sin(startAngle));

    vec3 glow = vec3(0.0);
    float weightSum = 0.0;
    for (int i = 0; i < SAMPLES; i++) {
        float t = (float(i) + 0.5) / float(SAMPLES);
        vec2 offset = dir * (sqrt(t) * RADIUS); // sqrt: uniform coverage of the disc

        vec3 sampleColor = texture(iChannel0, (fragCoord + offset) * invRes).rgb;
        float falloff = 1.0 - 0.63 * t;
        float weight = falloff * falloff; // cheap stand-in for exp(-2t)
        glow += sampleColor * emitMask(sampleColor) * weight;
        weightSum += weight;

        dir = GOLDEN_ROTATION * dir;
    }
    glow /= weightSum;

    fragColor = vec4(base.rgb + glow * INTENSITY, base.a);
}
