
      uniform vec2 resolution;
      uniform float time;
      varying vec3 worldPos;

      varying vec2 vUv;
      varying float distortion;
      varying float alpha;

      varying float type ;
      varying float color_param ;

      uniform sampler2D colormap;
      

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
        float palette = 0.34;

        vec4 color = texture2D(colormap, vec2(palette, color_param));
        color *= alpha;

        // gl_FragColor = color;
        gl_FragColor = vec4(1.0 - color_param, color_param, 1.0,  alpha );

      }
