#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — "Static" (Pro).
//
// The page dies like a screen. Not fire, not water: a signal failing.
// The sheet is cut into blocks; each block, in its own random order,
// first drops to snow (grey noise), then goes dark and drops out. Around
// that, the whole image tears horizontally in bands, splits into its
// colour channels, and wears scanlines — all of it worsening with the
// hold. For the register this is for — a subscription, an app, a
// feed — a screen switching off is the exact gesture.
//
// Same uniform contract as every effect. Impeller rules: no discard,
// premultiplied output, ascending smoothsteps.

uniform vec2 uSize;
uniform float uProgress;
uniform float uTime;
uniform vec4 uPaper;
uniform sampler2D uTexture;

out vec4 fragColor;

const vec2 GRID = vec2(18.0, 30.0);   // blocks across, down
const float SNOW_W = 0.14;            // how long a block shows snow

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float hash1(float p) { return hash(vec2(p, p * 1.37 + 0.13)); }

void main() {
  vec2 quad = FlutterFragCoord().xy / uSize;
  vec2 uv = (quad - uPaper.xy) / (uPaper.zw - uPaper.xy);
  bool onPaper = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;

  // Frame clock: the glitch steps, it doesn't glide.
  float frame = floor(uTime * 12.0);
  float p = uProgress;

  // Horizontal tearing: bands of rows slide sideways, more and further
  // as the hold goes on. Bands re-roll every frame.
  float band = floor(uv.y * 26.0);
  float tearRoll = hash(vec2(band, frame));
  float tearOn = step(1.0 - (0.06 + 0.55 * p), tearRoll);
  float tear = (hash(vec2(band * 3.1, frame * 1.7)) - 0.5) * 0.18 * p * tearOn;
  vec2 tuv = vec2(uv.x + tear, uv.y);

  // Colour split grows with progress.
  float split = 0.004 + 0.022 * p;
  vec4 texC = texture(uTexture, clamp(tuv, 0.0, 1.0));
  float r = texture(uTexture, clamp(tuv + vec2(split, 0.0), 0.0, 1.0)).r;
  float b = texture(uTexture, clamp(tuv - vec2(split, 0.0), 0.0, 1.0)).b;
  vec3 rgb = vec3(r, texC.g, b);
  float alpha = onPaper ? texC.a : 0.0;

  // Blocks: each dies at its own moment. h in [0,1); a block turns to
  // snow when p > h*0.84 and drops out SNOW_W later — so the last one is
  // gone by 0.98, before the hold ends, and nothing is drawn after.
  vec2 cell = floor(uv * GRID);
  float h = hash(cell + vec2(11.0, 3.0));
  float dieAt = h * 0.84;
  float snow = step(dieAt, p) * (1.0 - step(dieAt + SNOW_W, p));
  float gone = step(dieAt + SNOW_W, p);

  // Snow: grey noise re-rolled every frame, brighter than the paper so it
  // reads as light, not dirt.
  float n = hash(vec2(floor(uv.x * 220.0), floor(uv.y * 380.0)) + frame);
  vec3 snowCol = vec3(0.55 + 0.45 * n);

  // Scanlines everywhere, heavier as it dies.
  float scan = 0.88 + 0.12 * sin(uv.y * 900.0);
  scan = mix(1.0, scan, 0.35 + 0.65 * p);

  // The occasional whole-frame flash to white when it's nearly over.
  float flash = step(0.985, hash1(frame)) * step(0.55, p) * 0.35;

  vec3 c = mix(rgb, snowCol, snow);
  c = c * scan + flash;
  float a = alpha * (1.0 - gone);
  // Snow blocks are opaque light even where the texture was transparent.
  a = max(a, snow * (onPaper ? 1.0 : 0.0) * (1.0 - gone));

  // Off-paper: nothing but the tear can drag pixels past the edge — keep
  // it clean by killing anything outside the quad's paper.
  if (!onPaper) a = 0.0;

  fragColor = vec4(min(c, vec3(1.0)) * a, a);
}
