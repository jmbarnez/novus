// Shield - only visible on impact, then fades out
// Shows bright shield sphere + ripple effect starting at impact point

extern float time;         // Current animation time for ripple
extern float duration;     // Total duration of the effect
extern vec2 hitPos;        // Impact position in normalized coords (0-1)
extern float shieldRadius; // Normalized shield radius

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 center = vec2(0.5, 0.5);
    vec2 p = texture_coords - center;
    float dist = length(p);
    
    float t = time / duration;
    
    // === SHIELD VISIBILITY (fades in on impact, fades out over time) ===
    float shieldVisibility = 1.0 - smoothstep(0.5, 1.0, t);
    
    // Shield edge
    float edgeGlow = smoothstep(shieldRadius - 0.06, shieldRadius, dist) * 
                     (1.0 - smoothstep(shieldRadius, shieldRadius + 0.02, dist));
    
    // Inner fill
    float innerFill = (1.0 - smoothstep(0.0, shieldRadius, dist)) * 0.15;
    
    // Hex pattern
    float angle = atan(p.y, p.x);
    float hexPattern = 0.5 + 0.5 * sin(angle * 6.0 + dist * 30.0);
    hexPattern *= smoothstep(shieldRadius - 0.1, shieldRadius - 0.03, dist);
    hexPattern *= (1.0 - smoothstep(shieldRadius - 0.03, shieldRadius, dist));
    
    float shieldIntensity = (edgeGlow * 0.6 + innerFill + hexPattern * 0.1) * shieldVisibility;
    
    // === RIPPLE FROM IMPACT POINT ===
    vec2 hitOffset = hitPos - center;
    vec2 fromHit = p - hitOffset;
    float distFromHit = length(fromHit);
    
    // Expanding ring from hit point
    float maxDist = shieldRadius * 2.5;
    float rippleRadius = t * maxDist;
    
    // Ring shape
    float ringWidth = 0.07 * (1.0 - t * 0.3);
    float ringDist = abs(distFromHit - rippleRadius);
    float ring = 1.0 - smoothstep(0.0, ringWidth, ringDist);
    
    // Only show where ring is on the shield
    float onShield = 1.0 - smoothstep(shieldRadius - 0.01, shieldRadius + 0.02, dist);
    ring *= onShield;
    
    // Fade over time
    float timeFade = 1.0 - smoothstep(0.4, 1.0, t);
    float rippleIntensity = ring * timeFade * 1.5;
    
    // === BRIGHT FLASH AT IMPACT ===
    float flashTime = 1.0 - smoothstep(0.0, 0.25, t);
    float flashRadius = 0.12 * flashTime;
    float flash = (1.0 - smoothstep(0.0, flashRadius, distFromHit)) * flashTime;
    float flashIntensity = flash * 2.5;
    
    // === COMBINE ===
    float totalIntensity = shieldIntensity + rippleIntensity + flashIntensity;
    
    // Color - cyan base, white for flash
    vec3 shieldColor = vec3(0.3, 0.85, 1.0);
    vec3 flashColor = vec3(0.8, 0.95, 1.0);
    float flashRatio = flashIntensity / max(totalIntensity, 0.01);
    vec3 finalColor = mix(shieldColor, flashColor, min(flashRatio, 1.0));
    
    float alpha = totalIntensity;
    
    if (alpha < 0.01) {
        discard;
    }
    
    alpha = min(alpha, 1.0);
    
    return vec4(finalColor, alpha);
}
