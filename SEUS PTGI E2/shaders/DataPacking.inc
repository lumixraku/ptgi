
//Packing functions
float PackTwo4BitTo8Bit(float a, float b)
{
	float data;

	a = clamp(a, 0.0, 1.0);
	b = clamp(b, 0.0, 1.0);

	a *= 15.0;
	b *= 15.0;

	a = floor(a);
	b = floor(b);

	data = a * exp2(4.0);
	data += b;

	data /= exp2(8.0) - 1;

	return data;
}

vec2 UnpackTwo4BitFrom8Bit(float value)
{
	vec2 data;

	value *= exp2(8.0) - 1;

	data.x = floor(value / exp2(4.0));
	data.y = mod(value, exp2(4.0));

	data.x /= 15.0;
	data.y /= 15.0;

	return data;
}





float PackTwo8BitTo16Bit(float a, float b)
{
	float data;

	a = clamp(a, 0.0, 1.0);
	b = clamp(b, 0.0, 1.0);

	a *= 255.0;
	b *= 255.0;
    
    a = floor(a);
    b = floor(b);

	data = a * exp2(8.0);
	data += b;



	data /= exp2(16.0) - 1;

	return data;
}

vec2 UnpackTwo8BitFrom16Bit(float value)
{
	vec2 data;

	value *= exp2(16.0) - 1;

	data.x = floor(value / exp2(8.0));
	data.y = mod(value, exp2(8.0));

	data.x /= 255.0;
	data.y /= 255.0;

	return data;
}





float PackTwo16BitTo32Bit(float a, float b)
{
	float data;

	a = clamp(a, 0.0, 1.0);
	b = clamp(b, 0.0, 1.0);

	a *= 65536.0;
	b *= 65536.0;
    
    a = floor(a);
    b = floor(b);

	data = a * exp2(16.0);
	data += b;



	data /= exp2(32.0) - 1;

	return data;
}

vec2 UnpackTwo16BitFrom32Bit(float value)
{
	vec2 data;

	value *= exp2(32.0) - 1;

	data.x = floor(value / exp2(16.0));
	data.y = mod(value, exp2(16.0));

	data.x /= 65536.0;
	data.y /= 65536.0;

	return data;
}