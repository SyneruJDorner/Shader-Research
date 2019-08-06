float3 DecodeViewNormalStereo(float4 enc4)
{
	float kScale = 1.7777;
	float3 nn = enc4.xyz * float3(2 * kScale, 2 * kScale, 0) + float3(-kScale, -kScale, 1);
	float g = 2.0 / dot(nn.xyz, nn.xyz);
	float3 n;
	n.xy = g * nn.xy;
	n.z = g - 1;
	return n;
}

float3 DecodeNormal(float4 enc)
{
	return DecodeViewNormalStereo(enc);
}

void Outline_float(float4 ScreenPos, float Scale, float DepthThreshold, float NormalThreshold, float2 Texel, Texture2D DepthNormalsTexture, Texture2D DepthTexture, SamplerState Sampler, out float Out)
{
	float halfScaleFloor = floor(Scale * 0.5);
	float halfScaleCeil = ceil(Scale * 0.5);

	float2 bottomLeftUV = ScreenPos.xy - float2(Texel.x, Texel.y) * halfScaleFloor;
	float2 topRightUV = ScreenPos.xy + float2(Texel.x, Texel.y) * halfScaleCeil;
	float2 bottomRightUV = ScreenPos.xy + float2(Texel.x * halfScaleCeil, -Texel.y * halfScaleFloor);
	float2 topLeftUV = ScreenPos.xy + float2(-Texel.x * halfScaleFloor, Texel.y * halfScaleCeil);

	// Depth from DepthTexture
	float depth0 = SAMPLE_TEXTURE2D(DepthTexture, Sampler, bottomLeftUV).r;
	float depth1 = SAMPLE_TEXTURE2D(DepthTexture, Sampler, topRightUV).r;
	float depth2 = SAMPLE_TEXTURE2D(DepthTexture, Sampler, bottomRightUV).r;
	float depth3 = SAMPLE_TEXTURE2D(DepthTexture, Sampler, bottomLeftUV).r;

	float depthFiniteDifference0 = depth1 - depth0;
	float depthFiniteDifference1 = depth3 - depth2;

	float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;

	float newDepthThreshold = DepthThreshold * depth0;
	edgeDepth = edgeDepth > newDepthThreshold ? 1 : 0;


	// Normals extracted from DepthNormalsTexture
	float3 normal0 = DecodeNormal(SAMPLE_TEXTURE2D(DepthNormalsTexture, Sampler, bottomLeftUV));
	float3 normal1 = DecodeNormal(SAMPLE_TEXTURE2D(DepthNormalsTexture, Sampler, topRightUV));
	float3 normal2 = DecodeNormal(SAMPLE_TEXTURE2D(DepthNormalsTexture, Sampler, bottomRightUV));
	float3 normal3 = DecodeNormal(SAMPLE_TEXTURE2D(DepthNormalsTexture, Sampler, topLeftUV));

	float3 normalFiniteDifference0 = normal1 - normal0;
	float3 normalFiniteDifference1 = normal3 - normal2;

	float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
	edgeNormal = edgeNormal > NormalThreshold ? 1 : 0;


	// Combined
	float edge = max(edgeDepth, edgeNormal);

	Out = edge;
}