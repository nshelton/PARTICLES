
//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
  { 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
  }



#define PI 3.141592


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
// Pass UVs into fragment shader

varying float type ;
varying float distance ;
varying float alpha;
varying vec3 worldPos;
varying vec3 p;
varying float color_param ;
varying float fog;

uniform float time;
varying vec2 vUv;
varying float distortion;


float fbm(vec2 uv) 
{
  float speed = 0.1;
vec2 p = uv * 3.;
return  snoise(vec3(p , time*speed))        * 0.7     * audioLevelsSmooth[1] + 
        snoise(vec3(p * 2. , time*speed))   * 0.35    * audioLevelsSmooth[1]+
        snoise(vec3(p * 4. , time*speed))   * 0.125   * audioLevelsSmooth[2]+
        snoise(vec3(p * 8. , time*speed))   * 0.062   * audioLevelsSmooth[3] +
        snoise(vec3(p * 16. , time*speed))  * 0.031   * audioLevelsSmooth[3] ;
}

float gaussian(vec2 uv)
{
float x = length(uv) * 10. ;
float sigma = 0.2;
float alpha = 1.0 / ( sigma * sqrt(2.0 * 3.1415) );
return alpha * exp(-x * x / 2.0 * sigma);

}

// float interpolateAudioBuffer(float index) {
//   int a = int(floor(index));
//   float alpha = index - float(a);

//   float b = audio[a];
//   float c = audio[a+1];

//   return alpha * b + (1.0 - alpha) * c;

// }

void main()
{
  vUv = uv;

  // vec4 distorted_pos = modelViewMatrix * vec4(position, 1.0);

  // distortion =  sin(vUv.x* 10.  + time speed* sin(vUv.y  + time) ;
  // distortion = fbm(uv) * gaussian(uv);

  p = fract(position.yxz);
  // p.z += fract(time/100.0);
  worldPos = position;
  type = 0.0;
  // alpha =  snoise(p.xyz *2.0 + vec3(0.,0.,time/20.)) ; 

  // float torus_thickness = 0.4 + snoise(p.xyz* 3.0 + snoise(p.xyz) + time) * 0.3 ;

  // float audio = interpolateAudioBuffer(p.x * 512.0);
  float audio = texture2D(timeData,  vec2(p.x, audioOffset)).a  ;
  float freq = texture2D(timeData, p.xy + vec2(0.0, audioOffset)).a  ;
  // gl_PointSize =   audioLevels[int(p.x * 4.0)] * 3.0 + 1.0;
  // gl_PointSize = 0.1 ; //audioLevelsSmooth[1] * 3.0 + 1.;
  // gl_PointSize =   3.0;

  float dist = 1.0 - p.y;
  p -= 0.5; 

if (false){

   if( p.y > -0.4) {
  // if( true) {
    float rad = freq / 10.0 + dist;
    float strength = audioLevelsSmooth[0];
    rad += strength * snoise(p * 10.0 + vec3(0.,  time/10., 0.)) / 4.0 ;
    float angle = p.x * PI * 2.0;

    p.x = cos(angle) * rad;
    p.z = sin(angle) * rad;


    color_param = freq;
    alpha = (p.y + 0.5) / 10.0;
  }
  else{
    p.z = audio / 2.0 - 0.25 ;
    p.z += snoise(p)*0.1;
    // p.xy *= 3.0;
    p.y *= audioLevelsSmooth[1];
    alpha =audioLevelsSmooth[2];
    color_param = worldPos.y;
  }
}



  distortion = fbm(p.xy  * 3.0);

  float r = 0.5 + distortion * 0.1 ;
  // r *= 1.0 - (p.y + 0.5);

  float theta = p.x * 2.0  + time * 0.01;

  // p.z = r * cos(theta);
  // p.x = r * sin(theta);
  // p.y += distortion;

  distortion = distortion * audioLevels[0] * gaussian(p.xy*2.0);
  

  p.z += distortion * 0.1 ;
  p *= 4.;
  




  vec4 viewSpace = modelViewMatrix * vec4(p,1.0);



  float FogDensity = 0.5;
  float p_dist = length(viewSpace);
  fog = 1.0 /exp( (p_dist * FogDensity)* (p_dist * FogDensity));
  fog = clamp( fog, 0.0, 1.0 );

  gl_PointSize = 10.0;

  gl_Position = projectionMatrix * viewSpace;

}