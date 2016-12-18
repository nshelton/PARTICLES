
var scene;
var camera;
var renderer;
var controls;

var loaded = false;
var plane;
var buffer_size = 512;
var history_size = 128;

var audio;
var cpu_buffer = new Uint8Array(buffer_size);


var particleMaterial;


function setup() {

  // Empty Scene
  scene = new THREE.Scene();

  // Setup Camera
  camera = new THREE.PerspectiveCamera( 60, window.innerWidth / window.innerHeight, 0.001, 1000 );
  camera.position.set(0, -1, 0.01);

  // Setup Renderer
  renderer = new THREE.WebGLRenderer();
	renderer.setSize( window.innerWidth, window.innerHeight );
	var container = $('body');
  container.append(renderer.domElement);

  //Trackball Controls
  controls = new THREE.TrackballControls( camera, renderer.domElement );
  controls.target.set(0, 0, 0);
  controls.noZoom = false;
  controls.noPan = false;

}


function setUniforms() {
  particleMaterial.uniforms.time.value += 0.1;
  // computeEffectEnvelopes();
}

function computeEffectEnvelopes() {
  var right = material.uniforms.r_click_effect.value;
  var left  = material.uniforms.l_click_effect.value;

  if( r_click_envelope == "attack" ) {
    material.uniforms.r_click_effect.value += 0.1;
    if ( material.uniforms.r_click_effect.value > 0.5 ) {
      r_click_envelope = "decay";
    }
  } else if (r_click_envelope == "decay") {
    material.uniforms.r_click_effect.value *= .99;
    if ( material.uniforms.r_click_effect.value < 0.01) {
      r_click_envelope = "off";
    }
  }
  if( l_click_envelope == "trans_on" ) {
    if ( material.uniforms.l_click_effect.value < 1.0 ) {
      material.uniforms.l_click_effect.value += 0.1
    } else {
      material.uniforms.l_click_effect.value = 1;
    }
  } else if (l_click_envelope == "trans_off") {
    material.uniforms.l_click_effect.value *= .9;;
    if ( material.uniforms.l_click_effect.value <  0.01) {
      material.uniforms.l_click_effect.value = 0.0
      l_click_envelope = "off";
    }
  }
}


 function genDataTex( width, height, color ) {
  var size = width * height;
  var data = new Uint8Array( 3 * size );
  var r = Math.floor( color.r * 255 );
  var g = Math.floor( color.g * 255 );
  var b = Math.floor( color.b * 255 );
  for ( var i = 0; i < size; i ++ ) {
          data[ i * 3 ]            = r;
          data[ i * 3 + 1 ] = g;
          data[ i * 3 + 2 ] = b;
  }
  var texture = new THREE.DataTexture( data, width, height, THREE.RGBFormat );
  texture.needsUpdate = true;
  return texture;
}



function texturePlane(texture, shaders) {
 
  var material = new THREE.ShaderMaterial({
    uniforms: {
          texture: {type : "t" , value : texture}
    },
    vertexShader: shaders.vert_plane.shader,
    fragmentShader: shaders.frag_plane.shader
  });
  var geometry = new THREE.PlaneGeometry( 0.5, 0.5, 3 );
  var plane = new THREE.Mesh( geometry, material );

  return plane ;


}
function emptyTex(buffer_size, history_size) {
  console.log("creating ", + buffer_size + " " + history_size)
    var size = buffer_size * history_size;
    var data = new Uint8Array( size );
 
    for ( var i = 0; i < size; i ++ ) {

      data[ i  ]   = Math.random() * 256;
    }

    var texture = new THREE.DataTexture( data, buffer_size, history_size, THREE.AlphaFormat );
    texture.needsUpdate = true;

    return texture;

}



function setupScene(shaders) {

  audio = new ThreeAudio.Source().mic()
  audioTextures = new ThreeAudio.Textures(renderer, audio);
  

  var geometry = new THREE.Geometry();

  var dim = 1024;

  for ( var x = 0; x < dim; x ++ ) {
    for ( var y = 0; y < dim; y ++ ) {
      // for ( var z = 0; z < 4; z ++ ) {
        geometry.vertices.push( new THREE.Vector3(
          // Math.random(), Math.random(), 0.5));
          x/dim, y/dim, 0.5));
      // }
    }
  }

  var colormapTex = THREE.ImageUtils.loadTexture("./img/colormap.jpg");
  colormapTex.magFilter = THREE.NearestFilter;
 

  var uniforms = {
    colorMap: {type : "t" , value : colormapTex},
    time: { 
      type : "f",
      value: 1.0 
    },
      resolution: {
      type: "v2",
      value: new THREE.Vector2() 
    },

    freqData  : emptyTex(buffer_size, history_size),

    timeData :  emptyTex(buffer_size, history_size),

    audioIsBeat: {
      type: 'f',
      value: 0,
    },
    audioWasBeat: {
      type: 'f',
      value: 0,
    },
    audioLevels: {
      type: 'fv1',
      value: [0,0,0,0],
    },
    audioLevelsSmooth: {
      type: 'fv1',
      value: [0,0,0,0],
    },
    audioLevelsChange: {
      type: 'fv1',
      value: [0,0,0,0],
    },
    audioOffset: {
      type: 'f',
      value: 0,
    },
    audioStep: {
      type: 'v2',
      value: { x: 0, y: 0 },
    }
  };

    particleMaterial = new THREE.ShaderMaterial({
      transparent:true,
      depthTest:false,
      blending:THREE.AdditiveBlending,
      uniforms: uniforms,
      vertexShader: shaders.vert_particle.shader,
      fragmentShader: shaders.frag_particle.shader
    })
 
    plane = new THREE.Points( geometry, particleMaterial )
    scene.add( plane );

  debugPlaneTime = texturePlane (  colormapTex, shaders);
  debugPlaneTime.position.set(-0.5, 0, 0);
  debugPlaneTime.rotation.x = 1.5;
  scene.add(debugPlaneTime);

  debugPlaneFreq = texturePlane ( emptyTex(buffer_size, history_size), shaders);
  debugPlaneFreq.position.set(0.5, 0, 0);
  debugPlaneFreq.rotation.x = 1.5;
  scene.add(debugPlaneFreq);

    loaded = true;

}

var frame = 1.0;
var j = 0;

function copyAudio() {

  // particleMaterial.uniforms.freqData.needsUpdate = true;
  // particleMaterial.uniforms.timeData.needsUpdate = true;
  // for( i in audioTextures.uniforms()) {
  //   if(particleMaterial.uniforms[i])
  //     particleMaterial.uniforms[i].value = audioTextures.uniforms()[i];
  // }

}


$( document ).ready(function() {


  
  new preLoad({

    vert_particle:         "./shaders/vert_particle.glsl",
    frag_particle:         "./shaders/frag_particle.glsl",

    vert_plane:         "./shaders/vert.glsl",
    frag_plane:         "./shaders/frag_plane.glsl",

    onLoadComplete: run

  });
});

function run( args) {

  setup();
  setupScene(args);

	function render() {

    audio.update();

    if (loaded){

      copyAudio();
      setUniforms();
      frame += 0.01;
      controls.update();
      renderer.render( scene, camera );

    }


    requestAnimationFrame( render );
	}


	render();

};