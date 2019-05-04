#version 120

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

/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////



#include "Common.inc"


#define SHADOW_MAP_BIAS 0.9

#define VARIABLE_PENUMBRA_SHADOWS	// Contact-hardening (area) shadows

#define GI_RENDER_RESOLUTION 1 // Render resolution of GI. 0 = High. 1 = Low. Set to 1 for faster but blurrier GI. [0 1]

#define RAYLEIGH_AMOUNT 1.0 // Density of atmospheric scattering. [0.5 1.0 1.5 2.0 3.0 4.0]

#define WATER_REFRACT_IOR 1.2


#define TORCHLIGHT_BRIGHTNESS 1.0 // Brightness of torch light. [0.5 1.0 2.0 3.0 4.0]


const int 		shadowMapResolution 	= 2048;	// Shadowmap resolution [1024 2048 4096]
const float 	shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 180.0 240.0]
const float 	shadowIntervalSize 		= 1.0f;
const bool 		shadowHardwareFiltering0 = true;

const bool 		shadowtex1Mipmap = false;
const bool 		shadowtex1Nearest = false;
const bool 		shadowcolor0Mipmap = false;
const bool 		shadowcolor0Nearest = true;
const bool 		shadowcolor1Mipmap = false;
const bool 		shadowcolor1Nearest = false;

const float shadowDistanceRenderMul = 1.0f;

const int 		RGB8 					= 0;
const int 		RGBA8 					= 0;
const int 		RGBA16 					= 0;
const int 		RGBA32F 				= 0;
const int 		RG16 					= 0;
const int 		RGB16 					= 0;
const int 		gcolorFormat 			= RGB8;
const int 		gdepthFormat 			= RGB16;
const int 		gnormalFormat 			= RGB16;
const int 		compositeFormat 		= RGBA16;
const int 		gaux1Format 			= RGBA32F;
const int 		gaux2Format 			= RGBA32F;
const int 		gaux3Format 			= RGBA16;
const int 		gaux4Format 			= RGBA32F;


const int 		superSamplingLevel 		= 0;

const float		sunPathRotation 		= -40.0f;

const int 		noiseTextureResolution  = 64;

const float 	ambientOcclusionLevel 	= 0.06f;


const bool gaux3MipmapEnabled = true;
const bool gaux1MipmapEnabled = false;

const bool gaux4Clear = false;

/* DRAWBUFFERS:3 */


uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D depthtex1;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

uniform sampler2DShadow shadow;


varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 sunVector;
varying vec3 upVector;

uniform int worldTime;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 skyColor;

uniform int   isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int   fogMode;

varying float timeSunriseSunset;
varying float timeNoon;
varying float timeMidnight;

varying vec3 colorSunlight;
varying vec3 colorSkylight;
varying vec3 colorTorchlight;

varying vec4 skySHR;
varying vec4 skySHG;
varying vec4 skySHB;

varying vec3 worldLightVector;
varying vec3 worldSunVector;

uniform int heldBlockLightValue;

varying float contextualFogFactor;

uniform int frameCounter;

varying float heldLightBlacklist;

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

vec4 GetViewPosition(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);
	TemporalJitterProjPos(tcoord);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 1.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}

vec4 GetViewPositionRaw(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);
	//TemporalJitterProjPos(tcoord);
	//TemporalJitterProjPos(tcoord);
	//tcoord.x += 1.1;
	//tcoord.x = 0.0;

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 1.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}


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



vec3 	CalculateNoisePattern1(vec2 offset, float size) 
{
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture2D(noisetex, coord).xyz;
}

float GetDepthLinear(in vec2 coord) 
{					
	return (near * far) / (texture2D(depthtex1, coord).x * (near - far) + far);
}

vec3 GetNormals(vec2 coord)
{
	return DecodeNormal(texture2D(gnormal, coord).xy);
}

float GetDepth(vec2 coord)
{
	return texture2D(depthtex1, coord).x;
}

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "GBufferData.inc"


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

struct Ray {
	vec3 dir;
	vec3 origin;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};

/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



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

Intersection 	RayPlaneIntersectionWorld(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.dir * planeRayDist;
		intersectionPos = -intersectionPos;

		intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}

Intersection 	RayPlaneIntersection(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin - ray.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.origin + ray.dir * planeRayDist;
		// intersectionPos = -intersectionPos;

		// intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}

vec3 CalculateSunlightVisibility(vec4 screenSpacePosition, MaterialMask mask) {				//Calculates shadows
	if (rainStrength >= 0.99f)
		return vec3(1.0f);



	//if (shadingStruct.direct > 0.0f) {
		float distance = sqrt(  screenSpacePosition.x * screenSpacePosition.x 	//Get surface distance in meters
							  + screenSpacePosition.y * screenSpacePosition.y
							  + screenSpacePosition.z * screenSpacePosition.z);

		vec4 ssp = screenSpacePosition;

		// if (isEyeInWater > 0.5)
		// {
		// 	ssp.xy *= 0.82;
		// }

		vec4 worldposition = vec4(0.0f);
			 worldposition = gbufferModelViewInverse * ssp;		//Transform from screen space to world space


		float yDistanceSquared  = worldposition.y * worldposition.y;

		worldposition = shadowModelView * worldposition;	//Transform from world space to shadow space
		float comparedepth = -worldposition.z;				//Surface distance from sun to be compared to the shadow map

		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;

		float dist = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
		worldposition.xy *= 0.95f / distortFactor;
		worldposition.z = mix(worldposition.z, 0.5, 0.8);
		worldposition = worldposition * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates

		float shadowMult = 0.0f;																			//Multiplier used to fade out shadows at distance
		float shading = 0.0f;

		float fademult = 0.15f;
			shadowMult = clamp((shadowDistance * 1.4f * fademult) - (distance * fademult), 0.0f, 1.0f);	//Calculate shadowMult to fade shadows out

		if (shadowMult > 0.0) 
		{

			float diffthresh = dist * 1.0f + 0.10f;
				  diffthresh *= 1.0f / (shadowMapResolution / 2048.0f);
				  //diffthresh /= shadingStruct.direct + 0.1f;


			#ifdef PIXEL_SHADOWS
				  //diffthresh += 1.5;
			#endif


			#ifdef ENABLE_SOFT_SHADOWS
			#ifndef VARIABLE_PENUMBRA_SHADOWS

				int count = 0;
				float spread = 1.0f / shadowMapResolution;

				vec3 noise = CalculateNoisePattern1(vec2(0.0), 64.0);

				for (float i = -0.5f; i <= 0.5f; i += 1.0f) 
				{
					for (float j = -0.5f; j <= 0.5f; j += 1.0f) 
					{
						float angle = noise.x * 3.14159 * 2.0;

						mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

						vec2 coord = vec2(i, j) * rot;

						shading += shadow2D(shadow, vec3(worldposition.st + coord * spread, worldposition.z - 0.0008f * diffthresh)).x;
						count += 1;
					}
				}
				shading /= count;

			#endif
			#endif

			#ifdef VARIABLE_PENUMBRA_SHADOWS

				float vpsSpread = 0.145 / distortFactor;

				float avgDepth = 0.0;
				float minDepth = 11.0;
				int c;

				for (int i = -1; i <= 1; i++)
				{
					for (int j = -1; j <= 1; j++)
					{
						vec2 lookupCoord = worldposition.xy + (vec2(i, j) / shadowMapResolution) * 8.0 * vpsSpread;
						//avgDepth += pow(texture2DLod(shadowtex1, lookupCoord, 2).x, 4.1);
						float depthSample = texture2DLod(shadowtex1, lookupCoord, 2).x;
						minDepth = min(minDepth, depthSample);
						avgDepth += pow(min(max(0.0, worldposition.z - depthSample) * 1.0, 0.025), 2.0);
						c++;
					}
				}

				avgDepth /= c;
				avgDepth = pow(avgDepth, 1.0 / 2.0);

				// float penumbraSize = min(abs(worldposition.z - minDepth), 0.15);
				float penumbraSize = avgDepth;

				//if (mask.leaves > 0.5)
				//{
					//penumbraSize = 0.02;
				//}

				int count = 0;
				float spread = penumbraSize * 0.125 * vpsSpread + 0.25 / shadowMapResolution;

				//vec3 noise = CalculateNoisePattern1(vec2(0.0 + sin(frameTimeCounter)), 64.0);
				vec2 noise = rand(texcoord.st + sin(frameTimeCounter)).xy;

				diffthresh *= 0.5 + avgDepth * 50.0;

				for (float i = -1.5f; i <= 1.5f; i += 1.0f) 
				{
					for (float j = -1.5f; j <= 1.5f; j += 1.0f) 
					{
						float angle = noise.x * 3.14159 * 2.0;

						mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

						vec2 coord = vec2(i + noise.y - 0.5, j + noise.y - 0.5) * rot;

						shading += shadow2D(shadow, vec3(worldposition.st + coord * spread, worldposition.z - 0.0012f * diffthresh)).x;
						count += 1;
					}
				}
				shading /= count;

			#endif

			#ifndef VARIABLE_PENUMBRA_SHADOWS
			#ifndef ENABLE_SOFT_SHADOWS
				//diffthresh *= 2.0f;
				shading = shadow2DLod(shadow, vec3(worldposition.st, worldposition.z - 0.0006f * diffthresh), 0).x;
			#endif
			#endif

		}

		//shading = mix(1.0f, shading, shadowMult);

		//surface.shadow = shading;

		vec3 result = vec3(shading);


		///*
		#ifdef COLORED_SHADOWS
		float shadowNormalAlpha = texture2DLod(shadowcolor1, worldposition.st, 0).a;

		vec3 noise2 = CalculateNoisePattern1(vec2(0.0), 64.0);

		//worldposition.st += (noise2.xy * 2.0 - 1.0) / shadowMapResolution;

		if (shadowNormalAlpha < 0.5)
		{
			result = mix(vec3(1.0), pow(texture2DLod(shadowcolor, worldposition.st, 0).rgb, vec3(1.6)), vec3(1.0 - shading));
			float solidDepth = texture2DLod(shadowtex1, worldposition.st, 0).x;
			float solidShadow = 1.0 - clamp((worldposition.z - solidDepth) * 1200.0, 0.0, 1.0); 
			result *= solidShadow;
		}
		#endif
		//*/

		result = mix(vec3(1.0), result, shadowMult);

		return result;
	//} else {
	//	return vec3(0.0f);
	//}
}

float RenderSunDisc(vec3 worldDir, vec3 sunDir)
{
	float d = dot(worldDir, sunDir);

	float disc = 0.0;

	//if (d > 0.99)
	//	disc = 1.0;

	float size = 0.00195;
	float hardness = 1000.0;

	disc = pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 30.0));

	disc *= visibility;

	return disc;
}


