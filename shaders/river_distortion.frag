#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uImageSize;
uniform float uProgress;
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
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
      mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += noise(p) * a;
    p = p * 2.03 + vec2(17.1, 9.2);
    a *= 0.5;
  }
  return v;
}

vec2 coverUv(vec2 pixel) {
  float scale = max(uSize.x / uImageSize.x, uSize.y / uImageSize.y);
  vec2 drawn = uImageSize * scale;
  vec2 crop = (drawn - uSize) * 0.5;
  return (pixel + crop) / drawn;
}

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 uv = pixel / uSize;
  vec2 sourceUv = coverUv(pixel);
  float bladeY = 1.0 - uProgress;
  float passed = smoothstep(-0.006, 0.012, uv.y - bladeY);

  // One continuous river around the sword. Each bank has unrelated width,
  // bend frequencies and noise seeds, so the silhouette is never mirrored.
  float leftReach = mix(0.035, 0.135, fbm(vec2(uv.y * 6.2, 3.1)));
  float rightReach = mix(0.035, 0.145, fbm(vec2(uv.y * 7.7, 21.9)));
  float leftBank = clamp(0.5 - leftReach
      + (fbm(vec2(uv.y * 15.0, 8.4)) - 0.5) * 0.110
      + sin(uv.y * 43.0 + 0.6) * 0.025, 0.34, 0.485);
  float rightBank = clamp(0.5 + rightReach
      + (fbm(vec2(uv.y * 12.5, 31.7)) - 0.5) * 0.120
      + sin(uv.y * 35.0 + 2.8) * 0.028, 0.515, 0.67);
  float inside = smoothstep(leftBank - 0.008, leftBank + 0.010, uv.x)
      * (1.0 - smoothstep(rightBank - 0.010, rightBank + 0.008, uv.x));
  float river = inside * passed;
  float disturbance = smoothstep(leftBank - 0.085, leftBank + 0.012, uv.x)
      * (1.0 - smoothstep(rightBank - 0.012, rightBank + 0.085, uv.x))
      * passed;

  float leftOut = (0.5 - uv.x) / max(0.5 - leftBank, 0.001);
  float rightOut = (uv.x - 0.5) / max(rightBank - 0.5, 0.001);
  float outward = clamp(max(leftOut, rightOut), 0.0, 1.0);

  // Gentle concentration curve across the channel width: the centerline
  // (outward = 0) stays a bit cleaner than the banks (outward = 1), but the
  // transition is gradual - a steeper curve here reads as two separate dark
  // streams split by a bright seam rather than one river with a lighter
  // current down the middle.
  float edgeConcentration = pow(outward, 1.0);

  // The uProgress value at which the blade line first reached this row
  // (bladeY = 1 - uProgress equals uv.y). Fixed per pixel, independent of
  // the current frame's uProgress.
  float rowCrossedAtProgress = 1.0 - uv.y;
  // Distance (in uv.y units) between the blade line and the sword's tail
  // (hilt end) at the moment this row was crossed, derived from the same
  // constants as SwordsmanFrame.swordY (swordsman_animation.dart:39, lerp
  // 1.08 -> -.46) and the sword sprite's height/offset in
  // swordsman_loading_scene.dart (swordHeight = .42 * H, drawn from
  // swordY*H - swordHeight*.16). If those constants change, this formula
  // must be updated to match. Evaluated at rowCrossedAtProgress (not the
  // live uProgress) so it stays fixed per row.
  // Distance (in uv.y units) between the blade line and where the sword's
  // grip/hilt begins (not the full sprite down to the tassel tip) at the
  // moment this row was crossed. Derived the same way as before but using
  // the hilt-start point (~58% down assets/splash/sword-v4-clean.webp, i.e.
  // swordY + swordHeight*.42 instead of the full-sprite swordY +
  // swordHeight*.84) - the tassel below the grip is a thin decorative cord,
  // not part of what needs to have "passed" before disturbance can begin.
  float tailGapAtCross = clamp(0.2564 - 0.54 * rowCrossedAtProgress, 0.0, 0.5);
  // Dead zone = full sword length past the blade line, plus a small extra
  // buffer, so disturbance starts a beat after the tail has cleared a row -
  // not the instant the tip appears there.
  float baseDelay = tailGapAtCross + 0.02;
  float flowStartProgress = rowCrossedAtProgress + baseDelay;

  // Once a row has been flowing for this many uProgress units, it freezes
  // solid instead of animating for the rest of the cycle. Empirical value,
  // tune during QA. Lowered from 0.26 so rows settle sooner instead of
  // still visibly churning well after the sword has passed.
  const float settleWindow = 0.14;
  float freezeAtProgress = flowStartProgress + settleWindow;

  // The freeze itself: everything downstream reads effectiveProgress
  // instead of uProgress, so once the live uProgress passes this row's
  // freeze point, effectiveProgress stops advancing and the pixel output
  // becomes a fixed function of uv alone - a true per-row freeze, no
  // feedback texture or extra uniform needed.
  float effectiveProgress = min(uProgress, freezeAtProgress);

  float crossProgress = clamp(effectiveProgress - rowCrossedAtProgress, 0.0, 1.0);
  float delayedCross = clamp(
      (crossProgress - baseDelay) / max(1.0 - baseDelay, 0.001), 0.0, 1.0);
  float flowEase = 1.0 - exp(-3.0 * delayedCross);
  const float streakMax = 0.40;
  // Core channel (river) is carried harder than the wide turbulence fringe.
  float streak = flowEase * streakMax * mix(0.55, 1.0, river);
  // Small perpetual creep while still active, driven by effectiveProgress
  // (not flowEase's plateau) so it keeps the current from feeling frozen
  // during the active window - and, since it reads effectiveProgress, it
  // stops advancing at exactly the same moment the row freezes.
  float continuousDrift = disturbance * flowEase * effectiveProgress * 0.02;

  // Turbulence fields drift with effectiveProgress (not wall-clock uTime)
  // on both axes, so the wobble pattern visibly travels while active and
  // - because effectiveProgress is what freezes per row - locks in place
  // exactly when that row freezes, with no separate uniform needed.
  float flowA = fbm(vec2(uv.x * 9.0 - effectiveProgress * 0.10, uv.y * 8.0 - effectiveProgress * 0.22));
  float flowB = fbm(vec2(uv.x * 13.0 + effectiveProgress * 0.16, uv.y * 17.0 - effectiveProgress * 0.28));
  float flowC = fbm(vec2(uv.x * 23.0 - effectiveProgress * 0.12, uv.y * 31.0 - effectiveProgress * 0.18));

  // Wobble amplitude is also gated by flowEase, so no horizontal jitter or
  // vertical micro-turbulence appears until a row has actually been left
  // behind by the blade for a beat.
  // Pushes samples near the centerline out toward whichever bank they're
  // closest to - strongest right at the center, fading to nothing once a
  // sample is already near the bank - selling the "squeezed outward" motion
  // rather than just a static concentration gradient.
  // Fade the push to zero in a thin band hugging the centerline instead of
  // flipping at full strength the instant uv.x crosses 0.5 - sign(uv.x-0.5)
  // jumps from -1 to +1 right where (1-edgeConcentration) is at its max,
  // so without this fade the two sides get yanked apart at full force at
  // exactly the same point, reading as a visible vertical seam.
  float distFromCenterForPush = abs(uv.x - 0.5);
  float centerFade = smoothstep(0.0, 0.05, distFromCenterForPush);
  float squeezePush = sign(uv.x - 0.5) * centerFade
      * (1.0 - edgeConcentration) * 0.02;
  float wobbleX = flowEase * (
      (flowA - 0.5) * (0.05 + outward * 0.05)
          + sin(uv.y * 42.0 + flowB * 8.0) * 0.012
          + squeezePush
  );
  float wobbleY = flowEase * ((flowB - flowC) * (0.03 + outward * 0.02));
  float verticalPull = streak + continuousDrift + wobbleY;

  // Positive y offset: sample the source from further down (larger uv.y),
  // so this pixel shows pigment carried up from below - matching the
  // sword's bottom-to-top travel direction.
  vec2 baseDisplacement = vec2(wobbleX, verticalPull) * disturbance;

  vec2 displacedUv = clamp(sourceUv + baseDisplacement, vec2(0.001), vec2(0.999));
  vec4 moved = texture(uTexture, displacedUv);

  // Two extra taps further along the same upward flow direction stand in for
  // a directional motion streak; min() across taps still pools/darkens wet
  // ink, but the pooling is now directional instead of symmetric left/right.
  vec2 tapUv1 = clamp(
    sourceUv + vec2(wobbleX * 0.6, streak * 0.33 + wobbleY),
    vec2(0.001), vec2(0.999)
  );
  vec2 tapUv2 = clamp(
    sourceUv + vec2(wobbleX * 1.2, streak * 0.66 + wobbleY),
    vec2(0.001), vec2(0.999)
  );
  vec4 tap1 = texture(uTexture, tapUv1);
  vec4 tap2 = texture(uTexture, tapUv2);

  // Dark pigment is pooled from nearby real source pixels; min() mimics wet
  // ink collecting in eddies while retaining the source painting's texture.
  vec3 pooledPigment = min(moved.rgb, min(tap1.rgb, tap2.rgb));
  float bandField = 0.5 + 0.5 * sin(
    uv.y * 83.0 + uv.x * 21.0
        + fbm(vec2(uv.x * 17.0, uv.y * 29.0 + effectiveProgress * 0.08)) * 15.0
  );
  float darkBand = 1.0 - smoothstep(0.24, 0.54, bandField);
  float pooling = disturbance * flowEase * mix(0.18, 1.0, darkBand)
      * mix(0.32, 1.0, edgeConcentration);
  vec3 color = mix(texture(uTexture, sourceUv).rgb, moved.rgb, disturbance * 0.92);
  color = mix(color, pooledPigment, pooling * 0.91);

  // Separate transported source pigment into fluid ink cells and paper cells.
  // The threshold is perturbed by the same moving flow, so the black/clear
  // shapes curl with the painting instead of looking painted on top.
  float pigmentLuma = dot(pooledPigment, vec3(0.299, 0.587, 0.114));
  float cellNoise = fbm(vec2(
    uv.x * 24.0 + flowA * 5.0 - effectiveProgress * 0.20,
    uv.y * 34.0 + flowB * 6.0 - streak * 6.0
  ));
  float inkCell = 1.0 - smoothstep(
    0.36,
    0.69,
    pigmentLuma + (cellNoise - 0.5) * 0.48
  );

  // Once the sword has crossed a row, the whole disturbed region keeps the
  // same fluid conversion strength. This is a persistent transformed painting,
  // not a temporary effect attached to the blade front.
  float fluidAmount = disturbance * flowEase * mix(0.38, 0.95, edgeConcentration);
  vec3 concentratedInk = pooledPigment * mix(0.48, 0.22, inkCell);
  color = mix(color, concentratedInk, inkCell * fluidAmount * 0.94);

  // Always fully opaque: pixels are only ever displaced/blended among
  // themselves, never faded to reveal the paper layer underneath.
  fragColor = vec4(color, 1.0);
}
