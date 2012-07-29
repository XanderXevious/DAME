package com.UI.Docking 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import mx.containers.TabNavigator;
	import mx.controls.Button;
	import com.UI.Docking.*;
	import mx.core.Container;
	
	import mx.events.ResizeEvent;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class DockableTabNav extends TabNavigator
	{
		private var clickedTab:Boolean = false;
		private var clickPos:Point = new Point;
		
		private var storedStage:Stage = null;
		
		
		public function DockableTabNav() 
		{
			addEventListener( Event.ENTER_FRAME, waitForStage );
			addEventListener(Event.RESIZE, resizeTabs);
			setStyle("paddingTop",0);
			setStyle("paddingBottom",0);
		}
		
		public function resizeTabs(event:ResizeEvent):void
		{
			// Make tthe last tab spread to the end of the container.
			var totalWidth:uint = 0;
			for ( var i:uint = 0; i < numChildren; i++ )
			{
				var tab:Button = getTabAt(i);
				if ( i + 1 == numChildren )
				{
					tab.width = width - totalWidth;
				}
				else
				{
					tab.width = tab.measuredWidth;
					totalWidth += tab.width;
				}
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
            super.updateDisplayList(unscaledWidth, unscaledHeight);
			resizeTabs(null);
		}
		
		public function AddTabPage( page:Container ):void
		{
			addChildAt(page, numChildren);
			selectedChild = page;
			validateNow();
			var tab:Button = this.getTabAt(numChildren - 1);
			tab.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
			//resizeTabs(null);
		}
		
		private function waitForStage(event:Event):void
		{
			if ( storedStage != stage)
			{
				if ( stage )
				{
					for (var i:int=0; i< numChildren; i++)  
					{  
						var tab:Button = this.getTabAt(i);  
						tab.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
					}
					stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
					stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true );
				}
				if ( storedStage )
				{
					storedStage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
					storedStage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				}
				storedStage = stage;
				resizeTabs(null);
			}
		}
		
		public function PreDelete():void
		{
			var i:int = numChildren;
			while( i-- )
			{  
				var tab:Button = this.getTabAt(i);  
				tab.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				var page:DisplayObject = getChildAt(selectedIndex);
				removeChild(page);
			}
			if ( stage )
			{
				stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			}
		}
		
		private function mouseDown(event:MouseEvent):void
		{
			clickedTab = true;
			clickPos.x = stage.nativeWindow.x + this.x + stage.nativeWindow.stage.mouseX;
			clickPos.y = stage.nativeWindow.y + this.y + stage.nativeWindow.stage.mouseY;
		}
		
		private function mouseUp(event:MouseEvent):void
		{
			clickedTab = false;
		}
		
		private function mouseMove(event:MouseEvent):void
		{
			if ( !clickedTab )
				return;
				
			var x:int = stage.nativeWindow.x + this.x + stage.nativeWindow.stage.mouseX;
			var y:int = stage.nativeWindow.y + this.y + stage.nativeWindow.stage.mouseY;
			
			if ( Math.abs(clickPos.x - x) > 10 || Math.abs(clickPos.y - y) > 7 )
			{
				var window:DockableWindow = App.CreatePopupWindow(DockableWindow, false) as DockableWindow;
				var page:DisplayObject = getChildAt(selectedIndex);
				var tab:Button = getTabAt(selectedIndex);
				window.title = tab.label;
				tab.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown );
				removeChild(page);
				if ( page is DockablePage )
				{
					window.container.addChild( page );
				}
				else
				{
					var dock:DockablePage = new DockablePage();
					dock.addChild(page);
					page.visible = true;
					window.container.addChild( dock );
					dock.percentHeight = 100;
					dock.percentWidth = 100;
				}
				
				var screenMouse:Point = stage.nativeWindow.globalToScreen(new Point(this.x, this.y));
				
				window.Resize();
				window.width = Math.max( page.width, width );
				window.height = Math.max( page.height, height );
				window.nativeWindow.x = screenMouse.x + ( window.nativeWindow.stage.mouseX - ( window.width / 2 ) );
				window.nativeWindow.y = screenMouse.y + ( window.nativeWindow.stage.mouseY - 15 );
				window.SetupDrag( screenMouse.x + window.nativeWindow.stage.mouseX, screenMouse.y + window.nativeWindow.stage.mouseY );
				//window.validateNow();
				window.nativeWindow.startMove();
				
				clickedTab = false;
				
				// When down to 1 page in the tab navigator this tabnav must be removed.
				if ( numChildren == 1 )
				{
					page = getChildAt(0);
					var container:Container = page as Container;
					parent.addChild(page);
					container = parent as Container;
					page.visible = true;
					parent.removeChild(this);
					dock = container as DockablePage;
					if ( dock )
						dock.AdjustTitle();
				}
			}
		}
		
	}

}