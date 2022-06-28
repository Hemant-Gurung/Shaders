float4x4 gWorld : WORLD;
float4x4 gWorldViewProj : WORLDVIEWPROJECTION; 
float4x4 gWorldViewProj_Light;
float3 gLightDirection = float3(-0.577f, -0.577f, 0.577f);
float gShadowMapBias = 0.01f;
float4x4 gBones[70];

Texture2D gDiffuseMap;
Texture2D gShadowMap;

SamplerComparisonState cmpSampler
{
	// sampler state
	Filter = COMPARISON_MIN_MAG_MIP_LINEAR;
	AddressU = MIRROR;
	AddressV = MIRROR;

	// sampler comparison state
	ComparisonFunc = LESS_EQUAL;
};

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;// or Mirror or Clamp or Border
    AddressV = Wrap;// or Mirror or Clamp or Border
};

struct VS_INPUT
{
	float3 pos : POSITION;
	float3 normal : NORMAL;
	float2 texCoord : TEXCOORD;
	float4 BoneIndices : BLENDINDICES;
	float4 BoneWeights : BLENDWEIGHTS;
};

struct VS_OUTPUT
{
	float4 pos : SV_POSITION;
	float3 normal : NORMAL;
	float2 texCoord : TEXCOORD;
	float4 lPos : TEXCOORD1;
};

DepthStencilState EnableDepth
{
	DepthEnable = TRUE;
	DepthWriteMask = ALL;
};

RasterizerState NoCulling
{
	CullMode = NONE;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(VS_INPUT input)
{
	VS_OUTPUT output = (VS_OUTPUT)0;
	//TODO: complete Vertex Shader 
	float4 originalPos = float4(input.pos,1.0f);
	float4 transformedPos =0;
	float3 transformedNormal =0;
	for(int a=0;a<4;++a)
	{
		int currIndex = input.BoneIndices[a];
		if(currIndex > -1)
		{
			transformedPos+=mul(originalPos,gBones[currIndex])*input.BoneWeights[a];
			transformedNormal += input.BoneWeights[a]*input.normal;
		}
	}
	transformedPos.w =1;
	output.pos = mul(transformedPos,gWorldViewProj);
	output.normal = normalize(mul(transformedNormal,(float3x3)gWorld));
	output.texCoord = input.texCoord;
	output.lPos = mul(float4(transformedPos),gWorldViewProj_Light);
	//Hint: use the previously made shaders PosNormTex3D_Shadow and PosNormTex3D_Skinned as a guide
	
	return output;
}

float2 texOffset(int u, int v)
{
	//TODO: return offseted value (our shadow map has the following dimensions: 1280 * 720)
	return float2(u,v);
}

float EvaluateShadowMap(float4 lpos)
{
	lpos.xyz = lpos.xyz/lpos.w;
	
	if(lpos.x<-1.0f || lpos.x > 1.0f || lpos.y<-1.0f || lpos.y>1.0f||lpos.z<0.0f || lpos.z>1.0f)
	{
		return 1.0f;
	}
	
	//transform to space coord
	lpos.x = lpos.x/2+0.5;
	lpos.y = lpos.y/-2+0.5;
	
	lpos.z = lpos.z-gShadowMapBias;
	
	float smDepth = gShadowMap.Sample(samLinear,lpos.xy).r;
	
	if(smDepth < lpos.z)
	{
		return 0.5f;
	}
	//TODO: complete
	return 1.0f;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input) : SV_TARGET
{
	float shadowValue = EvaluateShadowMap(input.lPos);

	float4 diffuseColor = gDiffuseMap.Sample( samLinear,input.texCoord );
	float3 color_rgb= diffuseColor.rgb;
	float color_a = diffuseColor.a;
	
	//HalfLambert Diffuse :)
	float diffuseStrength = dot(input.normal, -gLightDirection);
	diffuseStrength = diffuseStrength * 0.5 + 0.5;
	diffuseStrength = saturate(diffuseStrength);
	color_rgb = color_rgb * diffuseStrength;

	return float4( color_rgb * shadowValue, color_a );
}

//--------------------------------------------------------------------------------------
// Technique
//--------------------------------------------------------------------------------------
technique10 Default
{
    pass P0
    {
		SetRasterizerState(NoCulling);
		SetDepthStencilState(EnableDepth, 0);

		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( NULL );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
    }
}

