package com.UI.Tiles 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Tiles.FlxTilemapExt;
	import com.Utils.CustomEvent;
	import com.Utils.Hits;
	import flash.display.BitmapData;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import mx.controls.VScrollBar;
	import minimalcomps.bit101.components.VMinScrollBar;
	import mx.controls.HScrollBar;
	import minimalcomps.bit101.components.HMinScrollBar;
	import mx.core.UIComponent;
	import mx.events.ScrollEvent;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import com.Utils.Global;
	
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileList extends Sprite
	{
		public static const EVENT_TILES_DRAWN:String = "tilesDrawn";

		private var selectionOutline:Shape = new Shape();
		public var gfx:Bitmap;
		
		private var highlightBox:Bitmap;
		private var selectionBox:Bitmap;
		private var eraseTileBox:Bitmap;
		
		protected var sourceRect:Rectangle = new Rectangle( 0, 0, 1, 1);
		protected var _flashPoint:Point = new Point(0,0);
		
		protected var _data:Vector.<TileListData> = new Vector.<TileListData>();
		
		public var ColumnCount:uint = 0;
		
		private var Dirty:Boolean = true;
		public function get _dirty():Boolean { return Dirty; }
		public function set _dirty(doIt:Boolean):void
		{
			Dirty = doIt;
		}
		protected var _dirtyThisFrame:Boolean = true;
		
		protected var _lastMouseX:int;
		protected var _lastMouseY:int;
		
		public var smoothDraw:Boolean = false;
		
		private var menuHighlightCount:int = 0;
		private var menuHighlightIndex:int = -1;
		protected var _highlightIndex:int = -1;
		public function get highlightIndex():int { return _highlightIndex; }
		protected var _selectedIndex:int = 0;
		public function get selectedIndex():int { return _selectedIndex; }
		public function set selectedIndex(newIndex:int):void
		{
			_selectedIndex = Math.min(Math.max(newIndex,0),_data.length);
			_dirty = true;
		}
		
		protected var _clickIndex:int = -1;
		public function get clickIndex():int { return _clickIndex; }
		
		public var modifyTilesCallback:Function = null;
		
		// Turning on/off can fix some problems with the size of the container adjusting for the indent of the scrollbars.
		// It basically makes the container smaller so the scrollbars don't overlap it.
		public var adjustSizeForScrollBars:Boolean = true;
		
		public var autoResizeParents:Boolean = false;
		// This will rearrange the grid to best fit the container if it changes dimensions.
		public var autoRearrange:Boolean = false;
		// Ensures that overall height is maintained and TileHeight is scaled accordingly if the overall area is scaled.
		public var maintainTotalHeight:Boolean = false;
		public var currentResizeRatio:Number = 1;
		
		public var canBeginDrag:Boolean = false;
		public var canAcceptDrop:Boolean = false;
		public var isDraggingOver:Boolean = false;
		protected var wasDraggingOver:Boolean = false;
		
		public var Selectable:Boolean = true;
		
		// Need to know when the mouse is actually over this tilelist so we get the mousepos
		// when it's over the correct window. Issue when using multiple nativewindows.
		private var mouseIsOver:Boolean = false;
		
		private var eraseTileIdx:int = -1;
		
		public var SelectionChanged:Function = null;
		
		private var SelfMadeScrollBars:Boolean = false;
		private var HBarOld:HScrollBar;
		// Using minimalcomps due to a problem when the Flex scroll bars are used in an undocked window.
		// The scrollbars in that case are always highlighted and become undraggable.
		private var HBar:HMinScrollBar = null;
		private var VBar:VMinScrollBar = null;
		private var ScrollContainer:Object = null;
		
		public var CustomData:Object = null;
		public var HasEmptyFirstTile:Boolean = false;
		
		// Draw highlights over certain tiles.
		private var TileHighlights:Vector.<int> = null;
		private var showTileHighlights:Boolean = false;
		public function set ShowTileHighlights(show:Boolean):void
		{
			showTileHighlights = show;
			_dirty = true;
		}
		
		
		// There's a strange issue when dragging. It doesn't update mouseX and mouseY,
		// so I set values from the DraggableTileWrapper which I use instead.
		public var xmouse:int;
		public var ymouse:int;
		protected function get MouseX():int
		{
			if ( isDraggingOver )
			{
				return xmouse;
			}
			else if ( mouseIsOver )
			{
				return mouseX;
			}
			return -1;
		}
		protected function get MouseY():int
		{
			if ( isDraggingOver )
			{
				return ymouse;
			}
			else if ( mouseIsOver )
			{
				return mouseY;
			}
			return -1;
		}
		
		
		private var zoomItem25:NativeMenuItem;
		private var zoomItem50:NativeMenuItem;
		private var zoomItem100:NativeMenuItem;
		private var zoomItem200:NativeMenuItem;
		private var zoomItem400:NativeMenuItem;
		private var zoomItemAutoFit:NativeMenuItem;
		
		private var zoomFactor:Number = 1;
		// Ensure that tiles fit the shortest side to either 1 row or 1 column.
		private var scaleLongestAxis:Boolean = false;
		public var scaleToFit:Boolean = false;
		
		private var scaledTileWidth:uint = 0;
		private var scaledTileHeight:uint = 0;
		
		private var _tileWidth:uint = 0;
		private var _tileHeight:uint = 0;
		
		private var numTilesPerRow:uint = 1;
		public function get NumColumnsDrawn():uint { return numTilesPerRow; }
		private var numRows:uint = 1;
		public function get NumRowsDrawn():uint { return numRows; }
		
		protected var tileOffsetX:Number = 0;
		protected var tileOffsetY:Number = 0;
		protected var tileSpacingX:Number = 1;
		protected var tileSpacingY:Number = 1;
		
		// The drawn dimensions of 1 whole tile.
		protected var tWidth:Number = 0;
		protected var tHeight:Number = 0;
		protected var tOffsetX:int = 0;
		protected var tOffsetY:int = 0;
		protected var tSpacingX:int = 0;
		protected var tSpacingY:int = 0;
		protected var tilesStartY:int = 0;
		protected var tilesStartX:int = 0;
		
		protected var regenBoxes:Boolean = true;
		
		protected var posX:int = 0;
		protected var posY:int = 0;
		
		// The object used to work out the size of the display area.
		public var ContainerObject:Object = null;
		
		public var showInvalidTiles:Boolean = false;
		
		public function set TileWidth(wid:uint):void
		{
			_tileWidth = wid;
			scaledTileWidth = _tileWidth * zoomFactor;
			regenBoxes = true;
		}
		public function get TileWidth():uint { return _tileWidth; }
		
		public function set TileHeight(ht:uint):void
		{
			_tileHeight = ht;
			scaledTileHeight = _tileHeight * zoomFactor;
			regenBoxes = true;
		}
		public function get TileHeight():uint { return _tileHeight; }
		
		
		public function TileList() 
		{
			gfx = new Bitmap();
			addChild(gfx);
			
			eraseTileBox = new Bitmap();
			eraseTileBox.visible = false;
			addChild(eraseTileBox);
			
			highlightBox = new Bitmap();
			highlightBox.visible = false;
			addChild(highlightBox);
			
			selectionBox = new Bitmap();
			selectionBox.visible = false;
			addChild(selectionBox);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame,false,0,true);
			
			addEventListener(MouseEvent.CLICK, mousePressed, false, 0, true);
			
			
			contextMenu = new NativeMenu();
			contextMenu.addEventListener(Event.DISPLAYING, menuActivated, false, 0 , true);	
			var submenu:NativeMenu = new NativeMenu();
			contextMenu.addSubmenu(submenu, "Zoom");
			zoomItem25 = new NativeMenuItem("25%");
			zoomItem25.addEventListener(Event.SELECT, zoomMenuItemHandler,false,0,true);
			submenu.addItem(zoomItem25);
			zoomItem50 = new NativeMenuItem("50%");
			zoomItem50.addEventListener(Event.SELECT, zoomMenuItemHandler,false,0,true);
			submenu.addItem(zoomItem50);
			zoomItem100 = new NativeMenuItem("100%");
			zoomItem100.addEventListener(Event.SELECT, zoomMenuItemHandler,false,0,true);
			zoomItem100.checked = true;
			submenu.addItem(zoomItem100);
			zoomItem200 = new NativeMenuItem("200%");
			zoomItem200.addEventListener(Event.SELECT, zoomMenuItemHandler,false,0,true);
			submenu.addItem(zoomItem200);
			zoomItem400 = new NativeMenuItem("400%");
			zoomItem400.addEventListener(Event.SELECT, zoomMenuItemHandler,false,0,true);
			submenu.addItem(zoomItem400);
			zoomItemAutoFit = new NativeMenuItem("Auto Fit");
			zoomItemAutoFit.addEventListener(Event.SELECT, zoomMenuItemHandler,false,0,true);
			submenu.addItem(zoomItemAutoFit);
			
			submenu = new NativeMenu();
			contextMenu.addSubmenu(submenu, "Insert Blank Tile");
			var item:NativeMenuItem = new NativeMenuItem("Before Highlighted Tile");
			item.addEventListener(Event.SELECT, newTileMenuItemHandler,false,0,true);
			submenu.addItem(item);
			item = new NativeMenuItem("After Highlighted Tile");
			item.addEventListener(Event.SELECT, newTileMenuItemHandler,false,0,true);
			submenu.addItem(item);
			
			submenu = new NativeMenu();
			contextMenu.addSubmenu(submenu, "Insert Copy");
			item = new NativeMenuItem("Before Highlighted Tile");
			submenu.addItem(item);
			item.addEventListener(Event.SELECT, copyTileMenuItemHandler,false,0,true);
			item = new NativeMenuItem("After Highlighted Tile");
			submenu.addItem(item);
			item.addEventListener(Event.SELECT, copyTileMenuItemHandler, false, 0, true);
			item = new NativeMenuItem("Into Highlighted Tile");
			submenu.addItem(item);
			item.addEventListener(Event.SELECT, copyTileMenuItemHandler, false, 0, true);
			
			item = new NativeMenuItem("Swap With Highlighted Tile");
			contextMenu.addItem(item);
			item.addEventListener(Event.SELECT, tileMenuItemHandler,false,0,true);
			
			item = new NativeMenuItem("Highlight Current Tile");
			item.addEventListener(Event.SELECT, tileMenuItemHandler,false,0,true);
			contextMenu.addItem(item);
			
			item = new NativeMenuItem("Set As Erase Tile");
			item.addEventListener(Event.SELECT, tileMenuItemHandler,false,0,true);
			contextMenu.addItem(item);
			
			item = new NativeMenuItem("Delete Selected Tile");
			item.addEventListener(Event.SELECT, tileMenuItemHandler,false,0,true);
			contextMenu.addItem(item);
			
			item = new NativeMenuItem("Edit Raw Image Data");
			item.addEventListener(Event.SELECT, tileMenuItemHandler,false,0,true);
			contextMenu.addItem(item);
			
			item = new NativeMenuItem("Reload Image File");
			item.addEventListener(Event.SELECT, tileMenuItemHandler,false,0,true);
			contextMenu.addItem(item);
			
			addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut,false,0,true);
			addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver,false,0,true);
		}
		
		private function handleMouseOut(event:MouseEvent):void
		{
			mouseIsOver = false;
		}
		
		private function handleMouseOver(event:MouseEvent):void
		{
			mouseIsOver = true;
		}
		
		public function menuActivated(event:Event):void
		{
			menuHighlightCount = 2;
			_clickIndex = menuHighlightIndex = GetTileIndexAtCursor();
			_dirty = true;
		}
		
		public function getZoomPercentString():String
		{
			return scaleLongestAxis ? "Auto Fit" : (zoomFactor * 100) + "%";
		}
		
		public function setZoomPercent(percent:String):void
		{			
			switch( percent )
			{
				case "25%":
				zoomItem25.checked = true;
				zoomItem50.checked = false;
				zoomItem100.checked = false;
				zoomItem200.checked = false;
				zoomItem400.checked = false;
				zoomItemAutoFit.checked = false;
				scaleLongestAxis = false;
				zoomFactor = 0.25;
				break;
				
				case "50%":
				zoomItem25.checked = false;
				zoomItem50.checked = true;
				zoomItem100.checked = false;
				zoomItem200.checked = false;
				zoomItem400.checked = false;
				zoomItemAutoFit.checked = false;
				scaleLongestAxis = false;
				zoomFactor = 0.5;
				break;
				
				case "100%":
				zoomItem25.checked = false;
				zoomItem50.checked = false;
				zoomItem100.checked = true;
				zoomItem200.checked = false;
				zoomItem400.checked = false;
				zoomItemAutoFit.checked = false;
				scaleLongestAxis = false;
				zoomFactor = 1;
				break;
				
				case "200%":
				zoomItem25.checked = false;
				zoomItem50.checked = false;
				zoomItem100.checked = false;
				zoomItem200.checked = true;
				zoomItem400.checked = false;
				zoomItemAutoFit.checked = false;
				scaleLongestAxis = false;
				zoomFactor = 2;
				break;
				
				case "400%":
				zoomItem25.checked = false;
				zoomItem50.checked = false;
				zoomItem100.checked = false;
				zoomItem200.checked = false;
				zoomItem400.checked = true;
				zoomItemAutoFit.checked = false;
				scaleLongestAxis = false;
				zoomFactor = 4;
				break;
				
				case "Auto Fit":
				zoomItem25.checked = false;
				zoomItem50.checked = false;
				zoomItem100.checked = false;
				zoomItem200.checked = false;
				zoomItem400.checked = false;
				zoomItemAutoFit.checked = true;
				scaleLongestAxis = true;
				zoomFactor = 1;
				break;
			}
			posX = posY = 0;
			scaledTileWidth = _tileWidth * zoomFactor;
			scaledTileHeight = _tileHeight * zoomFactor;
			_dirty = true;
		}
		
		private function zoomMenuItemHandler(event:Event):void
		{			
			setZoomPercent( event.target.label );
		}
		
		private function newTileMenuItemHandler(event:Event):void
		{
			switch( event.target.label )
			{
				case "Before Highlighted Tile":
				if ( modifyTilesCallback != null )
				{
					modifyTilesCallback( true, false, false, true, false, false);
				}
				break;
				
				case "After Highlighted Tile":
				if ( modifyTilesCallback != null )
				{
					modifyTilesCallback( true, false, false, false, false, false);
				}
				break;
				
				
			}
			_dirty = true;
		}
		
		private function copyTileMenuItemHandler(event:Event):void
		{			
			switch( event.target.label )
			{
				case "Before Highlighted Tile":
				if ( modifyTilesCallback != null )
				{
					modifyTilesCallback( false, true, false, true, false, false);
				}
				break;
				
				case "After Highlighted Tile":
				if ( modifyTilesCallback != null )
				{
					modifyTilesCallback( false, true, false, false, false, false);
				}
				break;
				
				case "Into Highlighted Tile":
				if ( modifyTilesCallback != null )
				{
					modifyTilesCallback( false, true, false, false, true, false);
				}
				break;
			}
			_dirty = true;
		}
		
		private function tileMenuItemHandler(event:Event):void
		{			
			switch( event.target.label )
			{
				case "Swap With Highlighted Tile":
				if ( modifyTilesCallback != null )
				{
					modifyTilesCallback( false, false, false, false, false, true);
				}
				break;
				
				case "Highlight Current Tile":
				event.target.checked = !event.target.checked;
				EditorType.HighlightCurrentTile = event.target.checked;
				_dirty = true;
				break;
				
				case "Delete Selected Tile":
				if ( modifyTilesCallback != null && selectedIndex != -1)
				{
					modifyTilesCallback( false, false, true, false, false, false);
					_dirty = true;
				}
				break;
				
				case "Edit Raw Image Data":
				App.getApp().ShowTilemapImageViewer();
				break;
				
				case "Set As Erase Tile":
				EditorState.SetCurrentLayerEraseTileIdx(clickIndex);
				break;
				
				case "Reload Image File":
				EditorState.ReloadCurrentTileset();
				break;
			}
			
		}
		
		public function OnPreDragDrop():void { }
		public function OnDragDrop():void { }

		protected function onEnterFrame(event:Event):void
		{
			_dirtyThisFrame = _dirty;
			UpdateSelfScrollBars();
			
			if ( _dirtyThisFrame || MouseX != _lastMouseX || MouseY != _lastMouseY )
			{
				var newHighlightIndex:int = GetTileIndexAtCursor();
				if ( newHighlightIndex == -1 )
				{
					newHighlightIndex = menuHighlightIndex;
				}
				else
				{
					menuHighlightCount--;
					if( menuHighlightCount == 0)
						menuHighlightIndex = -1;
				}
				if ( newHighlightIndex != -1)
				{
					// Mouse is over the tile list.
					_dirty = true;
				}
				else
				{
					// Mouse not over the tile list.
					if ( _highlightIndex != -1 )
					{
						if ( _highlightIndex != _selectedIndex )
						{
							_dirty = true;
						}
						newHighlightIndex = -1;
					}
				}
				_highlightIndex = newHighlightIndex;
				_lastMouseX = MouseX;
				_lastMouseY = MouseY;
			}
			
			// Try to rearrange the tiles so they fit in the panel only when the width of the panel changes.
			if ( autoRearrange )
			{
				if ( ContainerObject )
				{
					var rowWidth:int = ColumnCount * _tileWidth;
					var widthDiff:int = ( ContainerObject.width / zoomFactor )- rowWidth;
					if ( widthDiff > _tileWidth || widthDiff < -1 )
					{
						var newColumnCount:uint = Math.max( 1, Math.floor( (ContainerObject.width - 2) / scaledTileWidth) );
						if ( newColumnCount != ColumnCount )
						{
							ColumnCount = newColumnCount;
							_dirty = true;
						}
					}
				}
			}
			
			// As we only draw enough to fit in the canvas we need to redraw any time the canvas changes size.
			if ( !_dirty && ContainerObject && gfx.bitmapData )
			{
				var desiredHeight:uint = ContainerObject.height;
				var desiredWidth:uint = ContainerObject.width;
				if ( VBar )
				{
					desiredWidth -= VBar.width;
				}
				if ( desiredWidth != gfx.bitmapData.width || desiredHeight != gfx.bitmapData.height )
				{
					_dirty = true;
				}
			}
			
			if ( _dirty )
			{
				_dirtyThisFrame = true;
				_dirty = false;
				
				renderTiles();
			}
			wasDraggingOver = isDraggingOver;
			
		}
		
		protected function mousePressed(event:MouseEvent):void
		{
			var newClickIndex:int = GetTileIndexAtCursor();
			if ( newClickIndex != _selectedIndex )
			{
				_selectedIndex = newClickIndex;
				if ( SelectionChanged != null )
				{
					SelectionChanged();
				}
				_dirty = true;
			}
		}
		
		public function insertTile( bitmapData:BitmapData, _metadata:Object, index:uint ):void
		{
			_data.splice( index, 0, { icon:bitmapData, metadata:_metadata } );
			_dirty = true;
		}
		
		public function pushTile( bitmapData:BitmapData, _metadata:Object ):void
		{
			var obj:TileListData = new TileListData( bitmapData, _metadata );
			if ( showInvalidTiles )
			{
				obj.valid = true;
			}
			_data.push( obj );
			_dirty = true;
		}
		
		public function SetTileUnderCursor( bitmapData:BitmapData, _metadata:Object ):void
		{
			var index:int = GetTileIndexAtCursor();
			if ( index == -1)
			{
				return;
			}
			_data[index] = new TileListData(bitmapData, _metadata );
			_dirty = true;
		}
		
		public function removeTileByIndex( index:uint ):Boolean
		{
			if ( index < _data.length )
			{
				_data.splice( index, 1 );
			}
			_dirty = true;
			return true;
		}
		
		public function removeTileByMetadata( metadata:Object, removeMultiples:Boolean ):Boolean
		{
			var i:uint = 0;
			var removed:Boolean = false;
			for ( i = 0; i < _data.length; i++ )
			{
				if ( _data[i].metadata == metadata )
				{
					_data.splice( i, 1 );
					if ( !removeMultiples )
					{
						_dirty = true;
						return true;
					}
					removed = true;
					i--;
				}
			}
			if ( removed )
			{
				_dirty = true;
			}
			return removed;
		}
		
		public function clearTiles():void
		{
			_data.length = 0;
			_dirty = true;
		}
		
		public function clearTilesMinimal():void
		{
			if ( _data.length )
			{
				_data.length = 1;
				var bmp:BitmapData = _data[0].icon;
				_data[0].icon = new BitmapData(bmp.width, bmp.height, true, 0x00000000);
				_dirty = true;
			}
		}
		
		public function GetTileIndexAtCursor():int
		{
			if ( MouseX < 0 || MouseY < 0 || MouseX >= width || MouseY >= height )
			{
				return -1;
			}
			
			// These are now taken from the rendered data.
			//var numTilesPerRow:uint = ColumnCount == 0 ? _data.length : Math.min( ColumnCount, _data.length );
			//var numRows:uint = ColumnCount == 0 ? 1 : Math.ceil( _data.length / numTilesPerRow );
			
			if ( MouseX > numTilesPerRow * tWidth )
			{
				return -1;
			}
			
			var worldx:int = MouseX + posX;
			var worldy:int = MouseY + posY;
			
			if ( tileOffsetX || tileOffsetY )
			{
				// Get position relative to the start of the tile that equates to x = 0, y = 0
				// Imagine rotating the tilemap so it is normal 2d, and worldx|y should match the top left of the tilemap.
				worldx -= tilesStartX;
				worldy -= ( tilesStartY + (tHeight - tSpacingY) );
				worldx += tOffsetX;
				if ( tileOffsetY > 0 )
				{
					// -ive tileOffset is going up, which means the origin of the map is where the tile is.
					worldy += tOffsetY;
				}
				if ( tileOffsetX > 0 )
				{
					worldx -= tOffsetX;
				}
				
				// Get the right edge of the map
				var endxx:Number = tSpacingX * numTilesPerRow;
				var endxy:Number = tOffsetY * numTilesPerRow;
				
				// Get location on x-axis where world pos lies.
				var pt:FlxPoint = new FlxPoint;
				var intersects:Boolean = Hits.LineRayIntersection(0, 0, endxx, endxy, worldx, worldy, worldx - tOffsetX, worldy - tSpacingY, pt);
				
				if ( !intersects )
				{
					return -1;
				}
				var offX:Number = pt.x;
			
				// Get location on y-axis where world pos lies.
				// This is just the difference between world pos and x-axis intersection
				// Will not work if height differences are 0, ie map is rotated 90 degrees.
				var offY:Number = worldy - pt.y;
				
				var xpos:int = offX / tSpacingX
				var ypos:int = offY / tSpacingY;
				
				intersects = ( offY >= 0 && ypos < numRows );
				
				if ( intersects )
				{
					// Account for the -0,+0 1 tile error on each axis.
					if ( offX < 0 )
						xpos--;
					if ( offY <= 0 )
						ypos--;
					
					if ( xpos >= 0 && xpos < numTilesPerRow && ypos >= 0 && ypos < numRows )
					{
						return ( ypos * numTilesPerRow ) + xpos;
					}
				}
				return -1;
			}
			
			worldy -= ( tHeight - tSpacingY );
			var ix:uint = Math.floor( worldx / tSpacingX );
			var iy:uint = ( worldy < 0 ) ? 0 : Math.floor( worldy / tSpacingY );
			
			var index:uint = (iy * numTilesPerRow ) + ix;
			
			if ( index >= _data.length )
			{
				return -1;
			}
			return index;
		}
		
		public function GetBitmapDataAtIndex( index:int ):BitmapData
		{
			if ( index == -1 || index >= _data.length )
			{
				return null;
			}
			return _data[index].icon;
		}		
		
		private function renderTiles():void
		{	
			if ( _data.length == 0 || !ContainerObject )
			{
				gfx.bitmapData = null;
				/*if ( autoResizeParents )
				{
					parent.width = 1;
					parent.height = 1;
				}*/
				UpdateHBar(false);
				UpdateVBar(false);
				return;
			}
			
			var currentWidth:int = ContainerObject.width;
			var currentHeight:int = ContainerObject.height;
			
			if ( SelfMadeScrollBars && adjustSizeForScrollBars)
			{
				if ( VBar )
				{
					currentWidth -= VBar.width;
				}
				if ( HBar )
				{
					currentHeight -= HBar.height;
				}
			}

			if ( ContainerObject && currentWidth > 0 && currentHeight )
			{
				gfx.bitmapData = new BitmapData( currentWidth, currentHeight,true,0xffffff);
			}
			else
			{
				return;
			}

			var bitmap:BitmapData = gfx.bitmapData;
			
			// Hacky code assuming this is wrapped up in a layer panel in order to resize it.
			if ( autoResizeParents )
			{
				parent.width = currentWidth;
				parent.height = currentHeight;
			}

			tWidth = scaledTileWidth;
			tHeight = scaledTileHeight;
			
			numTilesPerRow = ColumnCount == 0 ? _data.length : Math.min( ColumnCount, _data.length );
			numRows = ColumnCount == 0 ? 1 : Math.ceil( _data.length / numTilesPerRow );
			
			if ( scaleLongestAxis )
			{
				if ( currentWidth < currentHeight )
				{
					numTilesPerRow = 1;
					numRows = _data.length;
					if ( currentWidth > 40 && currentWidth > TileWidth * 1.5 )
					{
						if ( currentWidth > 80 && currentWidth > TileWidth * 3 )
							numTilesPerRow = 3;
						else
							numTilesPerRow = 2;
						numRows = Math.ceil( _data.length / numTilesPerRow )
					}
				}
				else
				{
					numRows = 1;
					numTilesPerRow = _data.length;
					if ( currentHeight > 50 && currentHeight > TileHeight * 2 )
					{
						if ( currentHeight > 100 && currentHeight > TileHeight * 4 )
							numRows = 3;
						else
							numRows = 2;
						numTilesPerRow = Math.ceil( _data.length / numRows )
					}
				}
			}
			if ( maintainTotalHeight )
			{
				numRows = 1;
				numTilesPerRow = _data.length;
			}

			// Calculate the total space on each side as a proportion of 1 tile.
			var totalX:Number = ( numTilesPerRow * tileSpacingX ) + Math.abs( tileOffsetX * numRows );
			var totalY:Number = ( numRows * tileSpacingY ) + Math.abs( tileOffsetY * numTilesPerRow );
			if ( tileOffsetX && tileOffsetY )
			{
				totalX += 1 - ( 2 * tileSpacingX );
				totalY += 1 - ( 2 * tileSpacingY );
			}
			else if ( !tileOffsetX && !tileOffsetY )
			{
				totalX += 1 - tileSpacingX;
				totalY += 1 - tileSpacingY;
			}
			
			if ( scaleLongestAxis )
			{
				if ( currentWidth < currentHeight )
				{
					tWidth = currentWidth / totalX;
					var newScale:Number = tWidth / scaledTileWidth;
					tHeight = scaledTileHeight * newScale;
				}
				else
				{
					tHeight = currentHeight / totalY;
					newScale = tHeight / scaledTileHeight;
					tWidth = scaledTileWidth * newScale;
				}
			}
			else if ( maintainTotalHeight )
			{
				tHeight = currentHeight / totalY;
				newScale = tHeight / scaledTileHeight;
				tWidth = scaledTileWidth * newScale;
			}
			else if ( scaleToFit )
			{
				// The drawn dimensions of 1 whole tile.
				tWidth = bitmap.width / totalX;
				tHeight = bitmap.height / totalY;
			}
			
			// When resizing need to ensure that the scroll pos is within valid bounds.
			posX = Math.max(0, Math.min( posX, ( totalX * tWidth ) - currentWidth ) ) ;
			posY = Math.max(0, Math.min( posY, ( totalY * tHeight ) - currentHeight ) );
			
			tOffsetX = tWidth * tileOffsetX;
			tOffsetY = tHeight * tileOffsetY;
			tSpacingX = tWidth * tileSpacingX;
			tSpacingY = tHeight * tileSpacingY;
		
			tilesStartY = (numTilesPerRow - 1) * -tOffsetY;
			tilesStartX = (numRows - 1) * -tOffsetX;
			
			tilesStartY = Math.max(0, tilesStartY );
			tilesStartX = Math.max(0, tilesStartX );
			
			var storedX:int = _flashPoint.x = tilesStartX - posX;
			var storedY:int = _flashPoint.y = tilesStartY - posY;
			
			//if ( _highlightIndex == -1 )
			{
				highlightBox.visible = false;
			}
			//if ( _selectedIndex == -1 || !Selectable )
			{
				// Only make it visible when it's actually drawn.
				selectionBox.visible = false;
			}
			
			
			if ( regenBoxes )
			{
				// Draw a transparent light blue.
				// Draw a transparent medium blue.
				if ( tileOffsetX || tileOffsetY )
				{
					var shape:Shape = new Shape;
					shape.graphics.lineStyle(1, 0xffffff, 1);
					shape.graphics.beginFill(0xffaa00,0.4);
					FlxTilemapExt.GenerateIsoTileShape(shape, tWidth, tHeight, tOffsetX, tOffsetY, tSpacingX, tSpacingY);
					shape.graphics.endFill();
					highlightBox.bitmapData = new BitmapData( tWidth, tHeight, true, 0 );
					highlightBox.bitmapData.draw(shape);
				}
				else
				{
					highlightBox.bitmapData = new BitmapData( _tileWidth, _tileHeight, true, 0x44ffaa00 );
					resizeSelectionOutline();
					highlightBox.bitmapData.draw(selectionOutline);
					resizedSelectionBox = true;
				}
				
				selectionBox.bitmapData = new BitmapData( _tileWidth, _tileHeight, true, 0x55ff8800 );
				if ( !resizedSelectionBox )
				{
					resizedSelectionBox = true;
					resizeSelectionOutline();
				}
				selectionBox.bitmapData.draw(selectionOutline);
				
				// Draw in dark grey
				eraseTileBox.bitmapData = new BitmapData( _tileWidth, _tileHeight, true, 0x55000000 );
				if ( !resizedSelectionBox )
				{
					resizedSelectionBox = true;
					resizeSelectionOutline();
				}
				eraseTileBox.bitmapData.draw(selectionOutline);
				
				regenBoxes = false;
			}
			
			var storedPt:Point = null;
			
			var tileHighlightBmp:BitmapData = null;
			if ( TileHighlights != null && showTileHighlights )
			{
				var tileHighlightShape:Shape = new Shape;
				tileHighlightBmp = new BitmapData(tWidth, tHeight, true, 0x00000000);
				tileHighlightShape.graphics.lineStyle(10, 0xff2222, 0.6);
				tileHighlightShape.graphics.beginFill(0x2222ff, 0.4);
				tileHighlightShape.graphics.drawRect(0, 0, tWidth, tHeight);
				tileHighlightShape.graphics.endFill();
				tileHighlightBmp.draw(tileHighlightShape);
			}
			
			var ix:uint = 0;
			var iy:uint = 0;
			var index:uint = 0;
			var rowStartIndex:uint = 0;
			
			// Prevent selection boxes from appearing outside the container.
			if ( posX || posY )
			{
				this.scrollRect = new Rectangle(0, 0, ContainerObject.width, ContainerObject.height);
			}
			else
			{
				this.scrollRect = null;
			}
	
			while ( index < _data.length )
			{
				var item:TileListData = _data[index];
				//var matrix:Matrix = new Matrix();
				//matrix.scale( tWidth / item.icon.width, tHeight / item.icon.height);
				//matrix.translate( _flashPoint.x, _flashPoint.y );
				//var colorTrans:ColorTransform = showInvalidTiles && !item.valid ? new ColorTransform(0.5, 0.5, 0.5) : null;
				//gfx.bitmapData.draw( new Bitmap(item.icon), matrix, colorTrans, null, null, smoothDraw);
				var iconBmp:BitmapData = item.GetScaledTileData(tWidth / item.icon.width, tHeight / item.icon.height, smoothDraw);
				
				gfx.bitmapData.copyPixels( iconBmp, iconBmp.rect, _flashPoint, null, null, true );
				if ( showInvalidTiles && !item.valid )
				{
					gfx.bitmapData.colorTransform( new Rectangle(_flashPoint.x, _flashPoint.y, iconBmp.width, iconBmp.height), new ColorTransform(0.5, 0.5, 0.5 ) );
				}
				
				if ( tileHighlightBmp && TileHighlights.indexOf(index)!=-1 )
				{
					gfx.bitmapData.copyPixels(tileHighlightBmp, tileHighlightBmp.rect, _flashPoint, null, null, true);
				}
				
				var resizedSelectionBox:Boolean = false;
				
				if ( _highlightIndex == index )
				{
					storedPt = _flashPoint.clone();
					
					highlightBox.visible = true;
					highlightBox.x = _flashPoint.x;
					highlightBox.y = _flashPoint.y;
					highlightBox.width = tWidth;
					highlightBox.height = tHeight;
					
					// The highlight box takes precedence over the selection box.
					if ( _selectedIndex == _highlightIndex )
					{
						selectionBox.visible = false;
					}
				}
				else if ( Selectable && _selectedIndex == index )
				{
					selectionBox.visible = true;
					selectionBox.x = _flashPoint.x;
					selectionBox.y = _flashPoint.y;
					selectionBox.width = tWidth;
					selectionBox.height = tHeight;
				}
				if ( eraseTileIdx == index )
				{
					eraseTileBox.visible = true;
					eraseTileBox.x = _flashPoint.x;
					eraseTileBox.y = _flashPoint.y;
					eraseTileBox.width = tWidth;
					eraseTileBox.height = tHeight;
					if ( eraseTileIdx == _highlightIndex || eraseTileIdx == _selectedIndex )
					{
						eraseTileBox.visible = false;
					}
				}
				
				ix++;
				index++;
				_flashPoint.x += tSpacingX;
				_flashPoint.y += tOffsetY;
				
				if ( ix >= numTilesPerRow || _flashPoint.x >= gfx.bitmapData.width )
				{
					storedX += tOffsetX;
					storedY += tSpacingY;
					_flashPoint.x = storedX;
					_flashPoint.y = storedY;
					index = rowStartIndex + numTilesPerRow;
					rowStartIndex = index;
					ix = 0;
					iy++;
				}
				
			}
			
			UpdateHBar();
			UpdateVBar();
			
			dispatchEvent(new CustomEvent(EVENT_TILES_DRAWN));
			
		}
		
		private function resizeSelectionOutline():void
		{
			selectionOutline.graphics.clear();
			selectionOutline.graphics.lineStyle(1, 0xffffff, 0.7);
			selectionOutline.graphics.drawRect(0, 0, _tileWidth - 1, _tileHeight - 1);
			//if ( isSelection )
			{
				selectionOutline.graphics.lineStyle(1, 0x000000, 0.3);
				selectionOutline.graphics.drawRect(1, 1, _tileWidth - 3, _tileHeight - 3);
			}
		}
		
		public function GetMetaDataAtIndex( index:int ):Object
		{
			if ( index < 0 || index >= _data.length )
			{
				return null;
			}
			
			return _data[index].metadata;
		}
		
		public function SetMetaDataAtIndex( index:int, newMetaData:Object ):void
		{
			if ( index < 0 || index >= _data.length )
			{
				return;
			}
			
			_data[index].metadata = newMetaData;
		}
		
		public function SetTileValid( index:int, valid:Boolean):void
		{
			if ( index < 0 || index >= _data.length || !showInvalidTiles)
			{
				return;
			}
			if ( _data[index].valid != valid )
			{
				_data[index].valid = valid;
				_dirty = true;
			}
		}
		
		public function GetTileValid( index:int ):Boolean
		{
			if ( index < 0 || index >= _data.length || !showInvalidTiles)
			{
				return false;
			}
			
			return _data[index].valid;
		}
		
		public function SetEraseTileIdx( index:int ):void
		{
			if ( index != eraseTileIdx )
			{
				eraseTileIdx = index;
				if ( eraseTileIdx == -1 )
				{
					eraseTileBox.visible = false;
				}
				_dirty = true;
			}
		}

		
		public function GetDataLength():uint
		{
			return _data.length;
		}
		
		public function SetTileAtIndex( bitmapData:BitmapData, _metadata:Object, index:uint ):void
		{
			if ( index >= 0 && index < _data.length )
			{
				_data[ index ] = new TileListData( bitmapData, _metadata );
				_dirty = true;
			}
		}
		
		private function UpdateSelfScrollBars():void
		{
			if ( SelfMadeScrollBars )
			{
				if ( VBar )
				{
					var desiredX:int = ContainerObject.width - VBar.width;
					if ( VBar.x != desiredX )
						VBar.x = desiredX;
					if ( VBar.y != 0 )
						VBar.y = 0;
				}
					
				if ( HBar )
				{
					var desiredY:int = ContainerObject.height - HBar.height;
					if ( HBar.y != desiredY )
						HBar.y = desiredY;
					if ( HBar.x != 0 )
						HBar.x = 0;
				}
			}
		}
		
		// Container is the component which contains the tile list and any uirefs.
		// This may be several levels up the hierarchy as it needs to be the one that doesn't change size when more tiles are added.
		public function AddHBar(hbar:HScrollBar, container:Object):void
		{
			if ( hbar )
			{
				hbar.removeEventListener(ScrollEvent.SCROLL, scrolledXold);
			}
			HBarOld = hbar;
			HBarOld.addEventListener(ScrollEvent.SCROLL, scrolledXold, false, 0, true);
			ScrollContainer = container;
			UpdateHBar();
		}
		
		private function UpdateHBar( show:Boolean = true):void
		{
			if ( HBar )
			{
				if ( show && SelfMadeScrollBars )
				{
					HBar.width = ContainerObject.width - HBar.height;
				}
				
				HBar.pageSize = ContainerObject.width;
				var maxPos:int = ( numTilesPerRow * tWidth );
				
				HBar.maximum = maxPos - ContainerObject.width;
				HBar.value = posX;
				HBar.setThumbPercent( maxPos > 0 ? HBar.pageSize / maxPos : 1 );
				
				if ( SelfMadeScrollBars && maxPos - ContainerObject.width <= 0 )
				{
					posX = 0;
				}
				else if ( !show )
				{
					HBar.visible = false;
				}
			}
			else if ( HBarOld )
			{
				HBarOld.visible = show;
				HBarOld.pageSize = ScrollContainer.width;
				maxPos = ( numTilesPerRow * tWidth ) - ScrollContainer.width;
				HBarOld.lineScrollSize = 50;
				HBarOld.pageScrollSize = 100;
				HBarOld.minScrollPosition = 0;
				HBarOld.maxScrollPosition = maxPos;
				HBarOld.scrollPosition = posX;
			}
		}
		
		private function UpdateVBar( show:Boolean = true):void
		{
			if ( VBar )
			{
				if ( show && SelfMadeScrollBars )
				{
					VBar.height = ContainerObject.height - VBar.width;
				}
				if ( !show )
				{
					VBar.visible = false;
				}
				VBar.pageSize = ContainerObject.height;
				var maxPos:int = ( numRows * tHeight );
				VBar.lineSize = 50;
				VBar.minimum = 0;
				VBar.maximum = maxPos - VBar.height;
				VBar.value = posY;
				VBar.setThumbPercent( maxPos > 0 ? VBar.pageSize / maxPos : 1 );
				if ( SelfMadeScrollBars && maxPos - VBar.height <= 0 )
				{
					VBar.visible = false;
					posY = 0;
				}
			}
		}
		
		private function scrolledX(event:Event):void
		{
			posX = event.currentTarget.value;
			_dirty = true;
		}
		
		private function scrolledY(event:Event):void
		{
			posY = event.currentTarget.value;
			_dirty = true;
		}
		
		private function scrolledXold(event:ScrollEvent):void
		{
			posX = event.currentTarget.scrollPosition;
			_dirty = true;
		}
		
		public function MakeAutoScroll( container:Object ):void
		{
			SelfMadeScrollBars = true;
			HBar = new HMinScrollBar;
			HBar.lineSize = 50;
			HBar.minimum = 0;
			HBar.autoHide = true;
			HBar.height = 16;
			//hbar.minScrollPosition = 0;
			container.addChild(HBar);
			HBar.addEventListener(Event.CHANGE, scrolledX, false, 0, true);
			
			VBar = new VMinScrollBar;
			VBar.lineSize = 50;
			VBar.minimum = 0;
			VBar.autoHide = true;
			VBar.width = 16;
			//vbar.includeInLayout = false;
			container.addChild(VBar);
			VBar.addEventListener(Event.CHANGE, scrolledY, false, 0, true);
			ScrollContainer = container;
			UpdateVBar();
		}
		
		public function ForceRedraw():void
		{
			_dirty = true;
		}
		
		public function AddTileHighlight( tileId:int ):void
		{
			if ( TileHighlights == null )
			{
				TileHighlights = new Vector.<int>;
			}
			if ( TileHighlights.indexOf(tileId) == -1 )
			{
				TileHighlights.push( tileId );
			}
			_dirty = true;
		}
		
		public function RemoveTileHighlight( tileId:int ):void
		{
			var index:int;
			if ( !TileHighlights )
				return;
			index = TileHighlights.indexOf( tileId );
			if ( index != -1 )
			{
				TileHighlights.splice( index, 1 );
			}
			if ( TileHighlights.length == 0 )
			{
				TileHighlights = null;
			}
			_dirty = true;
		}
		
	}

}