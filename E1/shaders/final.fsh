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



#include "Common.inc"



/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define TONEMAP_CURVE 5.5 // Controls the intensity of highlights. Lower values give a more filmic look, higher values give a more vibrant/natural look. Default: 5.5 [1.0 1.5 2.0 3.0 5.5 7.0]

#define EXPOSURE 1.0 // Controls overall brightness/exposure of the image. Higher values give a brighter image. Default: 1.0 [0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

#define GAMMA 1.0 // Gamma adjust. Lower values make shadows darker. Higher values make shadows brighter. Default: 1.0 [0.7 0.8 0.9 1.0 1.1 1.2 1.3]

#define SATURATION 1.0 // Saturation adjust. Higher values give a more colorful image. Default: 1.0 [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////


uniform sampler2D colortex0;
uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

varying vec4 texcoord;
varying vec3 lightVector;

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

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

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

varying float avgSkyBrightness;

uniform vec3 skyColor;

uniform int frameCounter;



const float overlap = 0.2;

const float rgOverlap = 0.1 * overlap;
const float rbOverlap = 0.01 * overlap;
const float gbOverlap = 0.04 * overlap;

const mat3 coneOverlap = mat3(1.0, 			rgOverlap, 	rbOverlap,
							  rgOverlap, 	1.0, 		gbOverlap,
							  rbOverlap, 	rgOverlap, 	1.0);

const mat3 coneOverlapInverse = mat3(	1.0 + (rgOverlap + rbOverlap), 			-rgOverlap, 	-rbOverlap,
									  	-rgOverlap, 		1.0 + (rgOverlap + gbOverlap), 		-gbOverlap,
									  	-rbOverlap, 		-rgOverlap, 	1.0 + (rbOverlap + rgOverlap));




vec3 Tonemap(vec3 color)
{
	const float p = TONEMAP_CURVE;
	color = pow(color, vec3(p));
	color = color / (1.0 + color);
	color = pow(color, vec3((1.0 / GAMMA) / p));


	color = mix(color, color * color * (3.0 - 2.0 * color), vec3(0.2));

	//color = pow(color, vec3(1.0 / 2.0));
	//color = mix(color, color * color * (3.0 - 2.0 * color), vec3(0.1));
	//color = pow(color, vec3(2.0));

	//color = color * 0.5 + 0.5;
	//color = mix(color, color * color * (3.0 - 2.0 * color), vec3(0.8));
	//color = saturate(color * 2.0 - 1.0);

	return color;
}

vec3 Tonemap2(vec3 color)
{
	color *= 1.3;

	const float p = 2.9;
	color = pow(color, vec3(p));
	color = color / (1.0 + color);
	color = pow(color, vec3(1.0 / p));


	color = mix(color, color * color * (3.0 - 2.0 * color), vec3(0.0));

	color = pow(color, vec3(1.0 / 2.0));
	color = mix(color, color * color * (3.0 - 2.0 * color), vec3(0.1));
	color = pow(color, vec3(2.0));

	//color = color * 0.5 + 0.5;
	//color = mix(color, color * color * (3.0 - 2.0 * color), vec3(0.8));
	//color = saturate(color * 2.0 - 1.0);






	return color;
}




