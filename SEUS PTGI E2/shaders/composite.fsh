#version 120



#include "Common.inc"


/*
 _______ _________ _______  _______  _ 
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _ 
\_______)   )_(   (_______)|/       (_)

Do not modify this code until you have read the LICENSE.txt contained in the root directory of this shaderpack!

*/
#define SHADOW_MAP_BIAS 0.90

/////////ADJUSTABLE VARIABLES//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////ADJUSTABLE VARIABLES//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




#define ENABLE_SSAO	// Screen space ambient occlusion.
#define GI	// Indirect lighting from sunlight.

#define GI_QUALITY 0.5 // Number of GI samples. More samples=smoother GI. High performance impact! [0.5 1.0 2.0]
//#define GI_ARTIFACT_REDUCTION // Reduces artifacts on back edges of blocks at the cost of performance.
#define GI_RENDER_RESOLUTION 1 // Render resolution of GI. 0 = High. 1 = Low. Set to 1 for faster but blurrier GI. [0 1]
#define GI_RADIUS 1.0 // How far indirect light can spread. Can help to reduce artifacts with low GI samples. [0.5 0.75 1.0 1.5 2.0]

//#define HALF_RES_TRACE

/////////INTERNAL VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////INTERNAL VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Do not change the name of these variables or their type. The Shaders Mod reads these lines and determines values to send to the inner-workings
//of the shaders mod. The shaders mod only reads these lines and doesn't actually know the real value assigned to these variables in GLSL.
//Some of these variables are critical for proper operation. Change at your own risk.

const float 	shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 180.0 240.0]
const bool 		shadowHardwareFiltering0 = true;

const bool 		shadowtex1Mipmap = true;
const bool 		shadowtex1Nearest = false;
const bool 		shadowcolor0Mipmap = true;
const bool 		shadowcolor0Nearest = false;
const bool 		shadowcolor1Mipmap = true;
const bool 		shadowcolor1Nearest = false;

const int 		noiseTextureResolution  = 64;


//END OF INTERNAL VARIABLES//



uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D depthtex1;
uniform sampler2D composite;
uniform sampler2D gdepth;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowtex1;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

varying vec4 texcoord;
varying vec3 lightVector;

varying float timeSunriseSunset;
varying float timeNoon;
varying float timeMidnight;
varying float timeSkyDark;

varying vec3 colorSunlight;
varying vec3 colorSkylight;
varying vec3 colorSunglow;
varying vec3 colorBouncedSunlight;
varying vec3 colorScatteredSunlight;
varying vec3 colorTorchlight;
varying vec3 colorWaterMurk;
varying vec3 colorWaterBlue;
varying vec3 colorSkyTint;

varying vec4 skySHR;
varying vec4 skySHG;
varying vec4 skySHB;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform int   isEyeInWater;

varying vec3 upVector;

varying vec3 worldLightVector;
varying vec3 worldSunVector;

uniform int frameCounter;

uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousProjectionInverse;



/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



void TemporalJitterProjPos(inout vec4 pos)
{
	const vec2 haltonSequenceOffsets[16] = vec2[16](vec2(-1, -1), vec2(0, -0.3333333), vec2(-0.5, 0.3333334), vec2(0.5, -0.7777778), vec2(-0.75, -0.1111111), vec2(0.25, 0.5555556), vec2(-0.25, -0.5555556), vec2(0.75, 0.1111112), vec2(-0.875, 0.7777778), vec2(0.125, -0.9259259), vec2(-0.375, -0.2592592), vec2(0.625, 0.4074074), vec2(-0.625, -0.7037037), vec2(0.375, -0.03703701), vec2(-0.125, 0.6296296), vec2(0.875, -0.4814815));
	const vec2 bayerSequenceOffsets[16] = vec2[16](vec2(0, 3) / 16.0, vec2(8, 11) / 16.0, vec2(2, 1) / 16.0, vec2(10, 9) / 16.0, vec2(12, 15) / 16.0, vec2(4, 7) / 16.0, vec2(14, 13) / 16.0, vec2(6, 5) / 16.0, vec2(3, 0) / 16.0, vec2(11, 8) / 16.0, vec2(1, 2) / 16.0, vec2(9, 10) / 16.0, vec2(15, 12) / 16.0, vec2(7, 4) / 16.0, vec2(13, 14) / 16.0, vec2(5, 6) / 16.0);
	const vec2 otherOffsets[16] = vec2[16](vec2(0.375, 0.4375), vec2(0.625, 0.0625), vec2(0.875, 0.1875), vec2(0.125, 0.0625),
vec2(0.375, 0.6875), vec2(0.875, 0.4375), vec2(0.625, 0.5625), vec2(0.375, 0.9375),
vec2(0.625, 0.3125), vec2(0.125, 0.5625), vec2(0.125, 0.8125), vec2(0.375, 0.1875),
vec2(0.875, 0.9375), vec2(0.875, 0.6875), vec2(0.125, 0.3125), vec2(0.625, 0.8125)
);
	pos.xy -= ((bayerSequenceOffsets[int(mod(frameCounter, 12))] * 2.0 - 1.0) / vec2(viewWidth, viewHeight)) * 0.5;
	//pos.xy += (rand(vec2(mod(float(frameCounter) / 16.0, 1.0))).xy / vec2(viewWidth, viewHeight)) * 1.0;
}

