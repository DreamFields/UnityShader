// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space"{
    Properties {
        _Color ("Color Tink", Color) = (1, 1, 1, 1)
        _MainTex ( "Main Tex" , 2D) = "white" {}
        // 对于法线纹理，用Unity内置的法线纹理"bump"作为默认值
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 用于控制凹凸程度
        _BumpScale ( "Bump Scale", Float) = 1.0
        _Specular ( "Specular", Color) = (1, 1, 1 , 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader{
        Pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragment

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                float4 texcoord:TEXCOORD;
            };

            struct v2f{
                float4 pos: SV_POSITION;
                float4 uv: TEXCOORD;
                float3 lightDir:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // xy 分扯存储了_MainTex 的纹理坐标， 而zw 分量存储了_BumpMap 的纹理坐标
                // （实际上， _MainTex 和_BumpMap 通常会使用同一组纹理坐标，出千减少插值寄存器的使用数目的目的， 我们往往只计算和存储一个纹理坐标即可
                // o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex_ST).xy;
                o.uv.xy = v.texcoord.xy*_MainTex_ST.xy +_MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy*_BumpMap_ST.xy +_BumpMap_ST.zw;




            }

            ENDCG
        }
    }
}