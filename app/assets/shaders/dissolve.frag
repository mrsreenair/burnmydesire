#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — "Dissolve" (Pro).
//
// The page is under water. Instead of a front eating in from a corner,
// dissolution blooms from many places at once (a cloud field), and where
// the paper has gone its pigment doesn't vanish — it lifts off, smears
// and drifts upward as ink before fading. Three zones per pixel:
//
//   * intact paper: soft caustic light wandering across it;
//   * the wet edge: colours bleed (blurred sample), paper darkens the way
//     wet paper does, and it thins to nothing;
//   * dissolved: a plume — the texture sampled through a swirl and
//     pulled upward, fading with distance from the front.
//
// Same uniform contract as every effect (burnable_image.dart): floats
// 0..7 and one sampler. Impeller rules: no discard, premultiplied output,
// smoothstep edges ascending.

uniform vec2 uSize;
uniform float uProgress;
uniform float uTime;
uniform vec4 uPaper;
uniform sampler2D uTexture;

out vec4 fragColor;

const float EDGE_W  = 0.10;  // the wet, bleeding band
const float PLUME_W = 0.34;  // how far behind the front ink still drifts

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

// A blurred read of the paper: five taps, for the wet edge and the plume.
vec4 soft(vec2 uv, float r) {
  vec4 c = texture(uTexture, uv) * 0.4;
  c += texture(uTexture, uv + vec2(r, 0.0)) * 0.15;
  c += texture(uTexture, uv - vec2(r, 0.0)) * 0.15;
  c += texture(uTexture, uv + vec2(0.0, r)) * 0.15;
  c += texture(uTexture, uv - vec2(0.0, r)) * 0.15;
  return c;
}

void main() {
  vec2 quad = FlutterFragCoord().xy / uSize;
  vec2 uv = (quad - uPaper.xy) / (uPaper.zw - uPaper.xy);
  bool onPaper = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
  vec4 tex = onPaper ? texture(uTexture, uv) : vec4(0.0);

  // The dissolution field: cloudy, with a gentle bias so the bottom goes
  // first (heavier, wetter) and the last dry island sits near the top.
  // fbm clusters around 0.5, so it's stretched ×2 about the middle to
  // spread the field over ~[0,1] — otherwise half the sheet vanished in
  // the first third of the hold and the rest lingered. With the bias the
  // range is [0, 1.0]; the front sweeps past both ends with margin so the
  // sheet is fully gone at the end of the hold.
  float cloud = fbm3(uv * 3.1 + vec2(3.7, 1.9)) * 0.75
              + fbm3(uv * 7.4 + vec2(0.3, 8.1)) * 0.25;
  cloud = clamp((cloud - 0.5) * 2.0 + 0.5, 0.0, 1.0);
  float field = cloud * 0.80 + (1.0 - uv.y) * 0.20;
  float front = mix(-0.10, 1.10, uProgress);
  float d = field - front;   // > 0: still paper; < 0: dissolved

  // Water light: slow caustics wandering over whatever's left.
  float caustic = fbm3(uv * 6.0 + vec2(uTime * 0.35, -uTime * 0.28));
  caustic = smoothstep(0.45, 0.85, caustic);

  vec4 col;
  if (!onPaper) {
    col = vec4(0.0);
  } else if (d >= EDGE_W) {
    vec3 lit = tex.rgb + vec3(0.10, 0.20, 0.26) * caustic * 0.35
             * step(0.002, uProgress);
    col = vec4(min(lit, vec3(1.0)) * tex.a, tex.a);
  } else if (d >= 0.0) {
    // Wet edge. Colours bleed sideways (blurred), the paper darkens like
    // wet paper, and it thins toward the front instead of curling.
    float t = d / EDGE_W;                       // 0 at front, 1 at paper
    float r = 0.012 * (1.0 - t);
    vec4 wet = soft(uv, r);
    vec3 c = mix(wet.rgb * 0.72, tex.rgb, t * t);
    c += vec3(0.05, 0.12, 0.18) * (1.0 - t) * caustic;
    float a = tex.a * (0.15 + 0.85 * smoothstep(0.0, 0.7, t));
    col = vec4(min(c, vec3(1.0)) * a, a);
  } else {
    // Dissolved: the plume. Pull the sample from below (ink rises) and
    // through a slow swirl; fade with how long ago this spot went.
    float gone = -d;                            // 0 at front, grows behind
    float lift = min(gone, PLUME_W) * 0.55;
    vec2 swirl = vec2(
      noise(uv * 5.0 + vec2(uTime * 0.6, 0.0)) - 0.5,
      noise(uv * 5.0 + vec2(0.0, uTime * 0.5) + 7.0) - 0.5
    ) * 0.09 * gone * 6.0;
    vec2 src = clamp(uv + vec2(0.0, lift) + swirl, 0.0, 1.0);
    vec4 ink = soft(src, 0.02 + gone * 0.05);
    // Streaks: the plume is stringy, not a fog — but soft strings, so
    // a pale page reads as ghosted paper lifting away, not grey smoke.
    float strand = fbm3(vec2(uv.x * 22.0, uv.y * 4.0 - uTime * 0.7));
    strand = smoothstep(0.30, 0.75, strand);
    float fade = 1.0 - smoothstep(0.0, PLUME_W, gone);
    float a = ink.a * fade * fade * (0.12 + 0.45 * strand);
    vec3 c = ink.rgb * (0.80 + 0.20 * fade);
    col = vec4(min(c, vec3(1.0)) * a, a);
  }

  // Bubbles: a few rising points over the whole sheet once it's wet.
  if (onPaper && uProgress > 0.002 && d < EDGE_W * 2.0) {
    vec2 bp = vec2(uv.x * 18.0, uv.y * 18.0 + uTime * 1.6);
    vec2 bi = floor(bp);
    vec2 bf = fract(bp);
    if (hash(bi) > 0.94) {
      vec2 c = vec2(hash(bi + vec2(2.1, 5.3)), hash(bi + vec2(7.7, 1.9)));
      float ring = abs(length(bf - c) - 0.10);
      float b = 1.0 - smoothstep(0.0, 0.035, ring);
      b *= 0.55;
      col = vec4(vec3(0.85, 0.95, 1.0) * b, b) + col * (1.0 - b);
    }
  }

  fragColor = col;
}
