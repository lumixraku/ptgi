#version 130

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



////////////////////////////////////////////////////ADJUSTABLE VARIABLES/////////////////////////////////////////////////////////



///////////////////////////////////////////////////END OF ADJUSTABLE VARIABLES///////////////////////////////////////////////////



#include "Common.inc"


/* DRAWBUFFERS:012 */

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform float wetness;
uniform float frameTimeCounter;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform ivec2 atlasSize;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 worldPosition;
varying vec4 vertexPos;
varying mat3 tbnMatrix;
varying vec3 viewPos;

varying vec3 normal;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 worldNormal;

varying vec2 blockLight;

varying float materialIDs;

varying float distance;



uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;


float CurveBlockLightTorchSource(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;

#include "GBufferData.inc"

void main() 
{	

	vec4 albedo = texture2D(texture, texcoord.st);
	albedo *= color;



	//vec2 lightmap;
	// lightmap.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
	// lightmap.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);


	// CurveLightmapSky(lightmap.y);

	vec4 specTex = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 normalTex = vec4(0.0, 1.0, 0.0, 1.0);
	vec3 viewNormal = normal;

		specTex = texture2D(specular, texcoord.st);
		normalTex = texture2D(normals, texcoord.st) * 2.0 - 1.0;

		// viewNormal = normalize(normalTex.xyz) * tbnMatrix;

	

	float smoothness = pow(specTex.r, 1.0);
	float metallic = specTex.g;
	float emissive = specTex.b;




	//vec2 normalEnc = EncodeNormal(viewNormal.xyz);




	//Calculate torchlight average direction
	vec3 Q1 = dFdx(viewPos.xyz);
	vec3 Q2 = dFdy(viewPos.xyz);
	float st1 = dFdx(blockLight.x);
	float st2 = dFdy(blockLight.x);

	st1 /= dot(fwidth(viewPos.xyz), vec3(0.333333));
	st2 /= dot(fwidth(viewPos.xyz), vec3(0.333333));
	vec3 T = (Q1*st2 - Q2*st1);
	T = normalize(T + normal.xyz * 0.0002);
	T = -cross(T, normal.xyz);

	T = normalize(T + normal * 0.01);
	T = normalize(T + normal * 0.85 * (blockLight.x));


	float torchLambert = pow(saturate(dot(T, viewNormal.xyz) * 1.0 + 0.0), 1.0);
	torchLambert += pow(saturate(dot(T, viewNormal.xyz) * 0.4 + 0.6), 1.0) * 0.5;

	if (dot(T, normal.xyz) > 0.99)
	{
		torchLambert = pow(torchLambert, 2.0) * 0.45;
	}



	vec2 mcLightmap = blockLight;
	mcLightmap.x = CurveBlockLightTorchSource(mcLightmap.x);
	mcLightmap.x = mcLightmap.x * torchLambert * 1.0;
	mcLightmap.x = pow(mcLightmap.x, 0.25);
	mcLightmap.x += rand(vertexPos.xy + sin(frameTimeCounter)).x * (1.5 / 255.0);


	// albedo.rgb = vec3(1.0);

	// gl_FragData[0] = albedo;
	// gl_FragData[1] = vec4(mcLightmap.xy, emissive, albedo.a);
	// gl_FragData[2] = vec4(normalEnc.xy, blockLight.x, albedo.a);
	// gl_FragData[3] = vec4(smoothness, metallic, (materialIDs + 0.1) / 255.0, albedo.a);



	GBufferData gbuffer;
	gbuffer.albedo = albedo;
	gbuffer.normal = viewNormal.xyz;
	gbuffer.mcLightmap = mcLightmap;
	gbuffer.smoothness = smoothness;
	gbuffer.metalness = metallic;
	gbuffer.materialID = (materialIDs + 0.1) / 255.0;
	gbuffer.emissive = 0.0;


	vec4 frag0, frag1, frag2, frag3;

	OutputGBufferDataSolid(gbuffer, frag0, frag1, frag2, frag3);

	gl_FragData[0] = frag0;
	gl_FragData[1] = frag1;
	gl_FragData[2] = frag2;
	//gl_FragData[0] = frag0;

}