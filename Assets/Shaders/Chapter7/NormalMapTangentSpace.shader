// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space"{
    Properties {
        _Color ("Color Tink", Color) = (1, 1, 1, 1)
        _MainTex ( "Main Tex" , 2D) = "white" {}
        // 对于法线纹理，用Unity内置的法线纹理"bump"作为默认值，bump就对应了模型自带的法线信息
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
            // 使用纹理名_ST的方式来声明某个纹理的属性。ST是缩放(scale) 和平移(translation) 的缩写
            // _MainTex_ST.xy存储缩放值，.zw存储偏移值
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                // 告诉Unity 把顶点的切线方向填充到tangent变量中
                // tangent 的类型是float4, 而非float3,这是因为我们需要使用tangent.w来决定切线空间中的第三个坐标轴——副切线的方向性。
                float4 tangent:TANGENT;
                float4 texcoord:TEXCOORD;
            };

            struct v2f{
                float4 pos: SV_POSITION;
                float4 uv: TEXCOORD;
                // 存储顶点着色器中在切线空间中变换后的光照方向和视角方向
                float3 lightDir:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // （实际上， _MainTex 和_BumpMap 通常会使用同一组纹理坐标，出于减少插值寄存器的使用数目的目的， 我们往往只计算和存储一个纹理坐标即可
                // o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex_ST).xy;
                // xy 分扯存储了_MainTex 的纹理坐标， 而zw 分量存储了_BumpMap 的纹理坐标
                o.uv.xy = v.texcoord.xy*_MainTex_ST.xy +_MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy*_BumpMap_ST.xy +_BumpMap_ST.zw;

                // 切线空间的三个轴在世界空间的坐标表示
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 切线空间的N 
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);// 切线空间的T
                // 在计算副切线时我们使用v.tangent.w 和叉积结果进行相乘，这是因为和切线与法线方向都垂直的方向有两个， 而w 决定了我们选择其中哪一个方向
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;// 切线空间的B
                
                // 如果我们想要把向量从空间 A 变换到空间 B，则需要得到空间 A 的三个基向量在空间 B 下的表示，并把这三个基向量依次按列摆放，再与需要进行变换的列向量相乘即可。
                // 切线空间的三个基向量在世界空间下的表示，并把它们按列摆放，得到的矩阵是切线空间到世界空间的变换矩阵
                // 其转置是世界空间到切线空间的变换矩阵（因为三个向量正交，正交矩阵的逆等于其转置）
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
                return o;
            }

            ENDCG
        }
    }
}