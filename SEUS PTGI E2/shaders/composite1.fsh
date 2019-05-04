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


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() 
{
	vec4 gaux2Data = texture2DLod(gaux2, texcoord.st, 0);

	float disocclusion = gaux2Data.b;
	float sampleAge = gaux2Data.a * 256.0;
	// int lod = int(saturate(disocclusion * 8.0) * 6.0);
	int lod = 0;

	vec3 centerGI = texture2DLod(gaux1, texcoord.st, lod).rgb;
	float centerLuminance = Luminance(centerGI.rgb);

	vec3 normal = GetNormal(texcoord.st);
	float depth = GetLinearDepth(texcoord.st);

	vec3 sum = vec3(0.0);
	float weightSum = 0.0;

	float normalRejectionWeight = 62.0;
	float depthRejectionWeight = 2.0;

	vec2 dither = rand(texcoord.st + sin(frameTimeCounter)).xy - 0.5;
	// dither *= 0.0;

	float prevGILuminance = gaux2Data.x;
	float filterWidth = 1.0 + (3.0 / (prevGILuminance * 200.0 + 1.0));
	// filterWidth *= 0.151515;
	filterWidth *= 0.1 * mix(BlurRadius, BlurRadiusDisocclusion, disocclusion);
	// filterWidth /= sampleAge + 0.2;
	// filterWidth = 0.0;

	vec3 dumbBlur = vec3(0.0);


	float colorRejection = mix(50.0 * ColorBlendRejection, 0.0, disocclusion);
	colorRejection /= prevGILuminance * 100.0 + 1.5;
	// colorRejection = 0.0;



	vec3 viewPos = GetViewPosition(texcoord.st, texture2D(depthtex1, texcoord.st * 2.0).x).xyz;

	// filterWidth /= dot(-normalize(viewPos), normal) + 1.0;


	int c = 0;
	for (int i = -3; i <= 3; i++)
	{
		for (int j = -3; j <= 3; j++)
		{
			vec2 coordOffset = ((vec2(i, j) + dither) / vec2(viewWidth, viewHeight)) * (6.5 + 6.0 * disocclusion) * filterWidth;
			vec2 coord = texcoord.st + coordOffset.st;
			float coordOffsetLength = length(coordOffset * vec2(viewWidth, viewHeight));

			#ifdef HALF_RES_TRACE
			coord = clamp(coord, 4.0 / vec2(viewWidth, viewHeight), 0.5 - (4.0 / vec2(viewWidth, viewHeight)));
			#else
			coord = clamp(coord, 4.0 / vec2(viewWidth, viewHeight), 1.0 - (4.0 / vec2(viewWidth, viewHeight)));
			#endif

			vec3 giSample = texture2DLod(gaux1, coord, lod).rgb;
			vec3 normalSample = GetNormal(coord);
			float depthSample = GetLinearDepth(coord);

			float normalWeight = pow(saturate(dot(normal, normalSample)), normalRejectionWeight);
			float depthWeight = exp(-(abs(depthSample - depth) * depthRejectionWeight));
			float colorWeight = exp(-(abs(centerLuminance - Luminance(giSample)) * colorRejection));

			float weight = normalWeight * depthWeight * colorWeight;

			sum += giSample * weight;
			weightSum += weight;
			dumbBlur += giSample;
			c++;
		}
	}

	sum /= weightSum + 0.0001;


	vec3 gi = sum.rgb;

	// gi += disocclusion;
	// gi.r = disocclusion;


	// gi.rgb = vec3(prevGILuminance);

	// gi.r += lod;


	// vec2 momentData = texture2D(gaux2, texcoord.st).xy;
	// float deviation = sqrt(max(0.0, momentData.y - momentData.x * momentData.x));
	// deviation = abs(centerLuminance - deviation * 2.99);

	// gi.rgb = vec3(deviation);


	// vec3 gi = texture2D(gaux1, texcoord.st).rgb;
	// gi = vec3(gaux2Data.y * 0.01);


	vec4 temporalBuffer1 = texture2D(gaux1, texcoord.st);

	//When a disocclusion happens, blend the blurred GI back to the accumulation buffer for the next frame, otherwise, return the centerGI sample
	//source of the seemingly accidentally perfect
	// temporalBuffer1.rgb = mix(centerGI.rgb, gi.rgb, vec3(disocclusion));
	// temporalBuffer1.rgb = mix(centerGI.rgb, gi.rgb, vec3(disocclusion * 0.9 + 0.1));
	// temporalBuffer1.rgb = mix(centerGI.rgb, gi.rgb, vec3(0.25));


	temporalBuffer1.rgb = mix(temporalBuffer1.rgb, gi.rgb, vec3(mix(saturate(0.9 * BlurBlendWeight / (prevGILuminance + 0.01)), 1.0, disocclusion)));

	if (weightSum < 0.0001)
	{
		// gi = dumbBlur / c;
		gi = centerGI;
	}



	vec4 temporalBuffer2 = vec4(Luminance(temporalBuffer1.rgb), gaux2Data.y, disocclusion, 1.0);

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


	gl_FragData[0] = temporalBuffer1;
	gl_FragData[1] = temporalBuffer2;
	gl_FragData[2] = vec4(gi, 1.0);





}