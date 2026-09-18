#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uImageSize;
uniform float uProgress;
uniform float uTime;
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

  // Curl-like displacement transports actual pigment from the source image.
  // No synthetic black marks are drawn.
  float flowA = fbm(vec2(uv.y * 8.0 - uTime * 0.16, uv.x * 9.0));
  float flowB = fbm(vec2(uv.y * 17.0 + 11.0, uv.x * 13.0 + uTime * 0.12));
  float flowC = fbm(vec2(uv.y * 31.0, uv.x * 23.0 - uTime * 0.10));
  float direction = (flowA - 0.5) * 2.0;
  vec2 displacement = vec2(
    direction * (0.014 + outward * 0.047)
        + sin(uv.y * 42.0 + flowB * 8.0) * 0.011,
    (flowB - flowC) * (0.008 + outward * 0.023)
  ) * disturbance;

  vec2 displacedUv = clamp(sourceUv + displacement, vec2(0.001), vec2(0.999));
  vec4 moved = texture(uTexture, displacedUv);
  vec4 pullLeft = texture(uTexture, clamp(
    displacedUv + vec2(-0.009 - outward * 0.018, 0.004),
    vec2(0.001), vec2(0.999)
  ));
  vec4 pullRight = texture(uTexture, clamp(
    displacedUv + vec2(0.010 + outward * 0.020, -0.004),
    vec2(0.001), vec2(0.999)
  ));

  // Dark pigment is pooled from nearby real source pixels; min() mimics wet
  // ink collecting in eddies while retaining the source painting's texture.
  vec3 pooledPigment = min(moved.rgb, min(pullLeft.rgb, pullRight.rgb));
  float bandField = 0.5 + 0.5 * sin(
    uv.y * 83.0 + uv.x * 21.0
        + fbm(vec2(uv.x * 17.0, uv.y * 29.0 + uTime * 0.08)) * 15.0
  );
  float darkBand = 1.0 - smoothstep(0.24, 0.54, bandField);
  float paperBand = smoothstep(0.46, 0.78, bandField);
  float pooling = disturbance * mix(0.18, 1.0, darkBand)
      * mix(0.34, 1.0, outward);
  vec3 color = mix(texture(uTexture, sourceUv).rgb, moved.rgb, disturbance * 0.92);
  color = mix(color, pooledPigment, pooling * 0.91);

  // Separate transported source pigment into fluid ink cells and paper cells.
  // The threshold is perturbed by the same moving flow, so the black/clear
  // shapes curl with the painting instead of looking painted on top.
  float pigmentLuma = dot(pooledPigment, vec3(0.299, 0.587, 0.114));
  float cellNoise = fbm(vec2(
    uv.x * 24.0 + flowA * 5.0 - uTime * 0.20,
    uv.y * 34.0 + flowB * 6.0 + uTime * 0.14
  ));
  float inkCell = 1.0 - smoothstep(
    0.36,
    0.69,
    pigmentLuma + (cellNoise - 0.5) * 0.48
  );

  // Once the sword has crossed a row, the whole disturbed region keeps the
  // same fluid conversion strength. This is a persistent transformed painting,
  // not a temporary effect attached to the blade front.
  float fluidAmount = disturbance * 0.92;
  vec3 concentratedInk = pooledPigment * mix(0.48, 0.22, inkCell);
  color = mix(color, concentratedInk, inkCell * fluidAmount * 0.94);

  // Reveal the actual paper layer instead of producing a flat white color.
  // Bright bands expose nearly all xuan-paper texture; dark bands retain the
  // displaced pigment, especially towards the two outer banks.
  float washNoise = fbm(vec2(uv.x * 19.0 + uTime * 0.06, uv.y * 25.0));
  float paperCell = (1.0 - inkCell) * mix(0.58, 1.0, paperBand);
  float wash = river * mix(0.92, 0.38, outward)
      * mix(0.24, 1.0, paperCell)
      * mix(0.76, 1.0, washNoise);
  float alpha = 1.0 - wash;
  fragColor = vec4(color, alpha);
}
