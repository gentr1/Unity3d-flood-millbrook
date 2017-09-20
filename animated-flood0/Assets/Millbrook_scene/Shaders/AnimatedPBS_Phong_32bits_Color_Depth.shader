Shader "Custom/AnimatedPBS_Phong_32bits_Color_Depth" {
	Properties {
            _EdgeLength ("Edge length", Range(2,50)) = 5
            _Phong ("Phong Strengh", Range(-1,1)) = 0
            _MainTex ("Base (RGB)", 2D) = "white" {}
            _MOS ("Metallic (R), Occlussion (G), Smoothness (B)", 2D) = "white" {}
            _DispTex ("Disp Texture", 2D) = "gray" {}
			_DispTex2 ("Disp2 Texture", 2D) = "gray" {}
			_DispTex0 ("Disp0 Texture", 2D) = "gray" {}
            _NormalMap ("Normalmap", 2D) = "bump" {}
            _Displacement ("Displacement", Range(0, 1.0)) = 0.3
			_ScaleDisplacement ("Scale Displacement", Range(1, 10.0)) = 1.0
			_Time_t ("Time_t", Range(0, 1.0)) = 0.0
            _DispOffset ("Disp Offset", Range(0, 1)) = 0.5
            _Color ("Color", color) = (1,1,1,0)
            _Metallic ("Metallic", Range(0, 1)) = 0.5
            _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        }
        SubShader {
            Tags { "Queue" = "Transparent" "RenderType"="Transparent" /*"RenderType"="Opaque"*/ }
            LOD 300
            
            CGPROGRAM
            #pragma surface surf Standard addshadow fullforwardshadows vertex:disp tessellate:tessEdge tessphong:_Phong alpha:fade
            #include "FreeTess_Tessellator.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
            };

            float _Phong;
            float _EdgeLength;
            float _Displacement;
			float _ScaleDisplacement;
			float _Time_t;
            float _DispOffset;

            float4 tessEdge (appdata v0, appdata v1, appdata v2)
            {
                return FTSphereProjectionTess (v0.vertex, v1.vertex, v2.vertex, _Displacement, _EdgeLength);
            }

            sampler2D _DispTex;
			sampler2D _DispTex2;
			sampler2D _DispTex0;
            sampler2D _MOS;
            uniform float4 _DispTex_ST;
			//float difference;
            void disp (inout appdata v)
            {
				float myr = tex2Dlod(_DispTex, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).x;
				float myg = tex2Dlod(_DispTex, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).y;
				float myb = tex2Dlod(_DispTex, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).z;
				float mya = tex2Dlod(_DispTex, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).w;
				float myr2 = tex2Dlod(_DispTex2, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).x;
				float myg2 = tex2Dlod(_DispTex2, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).y;
				float myb2 = tex2Dlod(_DispTex2, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).z;
				float mya2 = tex2Dlod(_DispTex2, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).w;
				float myr0 = tex2Dlod(_DispTex2, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).x;
				float myg0 = tex2Dlod(_DispTex0, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).y;
				float myb0 = tex2Dlod(_DispTex0, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).z;
				float mya0 = tex2Dlod(_DispTex0, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).w;
				const float UnpackDownscale = 255.0 / 256.0; 
				const float4 UnpackFactors = UnpackDownscale / float4( 256.0*256.0*256.0,256.0*256.0,256.0,1.0);
				float d = lerp(dot(float4 (myr,myg,myb,mya) ,UnpackFactors),dot(float4 (myr2,myg2,myb2,mya2) ,UnpackFactors),_Time_t) * _Displacement*_ScaleDisplacement;
				//difference = (d- (dot(float4 (myr0,myg0,myb0,mya0) ,UnpackFactors) * _Displacement*_ScaleDisplacement))/( _Displacement*_ScaleDisplacement);
                //float d = tex2Dlod(_DispTex, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).r * _Displacement;
                //d = d * 0.5 - 0.5 +_DispOffset;
				d = d +_DispOffset;
                v.vertex.xyz += v.normal * d;
            }

            struct Input {
                float2 uv_MainTex;
                float2 uv_MOS;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            fixed4 _Color;
            float _Metallic;
            float _Glossiness;

            void surf (Input IN, inout SurfaceOutputStandard o) {
                half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

				
				float4 flood_heigh= lerp(tex2D (_DispTex, IN.uv_MainTex),tex2D (_DispTex2, IN.uv_MainTex),_Time_t)-tex2D (_DispTex0, IN.uv_MainTex);
				const float UnpackDownscale = 255.0 / 256.0; 
				const float4 UnpackFactors = UnpackDownscale / float4( 256.0*256.0*256.0,256.0*256.0,256.0,1.0);
				float diff_color= dot(flood_heigh*100.0 ,UnpackFactors);
				c.r=0.9-((diff_color*10.0)*0.9);
				c.g=0.9-((diff_color*10.0)*0.7);
				c.b=0.9-((diff_color*10.0)*0.2);
				c.a=0.1+((diff_color*10.0)*0.6);
				//c.r=0.8-((flood_heigh*3.0)*0.8);
				//c.g=1.0-((flood_heigh*3.0)*0.7);
				//c.b=1.0-((flood_heigh*3.0)*0.2);
				//c.a=0.4+((flood_heigh*1.0)*0.3);
				//c.r=1.0-((flood_heigh*2.0)*1.0);
				//c.g=1.0-((flood_heigh*2.0)*0.7);
				//c.b=1.0-((flood_heigh*2.0)*0.2);
				//c.a=0.5+((flood_heigh*2.0)*0.3);
				//c.r=1.0-((log2(1.0+flood_heigh+1.)*1.2)*1.0);
				//c.g=1.0-((log2(1.0+flood_heigh+1.)*1.2)*0.7);
				//c.b=1.0-((log2(1.0+flood_heigh+1.)*1.2)*0.2);
				//c.a=0.3+((log2(1.0+flood_heigh+1.)*1.2)*0.4);

				//c.r=(difference);
				//c.r=(difference);
				//c.a=(difference*256.0);
				//c.r=0.3;
				//c.w=0.3;
                half4 mos = tex2D (_MOS, IN.uv_MOS);

                o.Albedo = c.rgb;
                o.Metallic = mos.r * _Metallic;
                o.Smoothness = mos.b *_Glossiness;
                o.Occlusion = mos.g;
                o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
				o.Alpha = c.a;
            }
            ENDCG
        }
        FallBack "Standard"
    }