
const float BlurBlendWeight = 0.006;
const float ColorBlendRejection = 2.0;
const float ColorBlendRejectionDisocclusion = 2.0;
const float BlurRadius = 2.0;
const float BlurRadiusDisocclusion = 1.0;

// #define BLUR_SELF_FEEDBACK




int FloorToInt(float x)
{
	return int(floor(x));
}

int RoundDownToEven(int x)
{
	return x - FloorToInt(mod(float(x), 2.0)) - 0;
}

int RoundDownToOdd(int x)
{
	return x - FloorToInt(mod(float(x), 2.0)) - 1;
}

int GetVolumeTexSize()
{
	ivec2 viewSize = ivec2(viewWidth, viewHeight);
	int totalPixels = viewSize.x * viewSize.y;
	return RoundDownToEven(FloorToInt(floor(pow(float(totalPixels), 0.333333333333333))));	//cube root
}


int GetVolumeTexSizeShadow()
{
	ivec2 viewSize = ivec2(4096, 4096);
	int totalPixels = viewSize.x * viewSize.y;
	return RoundDownToOdd(FloorToInt(floor(pow(float(totalPixels), 0.333333333333333))));	//cube root
}

vec3 TexcoordToVolumeCoord(vec2 coord)
{
	ivec2 viewSize = ivec2(viewWidth, viewHeight);
	int totalPixels = viewSize.x * viewSize.y;
	int volumeSize = GetVolumeTexSize();	

	ivec2 pixelCoord = ivec2(coord.x * viewSize.x, coord.y * viewSize.y);

	int flatPixelIndex = FloorToInt(pixelCoord.x + pixelCoord.y * viewSize.x);

	ivec3 volumeCoord;
	volumeCoord.x = FloorToInt(mod(flatPixelIndex, volumeSize));
	volumeCoord.y = FloorToInt(mod(flatPixelIndex / volumeSize, volumeSize));
	volumeCoord.z = FloorToInt(mod(flatPixelIndex / (volumeSize * volumeSize), volumeSize));

	vec3 volumePos = vec3(volumeCoord) / volumeSize;

	return volumePos;
}

vec2 VolumeCoordToTexcoord(vec3 volumePos)
{	
	ivec2 viewSize = ivec2(viewWidth, viewHeight);
	int volumeSize = GetVolumeTexSize();


	ivec3 volumeCoord = ivec3(volumePos * volumeSize + 0.00001);

	int flatPixelIndex = volumeCoord.x + (volumeCoord.y * volumeSize) + (volumeCoord.z * volumeSize * volumeSize);

	ivec2 pixelCoord;
	pixelCoord.x = FloorToInt(mod(flatPixelIndex, viewSize.x));
	pixelCoord.y = FloorToInt((flatPixelIndex / viewSize.x));

	vec2 coord = vec2(pixelCoord) / viewSize;

	coord += vec2(0.5 / viewSize.x, 0.5 / viewSize.y);

	return coord;
}

vec3 TexcoordToVolumeCoordShadow(vec2 coord)
{
	// ivec2 viewSize = ivec2(4096, 4096);
	// int totalPixels = viewSize.x * viewSize.y;
	// int volumeSize = GetVolumeTexSizeShadow();	

	// ivec2 pixelCoord = ivec2(coord.x * viewSize.x, coord.y * viewSize.y);

	// int flatPixelIndex = FloorToInt(pixelCoord.x + pixelCoord.y * viewSize.x);

	// ivec3 volumeCoord;
	// volumeCoord.x = FloorToInt(mod(flatPixelIndex, volumeSize));
	// volumeCoord.y = FloorToInt(mod(flatPixelIndex / volumeSize, volumeSize));
	// volumeCoord.z = FloorToInt(mod(flatPixelIndex / (volumeSize * volumeSize), volumeSize));

	// vec3 volumePos = vec3(volumeCoord) / volumeSize;

	// return volumePos;

	ivec2 viewSize = ivec2(4096, 4096);
	int totalPixels = viewSize.x * viewSize.y;
	int volumeSize = GetVolumeTexSizeShadow();	

	ivec2 pixelCoord = ivec2(coord.x * viewSize.x, coord.y * viewSize.y);

	float vSlice = float(pixelCoord.y / volumeSize);
	float sliceIndex = float(int(pixelCoord.x + mod(viewSize.x * vSlice, volumeSize)) / volumeSize);
	sliceIndex += floor((viewSize.x * vSlice) / volumeSize);

	vec3 volumePos = vec3(0.0, 0.0, sliceIndex);

	volumePos.x = mod(pixelCoord.x + mod(viewSize.x * vSlice, volumeSize), volumeSize);
	volumePos.y = mod(pixelCoord.y, volumeSize);

	volumePos.xyz = floor(volumePos.xyz);

	volumePos /= volumeSize;

	volumePos.xyz = volumePos.xzy;

	// int flatPixelIndex = FloorToInt(pixelCoord.x + pixelCoord.y * viewSize.x);

	// ivec3 volumeCoord;
	// volumeCoord.x = FloorToInt(mod(flatPixelIndex, volumeSize));
	// volumeCoord.y = FloorToInt(mod(flatPixelIndex / volumeSize, volumeSize));
	// volumeCoord.z = FloorToInt(mod(flatPixelIndex / (volumeSize * volumeSize), volumeSize));

	// vec3 volumePos = vec3(volumeCoord) / volumeSize;

	return volumePos;
}