vec4 BilateralUpsample(const in float scale, in vec2 offset, in float depth, in vec3 normal)
{
	vec2 recipres = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	vec4 light = vec4(0.0f);
	float weights = 0.0f;

	for (float i = -0.5f; i <= 0.5f; i += 1.0f)
	{
		for (float j = -0.5f; j <= 0.5f; j += 1.0f)
		{
			vec2 coord = vec2(i, j) * recipres * 2.0f;

			float sampleDepth = GetDepthLinear(texcoord.st + coord * 2.0f * (exp2(scale)));
			vec3 sampleNormal = GetNormals(texcoord.st + coord * 2.0f * (exp2(scale)));
			//float weight = 1.0f / (pow(abs(sampleDepth - depth) * 1000.0f, 2.0f) + 0.001f);
			float weight = clamp(1.0f - abs(sampleDepth - depth) / 2.0f, 0.0f, 1.0f);
				  weight *= max(0.0f, dot(sampleNormal, normal) * 2.0f - 1.0f);
			//weight = 1.0f;

			light +=	pow(texture2DLod(gaux3, (texcoord.st) * (1.0f / exp2(scale )) + 	offset + coord, 1), vec4(2.2f, 2.2f, 2.2f, 1.0f)) * weight;

			weights += weight;
		}
	}


	light /= max(0.00001f, weights);

	if (weights < 0.01f)
	{
		light =	pow(texture2DLod(gaux3, (texcoord.st) * (1.0f / exp2(scale 	)) + 	offset, 2), vec4(2.2f, 2.2f, 2.2f, 1.0f));
	}


	// vec3 light =	texture2DLod(gcolor, (texcoord.st) * (1.0f / pow(2.0f, 	scale 	)) + 	offset, 2).rgb;


	return light;
}

vec4 GetGI(vec3 albedo, vec3 normal, float skylight)
{
	///*
	float depth = GetDepthLinear(texcoord.st);

	vec4 indirectLight = BilateralUpsample(GI_RENDER_RESOLUTION, vec2(0.0f, 0.0f), 		depth, normal);

	float value = length(indirectLight.rgb);

	indirectLight.rgb = pow(value, 0.7) * normalize(indirectLight.rgb + 0.0001) * 0.4;
	//indirectLight.rgb = mix(indirectLight.rgb, vec3(dot(indirectLight.rgb, vec3(0.3333))), vec3(-0.5));


	indirectLight.rgb = indirectLight.rgb * albedo * mix(colorSunlight, vec3(0.4) * Luminance(colorSkylight), rainStrength);

	indirectLight.rgb *= 1.2f;

	indirectLight.rgb *= 3.0f * saturate(skylight * 7.0);






	// indirectLight.rgb *= sin(frameTimeCounter) > 0.6 ? 0.0 : 1.0;

	//*/

	//vec4 indirectLight = texture2D(gaux3, texcoord.st);

	return indirectLight;
}

vec3 GetWavesNormal(vec3 position) {

	vec2 coord = position.xz / 50.0;
	coord.xy -= position.y / 50.0;
	//coord -= floor(coord);

	coord = mod(coord, vec2(1.0));


	float texelScale = 4.0;

	//to fix color error with GL_CLAMP
	coord.x = coord.x * ((viewWidth - 1 * texelScale) / viewWidth) + ((0.5 * texelScale) / viewWidth);
	coord.y = coord.y * ((viewHeight - 1 * texelScale) / viewHeight) + ((0.5 * texelScale) / viewHeight);


	vec3 normal;
	//normal.xyz = ((texture2DLod(gaux4, coord, 2).xyz) * 2.0 - 1.0);
	normal.xyz = DecodeNormal(texture2DLod(gaux1, coord, 2).zw);

	return normal;
}

vec3 FakeRefract(vec3 vector, vec3 normal, float ior)
{
	return refract(vector, normal, ior);
	//return vector + normal * 0.5;
}

