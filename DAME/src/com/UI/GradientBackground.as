package com.UI
{
	import mx.skins.ProgrammaticSkin;
	import flash.geom.Matrix;

	public class GradientBackground extends ProgrammaticSkin
	{
		override public function get measuredWidth():Number
		{
			return 20;
		}

		override public function get measuredHeight():Number
		{
			return 20;
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var fillColors:Array = getStyle("fillColors");
			var fillAlphas:Array = getStyle("fillAlphas");
			var fillRatios:Array = getStyle("fillRatios");
			var gradientType:String = getStyle("gradientType");
			var angle:Number = getStyle("angle");
			var focalPointRatio:Number = getStyle("focalPointRatio");
			var borderSidesString:String = getStyle("borderSides");
			var borderSize:uint = getStyle("borderSize");
			var borderColor:uint = getStyle("borderColor");

			// Default values, if styles aren’t defined
			if (fillColors == null)
				fillColors = [0xEEEEEE, 0x999999];

			if (fillAlphas == null)
				fillAlphas = [1, 1];

			if (gradientType == "" || gradientType == null)
				gradientType = "linear";

			if (isNaN(angle))
				angle = 90;

			if (isNaN(focalPointRatio))
				focalPointRatio = 0.5;

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(unscaledWidth, unscaledHeight, angle * Math.PI / 180);

			graphics.beginGradientFill(gradientType, fillColors, fillAlphas, fillRatios, matrix, "pad", "rgb", focalPointRatio);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
			if ( borderSize && borderSidesString && borderSidesString.length)
			{
				borderSidesString.replace(" ", "");
				var borderSides:Array = borderSidesString.split(",");
				graphics.lineStyle(borderSize, borderColor);
				for each( var borderType:String in borderSides )
				{
					switch( borderType )
					{
						case "top":
						graphics.moveTo(0, 0);
						graphics.lineTo(unscaledWidth, 0);
						break;
						case "bottom":
						graphics.moveTo(0, unscaledHeight);
						graphics.lineTo(unscaledWidth, unscaledHeight);
						break;
						case "left":
						graphics.moveTo(0, 0);
						graphics.lineTo(0, unscaledHeight);
						break;
						case "right":
						graphics.moveTo(unscaledWidth, 0);
						graphics.lineTo(unscaledWidth, unscaledHeight);
						break;
					}
					
				}
			}
		}
	}
}