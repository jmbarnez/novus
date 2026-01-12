extern float time;
extern float duration;
extern vec2 explosionCenter;

float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    float t = clamp(time / duration, 0.0, 1.0);
    vec2 p = texture_coords;
    
    vec2 center = (length(explosionCenter) < 0.001) ? vec2(0.5, 0.5) : explosionCenter;
    vec2 toCenter = p - center;
    float dist = length(toCenter);
    vec2 dir = normalize(toCenter + 0.0001);
    
    // Simple expansion - pieces fly outward
    float expansion = pow(t, 0.7) * 0.4;
    vec2 offset = dir * expansion * (0.5 + dist);
    
    // Add some random scatter per-fragment
    float scatter = random(floor(p * 32.0)) * 0.15 * t;
    offset += dir * scatter;
    
    // Slight upward drift (smoke rises)
    offset.y -= t * t * 0.08;
    
    vec2 uv = p - offset;
    
    // Bounds check
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0);
    }
    
    vec4 texColor = Texel(texture, uv);
    if (texColor.a < 0.01) {
        return vec4(0.0);
    }
    
    // Flash at start, fade to orange/red, then darken
    float flash = (1.0 - smoothstep(0.0, 0.15, t));
    float heat = (1.0 - smoothstep(0.1, 0.6, t)) * (1.0 - dist);
    
    // Color: white flash -> orange fire -> dark smoke
    vec3 fireColor = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.8, 0.3), heat);
    vec3 finalColor = texColor.rgb;
    finalColor = mix(finalColor, fireColor, heat * 0.8);
    finalColor += vec3(1.0) * flash * 0.5; // white flash
    finalColor = mix(finalColor, texColor.rgb * 0.3, smoothstep(0.5, 1.0, t)); // darken late
    
    // Alpha: start full, fade out
    float alpha = texColor.a;
    alpha *= 1.0 - smoothstep(0.6, 1.0, t); // fade out
    alpha *= 1.0 - smoothstep(0.8, 1.2, dist + t * 0.5); // fade edges
    
    if (alpha < 0.01) {
        discard;
    }
    
    return vec4(finalColor, alpha) * color;
}
