#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — "Ash": the quiet burn (Pro).
//
// Fire is right for wanting something you shouldn't buy. It is the wrong
// register for grief. This effect keeps the same connected front — a real
// edge eating across a real sheet — but takes the flame away: the paper
// cools, greys, and crumbles into grains that lift off and drift.
//
// The signature difference is the CRUMBLE band. Instead of a bright line,
// the sheet's alpha is dissolved grain by grain against a high-frequency
// noise threshold, so paper granulates out of existence rather than being
// cut. Slower, colder, and it never lights the room.
//
// Uniform layout is identical across every burn effect (see
// burnable_image.dart) — the painter sets floats 0..7 and one sampler,
// and shaders are interchangeable behind that contract.

uniform vec2 uSize;      // draw rect size (logical px)
uniform float uProgress; // 0.0 intact -> 1.0 fully gone
uniform float uTime;     // seconds, drives drift and shimmer
uniform vec4 uPaper;     // paper rect within the quad: x0, y0, x1, y1
uniform sampler2D uTexture;

out vec4 fragColor;

const float CRUMBLE_W = 0.075; // band where the sheet granulates away
const float COOL_W    = 0.30;  // how far ahead the paper greys out
const float ASH_H     = 0.85;  // ash outlives flame: it drifts much further

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

// Sparse motes. `density` is the fraction of cells left empty — higher
// means fewer, lonelier flecks.
float ashPoint(vec2 p, float density, float radius) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  if (hash(i) < density) return 0.0;
  vec2 c = vec2(hash(i + vec2(3.7, 1.3)), hash(i + vec2(9.1, 5.5)));
  // NB: edges ascending. smoothstep with edge0 > edge1 is undefined in
  // GLSL and returns NaN on Metal, which then eats the whole composite.
  return 1.0 - smoothstep(0.0, radius, length(f - c));
}

void main() {
  vec2 quad = FlutterFragCoord().xy / uSize;

  vec2 uv = (quad - uPaper.xy) / (uPaper.zw - uPaper.xy);
  bool onPaper = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
  vec4 tex = onPaper ? texture(uTexture, uv) : vec4(0.0);

  // Same burn field as the fire: position dominates so the front stays a
  // connected line, noise only makes it ragged.
  float base = (1.0 - uv.y) * 0.86 + uv.x * 0.14;
  float sweep = fbm3(uv * vec2(2.6, 1.9)) - 0.5;
  float ragged = fbm3(uv * 11.0) - 0.5;
  float field = base + sweep * 0.26 + ragged * 0.055;

  // Ends at 1.08, not 1.30: `field` peaks at 1.021 across the sheet, and
  // nothing is drawn behind the front here, so 1.08 clears the last pixel
  // with margin. Running to 1.30 finished the sheet at 84% of the hold and
  // left the user pressing against an empty screen (see burn.frag).
  float front = mix(-0.34, 1.08, uProgress);
  float d = field - front;

  // A slow breath rather than a flicker — nothing here is alight.
  float breath = 0.90 + 0.10 * noise(uv * 9.0 + vec2(uTime * 0.7, uTime));

  vec4 col;
  if (!onPaper || d < 0.0) {
    col = vec4(0.0);
  } else {
    float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    float grain = 0.972 + 0.028 * noise(uv * vec2(420.0, 300.0));

    if (d >= CRUMBLE_W) {
      // Intact paper, losing its colour as the decay approaches.
      float cool = 1.0 - smoothstep(CRUMBLE_W, COOL_W, d);
      vec3 c = mix(tex.rgb * grain, vec3(lum * 0.92), cool * 0.85);
      c *= 1.0 - 0.22 * cool;
      col = vec4(c * tex.a, tex.a);
    } else {
      // The crumble. Each grain has its own moment of letting go, so the
      // sheet frays into flecks instead of being sliced.
      float t = d / CRUMBLE_W; // 0 at the leading edge, 1 at whole paper
      float mote = noise(uv * vec2(300.0, 240.0));
      float a = smoothstep(mote - 0.14, mote + 0.14, t) * tex.a;

      // What is still standing in the band is already ash-coloured.
      vec3 soot = vec3(0.13, 0.125, 0.13);
      vec3 c = mix(soot, vec3(lum * 0.9), t * t) * breath;
      col = vec4(c * a, a);
    }
  }

  // Motes lifting off the crumble line. Height is measured against the
  // front's own line (sampled at the front's height) so a whole column
  // agrees on one base and the drift stays rooted to the edge.
  float y0 = 1.0 - front / 0.86;
  vec2 s = vec2(uv.x, y0);
  float g = uv.x * 0.14
          + (fbm3(s * vec2(2.6, 1.9)) - 0.5) * 0.26
          + (fbm3(s * 11.0) - 0.5) * 0.055;
  float frontY = 1.0 - (front - g) / 0.86;
  float above = frontY - uv.y;

  if (above > 0.0 && above < ASH_H &&
      frontY > 0.0 && frontY < 1.0 && uProgress > 0.002) {
    float fade = 1.0 - above / ASH_H;

    // Two layers at different scales and speeds: near flecks travelling
    // fast, far ones slower. Parallax is what makes it read as air.
    float near = ashPoint(
        vec2(uv.x * 20.0 + sin(uv.y * 5.0 + uTime * 0.9) * 0.45,
             uv.y * 20.0 + uTime * 2.4),
        0.90, 0.20);
    float far = ashPoint(
        vec2(uv.x * 38.0 - sin(uv.y * 8.0 + uTime * 0.6) * 0.30,
             uv.y * 38.0 + uTime * 1.3),
        0.94, 0.16);

    float a = (near * 0.85 + far * 0.5) * fade * fade * breath;
    if (a > 0.01) {
      // Cools from warm grey to almost white as it rises and dies.
      vec3 c = mix(vec3(0.86, 0.85, 0.84), vec3(0.34, 0.32, 0.31), fade);
      a = clamp(a, 0.0, 1.0);
      col = vec4(c * a, a) + col * (1.0 - a);
    }
  }

  fragColor = col;
}