void TemporalJitterProjPos(inout vec3 pos)
{
	const vec2 haltonSequenceOffsets[16] = vec2[16](vec2(-1, -1), vec2(0, -0.3333333), vec2(-0.5, 0.3333334), vec2(0.5, -0.7777778), vec2(-0.75, -0.1111111), vec2(0.25, 0.5555556), vec2(-0.25, -0.5555556), vec2(0.75, 0.1111112), vec2(-0.875, 0.7777778), vec2(0.125, -0.9259259), vec2(-0.375, -0.2592592), vec2(0.625, 0.4074074), vec2(-0.625, -0.7037037), vec2(0.375, -0.03703701), vec2(-0.125, 0.6296296), vec2(0.875, -0.4814815));
	const vec2 bayerSequenceOffsets[16] = vec2[16](vec2(0, 3) / 16.0, vec2(8, 11) / 16.0, vec2(2, 1) / 16.0, vec2(10, 9) / 16.0, vec2(12, 15) / 16.0, vec2(4, 7) / 16.0, vec2(14, 13) / 16.0, vec2(6, 5) / 16.0, vec2(3, 0) / 16.0, vec2(11, 8) / 16.0, vec2(1, 2) / 16.0, vec2(9, 10) / 16.0, vec2(15, 12) / 16.0, vec2(7, 4) / 16.0, vec2(13, 14) / 16.0, vec2(5, 6) / 16.0);
	const vec2 otherOffsets[16] = vec2[16](vec2(0.375, 0.4375), vec2(0.625, 0.0625), vec2(0.875, 0.1875), vec2(0.125, 0.0625),
vec2(0.375, 0.6875), vec2(0.875, 0.4375), vec2(0.625, 0.5625), vec2(0.375, 0.9375),
vec2(0.625, 0.3125), vec2(0.125, 0.5625), vec2(0.125, 0.8125), vec2(0.375, 0.1875),
vec2(0.875, 0.9375), vec2(0.875, 0.6875), vec2(0.125, 0.3125), vec2(0.625, 0.8125)
);
	pos.xy -= ((bayerSequenceOffsets[int(mod(frameCounter, 12))] * 2.0 - 1.0) / vec2(viewWidth, viewHeight)) * 0.5;
	//pos.xy += (rand(vec2(mod(float(frameCounter) / 16.0, 1.0))).xy / vec2(viewWidth, viewHeight)) * 1.0;
}



vec3  	GetNormals(in vec2 coord) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	return DecodeNormal(texture2D(gnormal, coord).xy);
}

float 	GetDepth(in vec2 coord) {
	return texture2D(depthtex1, coord.st).x;
}

vec4  	GetScreenSpacePosition(in vec2 coord) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord);
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;
	
	return fragposition;
}

vec4  	GetScreenSpacePosition(in vec2 coord, in float depth) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;
	
	return fragposition;
}

vec4 GetViewPosition(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);
	TemporalJitterProjPos(tcoord);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 1.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}

vec3 	CalculateNoisePattern1(vec2 offset, float size) {
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture2D(noisetex, coord).xyz;
}

float 	GetMaterialIDs(in vec2 coord) {			//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(composite, coord).b;
}

float GetSkylight(in vec2 coord)
{
	return texture2DLod(gdepth, coord, 0).g;
}

