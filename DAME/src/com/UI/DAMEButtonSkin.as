package com.UI 
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import mx.controls.ButtonBar;
	import mx.controls.buttonBarClasses.ButtonBarButton;
	import mx.skins.ProgrammaticSkin;
	import com.UI.ButtonExt;
	/**
	 * ...
	 * @author ...
	 */
	public class DAMEButtonSkin extends ProgrammaticSkin 
	{
		public var borderAlwaysOn:Boolean = false;
		
		// Constructor.
		public function DAMEButtonSkin() 
		{
			super();
		}

		override protected function updateDisplayList(width:Number, height:Number):void 
		{
			super.updateDisplayList(width, height);
			var drawBox:Boolean = false;
			var drawDownIcon:Boolean = false;
			var disabled:Boolean = false;
			var lineThickness:uint = 1;
			
			borderAlwaysOn = getStyle("borderAlwaysOn");
			
			switch (name) 
			{
				case "upSkin":
					break;
					
				case "selectedDownSkin":
				case "downSkin":
					lineThickness = 2;
				case "selectedOverSkin":
				case "overSkin":
					drawBox = true;
					drawDownIcon = true;
					break;
					
				case "selectedUpSkin":
					drawBox = true;
					drawDownIcon = true;
					break;

				case "selectedDisabledSkin":
					drawDownIcon = true;
					disabled = true;
					break;

				case "disabledSkin":
					disabled = true;
					break;
			}
			graphics.clear();

			if ( drawBox )
			{
				graphics.lineStyle(lineThickness, 0, 0.4, true);
				drawRoundRect(0, 0, width, height, 3, 0x00000000, 0);
				
				var halfHeight:Number = height * 0.6;
				
				graphics.lineStyle(0, 0, 0);
				graphics.beginFill(0xffffff, 0.3);
				graphics.drawRect(0, 0, width, halfHeight);
				graphics.endFill();
				
				graphics.beginFill(0x000000, 0.1);
				graphics.drawRect(0, halfHeight, width, height - halfHeight);
				graphics.endFill();
			}
			else if ( borderAlwaysOn )
			{
				graphics.lineStyle(lineThickness, 0, 0.4, true);
				drawRoundRect(0, 0, width, height, 0, 0x00000000, 0);
			}
			
			var button:ButtonExt = parent as ButtonExt;
			if ( button )
			{
				var upSkin:BitmapData = button.upSkinBitmap;
				var downSkin:BitmapData = button.downSkinBitmap;
				graphics.lineStyle(0, 0, 0);
				
				//bgImg.bitmapData = new upSkin().bitmapData;
				if ( downSkin && drawDownIcon )
				{
					drawIcon(downSkin, width, height, true, true);
				}
				else if ( upSkin && !drawDownIcon )
				{
					drawIcon(upSkin, width, height, true, true);
				}
			}
			else
			{
				/*var buttonBarButton:ButtonBarButton = parent as ButtonBarButton;
				if ( buttonBarButton )
				{
					var buttonBar:ButtonBar = buttonBarButton.parent as ButtonBar;
					if ( buttonBar )
					{
						for ( var i:uint = 0; i < buttonBar.dataProvider.length; i++ )
						{
							var obj:Object = buttonBar.dataProvider[i];
							if ( obj.hasOwnProperty("label") && obj.label == buttonBarButton.label )
							{
								if ( drawDownIcon && obj.hasOwnProperty("highlightSkin") )
								{
									drawIcon(new obj.highlightSkin().bitmapData, width, height, false);
								}
								else if ( !drawDownIcon && obj.hasOwnProperty("defaultSkin") )
								{
									drawIcon(new obj.defaultSkin().bitmapData, width, height, false);
								}
							}
						}
					}
				}*/
			}
		}
		
		private function drawIcon(bitmap:BitmapData, width:Number, height:Number, centre:Boolean, drawOutline:Boolean ):void
		{
			var xdiff:int = (width - bitmap.width);
			var ydiff:int = (height - bitmap.height);
			var mat:Matrix = new Matrix;
			mat.translate(xdiff / 2, ydiff / 2);
			/*if ( drawOutline )
			{
				graphics.lineStyle(1, 0, 1);
			}
			else
			{
				graphics.lineStyle(0, 0, 0);
			}*/
			//graphics.drawRect(0, 0, width, height);
			graphics.beginBitmapFill(bitmap,mat,false);
			drawRoundRect(xdiff/2,ydiff/2,width-xdiff,height-ydiff);
			graphics.endFill();
		}
	}

}