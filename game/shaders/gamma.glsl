// Gamma/brightness correction shader
// Applied as post-processing to entire game render

uniform float gamma;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec4 pixel = Texel(tex, uv) * color;
    
    // Apply gamma correction: output = input ^ (1/gamma)
    // gamma > 1.0 = brighter, gamma < 1.0 = darker
    vec3 corrected = pow(pixel.rgb, vec3(1.0 / gamma));
    
    return vec4(corrected, pixel.a);
}