float 	GetMaterialMask(in vec2 coord, const in int ID) {
	float matID = (GetMaterialIDs(coord) * 255.0f);

	//Catch last part of sky
	if (matID > 254.0f) {
		matID = 0.0f;
	}

	if (matID == ID) {
		return 1.0f;
	} else {
		return 0.0f;
	}
}

bool 	GetSkyMask(in vec2 coord)
{
	float matID = GetMaterialIDs(coord);
	matID = floor(matID * 255.0f);

	if (matID < 1.0f || matID > 254.0f)
	{
		return true;
	} else {
		return false;
	}
}

vec3 ProjectBack(vec3 cameraSpace) 
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
		 //screenSpace.z = 0.1f;
    return screenSpace;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}


vec2 GetNearFragment(vec2 coord, float depth, out float minDepth)
{
	
	
	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
	vec4 depthSamples;
	depthSamples.x = texture2D(depthtex1, coord + texel * vec2(1.0, 1.0)).x;
	depthSamples.y = texture2D(depthtex1, coord + texel * vec2(1.0, -1.0)).x;
	depthSamples.z = texture2D(depthtex1, coord + texel * vec2(-1.0, 1.0)).x;
	depthSamples.w = texture2D(depthtex1, coord + texel * vec2(-1.0, -1.0)).x;

	vec2 targetFragment = vec2(0.0, 0.0);

	if (depthSamples.x < depth)
		targetFragment = vec2(1.0, 1.0);
	if (depthSamples.y < depth)
		targetFragment = vec2(1.0, -1.0);
	if (depthSamples.z < depth)
		targetFragment = vec2(-1.0, 1.0);
	if (depthSamples.w < depth)
		targetFragment = vec2(-1.0, -1.0);


	minDepth = min(min(min(depthSamples.x, depthSamples.y), depthSamples.z), depthSamples.w);

	return coord + texel * targetFragment;
}





#include "GIVolume.inc"


struct Ray {
	vec3 dir;
	vec3 origin;
};



struct BBRay 
{
    vec3 origin;
    vec3 direction;
    vec3 inv_direction;
    ivec3 sign;
};

BBRay MakeRay(vec3 origin, vec3 direction) 
{
    vec3 inv_direction = vec3(1.0) / direction;
    return BBRay(
        origin,
        direction,
        inv_direction,
        ivec3((inv_direction.x < 0) ? 1 : 0,
            (inv_direction.y < 0) ? 1 : 0,
            (inv_direction.z < 0) ? 1 : 0
        )
    );
}

void intersection_distances_no_if(
    in BBRay ray, in vec3 aabb[2],
    out float tmin, out float tmax)
{
    float tymin, tymax, tzmin, tzmax;
    tmin = (aabb[ray.sign[0]].x - ray.origin.x) * ray.inv_direction.x;
    tmax = (aabb[1-ray.sign[0]].x - ray.origin.x) * ray.inv_direction.x;
    tymin = (aabb[ray.sign[1]].y - ray.origin.y) * ray.inv_direction.y;
    tymax = (aabb[1-ray.sign[1]].y - ray.origin.y) * ray.inv_direction.y;
    tzmin = (aabb[ray.sign[2]].z - ray.origin.z) * ray.inv_direction.z;
    tzmax = (aabb[1-ray.sign[2]].z - ray.origin.z) * ray.inv_direction.z;
    tmin = max(max(tmin, tymin), tzmin);
    tmax = min(min(tmax, tymax), tzmax);
    // post condition:
    // if tmin > tmax (in the code above this is represented by a return value of INFINITY)
    //     no intersection
    // else
    //     front intersection point = ray.origin + ray.direction * tmin (normally only this point matters)
    //     back intersection point  = ray.origin + ray.direction * tmax
}


vec2 hash2(inout float seed) {
    return fract(sin(vec2(seed+=0.1,seed+=0.1))*vec2(43758.5453123,22578.1459123));
}

vec3 BlueNoise(vec2 coord)
{
	vec2 noiseCoord = vec2(coord.st * vec2(viewWidth, viewHeight)) / 64.0;
	//noiseCoord += vec2(frameCounter, frameCounter);
	//noiseCoord += mod(frameCounter, 16.0) / 16.0;
	//noiseCoord += rand(vec2(mod(frameCounter, 16.0) / 16.0, mod(frameCounter, 16.0) / 16.0) + 0.5).xy;
	noiseCoord += vec2(sin(frameCounter * 0.75), cos(frameCounter * 0.75));

	noiseCoord = (floor(noiseCoord * 64.0) + 0.5) / 64.0;

	return texture2D(noisetex, noiseCoord).rgb;
}

