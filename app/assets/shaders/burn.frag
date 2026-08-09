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
const float FLAME_H = 0.26;  // tallest tongue, in paper heights

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
  // two noise scales make it ragged at both large and small scale. The
  // x term leans the front into a diagonal, the way a held sheet burns.
  float base = uv.y * 0.86 + uv.x * 0.14;
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

  // Air ahead of the front: nothing to see. (Air *behind* it still gets
  // flames, handled below.)
  if (!onPaper && d >= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  if (onPaper && d >= CHAR_W) {
    // Intact paper. Pixels near the front catch the firelight — but only
    // once something is actually alight.
    float warm = (1.0 - smoothstep(CHAR_W, WARM_W, d))
               * step(0.002, uProgress);
    vec3 lit = tex.rgb + vec3(0.45, 0.20, 0.02) * warm * warm * flicker;
    fragColor = vec4(min(lit, vec3(1.0)) * tex.a, tex.a);
    return;
  }

  if (onPaper && d >= EMBER_W) {
    // Charred band: paper blackens as it approaches the ember line, with
    // a faint red heat bleeding through the char.
    float t = (d - EMBER_W) / (CHAR_W - EMBER_W); // 0 at ember, 1 at paper
    vec3 soot = vec3(0.06, 0.04, 0.035);
    vec3 charred = mix(soot, tex.rgb, t * t);
    charred += vec3(0.55, 0.12, 0.02) * (1.0 - t) * (1.0 - t) * flicker;
    fragColor = vec4(min(charred, vec3(1.0)) * tex.a, tex.a);
    return;
  }

  if (onPaper && d >= 0.0) {
    // The ember line itself — the brightest thing on screen.
    float t = d / EMBER_W; // 0 at the void, 1 at the char
    vec3 glow = fireColor(1.0 - t * 0.55) * (0.9 + 0.35 * flicker);
    float a = smoothstep(0.0, 0.006, d);
    fragColor = vec4(glow * a, a);
    return;
  }

  // --- Burned void: flames rise from the edge.
  //
  // Height is measured as real vertical distance above the local front
  // line, NOT as a difference in field value. The field's noise term is
  // as large as the flame height itself, so using it scatters fire into
  // detached patches; solving for where the front sits at this x keeps
  // every tongue rooted on the burning edge.
  //
  // The noise must be sampled at the front's OWN height, not at this
  // pixel's. Sampling locally makes every pixel disagree about where the
  // front is, so tongues float away from the paper. One refinement step
  // — guess the height ignoring noise, then re-sample there — makes a
  // whole column agree on one base line.
  float y0 = front / 0.86;
  vec2 s = vec2(uv.x, y0);
  float g = uv.x * 0.14
          + (fbm3(s * vec2(2.6, 1.9)) - 0.5) * 0.26
          + (fbm3(s * 11.0) - 0.5) * 0.055;
  float frontY = (front - g) / 0.86;
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
      // Alpha holds up through the body so the fire stays saturated
      // instead of washing out to brown.
      float a = pow(1.0 - t, 0.7) * flicker;
      vec3 c = fireColor(1.0 - t * 0.85);

      // Ragged edges so tongues don't look extruded.
      a *= 0.75 + 0.25 * fbm3(vec2(x * 22.0, uv.y * 9.0 - uTime * 3.4));

      fragColor = vec4(c * a, a);
      return;
    }
  }

  fragColor = vec4(0.0);
}