float CalculateWaterCaustics(vec4 screenSpacePosition, MaterialMask mask)
{
	//if (shading.direct <= 0.0)
	//{
	//	return 0.0;
	//}
	if (isEyeInWater == 1)
	{
		if (mask.water > 0.5)
		{
			return 1.0;
		}
	}
	vec4 worldPos = gbufferModelViewInverse * screenSpacePosition;
	worldPos.xyz += cameraPosition.xyz;

	vec2 dither = CalculateNoisePattern1(vec2(0.0), 2.0).xy;
	// float waterPlaneHeight = worldPos.y + 8.0;
	float waterPlaneHeight = 63.0;

	// vec4 wlv = shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0);
	vec4 wlv = gbufferModelViewInverse * vec4(lightVector.xyz, 0.0);
	vec3 worldLightVector = -normalize(wlv.xyz);
	// worldLightVector = normalize(vec3(-1.0, 1.0, 0.0));

	float pointToWaterVerticalLength = min(abs(worldPos.y - waterPlaneHeight), 2.0);
	vec3 flatRefractVector = FakeRefract(worldLightVector, vec3(0.0, 1.0, 0.0), 1.0 / 1.3333);
	float pointToWaterLength = pointToWaterVerticalLength / -flatRefractVector.y;
	vec3 lookupCenter = worldPos.xyz - flatRefractVector * pointToWaterLength;


	const float distanceThreshold = 0.15;

	const int numSamples = 1;
	int c = 0;

	float caustics = 0.0;

	for (int i = -numSamples; i <= numSamples; i++)
	{
		for (int j = -numSamples; j <= numSamples; j++)
		{
			vec2 offset = vec2(i + dither.x, j + dither.y) * 0.2;
			vec3 lookupPoint = lookupCenter + vec3(offset.x, 0.0, offset.y);
			// vec3 wavesNormal = normalize(GetWavesNormal(lookupPoint).xzy + vec3(0.0, 1.0, 0.0) * 100.0);
			vec3 wavesNormal = GetWavesNormal(lookupPoint).xzy;
			vec3 refractVector = FakeRefract(worldLightVector.xyz, wavesNormal.xyz, 1.0 / 1.3333);
			float rayLength = pointToWaterVerticalLength / refractVector.y;
			vec3 collisionPoint = lookupPoint - refractVector * rayLength;

			//float dist = distance(collisionPoint, worldPos.xyz);
			float dist = dot(collisionPoint - worldPos.xyz, collisionPoint - worldPos.xyz) * 7.1;

			caustics += 1.0 - saturate(dist / distanceThreshold);

			c++;
		}
	}

	caustics /= c;

	caustics /= distanceThreshold;


	return pow(caustics, 2.0) * 3.0;
}

vec3  	GetWaterNormals(in vec2 coord) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	return DecodeNormal(texture2D(gaux1, coord).xy);
}


void WaterFog(inout vec3 color, in MaterialMask mask, float waterSkylight, vec4 viewSpacePositionSolid, vec4 viewSpacePosition)
{
	// return;
	if (mask.water > 0.5 || isEyeInWater > 0)
	{
		//float depth = texture2D(depthtex1, texcoord.st).x;
		//float depthSolid = texture2D(gdepthtex, texcoord.st).x;

		//vec4 viewSpacePosition = GetScreenSpacePosition(texcoord.st, depth);
		//vec4 viewSpacePositionSolid = GetScreenSpacePosition(texcoord.st, depthSolid);

		vec3 viewVector = normalize(viewSpacePosition.xyz);


		float waterDepth = distance(viewSpacePosition.xyz, viewSpacePositionSolid.xyz);
		if (isEyeInWater > 0)
		{
			waterDepth = length(viewSpacePosition.xyz) * 0.5;		
			if (mask.water > 0.5)
			{
				waterDepth = length(viewSpacePosition.xyz) * 0.5;		
			}	
		}


		float fogDensity = 0.20;



		vec3 waterNormal = normalize(GetWaterNormals(texcoord.st));

		// vec3 waterFogColor = vec3(1.0, 1.0, 0.1);	//murky water
		// vec3 waterFogColor = vec3(0.2, 0.95, 0.0) * 1.0; //green water
		// vec3 waterFogColor = vec3(0.4, 0.95, 0.05) * 2.0; //green water
		// vec3 waterFogColor = vec3(0.7, 0.95, 0.00) * 0.75; //green water
		// vec3 waterFogColor = vec3(0.2, 0.95, 0.4) * 5.0; //green water
		// vec3 waterFogColor = vec3(0.2, 0.95, 1.0) * 1.0; //clear water
		vec3 waterFogColor = vec3(0.05, 0.8, 1.0) * 2.0; //clear water
			  waterFogColor *= 0.01 * dot(vec3(0.33333), colorSunlight);
			  waterFogColor *= (1.0 - rainStrength * 0.95);
			  waterFogColor *= isEyeInWater * 2.0 + 1.0;

		if (isEyeInWater == 0)
		{
			waterFogColor *= waterSkylight;
		}
		else
		{
			waterFogColor *= 0.5;
			//waterFogColor *= pow(eyeBrightnessSmooth.y / 240.0f, 6.0f);


			vec3 waterSunlightVector = refract(-lightVector, upVector, 1.0 / WATER_REFRACT_IOR);

			//waterFogColor *= (dot(lightVector, viewVector) * 0.5 + 0.5) * 2.0 + 1.0;
			float scatter = 1.0 / (pow(saturate(dot(waterSunlightVector, viewVector) * 0.5 + 0.5) * 20.0, 1.0) + 0.1);
			vec3 waterSunlightScatter = colorSunlight * scatter * 1.0 * waterFogColor * 16.0;

			float eyeWaterDepth = eyeBrightnessSmooth.y / 240.0;


			waterFogColor *= dot(viewVector, upVector) * 0.5 + 0.5;
			waterFogColor = waterFogColor * pow(eyeWaterDepth, 1.0f) + waterSunlightScatter * pow(eyeWaterDepth, 1.0);
			//waterFogColor = waterFogColor + waterSunlightScatter;
		

			waterFogColor *= pow(vec3(0.4, 0.72, 1.0) * 0.99, vec3(0.2 + (1.0 - eyeWaterDepth)));

			fogDensity *= 0.5;
		}


		float visibility = 1.0f / (pow(exp(waterDepth * fogDensity), 1.0f));
		float visibility2 = 1.0f / (pow(exp(waterDepth * fogDensity), 1.0f));


		// float scatter = CalculateSunglow(surface);

		vec3 viewVectorRefracted = refract(viewVector, waterNormal, 1.0 / 1.3333);
		float scatter = 1.0 / (pow(saturate(dot(-lightVector, viewVectorRefracted) * 0.5 + 0.5) * 20.0, 2.0) + 0.1);
		//vec3 reflectedLightVector = reflect(lightVector, upVector);
			  //scatter += (1.0 / (pow(saturate(dot(-reflectedLightVector, viewVectorRefracted) * 0.5 + 0.5) * 30.0, 2.0) + 0.1)) * saturate(1.0 - dot(lightVector, upVector) * 1.4);

		// scatter += pow(saturate(dot(-lightVector, viewVectorRefracted) * 0.5 + 0.5), 3.0) * 0.02;
		if (isEyeInWater < 1)
		{
			waterFogColor = mix(waterFogColor, colorSunlight * 21.0 * waterFogColor, vec3(scatter * (1.0 - rainStrength)));
		}



		// color *= pow(vec3(0.7, 0.88, 1.0) * 0.99, vec3(waterDepth * 0.45 + 0.2));
		// color *= pow(vec3(0.7, 0.88, 1.0) * 0.99, vec3(waterDepth * 0.45 + 1.0));
		color *= pow(vec3(0.4, 0.75, 1.0) * 0.99, vec3(waterDepth * 0.25 + 0.25));
		// color *= pow(vec3(0.7, 1.0, 0.2) * 0.8, vec3(waterDepth * 0.15 + 0.1));
		color = mix(waterFogColor * 40.0, color, saturate(visibility));





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

float GetAO(vec2 coord, vec3 normal, float dither)
{
	const int numRays = 16;

	const float phi = 1.618033988;
	const float gAngle = phi * 3.14159265 * 1.0003;

	float depth = GetDepth(coord);
	float linDepth = ExpToLinearDepth(depth);
	vec3 origin = GetViewPosition(coord, depth).xyz;

	float aoAccum = 0.0;

	const float radius = 2.0;
	
	for (int i = 0; i < numRays; i++)
	{
		float fi = float(i) + dither;
		float fiN = fi / float(numRays);
		float lon = gAngle * fi * 6.0;
		float lat = asin(fiN * 2.0 - 1.0) * 1.0;

		vec3 kernel;
		kernel.x = cos(lat) * cos(lon);
		kernel.z = cos(lat) * sin(lon);
		kernel.y = sin(lat);

		kernel.xyz = normalize(kernel.xyz + normal.xyz);

		float sampleLength = radius * mod(fiN, 0.07) / 0.07;

		vec3 samplePos = origin + kernel * sampleLength;

		vec3 samplePosProj = ProjectBack(samplePos);

		/*
		float sampleDepth = ExpToLinearDepth(GetDepth(samplePosProj.xy));

		float kernelAngle = dot(kernel, normal);

		if (sampleDepth < linDepth && kernelAngle > 0.0)
		{
			aoAccum += 1.0 * saturate(kernelAngle) * saturate(abs(sampleDepth - linDepth) * 50.0);
		}
		*/

		vec3 actualSamplePos = GetViewPosition(samplePosProj.xy, GetDepth(samplePosProj.xy)).xyz;

		float depthDiff = actualSamplePos.z - samplePos.z;

		if (depthDiff > 0.0 && depthDiff < 1.0)
		{
			//aoAccum += 1.0 * saturate(depthDiff * 100.0) * saturate(1.0 - depthDiff * 0.25 / (sampleLength + 0.001));
			aoAccum += 1.0;
		}
	}

	aoAccum /= numRays;

	float ao = 1.0 - aoAccum;
	ao = pow(ao, 2.5);

	return ao;
}

float ScreenSpaceShadow(vec3 origin, vec3 normal, MaterialMask mask)
{
	if (mask.sky > 0.5 || rainStrength >= 0.999)
	{
		return 1.0;
	}

	if (isEyeInWater > 0.5)
	{
		//origin.xy *=
	}

	if (isEyeInWater > 0.5)
	{
		origin.xy /= 0.82;
	}

	vec3 viewDir = normalize(origin.xyz);


	float nearCutoff = 0.50;
	float traceBias = 0.015;


	//Prevent self-intersection issues
	float viewDirDiff = dot(fwidth(viewDir), vec3(0.333333));


	vec3 rayPos = origin;
	vec3 rayDir = lightVector * 0.01;
	rayDir *= viewDirDiff * 2000.001;
	rayDir *= -origin.z * 0.28 + nearCutoff;


	rayPos += rayDir * -origin.z * 0.000037 * traceBias;



	float randomness = rand(texcoord.st + sin(frameTimeCounter)).x;

	rayPos += rayDir * randomness;



	float zThickness = 0.025 * -origin.z;

	float shadow = 1.0;

	float numSamplesf = 64.0;
	//numSamplesf /= -origin.z * 0.125 + nearCutoff;

	int numSamples = int(numSamplesf);


	float shadowStrength = 0.9;

	if (mask.grass > 0.5)
	{
		shadowStrength = 0.6;
	}
	if (mask.leaves > 0.5)
	{
		shadowStrength = 0.5;
	}

	// vec3 prevRayProjPos = ProjectBack(rayPos);

	for (int i = 0; i < 12; i++)
	{
		float fi = float(i) / float(12);

		rayPos += rayDir;

		vec3 rayProjPos = ProjectBack(rayPos);


		rayProjPos *= -1.0;
		TemporalJitterProjPos(rayProjPos);
		rayProjPos *= -1.0;




		// vec2 pixelPos = floor(rayProjPos.xy * vec2(viewWidth, viewHeight));
		// vec2 pixelPosPrev = floor(prevRayProjPos.xy * vec2(viewWidth, viewHeight));
		// if (pixelPos.x == pixelPosPrev.x || pixelPos.y == pixelPosPrev.y)
		// {
		// 	continue;
		// }

		// prevRayProjPos = rayProjPos;

		/*
		float sampleDepth = GetDepthLinear(rayProjPos.xy);

		float depthDiff = -rayPos.z - sampleDepth;
		*/

		vec3 samplePos = GetViewPositionRaw(rayProjPos.xy, GetDepth(rayProjPos.xy)).xyz;

		float depthDiff = samplePos.z - rayPos.z - 0.02 * -origin.z * traceBias;

		if (depthDiff > 0.0 && depthDiff < zThickness)
		{
			shadow *= 1.0 - shadowStrength;
		}
	}

	return shadow;
}


float OrenNayar(vec3 normal, vec3 eyeDir, vec3 lightDir)
{
	const float PI = 3.14159;
	const float roughness = 0.55;

	// interpolating normals will change the length of the normal, so renormalize the normal.



	// normal = normalize(normal + surface.lightVector * pow(clamp(dot(eyeDir, surface.lightVector), 0.0, 1.0), 5.0) * 0.5);

	// normal = normalize(normal + eyeDir * clamp(dot(normal, eyeDir), 0.0f, 1.0f));

	// calculate intermediary values
	float NdotL = dot(normal, lightDir);
	float NdotV = dot(normal, eyeDir);

	float angleVN = acos(NdotV);
	float angleLN = acos(NdotL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);
	float gamma = dot(eyeDir - normal * dot(eyeDir, normal), lightDir - normal * dot(lightDir, normal));

	float roughnessSquared = roughness * roughness;

	// calculate A and B
	float A = 1.0 - 0.5 * (roughnessSquared / (roughnessSquared + 0.57));

	float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));

	float C = sin(alpha) * tan(beta);

	// put it all together
	float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * C);

	//return max(0.0f, surface.NdotL * 0.99f + 0.01f);
	return clamp(L1, 0.0f, 1.0f);
}


