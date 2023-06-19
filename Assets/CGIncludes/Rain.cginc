#ifndef RAIN_CGINC_INCLUDED
#define RAIN_CGINC_INCLUDED

#include "UnityCG.cginc"

static float rippleFrequency = 4; // Display on every 4th cycle

sampler2D _Rain_Puddle_Map;
sampler2D _Rain_Ripple_Map;
float _Rain_Water_Level;
float _Rain_Intensity;
float _Rain_Min_Height;

void rain(float3 worldPos, float3 worldNormal, float mask, inout half3 Albedo, inout half Metallic, inout half Smoothness)
{
	mask *= saturate(worldPos.y - _Rain_Min_Height); // Fade out puddles within 1 meter of ocean

	// Grab puddle sample
	// A channel is the height of the puddle
	float puddleSample = tex2D(_Rain_Puddle_Map, worldPos.xz / 64).a;
	puddleSample = lerp(1, puddleSample, mask); // Lower (or 0) water height in masked areas
	float puddle = saturate((_Rain_Water_Level - puddleSample) / 0.05) * saturate(worldNormal.y);

	Metallic = puddle * 0.4;
	Smoothness = saturate(puddle * 4);

	// Grab ripple texture
	float3 rippleSample_0 = tex2D(_Rain_Ripple_Map, worldPos.xz / 5);
	// R channel is 0 in the middle, 1 in the outer edge
	float rippleGradient_0 = rippleSample_0.r;
	// G channel prevents all raindrops from occuring at the same time
	float rippleTimeOffset_0 = _Time.y * 1.275 / rippleFrequency + rippleSample_0.g + worldPos.x / 21 + worldPos.z / 12;
	// B channel masks out the areas that have ripples
	float rippleMask_0 = rippleSample_0.b;

	float ripple_0 = (1.0 - saturate(abs(rippleGradient_0 - frac(rippleTimeOffset_0) * rippleFrequency) / 0.05)) * pow(1.0 - rippleGradient_0, 2) * rippleMask_0;
	ripple_0 *= saturate(_Rain_Intensity);

	float3 rippleSample_1 = tex2D(_Rain_Ripple_Map, worldPos.xz / 4 + 70);
	float rippleGradient_1 = rippleSample_1.r;
	float rippleTimeOffset_1 = _Time.y * 1.521 / rippleFrequency + rippleSample_1.g + 0.5 + worldPos.x / 9 - worldPos.z / 17;
	float rippleMask_1 = rippleSample_1.b;

	float ripple_1 = (1.0 - saturate(abs(rippleGradient_1 - frac(rippleTimeOffset_1) * rippleFrequency) / 0.05)) * pow(1.0 - rippleGradient_1, 2) * rippleMask_1;
	ripple_1 *= saturate(_Rain_Intensity - 1);

	float ripple = saturate(ripple_0 + ripple_1) * puddle;

	Albedo = saturate(Albedo + ripple * 0.7);
}

void rainSpecular(float3 worldPos, float3 worldNormal, float mask, inout half3 Albedo, inout half3 Specular, inout half Smoothness)
{
	half Metallic;
	rain(worldPos, worldNormal, mask, Albedo, Metallic, Smoothness);
	Specular = half3(Metallic, Metallic, Metallic);
}

#endif