vec3 cosWeightedRandomHemisphereDirection( vec3 n, inout float seed, int offset ) {
  	vec2 r = hash2(seed);
  	// r = BlueNoise(texcoord.st).xy;
 //  	vec2 noiseCoord = texcoord.st * vec2(viewWidth, viewHeight);
 //  	noiseCoord /= 64.0;
 //  	noiseCoord += offset * 0.5;

	// noiseCoord += vec2(sin(frameCounter * 0.75), cos(frameCounter * 0.75));

 //  	vec2 r = texture2D(noisetex, noiseCoord.st).xy;
    
	vec3  uu = normalize( cross( n, vec3(0.0,1.0,1.0) ) );
	vec3  vv = cross( uu, n );
	
	float ra = sqrt(r.y);
	float rx = ra*cos(6.2831*r.x); 
	float ry = ra*sin(6.2831*r.x);
	float rz = sqrt( 1.0-r.y );
	vec3  rr = vec3( rx*uu + ry*vv + rz*n );
    
    return normalize( rr );
}

vec3 Fract01(vec3 pos)
{
	vec3 posf = fract(pos);

	for (int i = 0; i < 3; i++)
	{
		if (posf[i] == 0.0)
		{
			posf[i] = 1.0;
		}
	}

	return posf;
}

