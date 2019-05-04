#version 120

#define SHADOW_MAP_BIAS 0.90

#define GLOWING_REDSTONE_BLOCK // If enabled, redstone blocks are treated as light sources for GI
#define GLOWING_LAPIS_LAZULI_BLOCK // If enabled, lapis lazuli blocks are treated as light sources for GI



varying vec4 texcoord;
varying vec4 vPosition;
varying vec4 color;
varying vec4 lmcoord;

varying vec3 normal;
varying vec3 rawNormal;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;

varying float materialIDs;
varying float iswater;
varying float isStainedGlass;
varying vec4 viewPos;

uniform sampler2D noisetex;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;


varying float invalid;

vec4 cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	int resolution = 64;

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}


vec4 TextureSmooth(in sampler2D tex, in vec2 coord)
{
	int resolution = 64;

	coord *= resolution;
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	     f = f * f * (3.0f - 2.0f * f);

	coord = (i + f) / resolution;

	vec4 result = texture2D(tex, coord);

	return result;
}


uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;

#include "GIVolume.inc"





vec2 VolumeToScreenSpace(vec3 pos)
{
	pos = WorldToVolumeShadow(pos);

	return VolumeCoordToTexcoordShadow(pos);
}




void main() {
	gl_Position = ftransform();

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	texcoord = gl_MultiTexCoord0;
	

	viewPos = gl_ModelViewMatrix * gl_Vertex;


	vec4 position = gl_Position;


		 //position *= position.w;

		 position = shadowProjectionInverse * position;
		 position = shadowModelViewInverse * position;
		 position.xyz += cameraPosition.xyz;
		 //position = gbufferModelView * position;


	//convert to world-space position

	materialIDs = 100.0f;


	iswater = 0.0;

	if (mc_Entity.x == 1971.0f)
	{
		iswater = 1.0f;
	}

	if (mc_Entity.x == 8 || mc_Entity.x == 9) {
		iswater = 1.0f;
	}

	float isice = 0.0f;


	
	if (mc_Entity.x == 79) {
		isice = 1.0f;
	}

	isStainedGlass = 0.0f;

	if (mc_Entity.x == 95 || mc_Entity.x == 160)
	{
		isStainedGlass = 1.0f;
	}


	//Grass
	if  (  mc_Entity.x == 31.0

		|| mc_Entity.x == 38.0f 	//Rose
		|| mc_Entity.x == 37.0f 	//Flower

		/*
		|| mc_Entity.x == 1925.0f 	//Biomes O Plenty: Medium Grass
		|| mc_Entity.x == 1920.0f 	//Biomes O Plenty: Thorns, barley
		|| mc_Entity.x == 1921.0f 	//Biomes O Plenty: Sunflower
		|| mc_Entity.x == 188.0f 	//Biomes O Plenty: Medium Grass
		|| mc_Entity.x == 176.0f 	//Biomes O Plenty: Desert Grass
		|| mc_Entity.x == 177.0f 	//Biomes O Plenty: Desert Grass
		|| mc_Entity.x == 178.0f 	//Lavender

		*/
		)
	{
			materialIDs = max(materialIDs, 102.0f);
	}

	//Wheat
	if (mc_Entity.x == 59.0) {
		materialIDs = max(materialIDs, 102.0f);
	}	
	
	//Leaves
	if   ( mc_Entity.x == 18.0 

		|| mc_Entity.x == 161.0f

		/*
		|| mc_Entity.x == 1962.0f //Biomes O Plenty: Leaves
		|| mc_Entity.x == 1924.0f //Biomes O Plenty: Leaves
		|| mc_Entity.x == 1923.0f //Biomes O Plenty: Leaves
		|| mc_Entity.x == 1926.0f //Biomes O Plenty: Leaves
		|| mc_Entity.x == 1936.0f //Biomes O Plenty: Giant Flower Leaves
		|| mc_Entity.x == 184.0f  //Yellow autumn leaves
		|| mc_Entity.x == 185.0f  //Dying leaves
		|| mc_Entity.x == 186.0f  //maple leaves
		|| mc_Entity.x == 187.0f  //maple leaves
		|| mc_Entity.x == 192.0f  //maple leaves
		|| mc_Entity.x == 249.0f  //Willow leaves
		|| mc_Entity.x == 248.0f  //Sacred Oak Leaves
		*/

		 ) {
		materialIDs = max(materialIDs, 103.0f);
	}
		
	//Ice
	if (  mc_Entity.x == 79.0f
	   || mc_Entity.x == 174.0f)
	{
		materialIDs = max(materialIDs, 104.0f);
	}

	//Cobweb
	if ( mc_Entity.x == 30.0f)
	{
		materialIDs = max(materialIDs, 111.0f);
	}

	//torch	
	if (mc_Entity.x == 50) {
		materialIDs = max(materialIDs, 130.0f);
	}

	//lava
	if (mc_Entity.x == 10 || mc_Entity.x == 11) {
		materialIDs = max(materialIDs, 131.0f);
	}

	//glowstone and lamp
	if (mc_Entity.x == 89 || mc_Entity.x == 124) {
		materialIDs = max(materialIDs, 132.0f);
	}

	//fire
	if (mc_Entity.x == 51) {
		materialIDs = max(materialIDs, 133.0f);
	}


#ifdef GLOWING_LAPIS_LAZULI_BLOCK

	//lapis lazuli
	if (mc_Entity.x == 22) 
	{
		materialIDs = max(materialIDs, 135.0);
	}

#endif


#ifdef GLOWING_REDSTONE_BLOCK

	//Redstone block
	if (mc_Entity.x == 152) 
	{
		materialIDs = max(materialIDs, 136.0);
	}

#endif


	float grassWeight = mod(texcoord.t * 16.0f, 1.0f / 16.0f);

	float lightWeight = clamp((lmcoord.t * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
		  lightWeight *= 1.1f;
		  lightWeight -= 0.1f;
		  lightWeight = max(0.0f, lightWeight);
		  lightWeight = pow(lightWeight, 5.0f); 

		  if (grassWeight < 0.01f) {
		  	grassWeight = 1.0f;
		  } else {
		  	grassWeight = 0.0f;
		  }

		  /*
	//Waving grass
	//Waving grass
	if (materialIDs == 2.0f)
	{
		vec2 angleLight = vec2(0.0f);
		vec2 angleHeavy = vec2(0.0f);
		vec2 angle 		= vec2(0.0f);

		vec3 pn0 = position.xyz;
			 pn0.x -= frameTimeCounter / 3.0f;

		vec3 stoch = BicubicTexture(noisetex, pn0.xz / 64.0f).xyz;
		vec3 stochLarge = BicubicTexture(noisetex, position.xz / (64.0f * 6.0f)).xyz;

		vec3 pn = position.xyz;
			 pn.x *= 2.0f;
			 pn.x -= frameTimeCounter * 15.0f;
			 pn.z *= 8.0f;

		vec3 stochLargeMoving = BicubicTexture(noisetex, pn.xz / (64.0f * 10.0f)).xyz;



		vec3 p = position.xyz;
		 	 p.x += sin(p.z / 2.0f) * 1.0f;
		 	 p.xz += stochLarge.rg * 5.0f;

		float windStrength = mix(0.85f, 1.0f, rainStrength);
		float windStrengthRandom = stochLargeMoving.x;
			  windStrengthRandom = pow(windStrengthRandom, mix(2.0f, 1.0f, rainStrength));
			  windStrength *= mix(windStrengthRandom, 0.5f, rainStrength * 0.25f);
			  //windStrength = 1.0f;

		//heavy wind
		float heavyAxialFrequency 			= 8.0f;
		float heavyAxialWaveLocalization 	= 0.9f;
		float heavyAxialRandomization 		= 13.0f;
		float heavyAxialAmplitude 			= 15.0f;
		float heavyAxialOffset 				= 15.0f;

		float heavyLateralFrequency 		= 6.732f;
		float heavyLateralWaveLocalization 	= 1.274f;
		float heavyLateralRandomization 	= 1.0f;
		float heavyLateralAmplitude 		= 6.0f;
		float heavyLateralOffset 			= 0.0f;

		//light wind
		float lightAxialFrequency 			= 5.5f;
		float lightAxialWaveLocalization 	= 1.1f;
		float lightAxialRandomization 		= 21.0f;
		float lightAxialAmplitude 			= 5.0f;
		float lightAxialOffset 				= 5.0f;

		float lightLateralFrequency 		= 5.9732f;
		float lightLateralWaveLocalization 	= 1.174f;
		float lightLateralRandomization 	= 0.0f;
		float lightLateralAmplitude 		= 1.0f;
		float lightLateralOffset 			= 0.0f;

		float windStrengthCrossfade = clamp(windStrength * 2.0f - 1.0f, 0.0f, 1.0f);
		float lightWindFade = clamp(windStrength * 2.0f, 0.2f, 1.0f);

		angleLight.x += sin(frameTimeCounter * lightAxialFrequency 		- p.x * lightAxialWaveLocalization		+ stoch.x * lightAxialRandomization) 	* lightAxialAmplitude 		+ lightAxialOffset;	
		angleLight.y += sin(frameTimeCounter * lightLateralFrequency 	- p.x * lightLateralWaveLocalization 	+ stoch.x * lightLateralRandomization) 	* lightLateralAmplitude  	+ lightLateralOffset;

		angleHeavy.x += sin(frameTimeCounter * heavyAxialFrequency 		- p.x * heavyAxialWaveLocalization		+ stoch.x * heavyAxialRandomization) 	* heavyAxialAmplitude 		+ heavyAxialOffset;	
		angleHeavy.y += sin(frameTimeCounter * heavyLateralFrequency 	- p.x * heavyLateralWaveLocalization 	+ stoch.x * heavyLateralRandomization) 	* heavyLateralAmplitude  	+ heavyLateralOffset;

		angle = mix(angleLight * lightWindFade, angleHeavy, vec2(windStrengthCrossfade));
		angle *= 2.0f;

		// //Rotate block pivoting from bottom based on angle
		position.x += (sin((angle.x / 180.0f) * 3.141579f)) * grassWeight * lightWeight						* 0.5f	;
		position.z += (sin((angle.y / 180.0f) * 3.141579f)) * grassWeight * lightWeight						* 0.5f	;
		position.y += (cos(((angle.x + angle.y) / 180.0f) * 3.141579f) - 1.0f)  * grassWeight * lightWeight	* 0.5f	;
	}


	const float pi = 3.14159265;

	if (materialIDs == 3.0f && texcoord.t < 1.90 && texcoord.t > -1.0) {
		float speed = 0.05;


			  //lightWeight = max(0.0f, 1.0f - (lightWeight * 5.0f));
		
		float magnitude = (sin((position.y + position.x + frameTimeCounter * pi / ((28.0) * speed))) * 0.15 + 0.15) * 0.30 * lightWeight * 0.2;
			  // magnitude *= grassWeight;
			  magnitude *= lightWeight;
		float d0 = sin(frameTimeCounter * pi / (112.0 * speed)) * 3.0 - 1.5;
		float d1 = sin(frameTimeCounter * pi / (142.0 * speed)) * 3.0 - 1.5;
		float d2 = sin(frameTimeCounter * pi / (132.0 * speed)) * 3.0 - 1.5;
		float d3 = sin(frameTimeCounter * pi / (122.0 * speed)) * 3.0 - 1.5;
		position.x += sin((frameTimeCounter * pi / (18.0 * speed)) + (-position.x + d0)*1.6 + (position.z + d1)*1.6) * magnitude * (1.0f + rainStrength * 1.0f);
		position.z += sin((frameTimeCounter * pi / (17.0 * speed)) + (position.z + d2)*1.6 + (-position.x + d3)*1.6) * magnitude * (1.0f + rainStrength * 1.0f);
		position.y += sin((frameTimeCounter * pi / (11.0 * speed)) + (position.z + d2) + (position.x + d3)) * (magnitude/2.0) * (1.0f + rainStrength * 1.0f);
		
	}
	
	//lower leaf movement
	if (materialIDs == 3.0f) {
		float speed = 0.075;


		
		float magnitude = (sin((frameTimeCounter * pi / ((28.0) * speed))) * 0.05 + 0.15) * 0.075 * lightWeight * 0.2;
			  // magnitude *= 1.0f - grassWeight;
			  magnitude *= lightWeight;
		float d0 = sin(frameTimeCounter * pi / (122.0 * speed)) * 3.0 - 1.5;
		float d1 = sin(frameTimeCounter * pi / (142.0 * speed)) * 3.0 - 1.5;
		float d2 = sin(frameTimeCounter * pi / (162.0 * speed)) * 3.0 - 1.5;
		float d3 = sin(frameTimeCounter * pi / (112.0 * speed)) * 3.0 - 1.5;
		position.x += sin((frameTimeCounter * pi / (13.0 * speed)) + (position.x + d0)*0.9 + (position.z + d1)*0.9) * magnitude;
		position.z += sin((frameTimeCounter * pi / (16.0 * speed)) + (position.z + d2)*0.9 + (position.x + d3)*0.9) * magnitude;
		position.y += sin((frameTimeCounter * pi / (15.0 * speed)) + (position.z + d2) + (position.x + d3)) * (magnitude/1.0);
	}

*/


	vec3 worldNormal = gl_Normal;

	if (abs(materialIDs - 2.0) < 0.1)
	{
		worldNormal = vec3(0.0, 1.0, 0.0);
	}

	normal = normalize(gl_NormalMatrix * worldNormal);

	color = gl_Color;

	invalid = 0.0;

	float big = 1.0;

	if (iswater > 0.5 || isice > 0.5 || mc_Entity.x < 1.0
		|| fract(position.x) > 0.01 && fract(position.x) < 0.99
		|| fract(position.y) > 0.01 && fract(position.y) < 0.99
		|| fract(position.z) > 0.01 && fract(position.z) < 0.99
		// || mc_Entity.y != 3.0
		|| fract(worldNormal.x) > 0.01 && fract(worldNormal.x) < 0.99
		|| fract(worldNormal.y) > 0.01 && fract(worldNormal.y) < 0.99
		|| fract(worldNormal.z) > 0.01 && fract(worldNormal.z) < 0.99
		|| mc_Entity.x == 10.0 || mc_Entity.x == 11.0
		|| mc_Entity.x == 64.0 || mc_Entity.x == 102.0
		|| mc_Entity.x == 54.0 || mc_Entity.x == 65.0
		|| mc_Entity.x == 66.0 || mc_Entity.x == 68.0
		|| mc_Entity.x == 69.0 || mc_Entity.x == 70.0
		|| mc_Entity.x == 26.0 || mc_Entity.x == 27.0
		|| mc_Entity.x == 28.0 || mc_Entity.x == 34.0
		|| mc_Entity.x == 28.0 || mc_Entity.x == 55.0
		|| mc_Entity.x == 63.0 || mc_Entity.x == 68.0
		|| mc_Entity.x == 71.0 || mc_Entity.x == 72.0
		|| mc_Entity.x == 77.0 || mc_Entity.x == 85.0
		|| mc_Entity.x == 96.0 || mc_Entity.x == 101.0
		|| mc_Entity.x == 107.0 || mc_Entity.x == 113.0
		|| mc_Entity.x == 117.0 || mc_Entity.x == 118.0
		|| mc_Entity.x == 131.0 || mc_Entity.x == 132.0
		|| mc_Entity.x == 139.0 || mc_Entity.x == 157.0
		|| mc_Entity.x == 50.0 || mc_Entity.x == 51.0
		|| mc_Entity.x == 106.0 || mc_Entity.x == 20.0
		|| (mc_Entity.x > 192 && mc_Entity.x < 198) //doors
		)
	{
		// position.xyz += 0.0;
		invalid = 1.0;
		// big = 200.0;
	}



	// if (mc_Entity.x == 1.0)
	// {
	// 	// big = 20.0;
	// }


	//position = gbufferModelViewInverse * position;

	vec3 worldPosition = position.xyz;

	position.xyz -= cameraPosition.xyz;
	position = shadowModelView * position;
	position = shadowProjection * position;



	if (materialIDs != 2.0)
	{
		if (worldNormal.x > 0.85)
		{
			color.rgb *= 1.0 / 0.6;
		}
		if (worldNormal.x < -0.85)
		{
			color.rgb *= 1.0 / 0.6;
		}
		if (worldNormal.z > 0.85)
		{
			color.rgb *= 1.0 / 0.8;
		}
		if (worldNormal.z < -0.85)
		{
			color.rgb *= 1.0 / 0.8;
		}
		if (worldNormal.y < -0.85)
		{
			color.rgb *= 1.0 / 0.5;
		}
	}








	vec3 rawTangent;
	vec3 rawBinormal;

	if (gl_Normal.x > 0.5) 
	{
		rawTangent = vec3(0.0, 0.0, -1.0);
		rawBinormal = vec3(0.0, -1.0, 0.0);
	} 
	else if (gl_Normal.x < -0.5) 
	{
		rawTangent = vec3(0.0, 0.0, 1.0);
		rawBinormal = vec3(0.0, -1.0, 0.0);
	} 
	else if (gl_Normal.y > 0.5) 
	{
		rawTangent = vec3(1.0, 0.0, 0.0);
		rawBinormal = vec3(0.0, 0.0, 1.0);
	} 
	else if (gl_Normal.y < -0.5) 
	{
		rawTangent = vec3(1.0, 0.0, 0.0);
		rawBinormal = vec3(0.0, 0.0, -1.0);
	} 
	else if (gl_Normal.z > 0.5) 
	{
		rawTangent = vec3(1.0, 0.0, 0.0);
		rawBinormal = vec3(0.0, -1.0, 0.0);
	} 
	else if (gl_Normal.z < -0.5) 
	{
		rawTangent = vec3(-1.0, 0.0, 0.0);
		rawBinormal = vec3(0.0, -1.0, 0.0);
	}


	// if (fract(gl_Normal.x) > 0.0 || fract(gl_Normal.y) > 0.0 || fract(gl_Normal.z) > 0.0 || mc_Entity.x == 10 || mc_Entity.x == 11)
	// {
	// 	worldPosition.xyz = vec3(100000.0);
	// }


	vec2 fractionalTexcoord = clamp((texcoord.st - mc_midTexCoord.st) * 1000.0, vec2(0.0), vec2(1.0));


	float scale = 0.15;

	rawTangent = normalize(at_tangent.xyz);
	rawBinormal = normalize(cross(rawTangent, worldNormal.xyz));

	//slide in on face
	vec3 cubeCoord = worldPosition.xyz + mix(rawTangent * scale, -rawTangent * scale, vec3(fractionalTexcoord.x));
	cubeCoord.xyz += mix(rawBinormal * scale, -rawBinormal * scale, vec3(fractionalTexcoord.y));

	//push into cube
	cubeCoord.xyz -= gl_Normal.xyz * scale;


	//Squash into point at voxel center
	cubeCoord = floor(cubeCoord);

	cubeCoord -= cameraPosition.xyz;



	//gl_Position = vec4((cubeCoord.xz + fractionalTexcoord.xy) * 0.1, cubeCoord.z * 0.002, 1.0);
	gl_Position = vec4((VolumeToScreenSpace(cubeCoord.xyz ) + fractionalTexcoord.xy * (1.0 / vec2(4096, 4096)) * big) * 2.0 - 1.0, 0.0, 1.0);

	//gl_Position = vec4(texcoord.st * 2.0 - 1.0, 0.0, 1.0);







	// gl_Position = position;

	// float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	// float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS + 0.0;
	// gl_Position.xy *= 0.95f / distortFactor;

	// gl_Position.z = mix(gl_Position.z, 0.5, 0.8);


	vPosition = gl_Position;

	gl_FrontColor = gl_Color;


	
}
