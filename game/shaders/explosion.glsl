extern float time;
extern float duration;
extern Image mainTex;

// Improved pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Current progress (0.0 to 1.0)
    float t = time / duration;
    
    // Pixelate coords to initial texture resolution (approx) to keep pixels "chunky"
    // We can just use the texture coords directly if we want smooth, 
    // but for "pixel blast" we want debris chunks.
    vec2 p = texture_coords;
    
    // Calculate a random direction for this pixel based on its position
    float noise = random(p * 100.0);
    
    // Explosion strength (reduced for slower "drift")
    float strength = t * 1.0; 
    
    // Displace outwards from center (0.5, 0.5)
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = p - center;
    float dist = length(dir);
    
    // Circular mask to prevent square clipping artifacts
    // Instead of hard discard, fade out towards the edge
    float edgeFade = 1.0 - smoothstep(0.4, 0.5, dist);
    
    if (dist < 0.001) dist = 0.001;
    vec2 normDir = dir / dist;
    
    // Add some turbulence
    float angle = atan(dir.y, dir.x);
    float angleNoise = random(vec2(angle, 0.0)) * 0.5 - 0.25;
    
    // Radial movement
    vec2 offset = normDir * (strength * (0.2 + noise * 0.8));
    
    // Sample from "where it came from"
    vec2 sourceUV = p - offset;
    
    // Discard OOB (Texture sample logic)
    if (sourceUV.x < 0.0 || sourceUV.x > 1.0 || sourceUV.y < 0.0 || sourceUV.y > 1.0) {
        // Instead of returning 0, just let it be transparent (or discard if optimizing)
        // But edgeFade handles the bounds mostly.
        // Let's keep strict bounds checking for texture sample safety.
        return vec4(0.0);
    }
    
    vec4 texColor = Texel(texture, sourceUV);
    
    // Fade out over time (start fading later)
    float timeFade = 1.0 - smoothstep(0.6, 1.0, t);
    
    // Combined Alpha
    float finalAlpha = texColor.a * timeFade * edgeFade;
    
    // Add bright flash at the very start
    float flash = 1.0 - smoothstep(0.0, 0.15, t);
    vec3 flashColor = vec3(1.0, 1.0, 0.8) * flash * 1.5;

    // Combined color
    vec3 finalColor = texColor.rgb + flashColor;
    
    if (finalAlpha < 0.01) {
        discard;
    }
    
    return vec4(finalColor, finalAlpha);
}
