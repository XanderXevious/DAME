package com.UI
{
	import flash.display.Sprite;
	
	public class PickerCursor extends Sprite
	{
		public function PickerCursor()
		{
			super();
			
			graphics.lineStyle(2,0x000000,1);
			graphics.drawCircle(0,0,5);
			graphics.endFill();
			graphics.lineStyle(1,0xFFFFFF,1);
			graphics.drawCircle(0,0,4.5);
			
			graphics.lineStyle();
			graphics.beginFill(0xFFFFFF, 0);
			graphics.drawRect(-3, -3, 6, 6);
			graphics.endFill();
		}
	}
}