vec2 VolumeCoordToTexcoordShadow(vec3 volumePos, int volumeSize)
{	
	ivec2 viewSize = ivec2(4096, 4096);


	vec3 vpos = volumePos.xzy * volumeSize;
	vpos = floor(vpos + 0.00001);
	float sliceIndex = vpos.z;

	vec2 coord;
	coord.x = mod(vpos.x + sliceIndex * volumeSize, viewSize.x);
	float t = vpos.x + sliceIndex * volumeSize;
	coord.y = vpos.y + floor(t / viewSize.x) * volumeSize;

	coord += 0.5;
	coord /= viewSize;

	return coord;
}

vec2 VolumeCoordToTexcoordShadow(vec3 volumePos)
{	
	int volumeSize = GetVolumeTexSizeShadow();

	return VolumeCoordToTexcoordShadow(volumePos, GetVolumeTexSizeShadow());
}


vec3 WorldToVolumeShadow(vec3 pos, int volumeTexSize)
{
	pos *= (1.0 / volumeTexSize);
	pos = pos + vec3(0.5);
	pos = clamp(pos, vec3(0.0), vec3(1.0));

	return pos;
}

vec3 WorldToVolumeShadow(vec3 pos)
{
	return WorldToVolumeShadow(pos, GetVolumeTexSizeShadow());
}

vec3 VolumeToWorldShadow(vec3 pos)
{
	int volumeTexSize = GetVolumeTexSizeShadow();

	pos = pos - vec3(0.5);
	pos *= volumeTexSize;

	return pos;
}


vec3 WorldToVolume(vec3 pos)
{
	int volumeTexSize = GetVolumeTexSize();

	pos *= 1.0 / volumeTexSize;
	pos = pos + vec3(0.5);
	pos = clamp(pos, vec3(0.0), vec3(1.0));

	return pos;
}

vec3 VolumeToWorld(vec3 pos)
{
	int volumeTexSize = GetVolumeTexSize();

	pos = pos - vec3(0.5);
	pos *= volumeTexSize;

	return pos;
}




float GetVolumeSize0()
{
	return 1.0;
}


float GetVolumeSize1()
{
	return 2.0;
}


vec3 VolumeSpaceToWorldSpace0(vec3 volumePos)
{
	int volumeSize = GetVolumeTexSize();




	float sizeScale = GetVolumeSize0();

	float scale = volumeSize * sizeScale;


	vec3 worldPos = (volumePos * scale) - (scale * 0.5);

	worldPos -= fract(cameraPosition.xyz / sizeScale) * sizeScale;



	return worldPos;
}

vec3 WorldSpaceToVolumeSpace0(vec3 worldPos)
{
	int volumeSize = GetVolumeTexSize();


	float sizeScale = GetVolumeSize0();

	worldPos += fract(cameraPosition.xyz / sizeScale) * sizeScale;


	float scale = volumeSize * sizeScale;


	vec3 volumePos = (worldPos.xyz + (scale * 0.5)) / (scale);



	return volumePos;
}

vec3 VolumeCameraLock0(vec3 camPos)
{
	int volumeScale = GetVolumeTexSize();

	float sizeScale = GetVolumeSize0();
	float volumeExtents = volumeScale * sizeScale;

	camPos = floor(camPos / sizeScale) * sizeScale;

	camPos /= volumeExtents;

	return camPos;
}








vec3 VolumeSpaceToWorldSpace1(vec3 volumePos)
{
	int volumeSize = GetVolumeTexSize();




	float sizeScale = GetVolumeSize1();

	float scale = volumeSize * sizeScale;


	vec3 worldPos = (volumePos * scale) - (scale * 0.5);

	worldPos -= fract(cameraPosition.xyz / sizeScale) * sizeScale;



	return worldPos;
}

vec3 WorldSpaceToVolumeSpace1(vec3 worldPos)
{
	int volumeSize = GetVolumeTexSize();


	float sizeScale = GetVolumeSize1();

	worldPos += fract(cameraPosition.xyz / sizeScale) * sizeScale;


	float scale = volumeSize * sizeScale;


	vec3 volumePos = (worldPos.xyz + (scale * 0.5)) / (scale);



	return volumePos;
}

vec3 VolumeCameraLock1(vec3 camPos)
{
	int volumeScale = GetVolumeTexSize();

	float sizeScale = GetVolumeSize1();
	float volumeExtents = volumeScale * sizeScale;

	camPos = floor(camPos / sizeScale) * sizeScale;

	camPos /= volumeExtents;

	return camPos;
}










vec3 DistortVolumeI(vec3 pos)
{
	//return pos - vec3(0.2);

	pos = pos * 2.0 - 1.0;


	//pos = pow(pos, vec3(2.0)) * sign(pos);
	pos = pow(length(pos), 4.0) * normalize(pos);

	pos = pos * 0.5 + 0.5;

	return pos;
}

vec3 DistortVolume(vec3 pos)
{
	//return pos + vec3(0.2);

	pos = pos * 2.0 - 1.0;

	//float dist = length(pos);
	//float distortFactor = (1.0 - 0.9) + dist * 0.9;

	//pos /= 1.0 / distortFactor;

	//pos = pow(abs(pos), vec3(1.0 / 2.0)) * sign(pos);
	pos = pow(length(pos), 1.0 / 6.0) * normalize(pos);


	pos = pos * 0.5 + 0.5;

	return pos;
}