#version 330 compatibility
#extension GL_ARB_shading_language_packing : enable
#extension GL_ARB_shader_bit_encoding : enable

#define SHADOW_MAP_BIAS 0.900

#define GLOWING_REDSTONE_BLOCK // If enabled, redstone blocks are treated as light sources for GI
#define GLOWING_LAPIS_LAZULI_BLOCK // If enabled, lapis lazuli blocks are treated as light sources for GI

out vec4 vtexcoord;
out vec4 vcolor;
out vec4 vlmcoord;

out vec3 vnormal;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;

out float vmaterialIDs;
out float viswater;
out float visStainedGlass;
out vec4 vviewPos;

uniform sampler2D noisetex;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
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




out float vInvalidForVolume;
out vec4 volumeScreenPos;
out vec4 shadowScreenPos;

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

#include "DataPacking.inc"
#include "JvrXgACK.inc"


vec2 gSODjBNx(vec3 pos)
{
	return DiuEETJJ(pos);
}



 void main()
 {
   gl_Position=ftransform();
   vlmcoord=gl_TextureMatrix[1]*gl_MultiTexCoord1;
   vtexcoord=gl_MultiTexCoord0;
   vviewPos=gl_ModelViewMatrix*gl_Vertex;
   vec4 y=gl_Position;
   y=shadowProjectionInverse*y;
   y=shadowModelViewInverse*y;
   y.xyz+=cameraPosition.xyz;
   vmaterialIDs=100.f;
   viswater=0.;
   if(mc_Entity.x==1971.f)
     viswater=1.f;
   if(mc_Entity.x==8||mc_Entity.x==9)
     viswater=1.f;
   float x=0.f;
   if(mc_Entity.x==79)
     x=1.f;
   visStainedGlass=0.f;
   if(mc_Entity.x==95||mc_Entity.x==160)
     visStainedGlass=1.f;
   if(mc_Entity.x==31.||mc_Entity.x==38.f||mc_Entity.x==37.f)
     vmaterialIDs=102.f;
   if(mc_Entity.x==59.)
     vmaterialIDs=102.f;
   if(mc_Entity.x==18.||mc_Entity.x==161.f)
     vmaterialIDs=103.f;
   if(mc_Entity.x==79.f||mc_Entity.x==174.f)
     vmaterialIDs=104.f;
   if(mc_Entity.x==30.f)
     vmaterialIDs=111.f;
   if(mc_Entity.x==50)
     vmaterialIDs=130.f;
   if(mc_Entity.x==10||mc_Entity.x==11)
     vmaterialIDs=131.f;
   if(mc_Entity.x==89||mc_Entity.x==124)
     vmaterialIDs=132.f;
   if(mc_Entity.x==51)
     vmaterialIDs=133.f;
   #ifdef GLOWING_LAPIS_LAZULI_BLOCK
   if(mc_Entity.x==22)
     vmaterialIDs=135.;
   #endif
   #ifdef GLOWING_REDSTONE_BLOCK
   if(mc_Entity.x==152)
     vmaterialIDs=136.;
   #endif
   float v=mod(vtexcoord.y*16.f,.0625f),i=clamp(vlmcoord.y*33.05f/32.f-.0328125f,0.f,1.f);
   i*=1.1f;
   i-=.1f;
   i=max(0.f,i);
   i=pow(i,5.f);
   if(v<.01f)
     v=1.f;
   else
      v=0.f;
   vec3 f=gl_Normal;
   if(abs(vmaterialIDs-2.)<.1)
     f=vec3(0.,1.,0.);
   vnormal=f;
   vcolor=gl_Color;
   vInvalidForVolume=0.;
   if(viswater>.5||x>.5||mc_Entity.x<1.||fract(y.x)>.01&&fract(y.x)<.99||fract(y.y)>.01&&fract(y.y)<.99||fract(y.z)>.01&&fract(y.z)<.99||fract(f.x)>.01&&fract(f.x)<.99||fract(f.y)>.01&&fract(f.y)<.99||fract(f.z)>.01&&fract(f.z)<.99||mc_Entity.x==10.||mc_Entity.x==11.||mc_Entity.x==64.||mc_Entity.x==102.||mc_Entity.x==54.||mc_Entity.x==65.||mc_Entity.x==66.||mc_Entity.x==68.||mc_Entity.x==69.||mc_Entity.x==70.||mc_Entity.x==26.||mc_Entity.x==27.||mc_Entity.x==28.||mc_Entity.x==34.||mc_Entity.x==28.||mc_Entity.x==55.||mc_Entity.x==63.||mc_Entity.x==68.||mc_Entity.x==71.||mc_Entity.x==72.||mc_Entity.x==77.||mc_Entity.x==85.||mc_Entity.x==96.||mc_Entity.x==101.||mc_Entity.x==107.||mc_Entity.x==113.||mc_Entity.x==117.||mc_Entity.x==118.||mc_Entity.x==131.||mc_Entity.x==132.||mc_Entity.x==139.||mc_Entity.x==157.||mc_Entity.x==50.||mc_Entity.x==51.||mc_Entity.x==106.||mc_Entity.x==20.||mc_Entity.x>192&&mc_Entity.x<198)
     vInvalidForVolume=1.;
   vec3 s=y.xyz;
   if(vmaterialIDs!=2.)
     {
       if(f.x>.85)
         vcolor.xyz*=1./.6;
       if(f.x<-.85)
         vcolor.xyz*=1./.6;
       if(f.z>.85)
         vcolor.xyz*=1.25;
       if(f.z<-.85)
         vcolor.xyz*=1.25;
       if(f.y<-.85)
         vcolor.xyz*=2.;
     }
   vec3 m,g;
   if(gl_Normal.x>.5)
     m=vec3(0.,0.,-1.),g=vec3(0.,-1.,0.);
   else
      if(gl_Normal.x<-.5)
       m=vec3(0.,0.,1.),g=vec3(0.,-1.,0.);
     else
        if(gl_Normal.y>.5)
         m=vec3(1.,0.,0.),g=vec3(0.,0.,1.);
       else
          if(gl_Normal.y<-.5)
           m=vec3(1.,0.,0.),g=vec3(0.,0.,-1.);
         else
            if(gl_Normal.z>.5)
             m=vec3(1.,0.,0.),g=vec3(0.,-1.,0.);
           else
              if(gl_Normal.z<-.5)
               m=vec3(-1.,0.,0.),g=vec3(0.,-1.,0.);
   vec2 n=clamp((vtexcoord.xy-mc_midTexCoord.xy)*1000.,vec2(0.),vec2(1.));
   float r=.15;
   m=normalize(at_tangent.xyz);
   g=normalize(cross(m,f.xyz));
   vec3 z=s.xyz+mix(m*r,-m*r,vec3(n.x));
   z.xyz+=mix(g*r,-g*r,vec3(n.y));
   z.xyz-=gl_Normal.xyz*r;
   z=floor(z);
   z-=cameraPosition.xyz;
   z=HAWDRSEJ(z);
   volumeScreenPos=vec4((gSODjBNx(z.xyz)+n.xy*(1./vec2(4096,4096)))*2.-1.,0.,1.);
   y.xyz-=cameraPosition.xyz;
   y=shadowModelView*y;
   y=shadowProjection*y;
   gl_Position=y;
   float e=sqrt(gl_Position.x*gl_Position.x+gl_Position.y*gl_Position.y),l=1.f-SHADOW_MAP_BIAS+e*SHADOW_MAP_BIAS;
   gl_Position.xy*=.95f/l;
   gl_Position.xy*=.5;
   gl_Position.xy+=.5;
   gl_Position.z=mix(gl_Position.z,.5,.8);
   shadowScreenPos=gl_Position;
   gl_FrontColor=gl_Color;
 };