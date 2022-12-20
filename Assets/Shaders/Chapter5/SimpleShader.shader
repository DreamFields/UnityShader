//声明这个shader的名称和位置
Shader "Unity Shaders Book/Chapter5/Simple Shader"{
	//属性，可以在unity的material面板中显示并直接修改
	Properties {
		_Color ("Color Tint",Color) = (1.0,1.0,1.0,1.0)//这是一个颜色拾取器类型的属性，可以直接在面板上选择颜色
	}
	SubShader{
		Pass{
			//CG代码开始
			CGPROGRAM
			//声明顶点着色器和片元着色器分别是vert函数和frag函数
			#pragma vertex vert
			#pragma fragment frag

			//定义一个颜色拾取器类型的变量，就可以将面板上拾取的颜色直接在代码中使用
			// 注意：CG代码中的变量定义，要与属性中的名称和类型都匹配
			fixed4 _Color;

			// 定义一个结构体，是顶点着色器的输入，Unity根据这些语义来填充这个结构体。
			// 语义实际上就是一个赋给Shader输入和输出的字符串， 这个字符串表达了这个参数的含义。
			// 下面这些语义中的数据来源：在Unity中， 每帧调用Draw Call的时候，这些数据是由使用该材质的Mesh Render 组件提供。
			struct a2v{
				// POSITION语义告诉Unity, 用模型空间的顶点坐标填充vertex变量
				float4 vertex : POSITION;
				// NORMAL语义告诉Unity, 用模型空间的法线方向填充normal变量
				float3 normal : NORMAL;
				// TEXCOORDO语义告诉Unity, 用模型的第一套纹理坐标填充texcoord变量
				float4 texcoord : TEXCOORD0;
			};

			//定义一个结构体，是顶点着色器向片元着色器传递的值，即定义顶点着色器的输出
      // !顶点着色器的输出结构中， 必须包含一个变量，它的语义是SV_POSITION
			struct v2f{
        // SV_POSITION 将告诉Unity,顶点着色器的输出是裁剪空间中的顶点坐标
				float4 pos : SV_POSITION;
				fixed3 color : COLOR0;
			};

			//顶点着色器，逐顶点执行，输入是一个a2v的结构体，输出是一个v2f的结构体，输出给片元着色器
			v2f vert(a2v v){
				v2f o;
				// 使用v.vertex来访问模型空间的顶点坐标
				o.pos = UnityObjectToClipPos(v.vertex);
				// v.normal包含了顶点的法线方向， 其分量范围在[-1.0, 1.0]
        // 而存储到o.color中时，将v.normal映射到了[0.0,1.0]
				o.color = v.normal * 0.5 + fixed3(0.5,0.5,0.5);
				return o;
			}

			//片元着色器，逐片元执行。输入是顶点着色器输出的v2f的结构体，输出是一个fixed4类型的变量，输出到renderTarget中
      // SV_Target 也是HLSL 中的一个系统语义，它等同于告诉渲染器，把用户的输出颜色存储到一个渲染目标(render target) 中
			// 片元着色器中的输入实际上是把顶点着色器的输出进行插值后得到的结果。
      fixed4 frag(v2f i) : SV_Target{
				fixed3 c = i.color;
				c*= _Color.rgb;
				return fixed4(c,1.0);
			}
			//CG代码结束
			ENDCG
		}
	}
}