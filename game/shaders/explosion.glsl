extern float time;
extern float duration;
extern Image mainTex;
extern vec2 explosionCenter; // Center point of explosion in texture coords (default 0.5, 0.5)

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

// Improved pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D noise function for organic movement
float noise2D(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal brownian motion for complex turbulence
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise2D(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    float t = clamp(time / duration, 0.0, 1.0);
    vec2 p = texture_coords;

    // Use provided explosion center or default to texture center
    vec2 center = (length(explosionCenter) < 0.001) ? vec2(0.5, 0.5) : explosionCenter;
    vec2 toCenter = p - center;
    float dist = length(toCenter) + 1e-4;
    vec2 dir = toCenter / dist;

    // Temporal phases
    float ignitePhase = 1.0 - smoothstep(0.08, 0.28, t);   // quick flash
    float bloomPhase = smoothstep(0.0, 0.45, t);           // bulk expansion
    float driftPhase = smoothstep(0.2, 1.0, t);            // breakup / drift

    // Turbulent displacement and outward push
    float swirlNoise = fbm(p * 8.0 + t * 3.0);
    vec2 swirl = vec2(cos(swirlNoise * 6.283 + t * 6.0), sin(swirlNoise * 6.283 + t * 6.0));

    vec2 offset = dir * (0.25 * bloomPhase + dist * 0.35 * bloomPhase);
    offset += swirl * 0.05 * (0.5 + swirlNoise) * driftPhase;
    offset += (fbm(p * 20.0 + t * 8.0) - 0.5) * 0.06 * driftPhase;
    offset.y += driftPhase * driftPhase * 0.12; // soft gravity pull

    vec2 uv = p - offset;

    // Bounds check with soft edges
    vec2 edgeDist = min(uv, 1.0 - uv);
    float edgeFade = smoothstep(0.0, 0.05, min(edgeDist.x, edgeDist.y));

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0);
    }

    vec4 texColor = Texel(texture, uv);
    if (texColor.a < 0.01) {
        return vec4(0.0);
    }

    // Lighting layers
    float heat = saturate((1.0 - dist * 1.5) * (1.0 - smoothstep(0.35, 0.9, t)));
    float flash = ignitePhase * (1.0 - dist * 2.0);

    // Expanding shockwave ring
    float ringPos = mix(0.05, 1.1, t);
    float ringWidth = mix(0.08, 0.25, t);
    float ring = exp(-pow((dist - ringPos) / ringWidth, 2.0)) * driftPhase;

    // Smoke build-up towards the end
    float smoke = smoothstep(0.35, 1.0, t) * (1.0 - heat);

    // Sparkle fragments
    float sparkSeed = random(floor(p * 96.0) + floor(vec2(t * 24.0)));
    float sparks = step(0.97, sparkSeed) * ignitePhase * (1.0 - dist * 1.2);

    // Color composition
    vec3 base = texColor.rgb;
    vec3 fire = mix(vec3(0.95, 0.45, 0.12), vec3(1.0, 0.9, 0.55), heat);
    vec3 core = vec3(1.0, 0.98, 0.9) * flash;
    vec3 smokeColor = vec3(0.1, 0.08, 0.07);

    vec3 finalColor = base;
    finalColor = mix(finalColor, fire, clamp(heat * 1.5, 0.0, 1.0));
    finalColor += core * 1.6;
    finalColor += vec3(1.0, 0.75, 0.35) * ring * 1.3;
    finalColor = mix(finalColor, mix(finalColor, smokeColor, 0.7), smoke);
    finalColor += vec3(1.0, 0.85, 0.55) * sparks * 2.0;

    // Alpha shaping
    float alpha = texColor.a;
    alpha *= edgeFade;
    alpha *= (1.0 - smoothstep(0.55, 1.0, t));
    alpha *= (0.4 + heat * 0.8);
    alpha += ring * 0.4;
    alpha = max(alpha, sparks * 0.5);
    alpha *= (1.0 - smoothstep(0.75, 1.15, dist + t * 0.25));

    if (alpha < 0.01) {
        discard;
    }

    return vec4(finalColor, alpha) * color;
}
