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
            #pragma fragment frag

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
                // float3x3(a,b,c)按照行来填充的
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);

                // 把世界空间的光照方向和视线方向转换到切线空间
                o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));
                return o;
            }
            fixed4 frag(v2f i) : SV_Target {
                //采样得到切线空间的光照方向和视线方向 
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                
                // 采样法线纹理，得到的是法线经过映射后的像素值，需要反映射回来
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);

                fixed3 tangentNormal;
                // 如果在Unity里没有把法线纹理类型设置为"Normal map"，需要在代码中计算tangentNormal
                //tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                //tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                // 如果在Unity里把法线纹理类型设置为"Normal map"，直接使用内置函数即可。Unity会根据平台选择不同的纹理压缩方法，就不能使用上面的手动计算tangentNormal了，见7.2.4节
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                // 由于法线是单位矢量，且切线空间z都为正
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
                
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}