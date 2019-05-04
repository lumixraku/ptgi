#version 120

#define SHADOW_MAP_BIAS 0.90


varying vec4 texcoord;
varying vec4 vPosition;
varying vec4 color;
varying vec4 lmcoord;

varying vec3 normal;
varying vec3 rawNormal;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;

varying float materialIDs;
varying float iswater;
varying float isStainedGlass;
varying vec4 viewPos;

uniform sampler2D noisetex;
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


varying float invalid;

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

























void i(inout vec3 x,float m,float f){mat3 v=mat3(1.,0.,0.,0.,cos(m),sin(m),0.,-sin(m),cos(m)),s=mat3(cos(f),0.,-sin(f),0.,1.,0.,sin(f),0.,cos(f));x=s*x;x=v*x;}void f(inout vec3 x,float m,float i){m*=-1.;i*=-1.;mat3 v=mat3(1.,0.,0.,0.,cos(m),sin(m),0.,-sin(m),cos(m)),s=mat3(cos(i),0.,-sin(i),0.,1.,0.,sin(i),0.,cos(i));x=v*x;x=s*x;}vec2 f(){const float x=1.61803,v=x*3.14159;const int f=128;float i=mod(float(frameCounter)/f,1.);i=mod(i*(.333333*f)*(1.+1./f),1.);vec2 y=vec2(0.);y.x=v*i*f;y.y=asin(mod(i*2.,1.));return y;}void f(inout vec3 y){vec2 x=f();i(y.xyz,x.y,x.x);}void i(inout vec3 y){vec2 x=f();f(y.xyz,x.y,x.x);}float i(){return.02;}float t(){return.02;}int t(float m){return int(floor(m));}int x(int m){return m-t(mod(float(m),2.))-0;}int d(int m){return m-t(mod(float(m),2.))-1;}int d(){ivec2 y=ivec2(viewWidth,viewHeight);int m=y.x*y.y;return x(t(floor(pow(float(m),.333333))));}int x(){ivec2 x=ivec2(2048,2048);int m=x.x*x.y;return d(t(floor(pow(float(m),.333333))));}vec3 n(vec2 y){ivec2 x=ivec2(viewWidth,viewHeight);int s=x.x*x.y,m=d();ivec2 v=ivec2(y.x*x.x,y.y*x.y);int i=t(v.x+v.y*x.x);ivec3 f;f.x=t(mod(i,m));f.y=t(mod(i/m,m));f.z=t(mod(i/(m*m),m));vec3 r=vec3(f)/m;return r;}vec2 s(vec3 m){ivec2 x=ivec2(viewWidth,viewHeight);int y=d();ivec3 v=ivec3(m*y+1e-05);int i=v.x+v.y*y+v.z*y*y;ivec2 f;f.x=t(mod(i,x.x));f.y=t(i/x.x);vec2 r=vec2(f)/x;r+=vec2(.5/x.x,.5/x.y);return r;}vec3 r(vec2 y){ivec2 v=ivec2(2048,2048);int s=v.x*v.y,m=x();ivec2 i=ivec2(y.x*v.x,y.y*v.y);int f=t(i.x+i.y*v.x);ivec3 r;r.x=t(mod(f,m));r.y=t(mod(f/m,m));r.z=t(mod(f/(m*m),m));vec3 z=vec3(r)/m;return z;}vec2 v(vec3 m){ivec2 y=ivec2(2048,2048);int f=x();ivec3 v=ivec3(m*f+1e-05);int i=v.x+v.y*f+v.z*f*f;ivec2 r;r.x=t(mod(i,y.x));r.y=t(i/y.x);vec2 s=vec2(r)/y;s+=vec2(.5/y.x,.5/y.y);return s;}vec3 m(vec3 m){int f=x();m*=1./f;m=m+vec3(.5);m=clamp(m,vec3(0.),vec3(1.));return m;}vec3 e(vec3 i){int m=x();i=i-vec3(.5);i*=m;return i;}vec3 w(vec3 m){int x=d();m*=1./x;m=m+vec3(.5);m=clamp(m,vec3(0.),vec3(1.));return m;}vec3 p(vec3 x){int m=d();x=x-vec3(.5);x*=m;return x;}float e(){return 1.;}float m(){return 2.;}vec3 h(vec3 m){int x=d();float f=e(),s=x*f;vec3 i=m*s-s*.5;i-=fract(cameraPosition.xyz/f)*f;return i;}vec3 c(vec3 m){int x=d();float f=e();m+=fract(cameraPosition.xyz/f)*f;float y=x*f;vec3 i=(m.xyz+y*.5)/y;return i;}vec3 a(vec3 m){int x=d();float f=e(),v=x*f;m=floor(m/f)*f;m/=v;return m;}vec3 o(vec3 f){int x=d();float y=m(),s=x*y;vec3 i=f*s-s*.5;i-=fract(cameraPosition.xyz/y)*y;return i;}vec3 l(vec3 y){int x=d();float f=m();y+=fract(cameraPosition.xyz/f)*f;float i=x*f;vec3 s=(y.xyz+i*.5)/i;return s;}vec3 y(vec3 x){int i=d();float f=m(),v=i*f;x=floor(x/f)*f;x/=v;return x;}vec3 E(vec3 m){return m=m*2.-1.,m=pow(length(m),4.)*normalize(m),m=m*.5+.5,m;}vec3 z(vec3 m){return m=m*2.-1.,m=pow(length(m),1./6.)*normalize(m),m=m*.5+.5,m;}vec2 g(vec3 x){return x=m(x),v(x);}void main(){gl_Position=ftransform();lmcoord=gl_TextureMatrix[1]*gl_MultiTexCoord1;texcoord=gl_MultiTexCoord0;viewPos=gl_ModelViewMatrix*gl_Vertex;vec4 m=gl_Position;m=shadowProjectionInverse*m;m=shadowModelViewInverse*m;m.xyz+=cameraPosition.xyz;materialIDs=100.f;iswater=0.;if(mc_Entity.x==1971.f)iswater=1.f;if(mc_Entity.x==8||mc_Entity.x==9)iswater=1.f;float x=0.f;if(mc_Entity.x==79)x=1.f;isStainedGlass=0.f;if(mc_Entity.x==95||mc_Entity.x==160)isStainedGlass=1.f;if(mc_Entity.x==31.||mc_Entity.x==38.f||mc_Entity.x==37.f)materialIDs=max(materialIDs,102.f);if(mc_Entity.x==59.)materialIDs=max(materialIDs,102.f);if(mc_Entity.x==18.||mc_Entity.x==161.f)materialIDs=max(materialIDs,103.f);if(mc_Entity.x==79.f||mc_Entity.x==174.f)materialIDs=max(materialIDs,104.f);if(mc_Entity.x==30.f)materialIDs=max(materialIDs,111.f);if(mc_Entity.x==50)materialIDs=max(materialIDs,130.f);if(mc_Entity.x==10||mc_Entity.x==11)materialIDs=max(materialIDs,131.f);if(mc_Entity.x==89||mc_Entity.x==124)materialIDs=max(materialIDs,132.f);if(mc_Entity.x==51)materialIDs=max(materialIDs,133.f);if(mc_Entity.x==22)materialIDs=max(materialIDs,135.);if(mc_Entity.x==152)materialIDs=max(materialIDs,136.);float i=mod(texcoord.y*16.f,.0625f),f=clamp(lmcoord.y*33.05f/32.f-.0328125f,0.f,1.f);f*=1.1f;f-=.1f;f=max(0.f,f);f=pow(f,5.f);if(i<.01f)i=1.f;else i=0.f;vec3 y=gl_Normal;if(abs(materialIDs-2.)<.1)y=vec3(0.,1.,0.);normal=normalize(gl_NormalMatrix*y);color=gl_Color;invalid=0.;float s=1.;if(iswater>.5||x>.5||mc_Entity.x<1.||fract(m.x)>.01&&fract(m.x)<.99||fract(m.y)>.01&&fract(m.y)<.99||fract(m.z)>.01&&fract(m.z)<.99||fract(y.x)>.01&&fract(y.x)<.99||fract(y.y)>.01&&fract(y.y)<.99||fract(y.z)>.01&&fract(y.z)<.99||mc_Entity.x==10.||mc_Entity.x==11.||mc_Entity.x==64.||mc_Entity.x==102.||mc_Entity.x==54.||mc_Entity.x==65.||mc_Entity.x==66.||mc_Entity.x==68.||mc_Entity.x==69.||mc_Entity.x==70.||mc_Entity.x==26.||mc_Entity.x==27.||mc_Entity.x==28.||mc_Entity.x==34.||mc_Entity.x==28.||mc_Entity.x==55.||mc_Entity.x==63.||mc_Entity.x==68.||mc_Entity.x==71.||mc_Entity.x==72.||mc_Entity.x==77.||mc_Entity.x==85.||mc_Entity.x==96.||mc_Entity.x==101.||mc_Entity.x==107.||mc_Entity.x==113.||mc_Entity.x==117.||mc_Entity.x==118.||mc_Entity.x==131.||mc_Entity.x==132.||mc_Entity.x==139.||mc_Entity.x==157.||mc_Entity.x==50.||mc_Entity.x==51.||mc_Entity.x==106.||mc_Entity.x==20.)invalid=1.;vec3 v=m.xyz;m.xyz-=cameraPosition.xyz;m=shadowModelView*m;m=shadowProjection*m;if(materialIDs!=2.){if(y.x>.85)color.xyz*=1./.6;if(y.x<-.85)color.xyz*=1./.6;if(y.z>.85)color.xyz*=1.25;if(y.z<-.85)color.xyz*=1.25;if(y.y<-.85)color.xyz*=2.;}vec3 r,z;if(gl_Normal.x>.5)r=vec3(0.,0.,-1.),z=vec3(0.,-1.,0.);else if(gl_Normal.x<-.5)r=vec3(0.,0.,1.),z=vec3(0.,-1.,0.);else if(gl_Normal.y>.5)r=vec3(1.,0.,0.),z=vec3(0.,0.,1.);else if(gl_Normal.y<-.5)r=vec3(1.,0.,0.),z=vec3(0.,0.,-1.);else if(gl_Normal.z>.5)r=vec3(1.,0.,0.),z=vec3(0.,-1.,0.);else if(gl_Normal.z<-.5)r=vec3(-1.,0.,0.),z=vec3(0.,-1.,0.);vec2 n=clamp((texcoord.xy-mc_midTexCoord.xy)*1000.,vec2(0.),vec2(1.));float d=.15;r=normalize(at_tangent.xyz);z=normalize(cross(r,y.xyz));vec3 l=v.xyz+mix(r*d,-r*d,vec3(n.x));l.xyz+=mix(z*d,-z*d,vec3(n.y));l.xyz-=gl_Normal.xyz*d;l=floor(l);l-=cameraPosition.xyz;gl_Position=vec4((g(l.xyz)+n.xy*(1./vec2(2048,2048))*s)*2.-1.,0.,1.);vPosition=gl_Position;gl_FrontColor=gl_Color;}