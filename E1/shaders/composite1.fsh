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

#define TORCHLIGHT_FILL 1.0 // Amount of fill/ambient light to add to torchlight falloff. Higher values makes torchlight dim less intensely based on distance. [0.5 1.0 2.0 4.0 8.0]


const bool gaux1Clear = false;
const bool gaux2Clear = false;

const bool gaux1MipmapEnabled = true;


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
















void r(inout vec3 v, float y, float f) {
    mat3 m = mat3(1., 0., 0., 0., cos(y), sin(y), 0., -sin(y), cos(y)), t = mat3(cos(f), 0., -sin(f), 0., 1., 0., sin(f), 0., cos(f));
    v = t * v;
    v = m * v;
}
void v(inout vec3 v, float y, float f) {
    y *= -1.;
    f *= -1.;
    mat3 m = mat3(1., 0., 0., 0., cos(y), sin(y), 0., -sin(y), cos(y)), t = mat3(cos(f), 0., -sin(f), 0., 1., 0., sin(f), 0., cos(f));
    v = m * v;
    v = t * v;
}
vec2 r() {
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
void r(inout vec3 f) {
    vec2 v = r();
    r(f.xyz, v.y, v.x);
}
void v(inout vec3 f) {
    vec2 t = r();
    v(f.xyz, t.y, t.x);
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
int n(int f) {
    return f - d(mod(float(f), 2.)) - 0;
}
int t(int f) {
    return f - d(mod(float(f), 2.)) - 1;
}
int n() {
    ivec2 v = ivec2(viewWidth, viewHeight);
    int f = v.x * v.y;
    return n(d(floor(pow(float(f), .333333))));
}
int t() {
    ivec2 v = ivec2(2048, 2048);
    int f = v.x * v.y;
    return t(d(floor(pow(float(f), .333333))));
}
vec3 s(vec2 f) {
    ivec2 v = ivec2(viewWidth, viewHeight);
    int y = v.x * v.y, x = n();
    ivec2 m = ivec2(f.x * v.x, f.y * v.y);
    int z = d(m.x + m.y * v.x);
    ivec3 r;
    r.x = d(mod(z, x));
    r.y = d(mod(z / x, x));
    r.z = d(mod(z / (x * x), x));
    vec3 t = vec3(r) / x;
    return t;
}
vec2 w(vec3 f) {
    ivec2 v = ivec2(viewWidth, viewHeight);
    int y = n();
    ivec3 m = ivec3(f * y + 1e-05);
    int z = m.x + m.y * y + m.z * y * y;
    ivec2 r;
    r.x = d(mod(z, v.x));
    r.y = d(z / v.x);
    vec2 i = vec2(r) / v;
    i += vec2(.5 / v.x, .5 / v.y);
    return i;
}
vec3 e(vec2 f) {
    ivec2 v = ivec2(2048, 2048);
    int y = v.x * v.y, x = t();
    ivec2 m = ivec2(f.x * v.x, f.y * v.y);
    int z = d(m.x + m.y * v.x);
    ivec3 r;
    r.x = d(mod(z, x));
    r.y = d(mod(z / x, x));
    r.z = d(mod(z / (x * x), x));
    vec3 i = vec3(r) / x;
    return i;
}
vec2 p(vec3 f) {
    ivec2 v = ivec2(2048, 2048);
    int y = t();
    ivec3 m = ivec3(f * y + 1e-05);
    int z = m.x + m.y * y + m.z * y * y;
    ivec2 r;
    r.x = d(mod(z, v.x));
    r.y = d(z / v.x);
    vec2 i = vec2(r) / v;
    i += vec2(.5 / v.x, .5 / v.y);
    return i;
}
vec3 m(vec3 f) {
    int v = t();
    f *= 1. / v;
    f = f + vec3(.5);
    f = clamp(f, vec3(0.), vec3(1.));
    return f;
}
vec3 l(vec3 f) {
    int v = t();
    f = f - vec3(.5);
    f *= v;
    return f;
}
vec3 D(vec3 f) {
    int v = n();
    f *= 1. / v;
    f = f + vec3(.5);
    f = clamp(f, vec3(0.), vec3(1.));
    return f;
}
vec3 G(vec3 f) {
    int v = n();
    f = f - vec3(.5);
    f *= v;
    return f;
}
float D() {
    return 1.;
}
float G() {
    return 2.;
}
vec3 f(vec3 f) {
    int v = n();
    float y = D(), x = v * y;
    vec3 r = f * x - x * .5;
    r -= fract(cameraPosition.xyz / y) * y;
    return r;
}
vec3 h(vec3 f) {
    int v = n();
    float y = D();
    f += fract(cameraPosition.xyz / y) * y;
    float x = v * y;
    vec3 m = (f.xyz + x * .5) / x;
    return m;
}
vec3 a(vec3 f) {
    int v = n();
    float y = D(), t = v * y;
    f = floor(f / y) * y;
    f /= t;
    return f;
}
vec3 i(vec3 f) {
    int v = n();
    float y = G(), x = v * y;
    vec3 r = f * x - x * .5;
    r -= fract(cameraPosition.xyz / y) * y;
    return r;
}
vec3 x(vec3 f) {
    int v = n();
    float y = G();
    f += fract(cameraPosition.xyz / y) * y;
    float x = v * y;
    vec3 m = (f.xyz + x * .5) / x;
    return m;
}
vec3 o(vec3 f) {
    int v = n();
    float y = G(), t = v * y;
    f = floor(f / y) * y;
    f /= t;
    return f;
}
vec3 c(vec3 f) {
    return f = f * 2. - 1., f = pow(length(f), 4.) * normalize(f), f = f * .5 + .5, f;
}
vec3 u(vec3 f) {
    return f = f * 2. - 1., f = pow(length(f), 1. / 6.) * normalize(f), f = f * .5 + .5, f;
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
float D(float f, float v) {
    float r;
    f = clamp(f, 0., 1.);
    v = clamp(v, 0., 1.);
    f *= 256.;
    v *= 256.;
    f = floor(f);
    v = floor(v);
    r = f * exp2(8.);
    r += v;
    r /= exp2(16.) - 1;
    return r;
}
vec2 L(float f) {
    vec2 v;
    f *= exp2(16.) - 1;
    v.x = floor(f / exp2(8.));
    v.y = mod(f, exp2(8.));
    v.x /= 256.;
    v.y /= 256.;
    return v;
}
float G(float f, float v) {
    float r;
    f = clamp(f, 0., 1.);
    v = clamp(v, 0., 1.);
    f *= 65536.;
    v *= 65536.;
    f = floor(f);
    v = floor(v);
    r = f * exp2(16.);
    r += v;
    r /= exp2(32.) - 1;
    return r;
}
vec2 y(float f) {
    vec2 v;
    f *= exp2(32.) - 1;
    v.x = floor(f / exp2(16.));
    v.y = mod(f, exp2(16.));
    v.x /= 65536.;
    v.y /= 65536.;
    return v;
}
void D( in GBufferData f, out vec4 v, out vec4 y, out vec4 x, out vec4 t) {
    v = f.albedo, y = vec4(D(f.mcLightmap.x, f.mcLightmap.y), D(f.smoothness, f.metalness), D(f.materialID, f.emissive), 1.), x = vec4(EncodeNormal(f.normal.xyz), 1., 1.), t = vec4(0., 0., 0., 1.);
}
void D( in GBufferDataTransparent f, out vec4 v, out vec4 y) {
    v = vec4(f.mcLightmap.xy, f.materialID, 1.), y = vec4(f.normal.xy, D(f.albedo.x, f.albedo.y), D(f.albedo.z, f.albedo.w));
}
float g(float f) {
    return f = 1. - pow(1. - f, .45), f *= f * f, f;
}
float z(float f) {
    float v = pow(f, 4.);
    v = pow(v, 2.) * 5.;
    v += pow(v, .4) * .1 * TORCHLIGHT_FILL;
    return v;
}
GBufferData L() {
    GBufferData f;
    vec4 v = texture2DLod(gcolor, texcoord.xy, 0), t = texture2DLod(gdepth, texcoord.xy, 0), y = texture2DLod(gnormal, texcoord.xy, 0);
    float m = texture2D(depthtex1, texcoord.xy).x;
    vec2 r = L(t.x), x = L(t.y), p = L(t.z);
    f.albedo = vec4(GammaToLinear(v.xyz), 1.);
    f.mcLightmap = r;
    f.mcLightmap.y = g(f.mcLightmap.y);
    f.mcLightmap.x = z(f.mcLightmap.x);
    f.normal = DecodeNormal(y.xy);
    f.smoothness = x.x;
    f.metalness = x.y;
    f.emissive = p.y;
    f.materialID = p.x;
    f.depth = m;
    return f;
}
GBufferDataTransparent a() {
    GBufferDataTransparent f;
    vec4 v = texture2DLod(composite, texcoord.xy, 0), t = texture2DLod(gaux1, texcoord.xy, 0);
    vec2 m = L(t.z), x = L(t.w);
    f.albedo = vec4(m.xy, x.xy);
    f.albedo.xyz = GammaToLinear(f.albedo.xyz);
    f.mcLightmap = v.xy;
    f.mcLightmap.y = g(f.mcLightmap.y);
    f.mcLightmap.x = z(f.mcLightmap.x);
    f.materialID = v.z;
    f.normal = DecodeNormal(t.xy);
    return f;
}
float L(float f, float y) {
    return exp(-pow(f / (.9 * y), 2.));
}
vec3 b(vec2 f) {
    vec3 v = DecodeNormal(texture2D(gnormal, f.xy * 2.).xy);
    return v;
}
float T( in float f) {
    return 2. f * near * far / (far + near - (2. f * f - 1. f) * (far - near));
}
float I(vec2 f) {
    return T(texture2D(depthtex1, f * 2.).x);
}
void main() {
    vec4 f = texture2DLod(gaux2, texcoord.xy, 0);
    float v = f.z;
    int y = 1;
    vec3 m = texture2DLod(gaux1, texcoord.xy, y).xyz;
    float r = Luminance(m.xyz);
    vec3 x = b(texcoord.xy);
    float t = I(texcoord.xy);
    vec3 i = vec3(0.);
    float z = 0., o = 62., s = 5.;
    vec2 n = rand(texcoord.xy + sin(frameTimeCounter)).xy - .5;
    float g = f.x, h = 1. + 3. / (g * 200. + 1.);
    h *= .33;
    vec3 G = vec3(0.);
    float e = 111. * saturate(1. - v * 50.);
    e *= 1. - v;
    int p = 0;
    for (int c = -3; c <= 3; c++) {
        for (int w = -3; w <= 3; w++) {
            vec2 d = (vec2(c, w) + n) / vec2(viewWidth, viewHeight) * (6.5 + 10. * v) * h, l = texcoord.xy + d.xy;
            float D = length(d * vec2(viewWidth, viewHeight));
            vec3 L = texture2DLod(gaux1, l, y).xyz, a = b(l);
            float T = I(l), u = pow(saturate(dot(x, a)), o), B = exp(-(abs(T - t) * s)), H = exp(-(abs(r - Luminance(L)) * e)), W = u * B * H;
            i += L * W;
            z += W;
            G += L;
            p++;
        }
    }
    i /= z + .0001;
    vec3 d = i.xyz;
    vec4 c = texture2D(gaux1, texcoord.xy);
    c.xyz = mix(c.xyz, d.xyz, vec3(v));
    if (z < .0001) d = m;
    vec4 L = vec4(Luminance(d.xyz), f.y, v, 1.);
    gl_FragData[0] = c;
    gl_FragData[1] = L;
    gl_FragData[2] = vec4(d, 1.);
}