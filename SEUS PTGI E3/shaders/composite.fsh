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



const int 		noiseTextureResolution  = 64;

const bool gaux1Clear = false;
const bool gaux2Clear = false;
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

uniform sampler2DShadow shadow;

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

in vec4 skySHR;
in vec4 skySHG;
in vec4 skySHB;

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

in vec3 upVector;

in vec3 worldLightVector;
in vec3 worldSunVector;

uniform int frameCounter;

uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousProjectionInverse;



/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void f(inout vec4 f)
 {
   const vec2 r[16]=vec2[16](vec2(-1,-1),vec2(0,-.333333),vec2(-.5,.333333),vec2(.5,-.777778),vec2(-.75,-.111111),vec2(.25,.555556),vec2(-.25,-.555556),vec2(.75,.111111),vec2(-.875,.777778),vec2(.125,-.925926),vec2(-.375,-.259259),vec2(.625,.407407),vec2(-.625,-.703704),vec2(.375,-.037037),vec2(-.125,.62963),vec2(.875,-.481482)),v[16]=vec2[16](vec2(0,3)/16.,vec2(8,11)/16.,vec2(2,1)/16.,vec2(10,9)/16.,vec2(12,15)/16.,vec2(4,7)/16.,vec2(14,13)/16.,vec2(6,5)/16.,vec2(3,0)/16.,vec2(11,8)/16.,vec2(1,2)/16.,vec2(9,10)/16.,vec2(15,12)/16.,vec2(7,4)/16.,vec2(13,14)/16.,vec2(5,6)/16.),n[16]=vec2[16](vec2(.375,.4375),vec2(.625,.0625),vec2(.875,.1875),vec2(.125,.0625),vec2(.375,.6875),vec2(.875,.4375),vec2(.625,.5625),vec2(.375,.9375),vec2(.625,.3125),vec2(.125,.5625),vec2(.125,.8125),vec2(.375,.1875),vec2(.875,.9375),vec2(.875,.6875),vec2(.125,.3125),vec2(.625,.8125));
   f.xy-=(v[int(mod(frameCounter,12))]*2.-1.)/vec2(viewWidth,viewHeight)*.5;
 }
 vec4 f(in vec2 v,in float y)
 {
   vec4 d=vec4(v.xy,0.,0.);
   f(d);
   vec4 n=gbufferProjectionInverse*vec4(d.x*2.f-1.f,d.y*2.f-1.f,2.f*y-1.f,1.f);
   n/=n.w;
   return n;
 }
 vec2 f(vec2 v,float y,out float f)
 {
   vec2 w=1./vec2(viewWidth,viewHeight);
   vec4 i;
   i.x=texture2D(depthtex1,v+w*vec2(1.,1.)).x;
   i.y=texture2D(depthtex1,v+w*vec2(1.,-1.)).x;
   i.z=texture2D(depthtex1,v+w*vec2(-1.,1.)).x;
   i.w=texture2D(depthtex1,v+w*vec2(-1.,-1.)).x;
   vec2 s=vec2(0.,0.);
   if(i.x<y)
     s=vec2(1.,1.);
   if(i.y<y)
     s=vec2(1.,-1.);
   if(i.z<y)
     s=vec2(-1.,1.);
   if(i.w<y)
     s=vec2(-1.,-1.);
   f=min(min(min(i.x,i.y),i.z),i.w);
   return v+w*s;
 }
 vec3 v(vec3 v)
 {
   vec3 s=fract(v);
   for(int f=0;f<3;f++)
     {
       if(s[f]==0.)
         s[f]=1.;
     }
   return s;
 }
 vec3 t(vec3 f)
 {
   vec4 i=vec4(f,1.);
   i.xyz+=.5;
   i.xyz-=v(cameraPosition.xyz+.5)-.5;
   i=shadowModelView*i;
   float s=-i.z;
   i=shadowProjection*i;
   i/=i.w;
   float w=sqrt(i.x*i.x+i.y*i.y),n=1.f-SHADOW_MAP_BIAS+w*SHADOW_MAP_BIAS;
   i.xy*=.95f/n;
   i.z=mix(i.z,.5,.8);
   i=i*.5f+.5f;
   i.xy*=.5;
   i.xy+=.5;
   return i.xyz;
 }
 #include "JvrXgACK.inc"
 struct Ray{vec3 dir;vec3 origin;};struct BBRay{vec3 origin;vec3 direction;vec3 inv_direction;ivec3 sign;};
 BBRay t(vec3 v,vec3 y)
 {
   vec3 i=vec3(1.)/y;
   return BBRay(v,y,i,ivec3(i.x<0?1:0,i.y<0?1:0,i.z<0?1:0));
 }
 void f(in BBRay i,in vec3 v[2],out float f,out float r)
 {
   float y,z,w,n;
   f=(v[i.sign[0]].x-i.origin.x)*i.inv_direction.x;
   r=(v[1-i.sign[0]].x-i.origin.x)*i.inv_direction.x;
   y=(v[i.sign[1]].y-i.origin.y)*i.inv_direction.y;
   z=(v[1-i.sign[1]].y-i.origin.y)*i.inv_direction.y;
   w=(v[i.sign[2]].z-i.origin.z)*i.inv_direction.z;
   n=(v[1-i.sign[2]].z-i.origin.z)*i.inv_direction.z;
   f=max(max(f,y),w);
   r=min(min(r,z),n);
 }
 vec2 d(inout float v)
 {
   return fract(sin(vec2(v+=.1,v+=.1))*vec2(43758.5,22578.1));
 }
 vec3 s(vec2 i)
 {
   vec2 v=vec2(i.xy*vec2(viewWidth,viewHeight))/64.;
   v+=vec2(sin(frameCounter*.75),cos(frameCounter*.75));
   v=(floor(v*64.)+.5)/64.;
   return texture2D(noisetex,v).xyz;
 }
 vec3 d(vec3 i,inout float v,int y)
 {
   vec2 f=s(texcoord.xy+vec2(v+=.1,v+=.1)).xy;
   f=fract(f+d(v)*.1);
   float w=6.28319*f.x,z=sqrt(f.y);
   vec3 t=normalize(cross(i,vec3(0.,1.,1.))),r=cross(i,t),n=t*cos(w)*z+r*sin(w)*z+i.xyz*sqrt(1.-f.y);
   return n;
 }
 float d(vec3 v,vec3 y,vec3 f,int w)
 {
   vec3 i=IFwvgktA(v),d=t(i+y*.99);
   float s=.5,r=shadow2DLod(shadow,vec3(d.xy,d.z-.0006*s),3).x;
   r*=saturate(dot(worldLightVector,y));
   return r;
 }
 vec3 d()
 {
   vec3 f=cameraPosition.xyz+.5-v(cameraPosition.xyz+.5),i=previousCameraPosition+.5-v(previousCameraPosition+.5);
   return f-i;
 }
 vec3 d(vec3 v,vec3 y)
 {
   vec2 f=OhwBTsdT(SrTVycDN(IFwvgktA(v)+y+1.+d()));
   vec3 s=SdwzegmK(f).iGQYSjKr;
   return s;
 }
 vec3 f()
 {
   vec2 v=OhwBTsdT(vlgaEgnA(texcoord.xy)+d()/huLswJKj());
   vec3 f=SdwzegmK(v).iGQYSjKr;
   return f;
 }
 vec3 s(vec3 s,vec3 i,vec3 r,float y)
 {
   float w=fract(frameCounter*.0123456);
   vec3 n=d(i,w,0),z=s+i*.01;
   z+=v(cameraPosition.xyz+.5);
   z=HAWDRSEJ(z);
   int c=frzHVXWE();
   Ray m;
   m.origin=z*c-vec3(1.,1.,1.);
   m.dir=n;
   vec3 e=vec3(1.),x=vec3(0.),V[3]=vec3[3](vec3(1.,0.,0.),vec3(0.,1.,0.),vec3(0.,0.,1.));
   for(int g=0;g<1;g++)
     {
       ivec3 a=ivec3(floor(m.origin));
       vec3 h,W;
       ivec3 l;
       for(int B=0;B<3;B++)
         {
           float T=m.dir[0]/m.dir[B],A=m.dir[1]/m.dir[B],o=m.dir[2]/m.dir[B];
           h[B]=sqrt(T*T+A*A+o*o);
           if(m.dir[B]<0.)
             l[B]=-1,W[B]=(m.origin[B]-a[B])*h[B];
           else
              l[B]=1,W[B]=(a[B]+1.-m.origin[B])*h[B];
         }
       int B=0;
       float T=0.;
       vec4 o=vec4(0.);
       vec3 A=vec3(0.);
       for(int R=0;R<60;R++)
         {
           for(int S=0;S<3;S++)
             {
               if(W[B]>W[S])
                 B=S;
             }
           W[B]+=h[B];
           a[B]+=l[B];
           A=vec3(a)/float(c);
           vec2 S=DiuEETJJ(A,c);
           o=texture2DLod(shadowcolor,S,0);
           if(o.w*255.<254.f)
             {
               break;
             }
         }
       if(o.w*255.<1.f||o.w*255.>254.f)
         {
           vec3 S=max(vec3(0.),AtmosphericScattering(m.dir,worldSunVector,0.));
           S+=pow(saturate(dot(m.dir,worldLightVector)),5.)*colorSunlight*7.;
           S*=e;
           S*=saturate(dot(m.dir,vec3(0.,1.,0.))*100.)*.9+.1;
           x+=S*.1;
           break;
         }
       if(o.w*255.>1.f&&o.w*255.<128.f)
         {
           vec3 S=saturate(o.xyz);
           e*=S;
         }
       if(o.w*255.>128.f&&o.w<.9)
         x+=.5*e*normalize(o.xyz+.0001);
       vec3 S=V[B]*sign(-m.dir[B]);
       const float R=2.4;
       x+=d(A,S,n,c)*pow(e,vec3(.5))*R*colorSunlight*.5;
       x+=d(A,S)*e;
       float H,k;
       vec3 M=vec3(a),u=vec3(a)+1.,D[2]=vec3[2](vec3(a),vec3(a)+1.);
       f(t(m.origin,m.dir),D,H,k);
       m.origin+=n*H+S*.01;
       m.dir=d(S,w,0);
       w=mod(w*1.12346,13.);
     }
   return x;
 }
 vec3 s()
 {
   vec3 v=vlgaEgnA(texcoord.xy),i=evHMgHTx(v),y=HAWDRSEJ(i-vec3(1.,1.,0.));
   vec2 s=DiuEETJJ(y);
   float w=sin(frameTimeCounter*.1)+i.x*.11+i.y*.12+i.z*.13;
   vec3 r=normalize(rand(vec2(w))*2.-1.),m=i+vec3(1.,1.,1.);
   m=HAWDRSEJ(m);
   float z=1000.;
   z=min(z,texture2DLod(shadowcolor,DiuEETJJ(HAWDRSEJ(i-vec3(0.,0.,0.)))+vec2(.5,.5)/4096.,0).w);
   z=min(z,texture2DLod(shadowcolor,DiuEETJJ(HAWDRSEJ(i-vec3(0.,0.,0.)))+vec2(-.5,-.5)/4096.,0).w);
   z=min(z,texture2DLod(shadowcolor,DiuEETJJ(HAWDRSEJ(i-vec3(0.,1.,0.)))+vec2(0.,0.)/4096.,0).w);
   z=min(z,texture2DLod(shadowcolor,DiuEETJJ(HAWDRSEJ(i-vec3(0.,-1.,0.)))+vec2(0.,0.)/4096.,0).w);
   if(z*255>254)
     return vec3(0.);
   int n=frzHVXWE();
   Ray S;
   S.origin=m*n-vec3(1.,1.,1.);
   S.dir=r;
   vec3 e=vec3(1.),x=vec3(0.),V[3]=vec3[3](vec3(1.,0.,0.),vec3(0.,1.,0.),vec3(0.,0.,1.));
   for(int B=0;B<1;B++)
     {
       ivec3 a=ivec3(floor(S.origin)),A=a;
       vec3 h,W;
       ivec3 l;
       for(int R=0;R<3;R++)
         {
           float o=S.dir[0]/S.dir[R],c=S.dir[1]/S.dir[R],T=S.dir[2]/S.dir[R];
           h[R]=sqrt(o*o+c*c+T*T);
           if(S.dir[R]<0.)
             l[R]=-1,W[R]=(S.origin[R]-a[R])*h[R];
           else
              l[R]=1,W[R]=(a[R]+1.-S.origin[R])*h[R];
         }
       int R=0;
       float o=0.;
       vec4 c=vec4(0.);
       vec3 g=vec3(0.);
       for(int T=0;T<60;T++)
         {
           for(int k=0;k<3;k++)
             {
               if(W[R]>W[k])
                 R=k;
             }
           W[R]+=h[R];
           a[R]+=l[R];
           g=vec3(a)/float(n);
           vec2 H=DiuEETJJ(g,n);
           c=texture2DLod(shadowcolor,H,0);
           if(c.w*255.<254.f)
             {
               break;
             }
         }
       if(c.w*255.<1.f||c.w*255.>254.f)
         {
           vec3 T=max(vec3(0.),AtmosphericScattering(S.dir,worldSunVector,0.));
           T+=pow(saturate(dot(S.dir,worldLightVector)),5.)*colorSunlight*7.;
           T*=e;
           T*=saturate(dot(S.dir,vec3(0.,1.,0.))*100.)*.9+.1;
           x+=T*.1;
           break;
         }
       if(c.w*255.>1.f&&c.w*255.<128.f)
         {
           vec3 T=saturate(c.xyz);
           e*=T;
         }
       if(c.w*255.>128.f&&c.w<.9)
         x+=.5*e*normalize(c.xyz+.0001);
       vec3 T=V[R]*sign(-S.dir[R]);
       const float H=2.4;
       x+=d(g,T,r,n)*H*colorSunlight*e;
       x+=d(g,T)*e;
       float k,D;
       vec3 M=vec3(a),u=vec3(a)+1.,p[2]=vec3[2](vec3(a),vec3(a)+1.);
       f(t(S.origin,S.dir),p,k,D);
       S.origin+=r*k+T*.01;
       S.dir=d(T,w,0);
       w=mod(w*1.12346,13.);
     }
   return saturate(x);
 }
 vec4 w(vec2 v)
 {
   vec3 f=vlgaEgnA(v),i=evHMgHTx(f),y=HAWDRSEJ(i);
   vec2 r=DiuEETJJ(y);
   vec4 s=texture2DLod(shadowcolor,r,0);
   return s;
 }
 #include "GBufferData.inc"
 vec4 n(float v)
 {
   float s=v*v,i=s*v;
   vec4 f;
   f.x=-i+3*s-3*v+1;
   f.y=3*i-6*s+4;
   f.z=-3*i+3*s+3*v+1;
   f.w=i;
   return f/6.f;
 }
 vec4 n(in sampler2D v,in vec2 i)
 {
   vec2 f=vec2(viewWidth,viewHeight);
   i*=f;
   i-=.5;
   float s=fract(i.x),y=fract(i.y);
   i.x-=s;
   i.y-=y;
   vec4 d=n(s),S=n(y),z=vec4(i.x-.5,i.x+1.5,i.y-.5,i.y+1.5),m=vec4(d.x+d.y,d.z+d.w,S.x+S.y,S.z+S.w),c=z+vec4(d.y,d.w,S.y,S.w)/m,r=texture2DLod(v,vec2(c.x,c.z)/f,0),w=texture2DLod(v,vec2(c.y,c.z)/f,0),T=texture2DLod(v,vec2(c.x,c.w)/f,0),t=texture2DLod(v,vec2(c.y,c.w)/f,0);
   float o=m.x/(m.x+m.y),a=m.z/(m.z+m.w);
   return mix(mix(t,T,o),mix(w,r,o),a);
 }struct MaterialMask{float sky;float land;float grass;float leaves;float hand;float entityPlayer;float water;float stainedGlass;float ice;float torch;float lava;float glowstone;};
 float s(const in int v,in float f)
 {
   if(f>254.f)
     f=0.f;
   if(f==v)
     return 1.f;
   else
      return 0.f;
 }
 MaterialMask e(float v)
 {
   MaterialMask i;
   v*=255.;
   if(isEyeInWater>0)
     i.sky=0.f;
   else
     {
       i.sky=0.;
       if(texture2D(depthtex1,texcoord.xy).x>.999999)
         i.sky=1.;
     }
   i.land=s(1,v);
   i.grass=s(2,v);
   i.leaves=s(3,v);
   i.hand=s(4,v);
   i.entityPlayer=s(5,v);
   i.water=s(6,v);
   i.stainedGlass=s(7,v);
   i.ice=s(8,v);
   i.torch=s(30,v);
   i.lava=s(31,v);
   i.glowstone=s(32,v);
   return i;
 }
 void main()
 {
   GBufferData v=GetGBufferData();
   MaterialMask i=e(v.materialID);
   vec4 d=f(texcoord.xy,v.depth);
   if(isEyeInWater>.5)
     d.xy*=.8;
   vec4 m=gbufferModelViewInverse*vec4(d.xyz,1.),S=gbufferModelViewInverse*vec4(d.xyz,0.);
   vec3 r=normalize(d.xyz),y=normalize(S.xyz),c=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz);
   float w=length(d.xyz);
   if(i.grass>.5)
     c=vec3(0.,1.,0.);
   vec3 z=s(m.xyz,c.xyz,y.xyz,v.mcLightmap.y);
   float n=1./(saturate(-dot(c,y))*100.+1.),t;
   vec2 T=f(texcoord.xy,v.depth,t);
   float a=texture2D(depthtex1,T).x;
   vec4 o=vec4(texcoord.xy*2.-1.,a*2.-1.,1.),g=gbufferProjectionInverse*o;
   g.xyz/=g.w;
   vec4 x=gbufferModelViewInverse*vec4(g.xyz,1.),A=x;
   A.xyz+=cameraPosition-previousCameraPosition;
   vec4 B=gbufferPreviousModelView*vec4(A.xyz,1.),V=gbufferPreviousProjection*vec4(B.xyz,1.);
   V.xyz/=V.w;
   vec2 R=o.xy-V.xy;
   float l=length(R)*10.,W=clamp(l*500.,0.,1.);
   #ifdef HALF_RES_TRACE
   vec2 H=texcoord.xy*.5-R.xy*.25;
   if(a<.7)
     H=texcoord.xy*.5;
   #else
   vec2 k=texcoord.xy-R.xy*.5;
   if(a<.7)
     k=texcoord.xy;
   #endif
   #ifdef HALF_RES_TRACE
   vec2 M=cos((fract(abs(texcoord.xy*.5-k.xy)*vec2(viewWidth,viewHeight))*2.-1.)*3.14159)*.5+.5;
   #else
   vec2 h=cos((fract(abs(texcoord.xy-k.xy)*vec2(viewWidth,viewHeight))*2.-1.)*3.14159)*.5+.5;
   #endif
   vec2 u=pow(h,vec2(.5));
   vec4 p=gbufferProjectionInverse*vec4(texcoord.xy*2.-1.,texture2D(gaux1,k.xy).w*2.-1.,1.);
   p/=p.w;
   vec2 D=1./vec2(viewWidth,viewHeight),C=1.-D;
   LPRfwdzt G=SdwzegmK(k.xy);
   float P=G.mERUeFIj,L=G.TnLpRQbp,I=G.PHnZgwUO*256.,b=min(5.,I+1.),E=0.;
   if(length(p.z-B.z)>.5||(k.x<D.x||k.x>C.x||k.y<D.y||k.y>C.y)||abs(n-L)>.01)
     E=.99,P=0.,b=0.;
   float q=1.-exp2(-b);
   vec3 j=texture2D(gaux1,k.xy).xyz,F=mix(z,j,vec3(q));
   G.mERUeFIj=P;
   G.TnLpRQbp=n;
   G.eDReytEm=mix(G.eDReytEm,E,mix(.4,1.,E));
   G.PHnZgwUO=b/256;
   vec3 O=s();
   G.iGQYSjKr=mix(f(),O,vec3(.015));
   vec4 Z=eBNFItKo(G);
   gl_FragData[0]=vec4(F,a);
   gl_FragData[1]=Z;
 };

/* DRAWBUFFERS:45 */