void LandAtmosphericScattering(inout vec3 color, in vec3 viewPos, in vec3 viewDir)
{
	float dist = length(viewPos);

	float fogDensity = 0.003 * RAYLEIGH_AMOUNT;
	float fogFactor = pow(1.0 - exp(-dist * fogDensity), 2.0);


	vec3 absorption = vec3(0.2, 0.45, 1.0);

	color *= exp(-dist * absorption * fogDensity * 0.27);
	color += max(vec3(0.0), vec3(1.0) - exp(-fogFactor * absorption)) * mix(colorSunlight, vec3(dot(colorSunlight, vec3(0.33333))), vec3(0.9)) * 2.0;

	float VdotL = dot(viewDir, sunVector);

	float g = 0.72;
				//float g = 0.9;
	float g2 = g * g;
	float theta = VdotL * 0.5 + 0.5;
	float anisoFactor = 1.5 * ((1.0 - g2) / (2.0 + g2)) * ((1.0 + theta * theta) / (1.0 + g2 - 2.0 * g * theta)) + g * theta;

	color += colorSunlight * fogFactor * 0.2 * anisoFactor;

}

void ContextualFog(inout vec3 color, in vec3 viewPos, in vec3 viewDir, float density)
{
	float dist = length(viewPos);

	float fogDensity = density * 0.019;
		  fogDensity *= 1.0 -  saturate(viewDir.y * 0.5 + 0.5) * exp(-density * 0.125);
		  fogDensity *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 6.0f));

	float fogFactor = pow(1.0 - exp(-dist * fogDensity), 1.6);
		  //fogFactor = 1.0 -  saturate(viewDir.y * 0.5 + 0.5);




	vec3 fogColor = pow(gl_Fog.color.rgb, vec3(2.2));


	float VdotL = dot(viewDir, worldSunVector);

	float g = 0.72;
				//float g = 0.9;
		  //g = exp(-density) * 0.4 + 0.5;

	float g2 = g * g;
	float theta = VdotL * 0.5 + 0.5;
	float anisoFactor = 1.5 * ((1.0 - g2) / (2.0 + g2)) * ((1.0 + theta * theta) / (1.0 + g2 - 2.0 * g * theta)) + g * theta;


	float skyFactor = pow(saturate(viewDir.y * 0.5 + 0.5), 2.0);
		  //skyFactor = skyFactor * (3.0 - 2.0 * skyFactor);

	fogColor = colorSunlight * anisoFactor * (1.0 - rainStrength) + skyFactor * colorSkylight * 2.0;

	fogColor *= exp(-density * 1.5) * 2.0;

	color = mix(color, fogColor, fogFactor);

}

float Get2DNoise(in vec2 pos)
{
	pos.xy += 0.5f;

	vec2 p = floor(pos);
	vec2 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);

	vec2 uv =  p.xy + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	return xy1;
}

float Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	vec2 coord2 = (uv2 + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

float GetCoverage(in float coverage, in float density, in float clouds)
{
	clouds = clamp(clouds - (1.0f - coverage), 0.0f, 1.0f -density) / (1.0f - density);
		clouds = max(0.0f, clouds * 1.1f - 0.1f);
	 clouds = clouds = clouds * clouds * (3.0f - 2.0f * clouds);
	 // clouds = pow(clouds, 1.0f);
	return clouds;
}

float   CalculateSunglow(vec3 npos, vec3 lightVector) {

	float curve = 4.0f;

	vec3 halfVector2 = normalize(-lightVector + npos);
	float factor = 1.0f - dot(halfVector2, npos);

	return factor * factor * factor * factor;
}

vec4 CloudColor(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector, in float altitude, in float thickness, const bool isShadowPass)
{

	float cloudHeight = altitude;
	float cloudDepth  = thickness;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0f);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0f);

	//worldPosition.xz /= 1.0f + max(0.0f, length(worldPosition.xz - cameraPosition.xz) / 5000.0f);

	vec3 p = worldPosition.xyz / 150.0f;



	float t = frameTimeCounter * 1.0f;
		  t *= 0.5;


	 p += (Get3DNoise(p * 2.0f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 0.10f;
	 p.z -= (Get3DNoise(p * 0.25f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 0.45f;
	 p.x -= (Get3DNoise(p * 0.125f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 2.2f;
	p.xz -= (Get3DNoise(p * 0.0525f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 2.7f;


	p.x *= 0.5f;
	p.x -= t * 0.01f;

	vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);
	float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.01f, 0.0f));	p *= 2.0f;	p.x -= t * 0.057f;	vec3 p2 = p;
		  noise += (2.0f - abs(Get3DNoise(p) * 2.0f - 0.0f)) * (0.15f);						p *= 3.0f;	p.xz -= t * 0.035f;	p.x *= 2.0f;	vec3 p3 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.050f);						p *= 3.0f;	p.xz -= t * 0.035f;	vec3 p4 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.015f);						p *= 3.0f;	p.xz -= t * 0.035f;
		  if (!isShadowPass)
		  {
		 		noise += ((Get3DNoise(p))) * (0.022f);												p *= 3.0f;
		  		noise += ((Get3DNoise(p))) * (0.009f);
		  }
		  noise /= 1.475f;

	//cloud edge
	float coverage = 0.701f;
		  coverage = mix(coverage, 0.97f, rainStrength);

		  float dist = length(worldPosition.xz - cameraPosition.xz * 0.5);
		  coverage *= max(0.0f, 1.0f - dist / 14000.0f);
	float density = 0.1f + rainStrength * 0.3;

	if (isShadowPass)
	{
		return vec4(GetCoverage(0.4f, 0.4f, noise));
	}

	noise = GetCoverage(coverage, density, noise);

	const float lightOffset = 0.4f;



	float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset);
		  sundiff += (2.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset / 2.0f) * 2.0f - 0.0f)) * (0.55f);
		  				float largeSundiff = sundiff;
		  				      largeSundiff = -GetCoverage(coverage, 0.0f, largeSundiff * 1.3f);
		  sundiff += (3.0f - abs(Get3DNoise(p3 + worldLightVector.xyz * lightOffset / 5.0f) * 3.0f - 0.0f)) * (0.045f);
		  sundiff += (3.0f - abs(Get3DNoise(p4 + worldLightVector.xyz * lightOffset / 8.0f) * 3.0f - 0.0f)) * (0.015f);
		  sundiff /= 1.5f;

		  sundiff *= max(0.0f, 1.0f - dist / 14000.0f);

		  sundiff = -GetCoverage(coverage * 1.0f, 0.0f, sundiff);
	float secondOrder 	= pow(clamp(sundiff * 1.1f + 1.45f, 0.0f, 1.0f), 4.0f);
	float firstOrder 	= pow(clamp(largeSundiff * 1.1f + 1.66f, 0.0f, 1.0f), 3.0f);



	float directLightFalloff = firstOrder * secondOrder;
	float anisoBackFactor = mix(clamp(pow(noise, 1.6f) * 2.5f, 0.0f, 1.0f), 1.0f, pow(sunglow, 1.0f));

		  directLightFalloff *= anisoBackFactor;
	 	  directLightFalloff *= mix(11.5f, 1.0f, pow(sunglow, 0.5f));

	//noise *= saturate(1.0 - directLightFalloff);

	vec3 colorDirect = colorSunlight * 11.215f;
		 colorDirect = mix(colorDirect, colorDirect * vec3(0.2f, 0.2f, 0.2f), timeMidnight);
		 colorDirect *= 1.0f + pow(sunglow, 2.0f) * 120.0f * pow(directLightFalloff, 1.1f) * (1.0 - rainStrength * 0.8);
		 colorDirect *= 1.0f;


	vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(0.15f)) * 0.93f;
		 colorAmbient = mix(colorAmbient, vec3(0.4) * Luminance(colorSkylight), vec3(rainStrength));
		 colorAmbient *= mix(1.0f, 0.3f, timeMidnight);
		 colorAmbient = mix(colorAmbient, colorAmbient * 3.0f + colorSunlight * 0.05f, vec3(clamp(pow(1.0f - noise, 12.0f) * 1.0f, 0.0f, 1.0f)));




	directLightFalloff *= mix(1.0, 0.085, rainStrength);

	//directLightFalloff += (pow(Get3DNoise(p3), 2.0f) * 0.5f + pow(Get3DNoise(p3 * 1.5f), 2.0f) * 0.25f) * 0.02f;
	//directLightFalloff *= Get3DNoise(p2);

	vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));

	color *= 1.0f;

	color = mix(color, color * 0.9, rainStrength);


	vec4 result = vec4(color.rgb, noise);

	return result;

}

