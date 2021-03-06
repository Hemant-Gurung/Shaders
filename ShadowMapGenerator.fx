float4x4 gWorld;
float4x4 gLightViewProj;
float4x4 gBones[70];
 
DepthStencilState depthStencilState
{
	DepthEnable = TRUE;
	DepthWriteMask = ALL;
};

RasterizerState rasterizerState
{
	FillMode = SOLID;
	CullMode = NONE;
};

//--------------------------------------------------------------------------------------
// Vertex Shader [STATIC]
//--------------------------------------------------------------------------------------
float4 ShadowMapVS(float3 position:POSITION):SV_POSITION
{
	float4 pos = mul(float4(position,1.0f),mul(gWorld,gLightViewProj));
	//TODO: return the position of the vertex in correct space (hint: seen from the view of the light)
	return pos;
}

//--------------------------------------------------------------------------------------
// Vertex Shader [SKINNED]
//--------------------------------------------------------------------------------------
float4 ShadowMapVS_Skinned(float3 position:POSITION, float4 BoneIndices : BLENDINDICES, float4 BoneWeights : BLENDWEIGHTS) : SV_POSITION
{
	
	
	float4 transformedPos = float4(0,0,0,0);  
	 

	int i;
    for(i=0;i<4;++i)
	{
		transformedPos += mul(float4(position,1.0),gBones[BoneIndices[i]])*BoneWeights[i];
	}
	
	//float4 position = float4{0,0,0,0};
	transformedPos = mul ( transformedPos,mul(gWorld,gLightViewProj ));
	transformedPos.w =1;
	return transformedPos;
	
	//return pos;
	//TODO: return the position of the ANIMATED vertex in correct space (hint: seen from the view of the light)
}
 
//--------------------------------------------------------------------------------------
// Pixel Shaders
//--------------------------------------------------------------------------------------
void ShadowMapPS_VOID(float4 position:SV_POSITION){}

technique10 GenerateShadows
{
	pass P0
	{
		SetRasterizerState(rasterizerState);
	    SetDepthStencilState(depthStencilState, 0);
		SetVertexShader(CompileShader(vs_4_0, ShadowMapVS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, ShadowMapPS_VOID()));
	}
}

technique10 GenerateShadows_Skinned
{
	pass P0
	{
		SetRasterizerState(rasterizerState);
		SetDepthStencilState(depthStencilState, 0);
		SetVertexShader(CompileShader(vs_4_0, ShadowMapVS_Skinned()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, ShadowMapPS_VOID()));
	}
}