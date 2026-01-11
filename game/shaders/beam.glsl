// Beam shader for thick, energetic laser ribbons.
// Uses UV space of a simple rectangle quad.

extern number time;
extern vec3 beamColor;
extern number beamAlpha;

float rand(vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p = rot * p * 2.1 + shift;
    a *= 0.5;
  }
  return v;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  float along = clamp(uv.x, 0.0, 1.0);
  float across = uv.y - 0.5;

  // Multi-layer core with hot center
  float innerCore = exp(-40.0 * across * across);
  float outerCore = exp(-12.0 * across * across);
  float glow = exp(-3.5 * abs(across));
  float outerGlow = exp(-1.5 * abs(across));

  // Animated energy flow with multiple frequencies
  float scroll = -time * 3.0;
  float fastScroll = -time * 6.0;
  
  // Primary wisp pattern
  float wisp1 = fbm(vec2(along * 10.0 + scroll, across * 8.0 + time * 0.4));
  // Secondary faster, finer detail
  float wisp2 = fbm(vec2(along * 20.0 + fastScroll, across * 4.0 - time * 0.8));
  // Slow undulating wave
  float wave = sin(along * 15.0 + time * 4.0 + across * 3.0) * 0.5 + 0.5;
  
  // Combine wisps
  float wisp = wisp1 * 0.6 + wisp2 * 0.3 + wave * 0.1;

  // Multi-frequency flicker for energy feel
  float flicker = 0.85 + 0.1 * sin(time * 25.0 + along * 15.0)
                + 0.05 * sin(time * 47.0 + along * 8.0);

  // Edge crackle effect
  float edgeDist = abs(across) * 2.0;
  float crackle = noise(vec2(along * 30.0 + time * 5.0, edgeDist * 10.0));
  float edgeEnergy = smoothstep(0.3, 0.5, edgeDist) * crackle * 0.4;

  // Combine intensities
  float coreIntensity = innerCore * 1.2 + outerCore * 0.5;
  float glowIntensity = glow * 0.4 + outerGlow * 0.15;
  float intensity = (coreIntensity + glowIntensity) * mix(0.75, 1.25, wisp) * flicker;
  intensity += edgeEnergy * glow;

  // Color gradient: hot white core -> beam color -> darker edges
  vec3 hotCore = vec3(1.0, 1.0, 0.95);
  vec3 midColor = beamColor * 1.3;
  vec3 edgeColor = beamColor * 0.7;
  
  vec3 col = mix(hotCore, midColor, smoothstep(0.0, 0.4, abs(across)));
  col = mix(col, edgeColor, smoothstep(0.2, 0.5, abs(across)));
  
  // Add subtle chromatic variation along beam
  col += vec3(0.1, 0.0, -0.05) * sin(along * 20.0 + time * 3.0) * glow;

  // Soft fade at beam ends
  float endFade = smoothstep(0.0, 0.08, along) * smoothstep(1.0, 0.92, along);

  float alpha = clamp(intensity * beamAlpha * endFade, 0.0, 1.0);
  return vec4(col * intensity, alpha) * color;
}
