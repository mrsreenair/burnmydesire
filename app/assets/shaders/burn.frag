#version 460 core
#include <flutter/runtime_effect.glsl>

// Burn My Desire — paper burn.
//
// Real paper doesn't dissolve in random holes: a single ragged FRONT eats
// across the sheet. Everything here is driven by that idea. The burn field
// is dominated by position (a top-down, slightly tilted sweep) and only
// *perturbed* by noise, so the boundary stays a connected line while
// looking hand-torn.
//
// Front-to-back, a pixel passes through:
//   intact paper (warmed by nearby firelight)
//     -> charred band, darkening toward the edge
//       -> white-hot ember line
//         -> burned void, with flame tongues rising into it
//
// Impeller has no `discard`; burned pixels output premultiplied transparent.

uniform vec2 uSize;      // draw rect size (logical px)
uniform float uProgress; // 0.0 intact -> 1.0 fully burned
uniform float uTime;     // seconds, drives flame motion and flicker
uniform vec4 uPaper;     // paper rect within the quad: x0, y0, x1, y1
uniform sampler2D uTexture;

out vec4 fragColor;

// ---- Field widths, in burn-field units (roughly fractions of height) ----
const float EMBER_W = 0.028; // white-hot line at the very edge
const float CHAR_W  = 0.115; // blackened paper behind the ember
const float WARM_W  = 0.34;  // firelight falling on intact paper
const float FLAME_H = 0.20;  // tallest tongue, in paper heights
const float CURL_W  = 0.018; // curled-back lip of char at the burnt edge
const float ASH_H   = 0.55;  // how far embers drift before they die

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

// Three octaves is enough for the silhouette and keeps this cheap enough
// to hold 60fps on a phone — the ritual fails if it stutters.
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

// Sparse rising embers. Cell-based: each cell may hold one point, and
// most hold none, which is what keeps ash reading as flecks rather than
// texture.
float ashPoint(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  if (hash(i) < 0.88) return 0.0;
  vec2 c = vec2(hash(i + vec2(3.7, 1.3)), hash(i + vec2(9.1, 5.5)));
  // NB: edges ascending. smoothstep with edge0 > edge1 is undefined in
  // GLSL and returns NaN on Metal, which then eats the whole composite.
  return 1.0 - smoothstep(0.0, 0.18, length(f - c));
}

// Fire ramp: white-hot core -> yellow -> orange -> deep red at the tips.
vec3 fireColor(float h) {
  // Orange carries most of the range: a ramp weighted toward yellow reads
  // as mustard once alpha knocks the brightness down.
  vec3 red    = vec3(0.80, 0.05, 0.01);
  vec3 orange = vec3(1.00, 0.28, 0.02);
  vec3 yellow = vec3(1.00, 0.70, 0.10);
  vec3 white  = vec3(1.00, 0.95, 0.78);
  vec3 c = mix(red, orange, smoothstep(0.00, 0.45, h));
  c = mix(c, yellow, smoothstep(0.55, 0.88, h));
  c = mix(c, white,  smoothstep(0.92, 1.00, h));
  return c;
}

