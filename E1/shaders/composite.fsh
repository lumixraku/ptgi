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
#define TORCHLIGHT_FILL 1.0 // Amount of fill/ambient light to add to torchlight falloff. Higher values makes torchlight dim less intensely based on distance. [0.5 1.0 2.0 4.0 8.0]

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

/* DRAWBUFFERS:45 */


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

































void v(inout vec3 v, float y, float f) {
    mat3 m = mat3(1., 0., 0., 0., cos(y), sin(y), 0., -sin(y), cos(y)), t = mat3(cos(f), 0., -sin(f), 0., 1., 0., sin(f), 0., cos(f));
    v = t * v;
    v = m * v;
}
void f(inout vec3 v, float y, float f) {
    y *= -1.;
    f *= -1.;
    mat3 m = mat3(1., 0., 0., 0., cos(y), sin(y), 0., -sin(y), cos(y)), t = mat3(cos(f), 0., -sin(f), 0., 1., 0., sin(f), 0., cos(f));
    v = m * v;
    v = t * v;
}
vec2 f() {
    const float v = 1.61803,
        t = v * 3.14159;
    const int y = 128;
    float f = mod(float(frameCounter) / y, 1.);
    f = mod(f * (.333333 * y) * (1. + 1. / y), 1.);
    vec2 r = vec2(0.);
    r.x = t * f * y;
    r.y = asin(mod(f * 2., 1.));
    return r;
}
void f(inout vec3 y) {
    vec2 n = f();
    v(y.xyz, n.y, n.x);
}
void v(inout vec3 y) {
    vec2 v = f();
    f(y.xyz, v.y, v.x);
}
float v() {
    return .02;
}
float d() {
    return .02;
}
int d(float f) {
    return int(floor(f));
}
int t(int f) {
    return f - d(mod(float(f), 2.)) - 0;
}
int r(int f) {
    return f - d(mod(float(f), 2.)) - 1;
}
int r() {
    ivec2 v = ivec2(viewWidth, viewHeight);
    int f = v.x * v.y;
    return t(d(floor(pow(float(f), .333333))));
}
int t() {
    ivec2 v = ivec2(2048, 2048);
    int f = v.x * v.y;
    return r(d(floor(pow(float(f), .333333))));
}
vec3 s(vec2 v) {
    ivec2 f = ivec2(viewWidth, viewHeight);
    int y = f.x * f.y, x = r();
    ivec2 n = ivec2(v.x * f.x, v.y * f.y);
    int m = d(n.x + n.y * f.x);
    ivec3 i;
    i.x = d(mod(m, x));
    i.y = d(mod(m / x, x));
    i.z = d(mod(m / (x * x), x));
    vec3 z = vec3(i) / x;
    return z;
}
vec2 n(vec3 f) {
    ivec2 v = ivec2(viewWidth, viewHeight);
    int y = r();
    ivec3 n = ivec3(f * y + 1e-05);
    int m = n.x + n.y * y + n.z * y * y;
    ivec2 i;
    i.x = d(mod(m, v.x));
    i.y = d(m / v.x);
    vec2 x = vec2(i) / v;
    x += vec2(.5 / v.x, .5 / v.y);
    return x;
}
vec3 e(vec2 v) {
    ivec2 f = ivec2(2048, 2048);
    int y = f.x * f.y, x = t();
    ivec2 n = ivec2(v.x * f.x, v.y * f.y);
    int m = d(n.x + n.y * f.x);
    ivec3 i;
    i.x = d(mod(m, x));
    i.y = d(mod(m / x, x));
    i.z = d(mod(m / (x * x), x));
    vec3 z = vec3(i) / x;
    return z;
}
vec2 m(vec3 f) {
    ivec2 v = ivec2(2048, 2048);
    int y = t();
    ivec3 n = ivec3(f * y + 1e-05);
    int m = n.x + n.y * y + n.z * y * y;
    ivec2 i;
    i.x = d(mod(m, v.x));
    i.y = d(m / v.x);
    vec2 r = vec2(i) / v;
    r += vec2(.5 / v.x, .5 / v.y);
    return r;
}
vec3 i(vec3 v) {
    int y = t();
    v *= 1. / y;
    v = v + vec3(.5);
    v = clamp(v, vec3(0.), vec3(1.));
    return v;
}
vec3 w(vec3 v) {
    int f = t();
    v = v - vec3(.5);
    v *= f;
    return v;
}
vec3 x(vec3 v) {
    int y = r();
    v *= 1. / y;
    v = v + vec3(.5);
    v = clamp(v, vec3(0.), vec3(1.));
    return v;
}
vec3 p(vec3 v) {
    int f = r();
    v = v - vec3(.5);
    v *= f;
    return v;
}
float e() {
    return 1.;
}
float i() {
    return 2.;
}
vec3 h(vec3 v) {
    int f = r();
    float y = e(), x = f * y;
    vec3 i = v * x - x * .5;
    i -= fract(cameraPosition.xyz / y) * y;
    return i;
}
vec3 D(vec3 v) {
    int f = r();
    float y = e();
    v += fract(cameraPosition.xyz / y) * y;
    float x = f * y;
    vec3 n = (v.xyz + x * .5) / x;
    return n;
}
vec3 G(vec3 v) {
    int f = r();
    float y = e(), x = f * y;
    v = floor(v / y) * y;
    v /= x;
    return v;
}
vec3 l(vec3 v) {
    int f = r();
    float y = i(), x = f * y;
    vec3 n = v * x - x * .5;
    n -= fract(cameraPosition.xyz / y) * y;
    return n;
}
vec3 B(vec3 v) {
    int f = r();
    float y = i();
    v += fract(cameraPosition.xyz / y) * y;
    float x = f * y;
    vec3 n = (v.xyz + x * .5) / x;
    return n;
}
vec3 o(vec3 v) {
    int f = r();
    float y = i(), x = f * y;
    v = floor(v / y) * y;
    v /= x;
    return v;
}
vec3 a(vec3 v) {
    return v = v * 2. - 1., v = pow(length(v), 4.) * normalize(v), v = v * .5 + .5, v;
}
vec3 y(vec3 v) {
    return v = v * 2. - 1., v = pow(length(v), 1. / 6.) * normalize(v), v = v * .5 + .5, v;
}
struct Ray {
    vec3 dir;
    vec3 origin;
};
struct BBRay {
    vec3 origin;
    vec3 direction;
    vec3 inv_direction;
    ivec3 sign;
};
BBRay B(vec3 v, vec3 y) {
    vec3 f = vec3(1.) / y;
    return BBRay(v, y, f, ivec3(f.x < 0 ? 1 : 0, f.y < 0 ? 1 : 0, f.z < 0 ? 1 : 0));
}
void B( in BBRay v, in vec3 f[2], out float y, out float i) {
    float x, r, z, n;
    y = (f[v.sign[0]].x - v.origin.x) * v.inv_direction.x;
    i = (f[1 - v.sign[0]].x - v.origin.x) * v.inv_direction.x;
    x = (f[v.sign[1]].y - v.origin.y) * v.inv_direction.y;
    r = (f[1 - v.sign[1]].y - v.origin.y) * v.inv_direction.y;
    z = (f[v.sign[2]].z - v.origin.z) * v.inv_direction.z;
    n = (f[1 - v.sign[2]].z - v.origin.z) * v.inv_direction.z;
    y = max(max(y, x), z);
    i = min(min(i, r), n);
}
vec2 c(inout float v) {
    return fract(sin(vec2(v += .1, v += .1)) * vec2(43758.5, 22578.1));
}
vec3 H(vec2 v) {
    vec2 f = vec2(v.xy * vec2(viewWidth, viewHeight)) / 64.;
    f += vec2(sin(frameCounter * .75), cos(frameCounter * .75));
    f = (floor(f * 64.) + .5) / 64.;
    return texture2D(noisetex, f).xyz;
}
vec3 B(vec3 v, inout float f, int y) {
    vec2 n = c(f);
    vec3 x = normalize(cross(v, vec3(0., 1., 1.))), z = cross(x, v);
    float m = sqrt(n.y), i = m * cos(6.2831 * n.x), t = m * sin(6.2831 * n.x), r = sqrt(1. - n.y);
    vec3 s = vec3(i * x + t * z + r * v);
    return normalize(s);
}
vec3 g(vec3 v) {
    vec3 f = fract(v);
    for (int y = 0; y < 3; y++) {
        if (f[y] == 0.) f[y] = 1.;
    }
    return f;
}
vec3 D(vec3 v, vec3 f, vec3 y, float x) {
    const int n = 1;
    int z = t();
    float r = .5 / float(z);
    vec3 s = vec3(0.);
    float c = (texcoord.x + texcoord.y * 3.4321 + fract(frameCounter * .001) * 10.) * 9.1;
    vec3 p[3] = vec3[3](vec3(1., 0., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.));
    float d = 0., o = pow(x, 1.1);
    o = 1.;
    for (int w = 0; w < n; w++) {
        vec3 e = B(f, c, w), l = v + f * .01;
        l += g(cameraPosition.xyz + .5);
        l = i(l);
        Ray G;
        G.origin = l * z - vec3(1., 1., 1.);
        G.dir = e;
        vec3 b = vec3(1.);
        for (int D = 0; D < 2; D++) {
            ivec3 a = ivec3(floor(G.origin));
            vec3 h, k;
            ivec3 u;
            for (int R = 0; R < 3; R++) {
                float H = G.dir[0] / G.dir[R], T = G.dir[1] / G.dir[R], F = G.dir[2] / G.dir[R];
                h[R] = sqrt(H * H + T * T + F * F);
                if (G.dir[R] < 0.) u[R] = -1, k[R] = (G.origin[R] - a[R]) * h[R];
                else u[R] = 1, k[R] = (a[R] + 1. - G.origin[R]) * h[R];
            }
            int R = 0;
            float H = 0.;
            int T = 0;
            for (int L = 0; L < 60; L++) {
                for (int I = 0; I < 3; I++) {
                    if (k[R] > k[I]) R = I;
                }
                k[R] += h[R];
                a[R] += u[R];
                vec3 I = vec3(a) / float(z);
                vec2 F = m(I);
                vec4 E = texture2DLod(shadowcolor, F, 0);
                if (E.w * 255. > 1. f && E.w * 255. < 128. f) {
                    vec3 P = saturate(E.xyz * 2.);
                    b *= P;
                    break;
                }
                if (abs(E.w * 255. - 132) < .5) {
                    s += b * vec3(1., .5, .1) * .25;
                    break;
                }
                if (abs(E.w * 255. - 135) < .5) {
                    s += b * vec3(0., .1, 1.) * .7;
                    break;
                }
                if (abs(E.w * 255. - 136) < .5) {
                    s += b * vec3(1., 0., 0.) * .7;
                    break;
                }
                if (F.x < 0. || F.y < 0. || F.x > 1. || F.y > 1.) {
                    break;
                }
                T++;
            }
            if (T >= 59) {
                vec3 I = max(vec3(0.), FromSH(skySHR, skySHG, skySHB, G.dir)) * 3.;
                I += pow(saturate(dot(G.dir, worldLightVector)), 3.) * colorSunlight * 6.;
                I *= b;
                I *= saturate(dot(G.dir, vec3(0., 1., 0.)) * 100.) * .9 + .1;
                I *= o;
                s += I * .2;
                break;
            }
            float I, F;
            vec3 L = vec3(a), P = vec3(a) + 1., W[2] = vec3[2](vec3(a), vec3(a) + 1.);
            B(B(G.origin, G.dir), W, I, F);
            vec3 E = p[R];
            G.origin += e * I + E * .01;
            G.dir = B(-p[R] * sign(G.dir[R]), c, w);
            d += I;
        }
        c = mod(c * 1.12346, 13.);
    }
    if (d <= 0.) d = 10000.;
    return s / n;
}
vec4 R(vec2 v) {
    vec3 f = s(v), y = p(f), x = i(y);
    vec2 n = m(x);
    vec4 z = texture2DLod(shadowcolor, n, 0);
    return z;
}
struct GBufferData {
    vec4 albedo;
    float depth;
    vec3 normal;
    vec2 mcLightmap;
    float smoothness;
    float metalness;
    float materialID;
    float emissive;
};
struct GBufferDataTransparent {
    vec4 albedo;
    vec3 normal;
    vec2 mcLightmap;
    float materialID;
};
float D(float v, float f) {
    float y;
    v = clamp(v, 0., 1.);
    f = clamp(f, 0., 1.);
    v *= 256.;
    f *= 256.;
    v = floor(v);
    f = floor(f);
    y = v * exp2(8.);
    y += f;
    y /= exp2(16.) - 1;
    return y;
}
vec2 u(float v) {
    vec2 f;
    v *= exp2(16.) - 1;
    f.x = floor(v / exp2(8.));
    f.y = mod(v, exp2(8.));
    f.x /= 256.;
    f.y /= 256.;
    return f;
}
float G(float v, float f) {
    float y;
    v = clamp(v, 0., 1.);
    f = clamp(f, 0., 1.);
    v *= 65536.;
    f *= 65536.;
    v = floor(v);
    f = floor(f);
    y = v * exp2(16.);
    y += f;
    y /= exp2(32.) - 1;
    return y;
}
vec2 z(float v) {
    vec2 f;
    v *= exp2(32.) - 1;
    f.x = floor(v / exp2(16.));
    f.y = mod(v, exp2(16.));
    f.x /= 65536.;
    f.y /= 65536.;
    return f;
}
void B( in GBufferData v, out vec4 y, out vec4 f, out vec4 x, out vec4 n) {
    y = v.albedo, f = vec4(D(v.mcLightmap.x, v.mcLightmap.y), D(v.smoothness, v.metalness), D(v.materialID, v.emissive), 1.), x = vec4(EncodeNormal(v.normal.xyz), 1., 1.), n = vec4(0., 0., 0., 1.);
}
void D( in GBufferDataTransparent v, out vec4 y, out vec4 f) {
    y = vec4(v.mcLightmap.xy, v.materialID, 1.), f = vec4(v.normal.xy, D(v.albedo.x, v.albedo.y), D(v.albedo.z, v.albedo.w));
}
float L(float v) {
    return v = 1. - pow(1. - v, .45), v *= v * v, v;
}
float b(float v) {
    float f = pow(v, 4.);
    f = pow(f, 2.) * 5.;
    f += pow(f, .4) * .1 * TORCHLIGHT_FILL;
    return f;
}
GBufferData B() {
    GBufferData v;
    vec4 f = texture2DLod(gcolor, texcoord.xy, 0), n = texture2DLod(gdepth, texcoord.xy, 0), y = texture2DLod(gnormal, texcoord.xy, 0);
    float x = texture2D(depthtex1, texcoord.xy).x;
    vec2 m = u(n.x), t = u(n.y), i = u(n.z);
    v.albedo = vec4(GammaToLinear(f.xyz), 1.);
    v.mcLightmap = m;
    v.mcLightmap.y = L(v.mcLightmap.y);
    v.mcLightmap.x = b(v.mcLightmap.x);
    v.normal = DecodeNormal(y.xy);
    v.smoothness = t.x;
    v.metalness = t.y;
    v.emissive = i.y;
    v.materialID = i.x;
    v.depth = x;
    return v;
}
GBufferDataTransparent D() {
    GBufferDataTransparent v;
    vec4 f = texture2DLod(composite, texcoord.xy, 0), n = texture2DLod(gaux1, texcoord.xy, 0);
    vec2 y = u(n.z), x = u(n.w);
    v.albedo = vec4(y.xy, x.xy);
    v.albedo.xyz = GammaToLinear(v.albedo.xyz);
    v.mcLightmap = f.xy;
    v.mcLightmap.y = L(v.mcLightmap.y);
    v.mcLightmap.x = b(v.mcLightmap.x);
    v.materialID = f.z;
    v.normal = DecodeNormal(n.xy);
    return v;
}
vec4 I(float v) {
    float f = v * v, y = f * v;
    vec4 n;
    n.x = -y + 3 * f - 3 * v + 1;
    n.y = 3 * y - 6 * f + 4;
    n.z = -3 * y + 3 * f + 3 * v + 1;
    n.w = y;
    return n / 6. f;
}
vec4 H( in sampler2D v, in vec2 f) {
    vec2 y = vec2(viewWidth, viewHeight);
    f *= y;
    f -= .5;
    float x = fract(f.x), i = fract(f.y);
    f.x -= x;
    f.y -= i;
    vec4 n = I(x), G = I(i), t = vec4(f.x - .5, f.x + 1.5, f.y - .5, f.y + 1.5), m = vec4(n.x + n.y, n.z + n.w, G.x + G.y, G.z + G.w), d = t + vec4(n.y, n.w, G.y, G.w) / m, z = texture2DLod(v, vec2(d.x, d.z) / y, 0), c = texture2DLod(v, vec2(d.y, d.z) / y, 0), r = texture2DLod(v, vec2(d.x, d.w) / y, 0), s = texture2DLod(v, vec2(d.y, d.w) / y, 0);
    float w = m.x / (m.x + m.y), o = m.z / (m.z + m.w);
    return mix(mix(s, r, w), mix(c, z, w), o);
}
void main() {
    GBufferData v = B();
    vec4 f = GetViewPosition(texcoord.xy, v.depth);
    if (isEyeInWater > .5) f.xy *= .8;
    vec4 n = gbufferModelViewInverse * vec4(f.xyz, 1.), y = gbufferModelViewInverse * vec4(f.xyz, 0.);
    vec3 x = normalize(f.xyz), G = normalize(y.xyz), i = normalize((gbufferModelViewInverse * vec4(v.normal, 0.)).xyz);
    float m = length(f.xyz);
    vec3 z = D(n.xyz, i.xyz, G.xyz, v.mcLightmap.y);
    float s = 1. / (saturate(-dot(i, G)) * 100. + 1.), t;
    vec2 r = GetNearFragment(texcoord.xy, v.depth, t);
    float w = texture2D(depthtex1, r).x;
    vec4 d = vec4(texcoord.xy * 2. - 1., w * 2. - 1., 1.), c = gbufferProjectionInverse * d;
    c.xyz /= c.w;
    vec4 p = gbufferModelViewInverse * vec4(c.xyz, 1.), o = p;
    o.xyz += cameraPosition - previousCameraPosition;
    vec4 a = gbufferPreviousModelView * vec4(o.xyz, 1.), I = gbufferPreviousProjection * vec4(a.xyz, 1.);
    I.xyz /= I.w;
    vec2 E = d.xy - I.xy;
    float e = length(E) * 10., F = clamp(e * 500., 0., 1.);
    vec2 l = texcoord.xy * .5 - E.xy * .25, h = cos((fract(abs(texcoord.xy - l.xy) * vec2(viewWidth, viewHeight)) * 2. - 1.) * 3.14159) * .5 + .5, R = pow(h, vec2(.5));
    vec4 g = gbufferProjectionInverse * vec4(texcoord.xy * 2. - 1., texture2D(gaux1, l.xy).w * 2. - 1., 1.);
    g /= g.w;
    vec2 k = 1. / vec2(viewWidth, viewHeight), P = 1. - k;
    vec4 u = texture2DLod(gaux2, l.xy, 0);
    float H = u.x, T = u.y, L = u.w * 256., W = min(5., L + 1.), b = 0.;
    if (length(g.z - a.z) > .5 || (l.x < k.x || l.x > P.x || l.y < k.y || l.y > P.y) || abs(s - T) > .01) b = 1., H = 0., W = 0.;
    float V = 1. - exp2(-W);
    vec3 C = texture2D(gaux1, l.xy).xyz, S = mix(z, C, vec3(V));
    float M = mix(b, u.z, .6);
    gl_FragData[0] = vec4(S, w);
    gl_FragData[1] = vec4(H, s, M, W / 256.);
}