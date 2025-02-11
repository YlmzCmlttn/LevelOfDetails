// Upgrade NOTE: commented out 'float3 _WorldSpaceCameraPos', a built-in variable

Shader "Custom/TerrainTessellationShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TessellationUniform ("Tessellation Uniform Factor", Range(1, 32)) = 8
        _MaxTessDistance ("Max Tessellation Distance", Float) = 50.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300
        
        Pass
        {
            CGPROGRAM
            // Target shader model 5.0 for tessellation support.
            #pragma target 5.0
            // Specify the shader stages.
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _TessellationUniform;
            float _MaxTessDistance;
            // _WorldSpaceCameraPos is built in; if needed, declare it:
            // float3 _WorldSpaceCameraPos;

            // Structures for passing data between stages.
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            struct HS_OUTPUT
            {
                float4 pos      : POSITION;
                float2 uv       : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            // Vertex Shader: Compute world-space position and clip-space position.
            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos4 = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos4.xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // ***** PATCH CONSTANT FUNCTION DEFINITION *****
            // This function calculates tessellation factors for each patch.
            float4 PatchConstantFunction (InputPatch<v2f, 3> patch)
            {
                // Compute the center of the triangle patch in world space.
                float3 center = (patch[0].worldPos + patch[1].worldPos + patch[2].worldPos) / 3.0;
                // Compute distance from the patch center to the camera.
                float dist = distance(center, _WorldSpaceCameraPos);
                // Interpolate tessellation factor: high tessellation when close, low when far.
                float tessFactor = lerp(_TessellationUniform, 1.0, saturate(dist / _MaxTessDistance));
                // Return the same factor for all edges and the interior.
                return float4(tessFactor, tessFactor, tessFactor, tessFactor);
            }
            // ***********************************************

            // Hull Shader with required attributes.
            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [outputcontrolpoints(3)]
            [patchconstantfunc(PatchConstantFunction)]
            HS_OUTPUT hull (InputPatch<v2f, 3> patch, uint i : SV_OutputControlPointID)
            {
                HS_OUTPUT output;
                output.pos = patch[i].pos;
                output.uv = patch[i].uv;
                output.worldPos = patch[i].worldPos;
                return output;
            }

            // Domain Shader: Interpolates the control points using barycentrics.
            [domain("tri")]
            v2f domain (const OutputPatch<HS_OUTPUT, 3> patch, float3 bary : SV_DomainLocation)
            {
                v2f o;
                // Interpolate world-space position.
                o.worldPos = patch[0].worldPos * bary.x +
                             patch[1].worldPos * bary.y +
                             patch[2].worldPos * bary.z;
                // Interpolate UV coordinates.
                o.uv = patch[0].uv * bary.x +
                       patch[1].uv * bary.y +
                       patch[2].uv * bary.z;
                // Compute clip-space position from the interpolated world position.
                o.pos = UnityObjectToClipPos(float4(o.worldPos, 1.0));
                return o;
            }

            // Fragment Shader: For debugging, output a solid red color.
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(1.0, 0.0, 0.0, 1.0);
            }
            ENDCG
        }
    }
}