void main() {
  vec2 quad = FlutterFragCoord().xy / uSize;

  // Paper coordinates. Outside 0..1 is the air around the sheet, where
  // only flames may appear. The burn field is a continuous function of
  // these coords, so it keeps working past the paper's edge.
  vec2 uv = (quad - uPaper.xy) / (uPaper.zw - uPaper.xy);
  bool onPaper = uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
  vec4 tex = onPaper ? texture(uTexture, uv) : vec4(0.0);

  // --- The burn field. Position dominates so the front stays connected;
  // two noise scales make it ragged at both large and small scale.
  //
  // (1 - uv.y) lights the BOTTOM edge first and eats upward, the way a
  // sheet held at the top actually burns — and the way heat wants to go.
  float base = (1.0 - uv.y) * 0.86 + uv.x * 0.14;
  float sweep = fbm3(uv * vec2(2.6, 1.9)) - 0.5; // broad lobes
  float ragged = fbm3(uv * 11.0) - 0.5;          // torn-edge detail
  float field = base + sweep * 0.26 + ragged * 0.055;

  // Sweep the front past both ends so 0 leaves the sheet whole and 1
  // clears every pixel. The start must clear the field's lowest value by
  // more than CHAR_W, or the first pixels are already charred at rest.
  float front = mix(-0.34, 1.30, uProgress);
  float d = field - front; // > 0 intact, < 0 already burned

  // Flicker shared by the ember line and the flames.
  float flicker =
      0.84 + 0.16 * noise(uv * 26.0 + vec2(uTime * 6.0, uTime * 8.5));

  // --- Layer 1: the sheet, premultiplied.
  vec4 col;
  if (onPaper && d < 0.0 && d > -CURL_W) {
    // The curled lip. Real paper doesn't end at the ember — it peels back
    // into a blackened rim that hangs on a moment before it drops. Opaque
    // and dark, with the heat still showing through its underside.
    float t = -d / CURL_W; // 0 at the ember, 1 at the outer edge
    vec3 lip = mix(vec3(0.10, 0.06, 0.05), vec3(0.02, 0.015, 0.015), t);
    lip += vec3(0.5, 0.14, 0.03) * (1.0 - t) * (1.0 - t) * flicker;
    float a = 1.0 - smoothstep(0.7, 1.0, t);
    col = vec4(min(lip, vec3(1.0)) * a, a);
  } else if (!onPaper || d < 0.0) {
    // Air, or paper already consumed.
    col = vec4(0.0);
  } else if (d >= CHAR_W) {
    // Intact paper. Pixels near the front catch the firelight — but only
    // once something is actually alight.
    float warm = (1.0 - smoothstep(CHAR_W, WARM_W, d))
               * step(0.002, uProgress);
    // Fibre grain: flat cream reads as a rectangle, not as paper.
    float grain = 0.972 + 0.028 * noise(uv * vec2(420.0, 300.0));
    vec3 lit = tex.rgb * grain
             + vec3(0.45, 0.20, 0.02) * warm * warm * flicker;
    col = vec4(min(lit, vec3(1.0)) * tex.a, tex.a);
  } else if (d >= EMBER_W) {
    // Charred band: paper blackens as it approaches the ember line, with
    // a faint red heat bleeding through the char.
    float t = (d - EMBER_W) / (CHAR_W - EMBER_W); // 0 at ember, 1 at paper
    vec3 soot = vec3(0.06, 0.04, 0.035);
    vec3 charred = mix(soot, tex.rgb, t * t);
    charred += vec3(0.55, 0.12, 0.02) * (1.0 - t) * (1.0 - t) * flicker;
    col = vec4(min(charred, vec3(1.0)) * tex.a, tex.a);
  } else {
    // The ember line itself — the brightest thing on screen.
    float t = d / EMBER_W;
    vec3 glow = fireColor(1.0 - t * 0.55) * (0.9 + 0.35 * flicker);
    float a = smoothstep(0.0, 0.006, d);
    col = vec4(glow * a, a);
  }

  // --- Layer 2: flames, composited OVER the sheet.
  //
  // Burning upward means tongues lick across paper that is still
  // standing rather than into empty space, so fire is a layer on top of
  // whatever is behind it — not an alternative branch the way it was
  // when the burn ran downward into a void.
  //
  // Height is real vertical distance above the local front line, NOT a
  // difference in field value: the field's noise term is as large as the
  // flame height itself, and using it scatters fire into detached
  // patches. The noise is sampled at the front's OWN height so a whole
  // column agrees on one base line and the tongues stay rooted.
  float y0 = 1.0 - front / 0.86;
  vec2 s = vec2(uv.x, y0);
  float g = uv.x * 0.14
          + (fbm3(s * vec2(2.6, 1.9)) - 0.5) * 0.26
          + (fbm3(s * 11.0) - 0.5) * 0.055;
  float frontY = 1.0 - (front - g) / 0.86;
  float above = frontY - uv.y;

  // Only burn where the front is actually eating paper. The front starts
  // (and ends) outside the sheet so that progress 0 leaves it whole and 1
  // clears it — without this guard those off-sheet positions light a band
  // of fire in mid-air before the user has even touched the screen.
  if (above > 0.0 && frontY > 0.0 && frontY < 1.0 && uProgress > 0.002) {
    // Flames are a HEIGHT FIELD, not a thresholded cloud: every column of
    // pixels gets its own tongue height, animated over time. Thresholding
    // 2D turbulence (the obvious approach) fills the whole band with haze
    // and reads as smoke; per-column heights give the discrete, tapering
    // licks that actually look like fire.
    float sway = sin(uTime * 1.7 + uv.x * 9.0) * 0.02;
    float x = uv.x + sway;

    float broad = fbm3(vec2(x * 4.5, uTime * 1.15));  // big tongues
    float fine  = fbm3(vec2(x * 14.0, uTime * 2.45)); // small licks
    float tall = smoothstep(0.22, 0.80, broad * 0.72 + fine * 0.48);
    float top = FLAME_H * tall;

    if (top > 0.001 && above < top) {
      float t = above / top; // 0 at the burning edge, 1 at the tip

      // Solid and hot at the root, thinning and reddening as it climbs.
      float a = pow(1.0 - t, 0.7) * flicker;
      vec3 c = fireColor(1.0 - t * 0.85);

      // Ragged edges so tongues don't look extruded.
      a *= 0.75 + 0.25 * fbm3(vec2(x * 22.0, uv.y * 9.0 - uTime * 3.4));
      a = clamp(a, 0.0, 1.0);

      // Premultiplied source-over.
      col = vec4(c * a, a) + col * (1.0 - a);
    }
  }

  // --- Layer 3: ash. Embers lift off the burn line, drift up on the
  // draught and cool from orange to dead grey. They travel further than
  // the flames do, which is what sells the fire as something with heat
  // coming off it rather than a coloured band.
  if (above > 0.0 && above < ASH_H &&
      frontY > 0.0 && frontY < 1.0 && uProgress > 0.002) {
    float drift = sin(uv.y * 7.0 + uTime * 1.3) * 0.35;
    vec2 ap = vec2(uv.x * 24.0 + drift, uv.y * 24.0 + uTime * 3.2);
    float fade = 1.0 - above / ASH_H;
    float a = ashPoint(ap) * fade * fade * (0.55 + 0.45 * flicker);
    if (a > 0.01) {
      vec3 c = mix(vec3(0.30, 0.11, 0.05), vec3(1.0, 0.62, 0.20), fade);
      a = clamp(a, 0.0, 1.0);
      col = vec4(c * a, a) + col * (1.0 - a);
    }
  }

  fragColor = col;
}