vec3 PathTraceGI(vec3 worldPos, vec3 worldNormal, vec3 worldDir, float mcSkylight)
{


	const int numSamples = 1;

	int volumeSize = GetVolumeTexSizeShadow();

	float halfVexel = (0.5 / float(volumeSize));

	vec3 lightSum = vec3(0.0);

	//float seed = (texcoord.x + texcoord.y * 3.4321 + fract(1.12345 * frameTimeCounter)) * 6.1;
	float seed = (texcoord.x + texcoord.y * 3.4321 + fract(frameCounter * 0.01) * 10.0) * 9.1;


	vec3 sideNormals[3] = vec3[3](vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));

	float totalRayLength = 0.0;

	// float mcSkylightWeight = saturate(mcSkylight * 10.0);
	float mcSkylightWeight = pow(mcSkylight, 1.1);
	mcSkylightWeight = 1.0;



	for (int i = 0; i < numSamples; i++)
	{


		vec3 rayDir = cosWeightedRandomHemisphereDirection(worldNormal, seed, i);
		// rayDir = normalize(rayDir + vec3(0.0, 0.0, 1.0));
		// rayDir = normalize(reflect(worldDir, worldNormal));

		vec3 rayOrigin = worldPos + worldNormal * 0.01;
		rayOrigin += Fract01(cameraPosition.xyz + 0.5);

		rayOrigin = WorldToVolumeShadow(rayOrigin);

		Ray ray;
		ray.origin = (rayOrigin) * volumeSize - vec3(1.0, 1.0, 1.0);
		ray.dir = rayDir;

		vec3 absorption = vec3(1.0);

		for (int b = 0; b < 2; b++)
		{
			ivec3 coord = ivec3(floor(ray.origin));
			vec3 deltaDist;
			vec3 next;
			ivec3 step;

			for (int i = 0; i < 3; i++)
			{
				float x = (ray.dir[0] / ray.dir[i]);
				float y = (ray.dir[1] / ray.dir[i]);
				float z = (ray.dir[2] / ray.dir[i]);

				deltaDist[i] = sqrt(x*x + y*y + z*z);

				if (ray.dir[i] < 0.0)
				{
					step[i] = -1;
					next[i] = (ray.origin[i] - coord[i]) * deltaDist[i];
				}
				else
				{
					step[i] = 1;
					next[i] = (coord[i] + 1.0 - ray.origin[i]) * deltaDist[i];
				}
			}


			int side = 0;
			float rayTravelDistance = 0.0;
			int numStepsCompleted = 0;
			for (int c = 0; c < 60; c++)
			{
				for (int i = 0; i < 3; i++)
				{
					if (next[side] > next[i])
					{
						side = i;
					}
				}

				next[side] += deltaDist[side];
				coord[side] += step[side];


				vec3 volumeCoord = vec3(coord) / float(volumeSize);
				vec2 lookupCoord = VolumeCoordToTexcoordShadow(volumeCoord, volumeSize);

				vec4 raySample = texture2DLod(shadowcolor, lookupCoord, 0);

				//If hit non-light block
				if (raySample.a * 255.0 > 1.0f && raySample.a * 255.0 < 128.0f)
				{
					vec3 materialColor = saturate(raySample.rgb * normalize(raySample.rgb) * 2.0);
					// materialColor = saturate(mix(materialColor, vec3(dot(materialColor, vec3(0.33333))), vec3(-0.5)));
					absorption *= materialColor;
					break;
				}

				if (raySample.a * 255.0 > 128.0f && raySample.a < 0.9)
				{
					lightSum += 1.0 * absorption * (b * 0.0 + 1.0) * normalize(raySample.rgb * raySample.rgb + 0.0001) * 1.0;
					break;
				}

				if (lookupCoord.x < 0.0 || lookupCoord.y < 0.0 || lookupCoord.x > 1.0 || lookupCoord.y > 1.0)
				{
					break;
				}

				numStepsCompleted++;
			}

			if (numStepsCompleted >= 59)
			{
				// vec3 skyRay = vec3(1.0, 1.0, 1.0);
				// lightSum += vec3(1.0) * pow(saturate(dot(ray.dir, worldLightVector)), 15.0) * 8.0 * absorption;

				// vec3 skyRay = max(vec3(0.0), FromSH(skySHR, skySHG, skySHB, ray.dir)) * 3.0;
				// skyRay += pow(saturate(dot(ray.dir, worldLightVector)), 4.0) * colorSunlight * 12.0;
				vec3 skyRay = max(vec3(0.0), AtmosphericScattering(ray.dir, worldSunVector, 1.0));

				skyRay *= absorption;
				skyRay *= (saturate(dot(ray.dir, vec3(0.0, 1.0, 0.0)) * 100.0) * 0.9 + 0.1);


				lightSum += skyRay * 0.2;

				break;
			}

			// ray.origin += length(next) * ray.dir;
			// ray.origin += rayTravelDistance * ray.dir;

			float tmin, tmax;

			vec3 b1 = vec3(coord);
			vec3 b2 = vec3(coord) + 1.0;

			vec3 aabb[2] = vec3[2](vec3(coord), vec3(coord) + 1.0);
			intersection_distances_no_if(MakeRay(ray.origin, ray.dir), aabb, tmin, tmax);

			vec3 hitNormal = sideNormals[side];

			ray.origin += rayDir * tmin + hitNormal * 0.01;

			ray.dir = cosWeightedRandomHemisphereDirection(-hitNormal * sign(ray.dir[side]), seed, i);
			// ray.dir = reflect(ray.dir, hitNormal);
			// ray.dir = reflect(ray.dir, sideNormals[side]);

			totalRayLength += tmin;

		}

        seed = mod(seed * 1.1234567893490423, 13.0);

	}

	if (totalRayLength <= 0.0)
	{
		totalRayLength = 10000.0;
	}

	//lightSum /= totalRayLength;

	// lightSum /= saturate(vec3(totalRayLength * 0.01)) * 100.0 + 0.01;

	//return vec3(1.0);
	return lightSum * 1.0 / numSamples;
}






vec4 TransferVolumeFromShadowToBuffer(vec2 coord)
{
	vec3 bufferVolumeCoord = TexcoordToVolumeCoord(coord);
	vec3 bufferWorldPos = VolumeToWorld(bufferVolumeCoord);

	vec3 shadowVolumeCoord = WorldToVolumeShadow(bufferWorldPos);
	vec2 shadowCoord = VolumeCoordToTexcoordShadow(shadowVolumeCoord);

	vec4 data = texture2DLod(shadowcolor, shadowCoord, 0);

	return data;
}


/* DRAWBUFFERS:45 */



#include "GBufferData.inc"



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
	//int resolution = 64;
	vec2 resolution = vec2(viewWidth, viewHeight);

	coord *= resolution;

	coord -= 0.5;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2DLod(tex, (vec2(offset.x, offset.z) - 0.0) / resolution, 0);
    vec4 sample1 = texture2DLod(tex, (vec2(offset.y, offset.z) - 0.0) / resolution, 0);
    vec4 sample2 = texture2DLod(tex, (vec2(offset.x, offset.w) - 0.0) / resolution, 0);
    vec4 sample3 = texture2DLod(tex, (vec2(offset.y, offset.w) - 0.0) / resolution, 0);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

