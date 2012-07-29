package com.UI.Docking 
{
	import com.UI.ExtendedDividedBox;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import mx.containers.Box;
	import mx.containers.DividedBox;
	import mx.containers.Canvas;
	import com.Utils.Global;
	import mx.containers.HBox;
	import mx.containers.Panel;
	import mx.controls.Label;
	import mx.core.Container;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class DockablePage extends Panel
	{
		[Embed("../../../../assets/dockTopIcon.png")]private var dockTopIcon:Class;
		[Embed("../../../../assets/dockLeftIcon.png")]private var dockLeftIcon:Class;
		[Embed("../../../../assets/dockRightIcon.png")]private var dockRightIcon:Class;
		[Embed("../../../../assets/dockBottomIcon.png")]private var dockBottomIcon:Class;
		[Embed("../../../../assets/dockCenterIcon.png")]private var dockCenterIcon:Class;
		
		public var dockTopBmp:Bitmap = null;
		public var dockLeftBmp:Bitmap = null;
		public var dockRightBmp:Bitmap = null;
		public var dockBottomBmp:Bitmap = null;
		public var dockCenterBmp:Bitmap = null;
		
		private var uiRef:UIComponent = null;
		
		private var parentDock:DockablePage = null;
		//private var childDocks:Vector.<DockablePage> = new Vector.<DockablePage>;
		private var childDock:DockablePage = null;
		
		private var docksAdded:Boolean = false;
		private var docksVisible:Boolean = true;
		private var highlightBox:Box;
		
		public static const AREA:String = "area";
		public static const CENTER:String = "center";
		public static const TOP:String = "top";
		public static const BOTTOM:String = "bottom";
		public static const LEFT:String = "left";
		public static const RIGHT:String = "right";
		
		private var doneInit:Boolean = false;
		private static var defaultHeaderHeight:int = 0;
		private var titleBarBackground:HBox;
		
		private var clickedBar:Boolean = false;
		private var clickPos:Point = new Point;
		
		public var AllowCenterDock:Boolean = true;
		public var DragBarHidden:Boolean = false;
		
		public function DockablePage() 
		{
			Global.dockManager.RegisterDock(this);
			percentWidth = 100;
			percentHeight = 100;
			
			uiRef = new UIComponent;
			addChild( uiRef );
			
			dockTopBmp = new dockTopIcon;
			dockLeftBmp = new dockLeftIcon;
			dockRightBmp = new dockRightIcon;
			dockBottomBmp = new dockBottomIcon;
			dockCenterBmp = new dockCenterIcon;
			
			highlightBox = new Box;
			highlightBox.alpha = 0.3;
			highlightBox.setStyle("backgroundColor", 0x0000ff);
			highlightBox.visible = false;
			
			uiRef.addChild( highlightBox );
			uiRef.addChild( dockTopBmp );
			uiRef.addChild( dockLeftBmp );
			uiRef.addChild( dockRightBmp );
			uiRef.addChild( dockBottomBmp );
			uiRef.addChild( dockCenterBmp );
			
			uiRef.visible = false;
			
			titleBarBackground = new HBox;
			titleBarBackground.percentWidth = 100;
			titleBarBackground.styleName = "RibbonHeader";
			
			title = "";
			addEventListener( Event.ENTER_FRAME, waitForStage );
			
		}
		
		public function SetTile(name:String):void
		{
			title = name;
		}
		
		private function waitForStage(event:Event):void
		{
			if ( stage )
			{
				var child:Container = GetContents() as Container;
				if ( child )
				{
					title = child.label;
					removeEventListener(Event.ENTER_FRAME, waitForStage);
					stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
					stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove );
					addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				}
			}
		}
		
		protected override function createChildren():void
		{
			super.createChildren();
			rawChildren.addChildAt(titleBarBackground, 0);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
            super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if ( !doneInit )
			{
				defaultHeaderHeight = Math.max(defaultHeaderHeight, titleBar.height);// getStyle("headerHeight");
				//titleBarBackground.move(0, -defaultHeaderHeight);
				doneInit = true;
			}
			
			updateHeaderHeight();
			
			titleBarBackground.visible = titleBar.height > 0;
			titleBarBackground.setActualSize(unscaledWidth - 1, titleBar.height);
			
			
			if ( docksAdded )
			{
				removeChild( uiRef );
				docksAdded = false;
			}
			
			var adjustUI:Boolean = false;
			
			if ( parentDock != parent )
			{
				var oldParentDock:DockablePage = parentDock;
				parentDock = null;
				if ( parent )
				{
					if ( parent is DockablePage)
					{
						parentDock = parent as DockablePage;
					}
					else if ( parent.parent && parent.parent is DockablePage )
					{
						parentDock = parent.parent as DockablePage;
					}
				}
				if( oldParentDock )
				{
					oldParentDock.RegisterChildDock( null );
				}
				if ( parentDock )
				{
					parentDock.RegisterChildDock( this );
					if ( stage )
					{
						stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove );
						stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove );
					}
				}
			}
			
			var child:Container = GetContents() as Container;
			if ( child && child.label != title )
			{
				title = child.label;
			}
			
			if ( childDock )
			{
				return;
			}
			
			updateDockIcons();
			addChild(uiRef);
			docksAdded = true;
		}
		
		public function PreDelete():void
		{
			var child:DisplayObject = GetContents();
			var tabs:DockableTabNav = child as DockableTabNav;
			childDock = null;
			parentDock = null;
			if ( tabs )
			{
				tabs.PreDelete();
			}
			else
			{
				var divider:ExtendedDividedBox = child as ExtendedDividedBox;
				if ( divider )
				{
					divider.PreDelete();
				}
			}
			removeChild( child );
		}
		
		private function updateDockIcons():void
		{
			var xScroll:Number = 0;
			var yScroll:Number = 0;
			var pageWidth:int = unscaledWidth;
			var pageHeight:int = unscaledHeight;
			var testObj:DisplayObjectContainer = this;
			while ( testObj )
			{
				var testContainer:Container = testObj as Container;
				if ( testContainer && (testContainer.maxHorizontalScrollPosition || testContainer.maxVerticalScrollPosition ))
				{
					var max:int;
					var t:Number;
					if ( testContainer.maxHorizontalScrollPosition )
					{
						max = testContainer.maxHorizontalScrollPosition / 2;
						t = testContainer.horizontalScrollPosition / testContainer.maxHorizontalScrollPosition;
						if( testContainer is DockableWindow )
							xScroll = ( Misc.lerp(t, -max, max) ); // maxscroll->0->maxscroll
						else
							xScroll = Misc.lerp(t, 0, testContainer.maxHorizontalScrollPosition );
					}
					if ( testContainer.verticalScrollPosition )
					{
						max = testContainer.maxVerticalScrollPosition / 2;
						t = testContainer.verticalScrollPosition / testContainer.maxVerticalScrollPosition;
						if( testContainer is DockableWindow )
							yScroll = ( Misc.lerp(t, -max, max) ); // maxscroll->0->maxscroll
						else
							yScroll = Misc.lerp(t, 0, testContainer.verticalScrollPosition );
					}
					break;
				}
				testObj = testObj.parent;
			}
			//trace(xScroll + " , " + yScroll);
			var midX:int = ( pageWidth - dockTopBmp.width ) / 2;
			var midY:int = ( pageHeight - dockTopBmp.height ) / 2;
			uiRef.move(xScroll, yScroll);
			dockTopBmp.x = midX;
			dockTopBmp.y = midY - dockTopBmp.height;
			dockLeftBmp.x = midX - dockLeftBmp.width;
			dockLeftBmp.y = midY;
			dockBottomBmp.x = midX;
			dockBottomBmp.y = midY + dockBottomBmp.height;
			dockRightBmp.x = midX + dockRightBmp.width;
			dockRightBmp.y = midY;
			dockCenterBmp.visible = AllowCenterDock;
			dockCenterBmp.x = midX;
			dockCenterBmp.y = midY;
		}
		
		private function mouseDown(event:MouseEvent):void
		{
			if ( !stage )
				return;
			var screenMouse:Point = stage.nativeWindow.globalToScreen(new Point(App.getApp().stage.mouseX, App.getApp().stage.mouseY ));

			if ( titleBarBackground.visible && Misc.IsPosOverObject( titleBarBackground, screenMouse.x, screenMouse.y ) )
			{
				clickPos.x = stage.nativeWindow.x + this.x + stage.nativeWindow.stage.mouseX;
				clickPos.y = stage.nativeWindow.y + this.y + stage.nativeWindow.stage.mouseY;
				clickedBar = true;
				titleBarBackground.styleName = "SelectedRibbonHeader";
			}
		}
		
		private function mouseUp(event:MouseEvent):void
		{
			clickedBar = false;
			titleBarBackground.styleName = "RibbonHeader";
		}
		
		private function mouseMove(event:MouseEvent):void
		{
			if ( !clickedBar )
				return;
				
			var x:int = stage.nativeWindow.x + this.x + stage.nativeWindow.stage.mouseX;
			var y:int = stage.nativeWindow.y + this.y + stage.nativeWindow.stage.mouseY;
			
			if ( Math.abs(clickPos.x - x) > 10 || Math.abs(clickPos.y - y) > 7 )
			{
				var window:DockableWindow = App.CreatePopupWindow(DockableWindow, false) as DockableWindow;
				var page:DisplayObject = GetContents();
				window.title = title;
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
				
				var screenMouse:Point = stage.nativeWindow.globalToScreen(new Point(0,0));
				
				window.Resize();
				window.width = Math.max( page.width, width );
				window.height = Math.max( page.height, height );
				window.nativeWindow.x = screenMouse.x + ( window.nativeWindow.stage.mouseX - ( window.width / 2 ) );
				window.nativeWindow.y = screenMouse.y + ( window.nativeWindow.stage.mouseY - 15 );
				window.SetupDrag( screenMouse.x + window.nativeWindow.stage.mouseX, screenMouse.y + window.nativeWindow.stage.mouseY );
				//window.validateNow();
				//window.SetupDrag( screenMouse.x, screenMouse.y );
				window.nativeWindow.startMove();
				
				clickedBar = false;
				titleBarBackground.styleName = "RibbonHeader";
				
				// Iterate through parents removing all empty DockablePage objects.
				var currentObj:DisplayObjectContainer = this;
				var currentParent:DisplayObjectContainer = parent;
				var levelsSinceLastDock:int = 0;
				while ( currentObj && currentParent )
				{
					if ( currentObj is DockablePage )
					{
						currentParent.removeChild( currentObj );
						if ( currentParent.numChildren )
						{
							// The contents of any sibling dock must become the contents of the parent dock.
							var sibling:DockablePage = currentParent.getChildAt(0) as DockablePage;
							if ( sibling )
							{
								currentObj = currentParent;
								currentParent = currentObj.parent;
								while ( currentObj && currentParent )
								{
									if ( currentParent is DockablePage )
									{
										var newChild:DisplayObject = sibling.GetContents();
										if ( newChild )
										{
											currentParent.removeChild(currentObj);
											currentParent.addChild(newChild);
											dock = currentParent as DockablePage;
											if ( dock )
											{
												dock.AdjustTitle();
												dock.RegisterChildDock(sibling.GetChildDock());
												dock.invalidateDisplayList();
											}
										}
										break;
									}
									currentObj = currentParent;
									currentParent = currentObj.parent;
								}
							}
						}
						break;
					}
					currentObj = currentParent;
					currentParent = currentObj.parent;
				}
			}
		}
		
		private function updateHeaderHeight():void
		{
			if ( DragBarHidden || childDock || (parent && parent.parent && parent.parent is DockableWindow) )
			{
				setStyle("headerHeight", 0);
				titleBar.height = 0;
			}
			else
			{
				var container:Container = GetContents() as Container;
				if ( ! (container is DockableTabNav) )
				{
					setStyle("headerHeight", defaultHeaderHeight);
					titleBar.height = defaultHeaderHeight;
				}
				else
				{
					setStyle("headerHeight", 0);
					titleBar.height = 0;
				}
			}
		}
		
		public function RegisterChildDock( dock:DockablePage ):void
		{
			childDock = dock;
			/*if ( childDocks.indexOf( dock ) == -1 )
			{
				childDocks.push( dock );
			}*/
			updateHeaderHeight();
		}
		
		public function GetChildDock():DockablePage
		{
			return childDock;
		}
		
		public function CanDockInto( dock:DockablePage = null ):Boolean
		{
			return ( childDock == null );
		}
		
		public function ChangeDockVisibility( showDocks:Boolean, location:String ):void
		{
			highlightBox.visible = (location != AREA);
			
			if ( showDocks && !uiRef.visible && docksAdded )
			{
				updateDockIcons();
			}
			uiRef.visible = showDocks;
			
			if ( highlightBox.visible )
			{
				switch( location )
				{
					case TOP:
					highlightBox.width = width;
					highlightBox.height = height / 2;
					highlightBox.x = 0;
					highlightBox.y = 0;
					break;
					
					case BOTTOM:
					highlightBox.width = width;
					highlightBox.height = height / 2;
					highlightBox.x = 0;
					highlightBox.y = height / 2;
					break;
					
					case LEFT:
					highlightBox.width = width / 2;
					highlightBox.height = height;
					highlightBox.x = 0;
					highlightBox.y = 0;
					break;
					
					case RIGHT:
					highlightBox.width = width / 2;
					highlightBox.height = height;
					highlightBox.x = width / 2;
					highlightBox.y = 0;
					break;
					
					case CENTER:
					highlightBox.width = width;
					highlightBox.height = height;
					highlightBox.x = 0;
					highlightBox.y = 0;
					break;
				}
			}
		}
		
		public function GetContents():DisplayObject
		{
			for ( var i:int = 0; i < numChildren; i++ )
			{
				var child:DisplayObject = getChildAt(i);
				if ( child != uiRef )
				{
					return child;
				}
			}
			return null;
		}
		
		public function AdjustTitle():void
		{
			var child:Container = GetContents() as Container;
			if ( child )
			{
				title = child.label;
			}
		}
		
		public function MoveContentsInto(dock:DockablePage, contents:DisplayObject ):void
		{
			dock.AllowCenterDock = AllowCenterDock;
			dock.DragBarHidden = DragBarHidden;
								
			dock.addChild( contents );
		}
		
	}

}