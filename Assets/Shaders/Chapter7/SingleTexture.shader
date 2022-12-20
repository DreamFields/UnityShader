Shader "Unity Shaders Book/Chapter7/Single Texture"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {} // 纹理
        _Gloss ("Gloss", Range(8.0,256)) = 20
        _Specular ("Specular", Color) = (1,1,1,1)
    }
    SubShader
    {
         pass{
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            sampler2D _MainTex;
            // 使用纹理名_ST的方式来声明某个纹理的属性。ST是缩放(scale) 和平移(translation) 的缩写
            // _MainTex_ST.xy存储缩放值，.zw存储偏移值
            float4 _MainTex_ST;


            struct a2v{
                float4 vertex : POSITION; 
                float3 normal : NORMAL; 
                // Unity 会将模型的第一组纹理坐标存储到该变量中
                float4 texcoord : TEXCOORD0;
            };
            
            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                fixed3 worldPos : TEXCOORD1;
                // 在片元着色器中使用该坐标进行纹理采样
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                //将顶点从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //将法线从模型空间转换到世界空间
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                //将顶点从模型空间转换到世界空间
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                //TRANSFORM_TEX在UnityCG.cginc定义：
                // 接收两个参数：顶点纹理坐标，纹理名
                // #define TRANSFORM_TEX(tex, name) (tex.xy * name##_ST.xy + name##_ST.zw)
                // 得到最终的uv坐标
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;            
            }

            fixed4 frag(v2f i):SV_TARGET{
                //使用纹理来采样漫反射值
                // tex2D有两个参数：需要被采样的纹理，float2类型的纹理坐标
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb*_Diffuse.rgb;
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                //世界空间的光线方向
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                //计算漫反射
                fixed3 diffuse = _LightColor0.rbg * albedo * saturate(dot(i.worldNormal,worldLight));
                //计算世界空间的光线反射方向
                fixed3 reflectDir = normalize(reflect(-worldLight,i.worldNormal));
                //得到世界空间的视线方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //计算世界空间的半程方向
                fixed3 halfDir = normalize(worldLight+viewDir);
                //计算高光项
                fixed3 specular = _LightColor0.rbg*_Specular.rgb*pow(saturate(dot(i.worldNormal,halfDir)),_Gloss);
                fixed3 color = ambient + diffuse+specular;
                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
