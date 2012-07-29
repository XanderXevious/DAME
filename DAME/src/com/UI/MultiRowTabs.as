package com.UI {
	import com.UI.Docking.DockablePage;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.containers.ViewStack;
	import mx.skins.halo.TabSkin;
	
	public class MultiRowTabs extends Canvas {
		
		public var dp:ArrayCollection;
		public var myViewStack:ViewStack;
		public var tabsPerRow:Number = 4;
		public var rowHeight:Number = 22;
		public var tabRows:Array = new Array();
		private var buttonArray:ArrayCollection;
		
		public static var Tabs:MultiRowTabs = null;
		 
		public function MultiRowTabs()
		{
			super();
			this.percentWidth=100;
			this.setStyle("paddingTop", 0);
			this.setStyle("paddingBottom", 0);
			this.setStyle("paddingLeft", 0);
			this.setStyle("paddingRight", 0);
			Tabs = this;
		}
		
		private function clickHandler(event:MouseEvent):void
		{
			var splitArray:Array = event.target.data.split("|");
			var myRowNumber:Number = Number(splitArray[0]);
			var myButtonIndex:Number = Number(splitArray[1]);
			myViewStack.selectedIndex = myButtonIndex;
			
			for (var i:Number = 0; i < buttonArray.length; i++)
			{
				buttonArray[i].selected = false;
			}
			event.target.selected = true;
			var currentY:Number = 0;
			
			for (var j:Number = 0; j < tabRows.length; j++)
			{
				if (myRowNumber != j)
				{
					tabRows[j].y = currentY;
					currentY = currentY + rowHeight;
				}
			}
			tabRows[myRowNumber].y = currentY;
		}
		
		public function initTabs( _dp:ArrayCollection, _stack:ViewStack):void
		{
			myViewStack = _stack;
			dp = _dp;
			this.removeAllChildren();
			buttonArray = new ArrayCollection();
			var start:Number = 0;
			var end:Number = Math.min(tabsPerRow, this.dp.length);
			var currentY:Number = 0;
			
			for (var i:Number = 0; i < this.dp.length / tabsPerRow; i++) {
				tabRows[i] = new HBox();
				tabRows[i].percentWidth = 100;
				tabRows[i].setStyle("paddingTop", 0);
				tabRows[i].setStyle("paddingBottom", 0);
				tabRows[i].setStyle("horizontalGap", 0);
				tabRows[i].setStyle("verticalGap", 0);
				tabRows[i].y = currentY;
				currentY = currentY + rowHeight;
				this.addChild(tabRows[i]);
				
				for (var j:Number = start; j < end; j++) {
					var button:Button = new Button();
					
					if (this.dp[j].icon != null)
						button.setStyle("icon", this.dp[j].icon);
					
					if (this.dp[j].labelPlacement != null)
						button.labelPlacement = this.dp[j].labelPlacement;
					button.label = this.dp[j].label;
					button.data = i + "|" + j;
					/*button.setStyle("upSkin", TabSkin);
					button.setStyle("downSkin", TabSkin);
					button.setStyle("overSkin", TabSkin);
					button.setStyle("selectedUpSkin", TabSkin);
					button.setStyle("selectedOverSkin", TabSkin);
					button.setStyle("selectedDownSkin", TabSkin);
					button.setStyle("selectedDisabledSkin", TabSkin);*/
					button.setStyle("color", 0x000000);
					button.percentWidth = 100;
					button.height = rowHeight;
					button.addEventListener(MouseEvent.CLICK, clickHandler);
					
					
					tabRows[i].addChild(button);
					button.selected = false;
					
					if (j == 0)
						button.selected = true;
					buttonArray.addItem(button);
				}
				start = start + tabsPerRow;
				end = end + tabsPerRow;
				
				if (end > this.dp.length) {
					end = this.dp.length;
				}
				var myRowNumber:Number = 0;
				var newCurrentY:Number = 0;
				
				for (var k:Number = 0; k < tabRows.length; k++) {
					if (myRowNumber != k) {
						tabRows[k].y = newCurrentY;
						newCurrentY = newCurrentY + rowHeight;
					}
				}
				tabRows[myRowNumber].y = newCurrentY;
			}
		}
	}
}