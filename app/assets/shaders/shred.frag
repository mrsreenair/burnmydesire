#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — the shredder.
//
// Same contract as burn.frag: size, progress, time, paper rect, texture.
// No fire at all. A steel head crosses the page from the bottom up; above
// it the sheet is whole, below it the page has already come out the other
// side as ribbons, which separate, sway and fall away as they go.
//
// The ribbons are drawn INSIDE the paper rect rather than spilling below
// it: the quad's head-room is sized for flames, and a shredder needs far
// more room under the cut than a flame needs above it. Keeping the spill
// inside the sheet's own bounds also keeps the destruction contained,
// which is the point — the page does not escape.
//
// Impeller has no `discard`; gone pixels output premultiplied transparent.

uniform vec2 uSize;      // draw rect size (logical px)
uniform float uProgress; // 0.0 intact -> 1.0 fully shredded
uniform float uTime;     // seconds, drives sway and motor jitter
uniform vec4 uPaper;     // paper rect within the quad: x0, y0, x1, y1
uniform sampler2D uTexture;

out vec4 fragColor;

const float STRIPS  = 26.0;  // ribbons across the page
const float HEAD_H  = 0.020; // thickness of the shredder head, in uv
// Kept tight: spread over more than this the shadow stops reading as a
// hard object above the paper and turns into fog.
const float FEED_H  = 0.025;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float hash1(float n) { return hash(vec2(n, n * 1.37 + 7.1)); }

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

void main() {
  vec2 quad = FlutterFragCoord().xy / uSize;
  vec2 uv = (quad - uPaper.xy) / (uPaper.zw - uPaper.xy);
  bool onPaper = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
  if (!onPaper) {
    fragColor = vec4(0.0);
    return;
  }

  // The cut line, travelling up the page. It starts below the sheet and
  // ends above it so 0 leaves the page whole and 1 clears every pixel.
  // The motor's own vibration lives here, so the whole head shakes.
  float shake = (noise(vec2(uTime * 34.0, 3.0)) - 0.5) * 0.0022;
  float cut = mix(1.0 + HEAD_H, -HEAD_H, uProgress) + shake;

  // Which ribbon this pixel belongs to, and where across it we are.
  float strip = floor(uv.x * STRIPS);
  float across = fract(uv.x * STRIPS);
  float rs = hash1(strip);       // per-ribbon speed
  float rw = hash1(strip + 51.0); // per-ribbon sway phase

  vec4 col;

  if (uv.y < cut - HEAD_H * 0.5) {
    // --- Intact paper, being fed in. The crease lines the blades will
    // follow show up just before the cut, and the sheet darkens as it
    // disappears under the head.
    float toCut = (cut - HEAD_H * 0.5) - uv.y;
    float near = 1.0 - smoothstep(0.0, FEED_H, toCut);

    float crease = smoothstep(0.5, 0.0, abs(across - 0.5) * 2.0 - 0.86);
    vec3 c = texture(uTexture, uv).rgb;
    c *= 1.0 - crease * near * 0.35;             // blade creases
    c *= 1.0 - near * near * 0.40;               // shadow of the head
    float a = texture(uTexture, uv).a;
    col = vec4(c * a, a);
  } else if (uv.y < cut + HEAD_H * 0.5) {
    // --- The head itself: a dark steel bar with a lit top edge and a row
    // of teeth. Opaque, so it reads as a solid object crossing the page.
    float t = (uv.y - (cut - HEAD_H * 0.5)) / HEAD_H; // 0 top, 1 bottom
    vec3 steel = mix(vec3(0.42, 0.44, 0.47), vec3(0.07, 0.08, 0.09), t);
    // Teeth: a bright nick at every blade gap, biting into the paper.
    float tooth = smoothstep(0.72, 1.0, abs(across - 0.5) * 2.0);
    steel += vec3(0.55, 0.57, 0.60) * tooth * (1.0 - t) * 0.7;
    col = vec4(steel, 1.0);
  } else {
    // --- Ribbons. Everything below the head has already been cut, so it
    // is drawn from the page's own pixels, displaced per ribbon: each one
    // slips down at its own rate, sways, and thins as it falls.
    float below = uv.y - (cut + HEAD_H * 0.5);

    // Each ribbon runs out at its own length. Without this every strip
    // ends on the same line and the whole thing reads as a comb rather
    // than as paper coming apart.
    float len = 0.20 + 0.48 * hash1(strip + 17.0);

    // How far this ribbon has slipped past its neighbours, how far it has
    // fanned sideways, and its own sway. All scaled by `below`, so they
    // leave the blades together and separate as they fall.
    float slip = below * (0.05 + 0.85 * rs);
    float drift = (rs - 0.5) * below * 0.7 / STRIPS;
    float sway = sin(uTime * 2.3 + rw * 6.28 + below * 6.0)
               * below * 0.5 / STRIPS;

    vec2 sp = vec2(uv.x + sway + drift, uv.y - slip);
    vec4 tex = texture(uTexture, sp);
    bool inside = sp.y > cut && sp.x > 0.0 && sp.x < 1.0;

    // The gap between ribbons opens gradually — right under the blades
    // they are still touching.
    float gap = 0.06 + below * 0.55;
    float edge = 1.0 - smoothstep(0.5 - gap, 0.5 - gap * 0.45,
                                  abs(fract(sp.x * STRIPS) - 0.5));

    // Ribbons fade out rather than falling forever — the page is
    // destroyed, not dropped on the floor.
    float fade = 1.0 - smoothstep(len * 0.55, len, below);
    float a = inside ? tex.a * edge * fade : 0.0;

    // Cut edges are darker, and the curl shades one side of each ribbon.
    vec3 c = tex.rgb * (0.72 + 0.28 * edge);
    c *= 0.80 + 0.20 * cos((fract(sp.x * STRIPS) - 0.5) * 3.0);
    col = vec4(c * a, a);
  }

  fragColor = col;
}