/////////////////////////////////////////////////////////////////////////////////
//	ACES Fitting by Stephen Hill
vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786f) - 0.000090537f;
    vec3 b = v * (1.0f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

vec3 ACESTonemap2(vec3 color)
{
	color *= 1.5;
	color = color * coneOverlap;

    // Apply RRT and ODT
    color = RRTAndODTFit(color);


    // Clamp to [0, 1]
	color = color * coneOverlapInverse;
    color = saturate(color);

    return color;
}
/////////////////////////////////////////////////////////////////////////////////





vec3 ACESTonemap(vec3 color)
{
	color = color * coneOverlap;

	color = (color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14);

	color = color * coneOverlapInverse;

	color = saturate(color);


	return color;
}



vec3 	CalculateNoisePattern1(vec2 offset, float size) 
{
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= 64.0;

	return texture2D(noisetex, coord).xyz;
}

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
	vec2 resolution = vec2(viewWidth, viewHeight);

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    fx -= 0.5;
    fy -= 0.5;

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

vec3 GetBloomTap(vec2 coord, const float octave, const vec2 offset)
{
	float scale = exp2(octave);

	coord /= scale;
	coord -= offset;

	return GammaToLinear(BicubicTexture(gnormal, coord).rgb);
}

vec2 CalcOffset(float octave)
{
    vec2 offset = vec2(0.0);
    
    vec2 padding = vec2(30.0) / vec2(viewWidth, viewHeight);
    
    offset.x = -min(1.0, floor(octave / 3.0)) * (0.25 + padding.x);
    
    offset.y = -(1.0 - (1.0 / exp2(octave))) - padding.y * octave;

	offset.y += min(1.0, floor(octave / 3.0)) * 0.35;
    
 	return offset;   
}



vec3 GetBloom(vec2 coord)
{
	vec3 bloom = vec3(0.0);

	bloom += GetBloomTap(coord, 1.0, CalcOffset(0.0)) * 2.0;
	bloom += GetBloomTap(coord, 2.0, CalcOffset(1.0)) * 1.5;
	bloom += GetBloomTap(coord, 3.0, CalcOffset(2.0)) * 1.2;
	bloom += GetBloomTap(coord, 4.0, CalcOffset(3.0)) * 1.3;
	bloom += GetBloomTap(coord, 5.0, CalcOffset(4.0)) * 1.4;
	bloom += GetBloomTap(coord, 6.0, CalcOffset(5.0)) * 1.5;
	bloom += GetBloomTap(coord, 7.0, CalcOffset(6.0)) * 1.6;
	bloom += GetBloomTap(coord, 8.0, CalcOffset(7.0)) * 1.7;
	bloom += GetBloomTap(coord, 9.0, CalcOffset(8.0)) * 0.4;

	bloom /= 12.6;


	//bloom = mix(bloom, vec3(dot(bloom, vec3(0.3333))), vec3(-0.1));
	//bloom = mix(bloom, vec3(dot(bloom, vec3(0.3333))), vec3(0.1));

	//bloom = length(bloom) * pow(normalize(bloom + 0.00001), vec3(1.5));

	return bloom;
}

void CalculateExposureEyeBrightness(inout vec3 color) 
{
	float exposureMax = 1.55f;
		  //exposureMax *= mix(1.0f, 0.25f, timeSunriseSunset);
		  //exposureMax *= mix(1.0f, 0.0f, timeMidnight);
		  //exposureMax *= mix(1.0f, 0.25f, rainStrength);
		  exposureMax *= avgSkyBrightness * 2.0;
	float exposureMin = 0.07f;
	float exposure = pow(eyeBrightnessSmooth.y / 240.0f, 6.0f) * exposureMax + exposureMin;

	//exposure = 1.0f;

	color.rgb /= vec3(exposure);
	color.rgb *= 350.0;
}

void AverageExposure(inout vec3 color)
{
	float avglod = int(log2(min(viewWidth, viewHeight))) - 0;
	color /= pow(Luminance(texture2DLod(composite, vec2(0.5, 0.5), avglod).rgb), 1.1) * 0.9 + 0.00005;
}

void MicroBloom(inout vec3 color)
{
	/*
	vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
	vec3 sum = GetColorTexture(texcoord.st + vec2(0.5, -0.5) * texel * 0.9).rgb;
		 sum += GetColorTexture(texcoord.st + vec2(0.5, 0.5) * texel * 0.9).rgb;
		 sum += GetColorTexture(texcoord.st + vec2(-0.5, 0.5) * texel * 0.9).rgb;
		 sum += GetColorTexture(texcoord.st + vec2(-0.5, -0.5) * texel * 0.9).rgb;

	vec3 sum2 = GetColorTexture(texcoord.st + vec2(0.5, -0.5) * texel * 1.9).rgb;
		 sum2 += GetColorTexture(texcoord.st + vec2(0.5, 0.5) * texel * 1.9).rgb;
		 sum2 += GetColorTexture(texcoord.st + vec2(-0.5, 0.5) * texel * 1.9).rgb;
		 sum2 += GetColorTexture(texcoord.st + vec2(-0.5, -0.5) * texel * 1.9).rgb;

	color += sum * 0.1 * 0.75;
	color += sum2 * 0.05 * 0.75;
	*/

	vec3 bloom = vec3(0.0);
	float allWeights = 0.0f;

	for (int i = 0; i < 4; i++) 
	{
		for (int j = 0; j < 4; j++) 
		{
			float weight = 1.0f - distance(vec2(i, j), vec2(2.5f)) / 2.5;
				  weight = clamp(weight, 0.0f, 1.0f);
				  weight = 1.0f - cos(weight * 3.1415 / 2.0f);
				  weight = pow(weight, 2.0f);
			vec2 coord = vec2(i - 2.5, j - 2.5);
				 coord.x /= viewWidth;
				 coord.y /= viewHeight;
				 //coord *= 0.0f;

				 //coord.x -= 0.5f / viewWidth;
				 //coord.y -= 0.5f / viewHeight;

			vec2 finalCoord = (texcoord.st + coord.st * 1.0);

			if (weight > 0.0f)
			{
				bloom += pow(clamp(texture2DLod(composite, finalCoord, 0).rgb, vec3(0.0f), vec3(1.0f)), vec3(2.2f)) * weight;
				allWeights += 1.0f * weight;
			}
		}
	}
	bloom /= allWeights;

	color = mix(color, bloom, vec3(0.4));
}

void 	Vignette(inout vec3 color) {
	float dist = distance(texcoord.st, vec2(0.5f)) * 2.0f;
		  dist /= 1.5142f;

		  //dist = pow(dist, 1.1f);

	color.rgb *= 1.0f - dist * 0.5;

}

void DoNightEye(inout vec3 color)
{
	float lum = Luminance(color * vec3(1.0, 1.0, 1.0));
	float mixSize = 1250000.0;
	float mixFactor = 0.01 / (pow(lum * mixSize, 2.0) + 0.01);


	vec3 nightColor = mix(color, vec3(lum), vec3(0.9)) * vec3(0.25, 0.5, 1.0) * 2.0;

	color = mix(color, nightColor, mixFactor);
}

void Overlay(inout vec3 color, vec3 overlayColor)
{
	vec3 overlay = vec3(0.0);

	for (int i = 0; i < 3; i++)
	{
		if (color[i] > 0.5)
		{
			float valueUnit = (1.0 - color[i]) / 0.5;
			float minValue = color[i] - (1.0 - color[i]);
			overlay[i] = (overlayColor[i] * valueUnit) + minValue;
		}
		else
		{
			float valueUnit = color[i] / 0.5;
			overlay[i] = overlayColor[i] * valueUnit;
		}
	}

	color = overlay;
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

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec3 color = GammaToLinear(texture2D(composite, texcoord.st).rgb);

	/*
	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
	vec3 sharpenSample 	 = GammaToLinear(texture2D(gaux3, texcoord.st + texel * vec2(0.5, 0.5)).rgb);
	sharpenSample 		+= GammaToLinear(texture2D(gaux3, texcoord.st + texel * vec2(0.5, -0.5)).rgb);
	sharpenSample 		+= GammaToLinear(texture2D(gaux3, texcoord.st + texel * vec2(-0.5, 0.5)).rgb);
	sharpenSample 		+= GammaToLinear(texture2D(gaux3, texcoord.st + texel * vec2(-0.5, -0.5)).rgb);

	sharpenSample *= 0.25;

	float sharpenFactor = (1.0 - exp(-Luminance(color - sharpenSample) * 4.0)) * 0.25;

	color += sharpenFactor * 0.5;
	*/

	color = mix(color, GetBloom(texcoord.st), vec3(0.05 + isEyeInWater * 0.7));
	//color = GammaToLinear(texture2D(gaux1, texcoord.st).rgb);


	//CalculateExposureEyeBrightness(color);

	//DoNightEye(color);

	//MicroBloom(color);
	Vignette(color);


	// AverageExposure(color);
	color *= 160.0;


	//OLY FOR ME
	//color.g *= 1.05;



	color *= 16.0 * EXPOSURE; 


	color = Tonemap(color);

	color = pow(color, vec3(1.0 / 2.2));


	//vec3 skyTint = vec3(1.0);
	//float skyTintAmount = abs(skyColor.r - (116.0 / 255.0)) + abs(skyColor.g - (172.0 / 255.0)) + abs(skyColor.b - (255.0 / 255.0));
	//skyTint = mix(vec3(0.5), skyColor, saturate(skyTintAmount * 4.0));
	//Overlay(color, normalize(skyTint + 0.00001));

	//color = skyTint;
	//color *= gl_Fog.color.rgb;
	//color *= skyColor;



	color = mix(color, vec3(Luminance(color)), vec3(1.0 - SATURATION));






	color += rand(texcoord.st) * (1.0 / 255.0);


	//color = vec3(0.5, 0.25, 1.0);


	// color = texture2D(colortex0, texcoord.st).rgb;


	//color = vec3(gl_Fog.density * 0.1);


	// color = BlueNoise(texcoord.st).rgb;

	//color = texture2D(gaux4, mod(texcoord.st * 2.0 - 0.5, vec2(1.0))).rgb;


	// if (texcoord.x > 0.5 && texcoord.y > 0.5)
	// {
	// 	color = texture2D(shadowcolor, texcoord.st * 2.0 - 1.0).rgb;
	// }

	// color = texture2DLod(shadowcolor, texcoord.st, 0).rgb * 2.0;

	// color = vec3(texture2D(gaux4, texcoord.st).a);




	gl_FragColor = vec4(color.rgb, 1.0f);

}