struct MaterialMask
{
	float sky;
	float land;
	float grass;
	float leaves;
	float hand;
	float entityPlayer;
	float water;
	float stainedGlass;
	float ice;
	float torch;
	float lava;
	float glowstone;
};

float GetMaterialMask(const in int ID, in float matID) 
{
	//Catch last part of sky
	if (matID > 254.0f) 
	{
		matID = 0.0f;
	}

	if (matID == ID) 
	{
		return 1.0f;
	} 
	else 
	{
		return 0.0f;
	}
}

MaterialMask CalculateMasks(float materialID)
{
	MaterialMask mask;

	materialID *= 255.0;

	if (isEyeInWater > 0)
		mask.sky = 0.0f;
	else
	{
		mask.sky = 0.0;
		if (texture2D(depthtex1, texcoord.st).x > 0.999999)
		{
			mask.sky = 1.0;
		}
	}
		//mask.sky = GetMaterialMask(0, materialID);
		//mask.sky = texture2D(depthtex1, texcoord).x > 0.999999 ? 1.0 : 0.0;



	mask.land 			= GetMaterialMask(1, materialID);
	mask.grass 			= GetMaterialMask(2, materialID);
	mask.leaves 		= GetMaterialMask(3, materialID);
	mask.hand 			= GetMaterialMask(4, materialID);
	mask.entityPlayer 	= GetMaterialMask(5, materialID);
	mask.water 			= GetMaterialMask(6, materialID);
	mask.stainedGlass	= GetMaterialMask(7, materialID);
	mask.ice 			= GetMaterialMask(8, materialID);
	mask.torch 			= GetMaterialMask(30, materialID);
	mask.lava 			= GetMaterialMask(31, materialID);
	mask.glowstone 		= GetMaterialMask(32, materialID);

	return mask;
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() 
{
	GBufferData gbuffer 			= GetGBufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialID);

	vec4 viewPos 					= GetViewPosition(texcoord.st, gbuffer.depth);

	if (isEyeInWater > 0.5)
	{
		viewPos.xy *= 0.80;
	}

	vec4 worldPos					= gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);
	vec4 worldPosC					= gbufferModelViewInverse * vec4(viewPos.xyz, 0.0);
	vec3 viewDir 					= normalize(viewPos.xyz);
	vec3 worldDir 					= normalize(worldPosC.xyz);
	vec3 worldNormal 				= normalize((gbufferModelViewInverse * vec4(gbuffer.normal, 0.0)).xyz);
	float linearDepth 				= length(viewPos.xyz);

	// vec4 volumeData = TransferVolumeFromShadowToBuffer(texcoord.st);
	//vec4 volumeData = texture2D(shadowcolor, texcoord.st);

	if (materialMask.grass > 0.5)
	{
		worldNormal = vec3(0.0, 1.0, 0.0);
	}


	vec3 pathTraceGI = PathTraceGI(worldPos.xyz, worldNormal.xyz, worldDir.xyz, gbuffer.mcLightmap.g);
	// vec3 pathTraceGI = vec3(0.1);


	//float blockAngle = dot(worldNormal.xyz, normalize(vec3(1.9, 1.55, 1.0))) * 0.5 + 0.5;
	float blockAngle = 1.0 / (saturate(-dot(worldNormal, worldDir)) * 100.0 + 1.0);




	float minDepth;

	vec2 nearFragment = GetNearFragment(texcoord.st, gbuffer.depth, minDepth);

	float nearDepth = texture2D(depthtex1, nearFragment).x;

	vec4 projPos = vec4(texcoord.st * 2.0 - 1.0, nearDepth * 2.0 - 1.0, 1.0);
	vec4 viewPosNear = gbufferProjectionInverse * projPos;
	viewPosNear.xyz /= viewPosNear.w;

	vec4 worldPosNear = gbufferModelViewInverse * vec4(viewPosNear.xyz, 1.0);
	//worldPosNear.xyz += cameraPosition;

	vec4 worldPosPrev = worldPosNear;
	//worldPosPrev.xyz -= previousCameraPosition;
	worldPosPrev.xyz += (cameraPosition - previousCameraPosition);

	vec4 viewPosPrev = gbufferPreviousModelView * vec4(worldPosPrev.xyz, 1.0);
	vec4 projPosPrev = gbufferPreviousProjection * vec4(viewPosPrev.xyz, 1.0);
	projPosPrev.xyz /= projPosPrev.w;

	vec2 motionVector = (projPos.xy - projPosPrev.xy);

	float motionVectorMagnitude = length(motionVector) * 10.0;
	float pixelMotionFactor = clamp(motionVectorMagnitude * 500.0, 0.0, 1.0);

	#ifdef HALF_RES_TRACE
	vec2 reprojCoord = (texcoord.st * 0.5) - motionVector.xy * 0.25;
	#else
	vec2 reprojCoord = (texcoord.st) - motionVector.xy * 0.5;
	#endif

	#ifdef HALF_RES_TRACE
	vec2 pixelError = cos((fract(abs((texcoord.st * 0.5) - reprojCoord.xy) * vec2(viewWidth, viewHeight)) * 2.0 - 1.0) * 3.14159) * 0.5 + 0.5;
	#else
	vec2 pixelError = cos((fract(abs((texcoord.st) - reprojCoord.xy) * vec2(viewWidth, viewHeight)) * 2.0 - 1.0) * 3.14159) * 0.5 + 0.5;
	#endif
	vec2 pixelErrorFactor = pow(pixelError, vec2(0.5));


	vec4 prevDepthViewPos = gbufferProjectionInverse * vec4(texcoord.st * 2.0 - 1.0, texture2D(gaux1, reprojCoord.st).a * 2.0 - 1.0, 1.0);
	prevDepthViewPos /= prevDepthViewPos.w;



	vec2 lowerScreenBound = 1.0 / vec2(viewWidth, viewHeight);
	vec2 upperScreenBound = 1.0 - lowerScreenBound;

	vec4 gaux2Data = texture2DLod(gaux2, reprojCoord.st, 0);

	float prevGILumReproj = gaux2Data.r;
	float prevBlockAngle = gaux2Data.g;
	float prevSampleAge = gaux2Data.a * 256.0;

	float sampleAge = min(5.0, prevSampleAge + 1.0);

	float disocclusion = 0.0;
	// float blendWeight = 0.95;

	if (
		length(prevDepthViewPos.z - viewPosPrev.z) > 0.5 || 
		(reprojCoord.x < lowerScreenBound.x || reprojCoord.x > upperScreenBound.x ||
		 	reprojCoord.y < lowerScreenBound.y || reprojCoord.y > upperScreenBound.y)
		|| abs(blockAngle - prevBlockAngle) > 0.01
		)
	{
		// blendWeight = 0.0;
		disocclusion = 1.0;
		prevGILumReproj = 0.00;
		sampleAge = 0.0;
	}

	// disocclusion = 1.0;
	// sampleAge = 0.0;
	// prevGILumReproj = 0.00;




	float blendWeight = 1.0 - exp2(-(sampleAge));
	// float blendWeight = 1.0 - (1.0 / (sampleAge + 1.0));
	// float blendWeight = 0.975 * (1.0 - disocclusion);


	vec3 prevGI = texture2D(gaux1, reprojCoord.st).rgb;




	vec3 integratedGI = mix(pathTraceGI, prevGI, vec3(blendWeight));


	// float prevGILuminance = Luminance(prevGI.rgb);
	// float currGILuminance = Luminance(pathTraceGI.rgb);
	// float prevGILuminance2 = prevGILuminance * prevGILuminance;
	// float currGILuminance2 = currGILuminance * currGILuminance;

	// float temporalMoment1 = mix(currGILuminance, prevGILuminance, blendWeight);
	// float temporalMoment2 = mix(currGILuminance2, prevGILuminance2, blendWeight);

	// float temporalDiff = abs(prevGILuminance - currGILuminance);
	// float timeDiffAccum = mix(texture2D(gaux2, reprojCoord.st).x, temporalDiff, blendWeight);




	float disocclusionAccumulation = mix(disocclusion, gaux2Data.b, 0.7 * (1.0 - disocclusion));

	// disocclusionAccumulation = max(disocclusionAccumulation, 0.05);



	gl_FragData[0] = vec4(integratedGI, nearDepth);
	gl_FragData[1] = vec4(prevGILumReproj, blockAngle, disocclusionAccumulation, sampleAge / 256.0);

}