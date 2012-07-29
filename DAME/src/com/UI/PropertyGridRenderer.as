package com.UI 
{
	import com.Properties.PropertyData;
	import flash.events.Event;
	import mx.collections.ArrayCollection;
	import mx.controls.Label;
	import mx.controls.listClasses.*;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PropertyGridRenderer extends Label
	{	 
		//private const POSITIVE_COLOR:uint = 0x000000; // Black
		//private const NEGATIVE_COLOR:uint = 0xFF0000; // Red
		
		
		public function PropertyGridRenderer()
		{
			super();
			//doubleClickEnabled = true;
			//addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick, false, 0, true);
		}
 
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void 
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var propData:PropertyData = data as PropertyData;
			
			var defaultColor:uint = getStyle("defaultColor");
			var changedColor:uint = getStyle("changedColor");
 
			// Grey out values that are defaulted.
			setStyle("color", propData && propData.UsingDefaultValue ? defaultColor : changedColor);
			setStyle("fontWeight", propData ? "normal" : "bold" );
		}
		
		/*private function onDoubleClick(event:MouseEvent):void
		{
			App.CreatePopupWindow(TextEditor, true);
		}*/
	}

}