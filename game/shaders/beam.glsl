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
  float a = 0.55;
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p *= 2.3;
    a *= 0.5;
  }
  return v;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  // uv.x along the beam length, uv.y across thickness (0..1)
  float along = clamp(uv.x, 0.0, 1.0);
  float across = uv.y - 0.5;

  // Soft falloff from center to edges
  float core = exp(-9.0 * across * across);
  float glow = exp(-2.8 * abs(across));

  // Animated wisps running down the beam
  // Reverse scroll so energy appears to flow outward from the ship.
  float scroll = -time * 2.2;
  float wisp = fbm(vec2(along * 8.0 + scroll, across * 6.0 + time * 0.6));
  float flicker = 0.82 + 0.18 * sin(time * 18.0 + along * 12.0);

  float intensity = (core * 0.85 + glow * 0.35) * mix(0.7, 1.2, wisp) * flicker;

  vec3 coreTint = mix(beamColor * 1.2, vec3(1.0), 0.25);
  vec3 col = mix(beamColor, coreTint, core);

  float alpha = clamp(intensity * beamAlpha, 0.0, 1.0);
  return vec4(col * intensity, alpha) * color;
}
