#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — Phase 0 spike shader.
// Dissolves the image along an fbm noise field with a white-hot -> deep-red
// glowing rim and a charred band ahead of the flame front.
// Impeller has no `discard`; burned pixels output premultiplied transparent.

uniform vec2 uSize;      // draw rect size (logical px)
uniform float uProgress; // 0.0 intact -> 1.0 fully burned
uniform float uTime;     // seconds, drives ember flicker
uniform sampler2D uTexture;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 5; i++) {
    v += amp * noise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 tex = texture(uTexture, uv);

  // Bias so progress 0 leaves the image untouched and 1 clears every pixel.
  float n = fbm(uv * 5.0);
  float threshold = mix(-0.15, 1.15, uProgress);
  float d = n - threshold; // < 0: burned away, > 0: still intact

  const float GLOW_W = 0.06;
  const float CHAR_W = 0.18;

  if (d < 0.0) {
    fragColor = vec4(0.0);
  } else if (d < GLOW_W) {
    float t = d / GLOW_W;
    float flicker = 0.82 + 0.18 * noise(uv * 30.0 + vec2(uTime * 7.0, uTime * 9.0));
    vec3 hot = vec3(1.0, 0.90, 0.45);
    vec3 cool = vec3(0.75, 0.12, 0.02);
    vec3 glow = mix(hot, cool, t) * flicker;
    // soften the innermost edge so the flame front isn't aliased
    float a = smoothstep(0.0, 0.012, d);
    fragColor = vec4(glow * a, a);
  } else if (d < CHAR_W) {
    float t = (d - GLOW_W) / (CHAR_W - GLOW_W);
    vec3 charred = mix(vec3(0.08, 0.05, 0.04), tex.rgb, t * t);
    fragColor = vec4(charred * tex.a, tex.a);
  } else {
    fragColor = tex;
  }
}
