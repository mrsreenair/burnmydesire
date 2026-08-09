#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — "Cold flame" (Pro).
//
// The fire effect's structure with the heat inverted: a gas-blue burn.
// Two things make it a different object rather than a recolour —
//
//   1. no char. Paper doesn't blacken and curl, it BLEACHES: the band
//      behind the front goes white-blue and thins to nothing, so the sheet
//      looks like it's being erased instead of consumed.
//   2. tighter tongues. Cold flame is short, sharp and steady where the
//      orange one is tall and lazy.
//
// Uniform layout is identical across every burn effect (see
// burnable_image.dart) — floats 0..7 and one sampler.

uniform vec2 uSize;
uniform float uProgress;
uniform float uTime;
uniform vec4 uPaper;
uniform sampler2D uTexture;

out vec4 fragColor;

const float EMBER_W = 0.020; // the hot line — thinner than the fire's
const float BLEACH_W = 0.130; // whitened paper behind it
const float GLOW_W  = 0.30;  // blue light falling on intact paper
const float FLAME_H = 0.125; // short, contained tongues
const float SPARK_H = 0.42;

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

float fbm3(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 3; i++) {
    v += amp * noise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  return v;
}

float sparkPoint(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  if (hash(i) < 0.93) return 0.0;
  vec2 c = vec2(hash(i + vec2(3.7, 1.3)), hash(i + vec2(9.1, 5.5)));
  // NB: edges must ascend — a descending smoothstep is NaN on Metal.
  return 1.0 - smoothstep(0.0, 0.14, length(f - c));
}

// Cold ramp: deep blue at the tips, blue-white at the core.
vec3 coldColor(float h) {
  vec3 deep  = vec3(0.06, 0.10, 0.52);
  vec3 blue  = vec3(0.10, 0.44, 0.96);
  vec3 cyan  = vec3(0.55, 0.88, 1.00);
  vec3 white = vec3(0.92, 0.98, 1.00);
  vec3 c = mix(deep, blue, smoothstep(0.00, 0.45, h));
  c = mix(c, cyan, smoothstep(0.55, 0.88, h));
  c = mix(c, white, smoothstep(0.92, 1.00, h));
  return c;
}

void main() {
  vec2 quad = FlutterFragCoord().xy / uSize;

  vec2 uv = (quad - uPaper.xy) / (uPaper.zw - uPaper.xy);
  bool onPaper = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
  vec4 tex = onPaper ? texture(uTexture, uv) : vec4(0.0);

  float base = (1.0 - uv.y) * 0.86 + uv.x * 0.14;
  float sweep = fbm3(uv * vec2(2.6, 1.9)) - 0.5;
  float ragged = fbm3(uv * 11.0) - 0.5;
  float field = base + sweep * 0.26 + ragged * 0.055;

  float front = mix(-0.34, 1.30, uProgress);
  float d = field - front;

  // Faster and shallower than the fire's flicker — gas burns steady.
  float flicker =
      0.90 + 0.10 * noise(uv * 30.0 + vec2(uTime * 9.0, uTime * 11.0));

  vec4 col;
  if (!onPaper || d < 0.0) {
    col = vec4(0.0);
  } else if (d >= BLEACH_W) {
    float glow = (1.0 - smoothstep(BLEACH_W, GLOW_W, d))
               * step(0.002, uProgress);
    float grain = 0.972 + 0.028 * noise(uv * vec2(420.0, 300.0));
    vec3 lit = tex.rgb * grain
             + vec3(0.06, 0.20, 0.52) * glow * glow * flicker;
    col = vec4(min(lit, vec3(1.0)) * tex.a, tex.a);
  } else if (d >= EMBER_W) {
    // Bleached band. The paper loses its colour toward the edge and
    // loses its substance with it — no curled lip, it simply thins out.
    float t = (d - EMBER_W) / (BLEACH_W - EMBER_W); // 0 at edge, 1 at paper
    vec3 frost = vec3(0.88, 0.95, 1.00);
    vec3 c = mix(frost, tex.rgb, t * t);
    c += vec3(0.10, 0.34, 0.72) * (1.0 - t) * (1.0 - t) * flicker;
    float a = tex.a * (0.30 + 0.70 * smoothstep(0.0, 0.85, t));
    col = vec4(min(c, vec3(1.0)) * a, a);
  } else {
    float t = d / EMBER_W;
    vec3 glow = coldColor(1.0 - t * 0.5) * (0.95 + 0.25 * flicker);
    float a = smoothstep(0.0, 0.006, d);
    col = vec4(glow * a, a);
  }

  // Tongues, over the sheet. Same height-field approach as the fire so
  // they stay rooted to the front line, but shorter and sharper.
  float y0 = 1.0 - front / 0.86;
  vec2 s = vec2(uv.x, y0);
  float g = uv.x * 0.14
          + (fbm3(s * vec2(2.6, 1.9)) - 0.5) * 0.26
          + (fbm3(s * 11.0) - 0.5) * 0.055;
  float frontY = 1.0 - (front - g) / 0.86;
  float above = frontY - uv.y;

  if (above > 0.0 && frontY > 0.0 && frontY < 1.0 && uProgress > 0.002) {
    float sway = sin(uTime * 2.6 + uv.x * 13.0) * 0.010;
    float x = uv.x + sway;

    float broad = fbm3(vec2(x * 6.0, uTime * 1.6));
    float fine = fbm3(vec2(x * 18.0, uTime * 3.2));
    float tall = smoothstep(0.26, 0.78, broad * 0.68 + fine * 0.52);
    float top = FLAME_H * tall;

    if (top > 0.001 && above < top) {
      float t = above / top;
      // Higher exponent than the fire: cold flame tapers to a point.
      float a = pow(1.0 - t, 1.25) * flicker;
      vec3 c = coldColor(1.0 - t * 0.9);
      a *= 0.80 + 0.20 * fbm3(vec2(x * 26.0, uv.y * 11.0 - uTime * 4.2));
      a = clamp(a, 0.0, 1.0);
      col = vec4(c * a, a) + col * (1.0 - a);
    }
  }

  // Sparks instead of ash: fewer, whiter, and they wink out fast.
  if (above > 0.0 && above < SPARK_H &&
      frontY > 0.0 && frontY < 1.0 && uProgress > 0.002) {
    float drift = sin(uv.y * 9.0 + uTime * 1.8) * 0.25;
    vec2 sp = vec2(uv.x * 30.0 + drift, uv.y * 30.0 + uTime * 4.4);
    float fade = 1.0 - above / SPARK_H;
    float a = sparkPoint(sp) * fade * fade * (0.5 + 0.5 * flicker);
    if (a > 0.01) {
      vec3 c = mix(vec3(0.20, 0.34, 0.70), vec3(0.85, 0.96, 1.00), fade);
      a = clamp(a, 0.0, 1.0);
      col = vec4(c * a, a) + col * (1.0 - a);
    }
  }

  fragColor = col;
}
