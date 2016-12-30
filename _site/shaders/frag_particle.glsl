
uniform vec2 resolution;
uniform float time;
varying vec3 worldPos;
varying vec3 p;

varying vec2 vUv;
varying float distortion;
varying float fog;
varying float alpha;

varying float type ;
varying float color_param ;

uniform sampler2D colorMap;

// Audio data textures
uniform sampler2D freqData;
uniform sampler2D timeData;
// Offset and sample size for sampling data textures
uniform float audioOffset;
uniform vec2 audioStep;
// Beat detection. Is = 0 or 1, Was = smoothed value.
uniform float audioIsBeat;
uniform float audioWasBeat;
// Precalculated audio levels, the components being (all, bass, mid, treble).
// Contains raw levels, smoothed levels and instantaneous change in levels.
uniform float audioLevels[4];
uniform float audioLevelsSmooth[4];
uniform float audioLevelsChange[4];


float bump(float alpha)
{
  return smoothstep(0.5, 0.75, alpha) * (1.0 - smoothstep(0.75, 0.99, alpha));
}


void main(void)
{
  float palette =  5.0/14. + 1.0/28.; //fract(sin(time/500.));

  float p_color = abs(distortion* 8.0);
  vec4 color = texture2D(colorMap, vec2(palette, 1.0 - p_color));
  // color *= alpha;

  color *= pow(1.0 - length(gl_PointCoord -0.5) * 2.0, 2.0);

  color *= fog;

  gl_FragColor = color;
  // gl_FragColor = vec4(1.0 - color_param, color_param, 1.0,  alpha );

}
