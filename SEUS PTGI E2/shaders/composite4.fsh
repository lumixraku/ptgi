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


const bool gaux1Clear = false;
const bool gaux2Clear = false;

const bool gaux1MipmapEnabled = false;


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

varying vec3 upVector;

/* DRAWBUFFERS:456 */

uniform int frameCounter;

#include "GIVolume.inc"
#include "GBufferData.inc"

//#define HALF_RES_TRACE

float GaussianWindow(float x, float t)
{
	return exp(-pow(x / (0.9 * t), 2.0));
}

vec3 GetNormal(vec2 coord)
{
	#ifdef HALF_RES_TRACE
	vec3 normal = DecodeNormal(texture2DLod(gnormal, coord.st * 2.0, 0).xy);
	#else
	vec3 normal = DecodeNormal(texture2DLod(gnormal, coord.st, 0).xy);
	#endif
	return normal;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}

float GetLinearDepth(vec2 coord)
{
	#ifdef HALF_RES_TRACE
	return ExpToLinearDepth(texture2D(depthtex1, coord * 2.0).x);
	#else
	return ExpToLinearDepth(texture2D(depthtex1, coord).x);
	#endif
}

vec4 GetViewPosition(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 1.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}

#ifdef BLUR_SELF_FEEDBACK
#define SOURCE_TARGET gaux1
#else
#define SOURCE_TARGET gaux3
#endif

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() 
{
	#if 1
	vec4 gaux2Data = texture2DLod(gaux2, texcoord.st, 0);

	float disocclusion = gaux2Data.b;
	// int lod = int(saturate(disocclusion * 8.0) * 6.0);
	int lod = 0;

	vec3 centerGI = texture2DLod(SOURCE_TARGET, texcoord.st, lod).rgb;
	float centerLuminance = Luminance(centerGI.rgb);

	vec3 normal = GetNormal(texcoord.st);
	float depth = GetLinearDepth(texcoord.st);

	vec3 sum = vec3(0.0);
	float weightSum = 0.0;

	float normalRejectionWeight = 62.0;
	float depthRejectionWeight = 1.0;

	vec2 dither = rand(texcoord.st + sin(frameTimeCounter)).xy - 0.5;
	dither *= 0.0;

	float prevGILuminance = gaux2Data.x;
	float filterWidth = 1.0 + (3.0 / (prevGILuminance * 200.0 + 1.0));
	// filterWidth *= 0.151515;
	filterWidth *= 3.6 * mix(BlurRadius, BlurRadiusDisocclusion, disocclusion);
	// filterWidth = 0.0;

	vec3 dumbBlur = vec3(0.0);


	// float colorRejection = 600.0 * ColorBlendRejection;
	float colorRejection = mix(1000.0 * ColorBlendRejection, 510 * ColorBlendRejectionDisocclusion, disocclusion);
	// colorRejection *= 1.0 - disocclusion * 0.15;
	colorRejection /= prevGILuminance * 100.0 + 1.01;
	// colorRejection = 0.0;



	vec3 viewPos = GetViewPosition(texcoord.st, texture2D(depthtex1, texcoord.st * 2.0).x).xyz;

	// filterWidth /= dot(-normalize(viewPos), normal) + 1.0;


	int c = 0;
	for (int i = -1; i <= 1; i++)
	{
		for (int j = -1; j <= 1; j++)
		{
			vec2 coordOffset = ((vec2(i, j) + dither) / vec2(viewWidth, viewHeight)) * (6.5 + 6.0 * disocclusion) * filterWidth;
			vec2 coord = texcoord.st + coordOffset.st;
			float coordOffsetLength = length(coordOffset * vec2(viewWidth, viewHeight));

			#ifdef HALF_RES_TRACE
			coord = clamp(coord, 4.0 / vec2(viewWidth, viewHeight), 0.5 - (4.0 / vec2(viewWidth, viewHeight)));
			#else
			coord = clamp(coord, 4.0 / vec2(viewWidth, viewHeight), 1.0 - (4.0 / vec2(viewWidth, viewHeight)));
			#endif

			vec3 giSample = texture2DLod(SOURCE_TARGET, coord, lod).rgb;
			vec3 normalSample = GetNormal(coord);
			float depthSample = GetLinearDepth(coord);

			float normalWeight = pow(saturate(dot(normal, normalSample)), normalRejectionWeight);
			float depthWeight = exp(-(abs(depthSample - depth) * depthRejectionWeight));
			float colorWeight = exp(-(abs(centerLuminance - Luminance(giSample)) * colorRejection));

			float weight = normalWeight * colorWeight * depthWeight;

			sum += giSample * weight;
			weightSum += weight;
			dumbBlur += giSample;
			c++;
		}
	}

	sum /= weightSum + 0.0001;


	vec3 gi = sum.rgb;




















	vec4 temporalBuffer1 = texture2D(gaux1, texcoord.st);

	temporalBuffer1.rgb = mix(temporalBuffer1.rgb, gi.rgb, vec3(mix(saturate(0.0 * BlurBlendWeight / (prevGILuminance + 0.08)), 1.0, disocclusion)));
	// temporalBuffer1.rgb = mix(temporalBuffer1.rgb, gi.rgb, vec3(0.2));

	if (weightSum < 0.0001)
	{
		// gi = dumbBlur / c;
		gi = centerGI;
	}

	gi = centerGI;

	vec4 temporalBuffer2 = vec4(Luminance(temporalBuffer1.rgb), gaux2Data.y, disocclusion, 1.0);

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


	gl_FragData[0] = temporalBuffer1;
	// gl_FragData[0] = vec4(gi.rgb, texture2D(gaux1, texcoord.st).a);
	gl_FragData[1] = temporalBuffer2;
	gl_FragData[2] = vec4(gi, 1.0);


	#else
	gl_FragData[0] = texture2D(gaux1, texcoord.st);
	// gl_FragData[0] = vec4(gi.rgb, texture2D(gaux1, texcoord.st).a);
	gl_FragData[1] = texture2D(gaux2, texcoord.st);
	gl_FragData[2] = vec4(0.0, 0.5, 1.0, 1.0);
	#endif


}