void CloudPlane(inout vec3 color, vec3 viewDir, vec3 worldVector, float linearDepth, MaterialMask mask, vec3 worldLightVector, vec3 lightVector)
{
	//Initialize view ray
	//vec4 worldVector = gbufferModelViewInverse * (vec4(-GetScreenSpacePosition(texcoord.st).xyz, 0.0));


	Ray viewRay;

	viewRay.dir = normalize(worldVector.xyz);
	viewRay.origin = vec3(0.0f);

	float sunglow = CalculateSunglow(viewDir, lightVector);



	float cloudsAltitude = 540.0f;
	float cloudsThickness = 150.0f;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float density = 1.0f;

	float planeHeight = cloudsUpperLimit;
	float stepSize = 25.5f;
	planeHeight -= cloudsThickness * 0.85f;


	Plane pl;
	pl.origin = vec3(0.0f, cameraPosition.y - planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	Intersection i = RayPlaneIntersectionWorld(viewRay, pl);

	vec3 original = color.rgb;

	if (i.angle < 0.0f)
	{
		if (i.distance < linearDepth || mask.sky > 0.5 || linearDepth >= far - 0.1)
		{
			vec4 cloudSample = CloudColor(vec4(i.pos.xyz * 0.5f + vec3(30.0f) + vec3(1000.0, 0.0, 0.0), 1.0f), sunglow, worldLightVector, cloudsAltitude, cloudsThickness, false);
			 	 cloudSample.a = min(1.0f, cloudSample.a * density);


			float cloudDist = length(i.pos.xyz - cameraPosition.xyz);

			const vec3 absorption = vec3(0.2, 0.4, 1.0);

			cloudSample.rgb *= exp(-cloudDist * absorption * 0.0001 * saturate(1.0 - sunglow * 2.0) * (1.0 - rainStrength));

			cloudSample.a *= exp(-cloudDist * (0.0002 + rainStrength * 0.0009));


			//cloudSample.rgb *= sin(cloudDist * 0.3) * 0.5 + 0.5;

			color.rgb = mix(color.rgb, cloudSample.rgb * 1.0f, cloudSample.a);

		}
	}
}

float CloudShadow(vec3 lightVector, vec4 screenSpacePosition)
{
	lightVector = upVector;

	float cloudsAltitude = 540.0f;
	float cloudsThickness = 150.0f;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float planeHeight = cloudsUpperLimit;

	planeHeight -= cloudsThickness * 0.85f;

	Plane pl;
	pl.origin = vec3(0.0f, planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	//Cloud shadow
	Ray surfaceToSun;
	vec4 sunDir = gbufferModelViewInverse * vec4(lightVector, 0.0f);
	surfaceToSun.dir = normalize(sunDir.xyz);
	vec4 surfacePos = gbufferModelViewInverse * screenSpacePosition;
	surfaceToSun.origin = surfacePos.xyz + cameraPosition.xyz;

	Intersection i = RayPlaneIntersection(surfaceToSun, pl);

	//float cloudShadow = CloudColor(vec4(i.pos.xyz * 30.5f + vec3(30.0f) + vec3(1000.0, 0.0, 0.0), 1.0f), 0.0, worldLightVector, cloudsAltitude, cloudsThickness, false).x;
		  //cloudShadow += CloudColor(vec4(i.pos.xyz * 0.65f + vec3(10.0f) + vec3(i.pos.z * 0.5f, 0.0f, 0.0f), 1.0f), 0.0f, vec3(1.0f), cloudsAltitude, cloudsThickness, true).x;

	i.pos *= 0.015;
	i.pos.x -= frameTimeCounter * 0.42;

	float noise = Get2DNoise(i.pos.xz);
	noise += Get2DNoise(i.pos.xz * 0.5);

	noise *= 0.5;

	noise = mix(saturate(noise * 1.0 - 0.3), 1.0, rainStrength);
	noise = pow(noise, 0.5);
	//noise = mix(saturate(noise * 2.6 - 1.0), 1.0, rainStrength);

	noise = noise * noise * (3.0 - 2.0 * noise);

	//noise = GetCoverage(0.6, 0.2, noise);

	float cloudShadow = noise;

		  cloudShadow = min(cloudShadow, 1.0f);
		  cloudShadow = 1.0f - cloudShadow;

	return cloudShadow;
	// return 1.0f;
}

float G1V(float dotNV, float k)
{
	return 1.0 / (dotNV * (1.0 - k) + k);
}

vec3 SpecularGGX(vec3 N, vec3 V, vec3 L, float roughness, float F0)
{
	float alpha = roughness * roughness;

	vec3 H = normalize(V + L);

	float dotNL = saturate(dot(N, L));
	float dotNV = saturate(dot(N, V));
	float dotNH = saturate(dot(N, H));
	float dotLH = saturate(dot(L, H));

	float F, D, vis;

	float alphaSqr = alpha * alpha;
	float pi = 3.14159265359;
	float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
	D = alphaSqr / (pi * denom * denom);

	float dotLH5 = pow(1.0f - dotLH, 5.0);
	F = F0 + (1.0 - F0) * dotLH5;

	float k = alpha / 2.0;
	vis = G1V(dotNL, k) * G1V(dotNV, k);

	vec3 specular = vec3(dotNL * D * F * vis) * colorSunlight;

	//specular = vec3(0.1);
	specular *= saturate(pow(1.0 - roughness, 0.7) * 2.0);

	return specular;
}



























































void f(inout vec3 v, float y, float f) {
    mat3 z = mat3(1., 0., 0., 0., cos(y), sin(y), 0., -sin(y), cos(y)), i = mat3(cos(f), 0., -sin(f), 0., 1., 0., sin(f), 0., cos(f));
    v = i * v;
    v = z * v;
}
void v(inout vec3 v, float y, float f) {
    y *= -1.;
    f *= -1.;
    mat3 z = mat3(1., 0., 0., 0., cos(y), sin(y), 0., -sin(y), cos(y)), i = mat3(cos(f), 0., -sin(f), 0., 1., 0., sin(f), 0., cos(f));
    v = z * v;
    v = i * v;
}
vec2 f() {
    const float v = 1.61803,
        z = v * 3.14159;
    const int y = 128;
    float f = mod(float(frameCounter) / y, 1.);
    f = mod(f * (.333333 * y) * (1. + 1. / y), 1.);
    vec2 i = vec2(0.);
    i.x = z * f * y;
    i.y = asin(mod(f * 2., 1.));
    return i;
}
void f(inout vec3 v) {
    vec2 n = f();
    f(v.xyz, n.y, n.x);
}
void v(inout vec3 y) {
    vec2 n = f();
    v(y.xyz, n.y, n.x);
}
float v() {
    return .02;
}
float t() {
    return .02;
}
int t(float v) {
    return int(floor(v));
}
int d(int v) {
    return v - t(mod(float(v), 2.)) - 0;
}
int n(int v) {
    return v - t(mod(float(v), 2.)) - 1;
}
int d() {
    ivec2 v = ivec2(viewWidth, viewHeight);
    int y = v.x * v.y;
    return d(t(floor(pow(float(y), .333333))));
}
int n() {
    ivec2 v = ivec2(2048, 2048);
    int y = v.x * v.y;
    return n(t(floor(pow(float(y), .333333))));
}
vec3 s(vec2 v) {
    ivec2 n = ivec2(viewWidth, viewHeight);
    int y = n.x * n.y, z = d();
    ivec2 f = ivec2(v.x * n.x, v.y * n.y);
    int i = t(f.x + f.y * n.x);
    ivec3 r;
    r.x = t(mod(i, z));
    r.y = t(mod(i / z, z));
    r.z = t(mod(i / (z * z), z));
    vec3 x = vec3(r) / z;
    return x;
}
vec2 r(vec3 v) {
    ivec2 n = ivec2(viewWidth, viewHeight);
    int y = d();
    ivec3 i = ivec3(v * y + 1e-05);
    int f = i.x + i.y * y + i.z * y * y;
    ivec2 r;
    r.x = t(mod(f, n.x));
    r.y = t(f / n.x);
    vec2 z = vec2(r) / n;
    z += vec2(.5 / n.x, .5 / n.y);
    return z;
}
vec3 e(vec2 v) {
    ivec2 i = ivec2(2048, 2048);
    int y = i.x * i.y, z = n();
    ivec2 f = ivec2(v.x * i.x, v.y * i.y);
    int x = t(f.x + f.y * i.x);
    ivec3 r;
    r.x = t(mod(x, z));
    r.y = t(mod(x / z, z));
    r.z = t(mod(x / (z * z), z));
    vec3 k = vec3(r) / z;
    return k;
}
vec2 i(vec3 v) {
    ivec2 z = ivec2(2048, 2048);
    int y = n();
    ivec3 i = ivec3(v * y + 1e-05);
    int f = i.x + i.y * y + i.z * y * y;
    ivec2 r;
    r.x = t(mod(f, z.x));
    r.y = t(f / z.x);
    vec2 x = vec2(r) / z;
    x += vec2(.5 / z.x, .5 / z.y);
    return x;
}
vec3 m(vec3 v) {
    int y = n();
    v *= 1. / y;
    v = v + vec3(.5);
    v = clamp(v, vec3(0.), vec3(1.));
    return v;
}
vec3 w(vec3 v) {
    int y = n();
    v = v - vec3(.5);
    v *= y;
    return v;
}
vec3 p(vec3 v) {
    int y = d();
    v *= 1. / y;
    v = v + vec3(.5);
    v = clamp(v, vec3(0.), vec3(1.));
    return v;
}
vec3 h(vec3 v) {
    int y = d();
    v = v - vec3(.5);
    v *= y;
    return v;
}
float e() {
    return 1.;
}
float h() {
    return 2.;
}
vec3 x(vec3 v) {
    int y = d();
    float z = e(), n = y * z;
    vec3 i = v * n - n * .5;
    i -= fract(cameraPosition.xyz / z) * z;
    return i;
}
vec3 g(vec3 v) {
    int y = d();
    float z = e();
    v += fract(cameraPosition.xyz / z) * z;
    float f = y * z;
    vec3 i = (v.xyz + f * .5) / f;
    return i;
}
vec3 a(vec3 v) {
    int y = d();
    float z = e(), i = y * z;
    v = floor(v / z) * z;
    v /= i;
    return v;
}
vec3 B(vec3 v) {
    int y = d();
    float z = h(), n = y * z;
    vec3 i = v * n - n * .5;
    i -= fract(cameraPosition.xyz / z) * z;
    return i;
}
vec3 D(vec3 v) {
    int y = d();
    float z = h();
    v += fract(cameraPosition.xyz / z) * z;
    float i = y * z;
    vec3 f = (v.xyz + i * .5) / i;
    return f;
}
vec3 y(vec3 v) {
    int y = d();
    float z = h(), i = y * z;
    v = floor(v / z) * z;
    v /= i;
    return v;
}
vec3 S(vec3 v) {
    return v = v * 2. - 1., v = pow(length(v), 4.) * normalize(v), v = v * .5 + .5, v;
}
vec3 H(vec3 v) {
    return v = v * 2. - 1., v = pow(length(v), 1. / 6.) * normalize(v), v = v * .5 + .5, v;
}
vec3 c(vec3 v) {
    vec3 f = vec3(0.);
    f += vec3(-1., .5, -1.);
    f += fract(cameraPosition.xyz + .5);
    vec3 y = v, z = vec3(0.);
    for (int r = 0; r < 512; r++) {
        vec3 x = f + y * (r * .25), n = m(x);
        vec2 d = i(n) + vec2(0. / vec2(2048., 2048.));
        vec4 t = texture2D(shadowcolor, d);
        if (t.x < .49 || t.y < .49 || t.z < .49) {
            z = t.xyz;
            break;
        }
        if (d.x < 0. || d.y < 0. || d.x > 1. || d.y > 1.) {
            break;
        }
    }
    return z;
}
struct SHCoeffs {
    vec4 red;
    vec4 green;
    vec4 blue;
    vec4 alpha;
};#
define SH_ENCODE_POWER 3.0
SHCoeffs U(SHCoeffs v) {
    return v.red = v.red * 2. - 1., v.green = v.green * 2. - 1., v.blue = v.blue * 2. - 1., v.alpha = v.alpha * 2. - 1., v.red /= 1., v.green /= 1., v.blue /= 1., v.alpha /= 1., v.red = pow(abs(v.red), vec4(SH_ENCODE_POWER)) * sign(v.red), v.green = pow(abs(v.green), vec4(SH_ENCODE_POWER)) * sign(v.green), v.blue = pow(abs(v.blue), vec4(SH_ENCODE_POWER)) * sign(v.blue), v.alpha = pow(abs(v.alpha), vec4(SH_ENCODE_POWER)) * sign(v.alpha), v;
}
SHCoeffs G(vec3 v) {
    vec2 y = r(v);
    vec4 i = texture2DLod(gaux1, y, 0), n = texture2DLod(gaux2, y, 0);
    SHCoeffs f;
    f.red.xy = UnpackTwo16BitFrom32Bit(i.x);
    f.red.zw = UnpackTwo16BitFrom32Bit(n.x);
    f.green.xy = UnpackTwo16BitFrom32Bit(i.y);
    f.green.zw = UnpackTwo16BitFrom32Bit(n.y);
    f.blue.xy = UnpackTwo16BitFrom32Bit(i.z);
    f.blue.zw = UnpackTwo16BitFrom32Bit(n.z);
    f.alpha.xy = UnpackTwo16BitFrom32Bit(i.w);
    f.alpha.zw = UnpackTwo16BitFrom32Bit(n.w);
    f = U(f);
    return f;
}
vec3 B(vec3 v, vec3 y) {
    v += fract(cameraPosition.xyz + .5) - .5;
    v += y * .2;
    vec3 f = p(v);
    SHCoeffs i = G(f);
    vec3 t = FromSH(i.red, i.green, i.blue, y.xyz) * 5.;
    return t;
}
struct BBRay {
    vec3 origin;
    vec3 direction;
    vec3 inv_direction;
    ivec3 sign;
};
BBRay D(vec3 v, vec3 z) {
    vec3 i = vec3(1.) / z;
    return BBRay(v, z, i, ivec3(i.x < 0 ? 1 : 0, i.y < 0 ? 1 : 0, i.z < 0 ? 1 : 0));
}
void B( in BBRay v, in vec3 f[2], out float i, out float y) {
    float z, r, x, n;
    i = (f[v.sign[0]].x - v.origin.x) * v.inv_direction.x;
    y = (f[1 - v.sign[0]].x - v.origin.x) * v.inv_direction.x;
    z = (f[v.sign[1]].y - v.origin.y) * v.inv_direction.y;
    r = (f[1 - v.sign[1]].y - v.origin.y) * v.inv_direction.y;
    x = (f[v.sign[2]].z - v.origin.z) * v.inv_direction.z;
    n = (f[1 - v.sign[2]].z - v.origin.z) * v.inv_direction.z;
    i = max(max(i, z), x);
    y = min(min(y, r), n);
}
vec3 o(vec3 v) {
    vec3 f = vec3(0.);
    f += fract(cameraPosition.xyz + .5);
    vec3 y = v, z = vec3(0.);
    float r = 0.;
    int x = n();
    f = m(f) * x;
    Ray t;
    t.origin = f;
    t.dir = v;
    ivec3 c = ivec3(floor(t.origin));
    vec3 s, d;
    ivec3 p;
    for (int e = 0; e < 3; e++) {
        float a = t.dir[0] / t.dir[e], w = t.dir[1] / t.dir[e], h = t.dir[2] / t.dir[e];
        s[e] = sqrt(a * a + w * w + h * h);
        if (t.dir[e] < 0.) p[e] = -1, d[e] = (t.origin[e] - c[e]) * s[e];
        else p[e] = 1, d[e] = (c[e] + 1. - t.origin[e]) * s[e];
    }
    for (int e = 0; e < 60; e++) {
        int w = 0;
        for (int k = 0; k < 3; k++) {
            if (d[w] > d[k]) w = k;
        }
        d[w] += s[w];
        c[w] += p[w];
        vec3 a = vec3(c) / float(x);
        vec2 o = i(a);
        vec4 g = texture2DLod(shadowcolor, o, 0);
        if (g.x < .49 || g.y < .49 || g.z < .49) {
            z = g.xyz;
            r = g.w;
            break;
        }
        if (o.x < 0. || o.y < 0. || o.x > 1. || o.y > 1.) {
            break;
        }
    }
    return z;
}
vec3 l(vec2 v) {
    vec2 i = vec2(v.xy * vec2(viewWidth, viewHeight)) / 64.;
    i += vec2(sin(frameCounter * .75), cos(frameCounter * .75));
    i = (floor(i * 64.) + .5) / 64.;
    vec3 y = texture2DLod(noisetex, i.xy, 0).xyz;
    float f = .45, z = .25;
    vec3 r = texture2DLod(noisetex, i.xy + vec2(f, f) * vec2(1. / 64.), 0).xyz * .25;
    r += texture2DLod(noisetex, i.xy + vec2(f, -f) * vec2(1. / 64.), 0).xyz * .25;
    r += texture2DLod(noisetex, i.xy + vec2(-f, f) * vec2(1. / 64.), 0).xyz * .25;
    r += texture2DLod(noisetex, i.xy + vec2(-f, -f) * vec2(1. / 64.), 0).xyz * .25;
    vec3 n = y - r + .5;
    n = n * 2. - .498039;
    return n;
}
vec2 C(inout float v) {
    return fract(sin(vec2(v += .1, v += .1)) * vec2(43758.5, 22578.1));
}
vec3 B(vec3 v, inout float f, int y) {
    vec2 i = C(f);
    vec3 z = normalize(cross(v, vec3(0., 1., 1.))), n = cross(z, v);
    float x = sqrt(i.y), c = x * cos(6.2831 * i.x), w = x * sin(6.2831 * i.x), r = sqrt(1. - i.y);
    vec3 t = vec3(c * z + w * n + r * v);
    return normalize(t);
}
vec3 C(vec3 v, vec3 f, vec3 y, float z) {
    const int x = 1;
    int r = n();
    float w = .5 / float(r);
    vec3 e = vec3(0.);
    float c = (texcoord.x + texcoord.y * 3.4321 + fract(frameCounter * .001) * 10.) * 9.1;
    vec3 t[3] = vec3[3](vec3(1., 0., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.));
    float a = 0., d = pow(z * z * (3. - 2. * z), .1);
    for (int s = 0; s < x; s++) {
        vec3 k = B(f, c, s);
        k = worldLightVector;
        vec3 p = v + f * .01;
        p += fract(cameraPosition.xyz + .5);
        p = m(p);
        Ray o;
        o.origin = p * r - vec3(1., 1., 1.);
        o.dir = k;
        vec3 h = vec3(1.);
        ivec3 g = ivec3(floor(o.origin));
        vec3 U, S;
        ivec3 G;
        for (int b = 0; b < 3; b++) {
            float l = o.dir[0] / o.dir[b], L = o.dir[1] / o.dir[b], R = o.dir[2] / o.dir[b];
            U[b] = sqrt(l * l + L * L + R * R);
            if (o.dir[b] < 0.) G[b] = -1, S[b] = (o.origin[b] - g[b]) * U[b];
            else G[b] = 1, S[b] = (g[b] + 1. - o.origin[b]) * U[b];
        }
        int b = 0;
        float l = 0.;
        int L = 0;
        for (int R = 0; R < 100; R++) {
            for (int C = 0; C < 3; C++) {
                if (S[b] > S[C]) b = C;
            }
            S[b] += U[b];
            g[b] += G[b];
            vec3 C = vec3(g) / float(r);
            vec2 H = i(C);
            vec4 F = texture2DLod(shadowcolor, H, 0);
            if (F.w * 255. > 1. f && F.w * 255. < 128. f) {
                h *= vec3(0.);
                break;
            }
            if (H.x < 0. || H.y < 0. || H.x > 1. || H.y > 1.) {
                break;
            }
            L++;
        }
        if (L >= 99) {
            e += vec3(1.);
            break;
        }
        float C, R;
        vec3 H = vec3(g), F = vec3(g) + 1., W[2] = vec3[2](vec3(g), vec3(g) + 1.);
        B(D(o.origin, o.dir), W, C, R);
        vec3 A = t[b];
        o.origin += k * C + A * .01;
        o.dir = B(-t[b] * sign(o.dir[b]), c, s);
        a += C;
        c = mod(c * 1.12346, 13.);
    }
    if (a <= 0.) a = 10000.;
    e *= saturate(dot(f, worldLightVector));
    return e / x;
}
vec3 F(vec2 v) {
    vec3 y = DecodeNormal(texture2DLod(gnormal, v.xy * 2., 0).xy);
    return y;
}
float A(vec2 v) {
    return ExpToLinearDepth(texture2DLod(depthtex1, v * 2., 0).x);
}
vec3 A(vec2 v, vec3 f, float y, vec3 z) {
    vec3 i = vec3(0.), r = vec3(0.);
    float n = 0.;
    int x = 0;
    f = F(v * .5);
    y = A(v * .5);
    float t = 1., s = 5.;
    vec2 o = rand(v + sin(frameTimeCounter)).xy - .5;
    float e = 3.;
    for (int c = -1; c <= 1; c++) {
        for (int w = -1; w <= 1; w++) {
            vec2 d = (vec2(c, w) + o.xy) / vec2(viewWidth, viewHeight) * e + v.xy * .5, g = (vec2(c, w) + o.xy) / vec2(viewWidth, viewHeight) * e * 1.5 + v.xy * .5;
            float a = A(g);
            vec3 R = F(g), k = texture2DLod(gaux3, d, 0).xyz;
            float p = pow(saturate(dot(f, R)), t), h = exp(-(abs(a - y) * s)), m = p * h;
            i += k * m;
            n += m;
            r += k;
            x++;
        }
    }
    i /= n + 1e-05;
    if (n < .0001);
    return i;
}
void main() {
    GBufferData v = GetGBufferData();
    MaterialMask i = CalculateMasks(v.materialID);
    vec4 f = GetViewPosition(texcoord.xy, v.depth);
    if (isEyeInWater > .5) f.xy *= .8;
    vec4 r = gbufferModelViewInverse * vec4(f.xyz, 1.), n = gbufferModelViewInverse * vec4(f.xyz, 0.);
    vec3 y = normalize(f.xyz), z = normalize(n.xyz), x = normalize((gbufferModelViewInverse * vec4(v.normal, 0.)).xyz), w = normalize((gbufferModelViewInverse * vec4(GetWaterNormals(texcoord.xy), 0.)).xyz);
    float c = length(f.xyz);
    vec3 t = vec3(0.);
    v.albedo.xyz *= 1. + i.water * .2;
    v.albedo.xyz *= 1. + i.stainedGlass * .2;
    if (i.water > .5) v.mcLightmap.y = CurveBlockLightSky(texture2D(composite, texcoord.xy).y);
    vec4 o = GetGI(v.albedo.xyz, v.normal, v.mcLightmap.y);
    vec3 g = normalize(v.albedo.xyz + .0001) * pow(length(v.albedo.xyz), 1.) * colorSunlight * .13 * v.mcLightmap.y;
    float a = saturate(shadowDistance * .1 * 1.2 - length(f) * .1);
    o.xyz = mix(g, o.xyz, vec3(a));
    float e = 1.;
    o.xyz = vec3(0.);
    if (i.grass > .5) x = vec3(0., 1., 0.);
    vec3 m = FromSH(skySHR, skySHG, skySHB, x);
    m = mix(m, vec3(.3) * (dot(x, vec3(0., 1., 0.)) * .35 + .65) * Luminance(colorSkylight), vec3(rainStrength));
    m *= v.mcLightmap.y;
    t += m * v.albedo.xyz * 2. * e;
    const float k = 3.7 * TORCHLIGHT_BRIGHTNESS;
    t += v.mcLightmap.x * colorTorchlight * v.albedo.xyz * .5 * e * k;
    float s = 1. / (pow(length(r.xyz), 2.) + .5);
    t += v.albedo.xyz * s * heldBlockLightValue * colorTorchlight * .025 * k * e * heldLightBlacklist;
    if (i.lava > .5) t += v.albedo.xyz * 8.;
    vec4 d = GetViewPosition(texcoord.xy, texture2D(gdepthtex, texcoord.xy).x);
    if (isEyeInWater > 0) {
        if (i.water > .5) z = refract(z, w, WATER_REFRACT_IOR);
    }
    t.xyz = A(texcoord.xy, v.normal, v.depth, f.xyz) * v.albedo.xyz * 5.;
    if (i.sky > .5 || v.depth > 1.) {
        v.albedo.xyz *= 1. - saturate((dot(z, worldSunVector) - .95) * 50.);
        vec3 p = vec3(RenderSunDisc(z, worldSunVector)), C = AtmosphericScattering(vec3(z.x, z.y, z.z), worldSunVector, 1.);
        C = mix(C, vec3(.6) * Luminance(colorSkylight), vec3(rainStrength * .95));
        t.xyz = C;
        p *= colorSunlight;
        p *= pow(saturate(worldSunVector.y + .1), .9);
        t += 0.;
        CloudPlane(t, y, -z, c, i, worldLightVector, lightVector);
        vec3 l = AtmosphericScattering(vec3(z.x, z.y, z.z), -worldSunVector, 1.);
        l = mix(l, vec3(.6) * .00025, vec3(rainStrength * .95));
        t += l * .00025;
        t += v.albedo.xyz * normalize(l + 1e-07) * .13;
        r.xyz = z.xyz * 2670.;
    }
    float p = 0.;
    if (length(z) < .5) t *= 0., p = 1.;
    WaterFog(t, i, v.mcLightmap.y, f, d);
    if (i.grass > .5) t.x = 1.;
    t *= .001;
    t = LinearToGamma(t);
    t += rand(texcoord.xy + sin(frameTimeCounter)) * (1. / 65535.);
    gl_FragData[0] = vec4(t.xyz, 1.);
}