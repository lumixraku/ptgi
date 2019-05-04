#version 330 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices = 6) out;

in vec4 vcolor[];
in vec4 vtexcoord[];
in vec3 vnormal[];
in vec3 vrawNormal[];
in vec4 vviewPos[];
in float vmaterialIDs[];
in float visStainedGlass[];
in vec4 volumeScreenPos[];
in vec4 shadowScreenPos[];
in float vInvalidForVolume[];

out vec4 color;
out vec4 texcoord;
out vec3 normal;
out vec3 rawNormal;
out vec4 viewPos;
out float materialIDs;
out float isStainedGlass;
out float isVoxelized;


void main()
{
	int i;
	vec4 vertex;

	//Standard shadow pos
	for (i = 0; i < 3; i++)
	{
		vertex = gl_in[1].gl_Position;

		//...
		vertex = shadowScreenPos[i];

		gl_Position = vertex;

		//copy varying here
		color = vcolor[i];
		texcoord = vtexcoord[i];
		normal = vnormal[i];
		rawNormal = vrawNormal[i];
		viewPos = vviewPos[i];
		materialIDs = vmaterialIDs[i];
		isStainedGlass = visStainedGlass[i];
		isVoxelized = 0.0;

		EmitVertex();
	}
	EndPrimitive();


	//volume pos
	bool valid = true;
	if (vInvalidForVolume[0] > 0.5 || vInvalidForVolume[1] > 0.5 || vInvalidForVolume[2] > 0.5)
	{
		valid = false;
	}

	if (valid)
	{
		for (i = 0; i < 3; i++)
		{
			vertex = gl_in[1].gl_Position;

			//...
			vertex = volumeScreenPos[i];


			gl_Position = vertex;

			//copy varying here
			color = vcolor[i];
			texcoord = vtexcoord[i];
			normal = vnormal[i];
			rawNormal = vrawNormal[i];
			viewPos = vviewPos[i];
			materialIDs = vmaterialIDs[i];
			isStainedGlass = visStainedGlass[i];
			isVoxelized = 1.0;


			EmitVertex();
		}
		EndPrimitive();
	}



}