
const float hOkygxWq = 0.00006;
const float CRgczcVK = 1.45;
const float LwgeyngM = 0.0;
const float uwtHmhPW = 0.95;
const float KLKQcJfi = 0.95;
const float gPdrYTep = 2.0;
const float pehfXVXY = 1.125;
const int TjeJxnda = 2048;
int nGmjprCQ(float x)
{
return int(floor(x));
}
int LVBpSQxw(int x)
{
return x - nGmjprCQ(mod(float(x), 2.0)) - 0;
}
int fTpLuOmj(int x)
{
return x - nGmjprCQ(mod(float(x), 2.0)) - 1;
}
int huLswJKj()
{
ivec2 viewSize = ivec2(viewWidth, viewHeight);
int totalPixels = viewSize.x * viewSize.y;
return LVBpSQxw(nGmjprCQ(floor(pow(float(totalPixels), 0.333333333333333))));
}
int frzHVXWE()
{
ivec2 viewSize = ivec2(TjeJxnda, TjeJxnda);
int totalPixels = viewSize.x * viewSize.y;
return fTpLuOmj(nGmjprCQ(floor(pow(float(totalPixels), 0.333333333333333))));
}
vec3 vlgaEgnA(vec2 v)
{
ivec2 f=ivec2(viewWidth,viewHeight);
int z=f.x*f.y,y=huLswJKj();
ivec2 d=ivec2(v.x*f.x,v.y*f.y);
float x=float(d.y/y),i=float(int(d.x+mod(f.x*x,y))/y);
i+=floor(f.x*x/y);
vec3 m=vec3(0.,0.,i);
m.x=mod(d.x+mod(f.x*x,y),y);
m.y=mod(d.y,y);
m.xyz=floor(m.xyz);
m/=y;
m.xyz=m.xzy;
return m;
};
vec2 OhwBTsdT(vec3 x)
{
ivec2 r=ivec2(viewWidth,viewHeight);
int y=huLswJKj();
vec3 v=x.xzy*y;
v=floor(v+1e-05);
float f=v.z;
vec2 i;
i.x=mod(v.x+f*y,r.x);
float e=v.x+f*y;
i.y=v.y+floor(e/r.x)*y;
i+=.5;
i/=r;
return i;
};
vec3 uDSOfMrW(vec2 f)
{
vec2 i=f;
i.xy/=.5;
ivec2 v=ivec2(TjeJxnda,TjeJxnda);
int z=v.x*v.y,y=frzHVXWE();
ivec2 d=ivec2(i.x*v.x,i.y*v.y);
float x=float(d.y/y),r=float(int(d.x+mod(v.x*x,y))/y);
r+=floor(v.x*x/y);
vec3 m=vec3(0.,0.,r);
m.x=mod(d.x+mod(v.x*x,y),y);
m.y=mod(d.y,y);
m.xyz=floor(m.xyz);
m/=y;
m.xyz=m.xzy;
return m;
};
vec2 DiuEETJJ(vec3 r,int x)
{
ivec2 i=ivec2(TjeJxnda,TjeJxnda);
vec3 v=r.xzy*x;
v=floor(v+1e-05);
float y=v.z;
vec2 f;
f.x=mod(v.x+y*x,i.x);
float T=v.x+y*x;
f.y=v.y+floor(T/i.x)*x;
f+=.5;
f/=i;
f.xy*=.5;
return f;
};
vec2 DiuEETJJ(vec3 ZvNNVFBm)
{	
return DiuEETJJ(ZvNNVFBm, frzHVXWE());
}
vec3 HAWDRSEJ(vec3 h, int p)
{
h *= (1.0 / p);
h = h + vec3(0.5);
h = clamp(h, vec3(0.0), vec3(1.0));
return h;
}
vec3 HAWDRSEJ(vec3 p)
{
return HAWDRSEJ(p, frzHVXWE());
}
vec3 IFwvgktA(vec3 p)
{
int BubtEJIQ = frzHVXWE();
p = p - vec3(0.5);
p *= BubtEJIQ;
return p;
}
vec3 SrTVycDN(vec3 p)
{
int BubtEJIQ = huLswJKj();
p *= 1.0 / BubtEJIQ;
p = p + vec3(0.5);
p = clamp(p, vec3(0.0), vec3(1.0));
return p;
}
vec3 evHMgHTx(vec3 p)
{
int BubtEJIQ = huLswJKj();
p = p - vec3(0.5);
p *= BubtEJIQ;
return p;
}
struct LPRfwdzt
{
float mERUeFIj;
float TnLpRQbp;
float eDReytEm;
float PHnZgwUO;
vec3 iGQYSjKr;
};
vec4 eBNFItKo(LPRfwdzt g)
{
vec4 d;
d.x = g.mERUeFIj;
g.iGQYSjKr = pow(g.iGQYSjKr, vec3(0.25));
d.y = PackTwo16BitTo32Bit(g.iGQYSjKr.x, g.TnLpRQbp);
d.z = PackTwo16BitTo32Bit(g.iGQYSjKr.y, g.eDReytEm);
d.w = PackTwo16BitTo32Bit(g.iGQYSjKr.z, g.PHnZgwUO);
return d;
}
LPRfwdzt iAGSTqeu(vec4 d)
{
LPRfwdzt g;
vec2 unpackedY = UnpackTwo16BitFrom32Bit(d.y);
vec2 unpackedZ = UnpackTwo16BitFrom32Bit(d.z);
vec2 unpackedW = UnpackTwo16BitFrom32Bit(d.w);
g.mERUeFIj = d.x;
g.TnLpRQbp = unpackedY.y;
g.eDReytEm = unpackedZ.y;
g.PHnZgwUO = unpackedW.y;
g.iGQYSjKr = pow(vec3(unpackedY.x, unpackedZ.x, unpackedW.x), vec3(4.0));
return g;
}
LPRfwdzt SdwzegmK(vec2 p)
{
vec2 v1 = 1.0 / vec2(viewWidth, viewHeight);
vec2 v2 = vec2(viewWidth, viewHeight);
p = (floor(p * v2) + 0.5) * v1;
return iAGSTqeu(texture2DLod(gaux2, p, 0));
}