// Console rain experiment:
//
//sampler2D _Rain_Puddle_Map;
//sampler2D _Rain_Ripple_Map;
//sampler2D _Rain_Drip_Map;
//float _Rain_Water_Level;
//float _Rain_Intensity;
//float _Rain_Drip;
//
//void rainify(float3 worldPos, float3 worldNormal, float3 weather, out float puddle, out float ripple)
//{
//	worldPos.y += _Rain_Drip;
//	worldPos.y /= 8;
//
//	float2 uv_X = worldPos.zy;
//	float2 uv_Y = worldPos.xz;
//	float2 uv_Z = worldPos.xy;
//
//	float4 drip_X = (tex2D(_Rain_Drip_Map, uv_X / 8) + tex2D(_Rain_Drip_Map, uv_X / 2)) / 2;
//	float4 drip_Z = (tex2D(_Rain_Drip_Map, uv_Z / 8) + tex2D(_Rain_Drip_Map, uv_Z / 2)) / 2;
//
//	float3 dripNormal = worldNormal;
//	dripNormal.y = 0;
//	dripNormal = normalize(dripNormal);
//
//	float3 dripBlend = pow(abs(dripNormal), 2);
//	dripBlend = normalize(dripBlend);
//
//	float drip = (_Rain_Intensity / 6) * (dripBlend.x * drip_X + dripBlend.z * drip_Z);
//	drip *= saturate((worldNormal.y + 0.1) * 10) * weather.g; // (1.0 - pow(abs(worldNormal.y), 3)) 
//	drip = saturate(drip);
//
//	float rain = lerp(drip, _Rain_Water_Level, max(_Rain_Water_Level, 1.0 - weather.r));
//	float height = tex2D(_Rain_Puddle_Map, uv_Y / 24);
//	float blend = saturate((rain - height) / 0.05) * saturate(worldNormal.y) * weather.g;
//
//	float4 ripple0 = tex2D(_Rain_Ripple_Map, uv_Y / 1.5);
//	float4 ripple1 = tex2D(_Rain_Ripple_Map, uv_Y / 1.5 + 0.47);
//	float4 ripple2 = tex2D(_Rain_Ripple_Map, uv_Y / 2 + 0.33);
//	float4 ripple3 = tex2D(_Rain_Ripple_Map, uv_Y / 2 + 0.1);
//	float4 ripple4 = tex2D(_Rain_Ripple_Map, uv_Y / 2.5 + 0.64);
//	float4 ripple5 = tex2D(_Rain_Ripple_Map, uv_Y / 2.5 + 0.47);
//
//	float ripple0mask = frac(saturate((ripple0.b - frac(_Time.y / 3.9)) * 10));
//	float ripple0state = (1.0 - saturate(abs(ripple0mask - ripple0.g) / 0.25)) * ripple0.r;
//	ripple0mask *= saturate(_Rain_Intensity);
//
//	float ripple1mask = frac(saturate((ripple1.b - frac(_Time.y / 4.1 + 0.333)) * 10));
//	float ripple1state = (1.0 - saturate(abs(ripple1mask - ripple1.g) / 0.25)) * ripple1.r;
//	ripple1mask *= saturate(_Rain_Intensity - 1);
//
//	float ripple2mask = frac(saturate((ripple2.b - frac(_Time.y / 3.95 + 0.667)) * 10));
//	float ripple2state = (1.0 - saturate(abs(ripple2mask - ripple2.g) / 0.25)) * ripple2.r;
//	ripple2mask *= saturate(_Rain_Intensity - 2);
//
//	float ripple3mask = frac(saturate((ripple3.b - frac(_Time.y / 4.05 + 0.175)) * 10));
//	float ripple3state = (1.0 - saturate(abs(ripple3mask - ripple3.g) / 0.25)) * ripple3.r;
//	ripple3mask *= saturate(_Rain_Intensity - 3);
//
//	float ripple4mask = frac(saturate((ripple4.b - frac(_Time.y / 3.37 + 0.472)) * 10));
//	float ripple4state = (1.0 - saturate(abs(ripple4mask - ripple4.g) / 0.25)) * ripple4.r;
//	ripple4mask *= saturate(_Rain_Intensity - 4);
//
//	float ripple5mask = frac(saturate((ripple5.b - frac(_Time.y / 4.67 + 0.893)) * 10));
//	float ripple5state = (1.0 - saturate(abs(ripple5mask - ripple5.g) / 0.25)) * ripple5.r;
//	ripple5mask *= saturate(_Rain_Intensity - 5);
//
//	float shine = blend * saturate(ripple0mask * ripple0state + ripple1mask * ripple1state + ripple2mask * ripple2state + ripple3mask * ripple3state + ripple4mask * ripple4state + ripple5mask * ripple5state);
//	blend += drip;
//
//	puddle = blend;
//	ripple = shine;
//}