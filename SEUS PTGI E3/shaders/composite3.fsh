#version 130



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

in vec4 texcoord;
in vec3 lightVector;

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;
in float timeSkyDark;

in vec3 colorSunlight;
in vec3 colorSkylight;
in vec3 colorSunglow;
in vec3 colorBouncedSunlight;
in vec3 colorScatteredSunlight;
in vec3 colorTorchlight;
in vec3 colorWaterMurk;
in vec3 colorWaterBlue;
in vec3 colorSkyTint;

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

in vec3 upVector;


uniform int frameCounter;

#include "JvrXgACK.inc"
#include "GBufferData.inc"
float e(float v,float f)
 {
   return exp(-pow(v/(.9*f),2.));
 }
 vec3 e(vec2 v)
 {
   vec3 d=DecodeNormal(texture2DLod(gnormal,v.xy,0).xy);
   return d;
 }
 float d(in float f)
 {
   return 2.f*near*far/(far+near-(2.f*f-1.f)*(far-near));
 }
 float v(vec2 v)
 {
   return d(texture2D(depthtex1,v).x);
 }
 vec4 d(in vec2 v,in float f)
 {
   vec4 d=vec4(v.xy,0.,0.),e=gbufferProjectionInverse*vec4(d.x*2.f-1.f,d.y*2.f-1.f,2.f*f-1.f,1.f);
   e/=e.w;
   return e;
 }
 float v(vec3 v,vec3 f)
 {
   return dot(abs(v-f),vec3(.3333));
 }
 void main()
 {
   LPRfwdzt f=SdwzegmK(texcoord.xy);
   float d=f.eDReytEm,t=f.PHnZgwUO*256.,i=f.mERUeFIj;
   int y=0;
   vec3 g=texture2DLod(gaux3,texcoord.xy,y).xyz;
   float m=Luminance(g.xyz);
   vec3 h=e(texcoord.xy);
   float n=v(texcoord.xy);
   vec2 z=vec2(0.);
   float r=1.+3./(i*200.*gPdrYTep+pehfXVXY);
   r*=.9*mix(uwtHmhPW,KLKQcJfi,d);
   float C=mix(800.*CRgczcVK,800.*LwgeyngM,d);
   C/=i*100.+.5;
   float x=62.,B=2.;
   vec3 L=vec3(0.),T=vec3(0.);
   float a=0.;
   int o=0;
   for(int s=-1;s<=1;s++)
     {
       for(int c=-1;c<=1;c++)
         {
           vec2 A=(vec2(s,c)+z)/vec2(viewWidth,viewHeight)*(6.5+6.*d)*r,l=texcoord.xy+A.xy;
           float u=length(A*vec2(viewWidth,viewHeight));
           l=clamp(l,4./vec2(viewWidth,viewHeight),1.-4./vec2(viewWidth,viewHeight));
           vec3 D=texture2DLod(gaux3,l,y).xyz,p=e(l);
           float w=v(l),P=pow(saturate(dot(h,p)),x),R=exp(-(abs(w-n)*B)),I=exp(-(v(D,g)*C)),S=P*R*I;
           L+=D*S;
           a+=S;
           T+=D;
           o++;
         }
     }
   L/=a+.0001;
   vec3 l=L.xyz;
   if(a<.0001)
     l=g;
   f.mERUeFIj=Luminance(l.xyz);
   vec4 D=eBNFItKo(f);
   gl_FragData[0]=D;
   gl_FragData[1]=vec4(l,1.);
 };
/* DRAWBUFFERS:56 */