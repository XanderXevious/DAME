package com.Editor 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Operations.HistoryStack;
	import com.Operations.OperationChangeTileSelection;
	import com.Operations.OperationMoveMap;
	import com.Operations.OperationMoveTiles;
	import com.Operations.OperationPaintTiles;
	import com.Operations.OperationPasteTiles;
	import com.Operations.OperationResizeMap;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.StackTileInfo;
	import com.Utils.Hits;
	import com.Utils.Misc;
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import mx.collections.ArrayCollection;
	import mx.managers.CursorManager;
	import org.flixel.FlxPoint;
	import com.Utils.DebugDraw;
	import org.flixel.FlxG;
	import com.Utils.Global;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeTiles extends EditorType
	{
		protected static var _isActive:Boolean = false;
		public static function IsActiveEditor():Boolean { return _isActive; };
		
		private var selectedTiles:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
		
		public static var UseMagicWand:Boolean = false;
		public static var UsePaintBucket:Boolean = false;
		public static var SelectHiddenTiles:Boolean = false;
		public static var UsingDropper:Boolean = false;
		public static var ResizeMapMode:Boolean = false;
		public static var InfiniteStacking:Boolean = false;
		
		// lists used for the magic wand selection.
		private var openListX:Vector.<int> = new Vector.<int>();
		private var openListY:Vector.<int> = new Vector.<int>();
		private var openListIndices:Vector.<uint> = new Vector.<uint>();
		private var closedListX:Vector.<int> = new Vector.<int>();
		private var closedListY:Vector.<int> = new Vector.<int>();
		private var closedListIndices:Vector.<uint> = new Vector.<uint>();
		
		[Embed(source="../../../assets/eyeDropperCursor.png")]
        private static var eyeDropperCursor:Class;
		
		[Embed(source="../../../assets/paintBucketCursor.png")]
        private static var paintBucketCursor:Class;
		
		private static var rhs:int = 10;	// Resize handle size;
		
		private var movingMap:Boolean = false;
		private var mapMoveStartPos:FlxPoint;
		private var mapMoveMouseStartPos:FlxPoint;
		private var resizingMap:Boolean = false;
		private var resizeHandlePos:FlxPoint = new FlxPoint;// which corner/edge : x,y=0,0.5,1
		private var calculatedMapClips:Boolean = false;
	
		private var transformHandles:Vector.<Quad> = new Vector.<Quad>(9);
		
		private var currentTileHeight:int = 0;	// Value is in number of tiles, not pixels.
		
		private var lastTimePlacedstackedTiles:Number = 0;
		
		private var	moveStackStartPos:FlxPoint = null;
		private var tileStackOffset:int = 0;
		private var moveStackStartTileHeight:int = 0;
		
		private var currentZText:String = "";
		
		public function EditorTypeTiles( editor:EditorState ) 
		{
			super( editor );
			
			allowContinuousPainting = true;
			
			selectionEnabled = true;
			
			for ( var i:uint = 0; i < transformHandles.length; i++ )
			{
				transformHandles[i] = new Quad();
			}
		}
		
		override public function Update(isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			_isActive = isActive;
			
			if ( isActive)
			{
				var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
				
				var canUpdateStack:Boolean = false;
				if ( InfiniteStacking && !inSelectionMode && mapLayer.map.stackHeight && !( App.getApp().brushesWindow && App.getApp().brushesWindow.Active && App.getApp().brushesWindow.ListBrushes.selectedItem != null) )
				{
					// Only allow updating if the current tile is valid.
					if ( currentTileValid )
					{
						canUpdateStack = true;
						if ( FlxG.keys.justPressed("Z") )
						{
							moveStackStartPos = mousePos.copy();
							moveStackStartPos.y += ( tileStackOffset >> FlxG.zoomBitShifter );
						}
						else if ( moveStackStartPos )
						{
							if ( FlxG.keys.Z )
							{
								tileStackOffset = Math.max(0, Math.floor( moveStackStartPos.y - mousePos.y ) << FlxG.zoomBitShifter );
								currentTileHeight = tileStackOffset / mapLayer.map.stackHeight;
								currentTileHeight = currentTileHeight;
							}
							else
							{
								moveStackStartPos = null;
							}
						}
					}
				}
				else
				{
					tileStackOffset = 0;
				}
				
				mousePos.y += ( tileStackOffset >> FlxG.zoomBitShifter );
				if( !canUpdateStack || !FlxG.keys.Z )
					UpdateCurrentTile( mapLayer ? mapLayer.map : null, mousePos.x - mapLayer.map.x * FlxG.extraZoom, mousePos.y - mapLayer.map.y * FlxG.extraZoom);
				
				if ( !mapLayer )
					return;
				
				if ( mapLayer.map.stackHeight )
				{
					var limitHeight:Boolean = false;
					if ( !InfiniteStacking )
					{
						if ( FlxG.keys.justPressed("LBRACKET") )
						{
							currentTileHeight = Math.max(0, currentTileHeight - 1 );
						}
						else if ( FlxG.keys.justPressed("RBRACKET") )
						{
							currentTileHeight = Math.min(FlxTilemapExt.MAX_STACKED_TILES, currentTileHeight + 1 );
							limitHeight = true;
						}
						if ( limitHeight && currentTileHeight )
						{
							if ( !mapLayer.map.stackedTiles )
							{
								currentTileHeight = 0;
							}
							else
							{
								var tileInfo:StackTileInfo = mapLayer.map.stackedTiles[ currentTile.y * mapLayer.map.widthInTiles + currentTile.x ];
								if ( tileInfo )
								{
									currentTileHeight = Math.min( tileInfo.GetHeight(), currentTileHeight );
								}
							}
						}
					}
				}
				
				if ( Global.DrawCurrentTileAbove )
				{
					if( currentTileValid )
						mapLayer.map.drawTileAboveTileId = currentTile.y * mapLayer.map.widthInTiles + currentTile.x;
				}
				
				if ( ResizeMapMode && inSelectionMode )
				{
					if ( movingMap )
					{
						var xDiff:int = ( mousePos.x - mapMoveMouseStartPos.x ) * FlxG.invExtraZoom;
						var yDiff:int = ( mousePos.y - mapMoveMouseStartPos.y ) * FlxG.invExtraZoom;
						if ( GuideLayer.SnappingEnabled )
						{
							xDiff = Math.floor( xDiff / mapLayer.map.tileWidth ) * mapLayer.map.tileWidth;
							yDiff = Math.floor( yDiff / mapLayer.map.tileHeight ) * mapLayer.map.tileHeight;
						}
						mapLayer.map.x = mapMoveStartPos.x + xDiff;
						mapLayer.map.y = mapMoveStartPos.y + yDiff;
					}
					else if ( resizingMap )
					{
						mapLayer.map.clipRender = true;	// Must be set every frame it is needed.
						mapLayer.map.clipLeft = 0;
						mapLayer.map.clipRight = mapLayer.map.widthInTiles;
						mapLayer.map.clipTop = 0;
						mapLayer.map.clipBottom = mapLayer.map.heightInTiles;
						if ( resizeHandlePos.x != 0.5 )
						{
							if ( resizeHandlePos.x == 0 )
							{
								mapLayer.map.clipLeft = currentTile.x + 1;
							}
							else
							{
								mapLayer.map.clipRight = currentTile.x;
							}
						}
						if ( resizeHandlePos.y != 0.5 )
						{
							if ( resizeHandlePos.y == 0 )
							{
								mapLayer.map.clipTop = currentTile.y + 1;
							}
							else
							{
								mapLayer.map.clipBottom = currentTile.y;
							}
						}
						if ( resizeHandlePos.x == 0 )
						{
							mapLayer.map.clipLeft = Math.min(mapLayer.map.clipLeft, mapLayer.map.clipRight - 1);
						}
						else if( resizeHandlePos.x == 1 )
						{
							mapLayer.map.clipRight = Math.max(mapLayer.map.clipLeft + 1, mapLayer.map.clipRight);
						}
						if ( resizeHandlePos.y == 0 )
						{
							mapLayer.map.clipTop = Math.min(mapLayer.map.clipTop, mapLayer.map.clipBottom - 1);
						}
						else if( resizeHandlePos.y == 1 )
						{
							mapLayer.map.clipBottom = Math.max(mapLayer.map.clipTop + 1, mapLayer.map.clipBottom);
						}
						
						calculatedMapClips = true;
					}
				}
				else if( FlxG.keys.SPACE )
				{
					if ( currentTileValid )
					{
						//var mapPos:FlxPoint = EditorState.getMapXYFromScreenXY(mouseScreenPos.x, mouseScreenPos.y, mapLayer.xScroll, mapLayer.yScroll );
						//mapPos.subFrom(mapLayer.map);
						EditorState.SetCurrentTileToTileAtLocation( currentTile.x, currentTile.y );
					}
				}
				else if ( FlxG.keys.justPressed("COMMA") )
				{
					App.getApp().myTileList.selectedIndex = Math.max(App.getApp().myTileList.selectedIndex-1,0);
				}
				else if ( FlxG.keys.justPressed("PERIOD"))
				{
					if ( mapLayer )
					{
						App.getApp().myTileList.selectedIndex = Math.min(App.getApp().myTileList.selectedIndex + 1, mapLayer.map.tileCount-1);
					}
				}
			}
			
		}
		
		private function CreateMapHandles( x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number, mapLayer:LayerMap, forceSelect:Boolean, fillRegion:Boolean, quad:Quad ):void
		{
			var cornerPt:FlxPoint = new FlxPoint;
			var ptB:FlxPoint = new FlxPoint;
			var ptC:FlxPoint = new FlxPoint;
				
			cornerPt.create_from_points(x2, y2);
			ptB.create_from_points(x1, y1);
			ptC.create_from_points(x3, y3);
			//var scaledMousePos:FlxPoint = new FlxPoint(mousePos.x * FlxG.extraZoom, mousePos.y * FlxG.extraZoom);
			if ( !resizingMap && Hits.PointInRectangle(mousePos, cornerPt, ptB, ptC) )
			{
				quad.selected = true;
			}
			else
			{
				quad.selected = false;
			}
			DebugDraw.DrawQuad( x1, y1, x2, y2, x3, y3, x4, y4, mapLayer.map.scrollFactor, Global.MapBoundsColour, fillRegion, (resizingMap && forceSelect ) || quad.selected ? 0xbbffff00 : 0x880000aa);
			
			quad.SetupQuad( x1, y1, x2, y2, x3, y3, x4, y4 );
		}
		
		override protected function UpdateDisplay( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			currentZText = "";
			
			if ( mapLayer == null || mapLayer.map == null || !mapLayer.map.visible )
			{
				RemoveCurrentCursor();
				return;
			}
			
			if( mouseScreenPos.x > 0 && mouseScreenPos.y > 0 && mouseScreenPos.x < FlxG.width && mouseScreenPos.y < FlxG.height )
			{
				if( UsingDropper )
				{
					SetCurrentCursor(eyeDropperCursor, 0, -17);
				}
				else if ( UsePaintBucket )
				{
					SetCurrentCursor(paintBucketCursor, 0, -11);
				}
				else
				{
					RemoveCurrentCursor();
				}
			}
			else
			{
				RemoveCurrentCursor();
			}
			
			if ( HighlightCurrentTile )
			{
				mapLayer.map.highlightTileIndexForThisFrame = App.getApp().myTileList.GetMetaDataAtIndex(App.getApp().myTileList.selectedIndex) as int;
			}
			
			if ( !ResizeMapMode || !inSelectionMode )
			{
				DebugDraw.DrawBox( mapLayer.map.x>>FlxG.zoomBitShifter, mapLayer.map.y>>FlxG.zoomBitShifter, (mapLayer.map.x + mapLayer.map.width)>>FlxG.zoomBitShifter, (mapLayer.map.y + mapLayer.map.height)>>FlxG.zoomBitShifter, 0, mapLayer.map.scrollFactor, false, Global.MapBoundsColour, true);
			}
			
			if ( ResizeMapMode && inSelectionMode )
			{
				var map:FlxTilemapExt = mapLayer.map;
				var tileSpacingY:int = map.tileSpacingY >> FlxG.zoomBitShifter;
				var tileSpacingX:int = map.tileSpacingX >> FlxG.zoomBitShifter;
				var tileHeight:int = map.tileHeight >> FlxG.zoomBitShifter;
				var tileWidth:int = map.tileWidth >> FlxG.zoomBitShifter;
				var tileOffsetX:int = map.tileOffsetX >> FlxG.zoomBitShifter;
				var tileOffsetY:int = map.tileOffsetY >> FlxG.zoomBitShifter;
				var xStagger:int = map.xStagger >> FlxG.zoomBitShifter;
				// Draw boxes around each corner, highlighting if the mouse is over any of them.
				var tileSub:int = tileHeight - tileSpacingY;
				var x1:int = (map.x + map.tilesStartX)>> FlxG.zoomBitShifter;
				var y1:int = ((map.y + map.tilesStartY)>> FlxG.zoomBitShifter) + tileSub;
				
				// top right
				var x2:int;
				var y2:int;
				// bottom right
				var x3:int;
				var y3:int;
				// bottom left
				var x4:int;
				var y4:int;
				
				// Normal for x axis
				var xNorm:FlxPoint = new FlxPoint;
				// Normal for y axis.
				var yNorm:FlxPoint = new FlxPoint;
				
				var left:Number = 0;
				var wid:Number = map.widthInTiles;
				var top:Number = 0;
				var ht:Number = map.heightInTiles;
				
				if ( resizingMap && calculatedMapClips)
				{
					left = map.clipLeft;
					top = map.clipTop;
					wid = map.clipRight - left;
					ht = map.clipBottom - top;
				}
				
				if ( tileOffsetX || tileOffsetY )
				{
					y1 -= tileOffsetY;
					if ( tileOffsetY < 0 )
					{
						// -ive tileOffset is going up, which means the origin of the map is where the tile is.
						y1 += tileOffsetY;
					}
					if ( tileOffsetX < 0 )
					{
						x1 -= tileOffsetX;
					}
					if ( left )
					{
						x1 += left * tileSpacingX;
						y1 += left * tileOffsetY;
					}
					if ( top )
					{
						x1 += top * tileOffsetX;
						y1 += top * tileSpacingY;
					}
					
					var endxx:Number = tileSpacingX * wid;
					var endxy:Number = tileOffsetY * wid;
					
					x2 = x1 + endxx;
					y2 = y1 + endxy;
					
					x3 = x2 + tileOffsetX * ht;
					y3 = y2 + tileSpacingY * ht;
					
					x4 = x3 - endxx;
					y4 = y3 - endxy;
				}
				else
				{
					x1 += left * tileSpacingX;
					y1 += top * tileSpacingY;

					x2 = x1 + wid * tileSpacingX;
					if ( xStagger )
					{
						x2 += Math.abs(xStagger);
						y1 -= tileSpacingY;
					}
					y2 = y1;
					
					x3 = x2;
					y3 = y1 + ht * tileSpacingY;
					if ( xStagger )
						y3 += tileSpacingY;
					
					x4 = x1;
					y4 = y3;
				}
				
				xNorm.create_from_points( x2 - x3, y2 - y3 );
				xNorm.normalize();
				xNorm.multiplyBy(rhs);
				yNorm.create_from_points( x2 - x1, y2 - y1 );
				yNorm.normalize();
				yNorm.multiplyBy(rhs);
				
				// Draw sides.
				CreateMapHandles( x1, y1, x2, y2, x2 + xNorm.x, y2 + xNorm.y, x1 + xNorm.x, y1 + xNorm.y, mapLayer, resizeHandlePos.x==0.5 && resizeHandlePos.y==0, true, transformHandles[0] );
				CreateMapHandles( x2, y2, x3, y3, x3 + yNorm.x, y3 + yNorm.y, x2 + yNorm.x, y2 + yNorm.y, mapLayer, resizeHandlePos.x==1 && resizeHandlePos.y==0.5, true, transformHandles[1] );
				CreateMapHandles( x3, y3, x4, y4, x4 - xNorm.x, y4 - xNorm.y, x3 - xNorm.x, y3 - xNorm.y, mapLayer, resizeHandlePos.x==0.5 && resizeHandlePos.y==1, true, transformHandles[2] );
				CreateMapHandles( x4, y4, x1, y1, x1 - yNorm.x, y1 - yNorm.y, x4 - yNorm.x, y4 - yNorm.y, mapLayer, resizeHandlePos.x==0 && resizeHandlePos.y==0.5, true, transformHandles[3] );
				
				// Draw Corners.
				var tx:Number = x1 - yNorm.x;
				var ty:Number = y1 - yNorm.y;
				CreateMapHandles( x1, y1, tx, ty, tx + xNorm.x, ty + xNorm.y, x1 + xNorm.x, y1 + xNorm.y, mapLayer, resizeHandlePos.x==0 && resizeHandlePos.y==0, true, transformHandles[4] );
				tx = x2 + yNorm.x;
				ty = y2 + yNorm.y;
				CreateMapHandles( x2, y2, tx, ty, tx + xNorm.x, ty + xNorm.y, x2 + xNorm.x, y2 + xNorm.y, mapLayer, resizeHandlePos.x==1 && resizeHandlePos.y==0, true, transformHandles[5] );
				tx = x3 + yNorm.x;
				ty = y3 + yNorm.y;
				CreateMapHandles( x3, y3, tx, ty, tx - xNorm.x, ty - xNorm.y, x3 - xNorm.x, y3 - xNorm.y, mapLayer, resizeHandlePos.x==1 && resizeHandlePos.y==1, true, transformHandles[6] );
				tx = x4 - yNorm.x;
				ty = y4 - yNorm.y;
				CreateMapHandles( x4, y4, tx, ty, tx - xNorm.x, ty - xNorm.y, x4 - xNorm.x, y4 - xNorm.y, mapLayer, resizeHandlePos.x==0 && resizeHandlePos.y==1, true, transformHandles[7] );
				
				// The main area. No need to draw it, but need to store it so we can do the hit test later.
				CreateMapHandles(x1, y1, x2, y2, x3, y3, x4, y4, mapLayer, false, false, transformHandles[8] );
			}
			else
			{
				if ( currentTileValid )
				{
					var height:int = currentTileHeight;
					if ( !InfiniteStacking )
					{
						if ( mapLayer.map.stackedTiles )
						{
							var tileInfo:StackTileInfo = mapLayer.map.stackedTiles[ currentTile.y * mapLayer.map.widthInTiles + currentTile.x ];
							if ( tileInfo )
							{
								height = FlxG.keys.Z ? tileInfo.GetHeight() : Math.min( currentTileHeight, tileInfo.GetHeight() );
							}
							else
							{
								height = 0;
							}
						}
						else if( currentTileHeight > 0)
						{
							height = 1;
						}
					}
					
					currentZText = "Z: " + height;
					if( height )
						DrawBoxAroundTile( mapLayer.map, currentTileWorldPos.x, currentTileWorldPos.y, Global.TileUnderCursorColour, (height * mapLayer.map.stackHeight), true );
					DrawBoxAroundTile( mapLayer.map, currentTileWorldPos.x, currentTileWorldPos.y, (height ? Global.TileUnderCursorColourStackBase : Global.TileUnderCursorColour), 0, true );
					
					if ( height && mapLayer.map.stackHeight )
					{
						// Draw a helper to indicate the height.
						var helperX:int = (currentTileWorldPos.x + mapLayer.tileWidth + 5)>> FlxG.zoomBitShifter;
						var helperY:int = (currentTileWorldPos.y + mapLayer.map.tileHeight)>> FlxG.zoomBitShifter;
						DebugDraw.DrawBox(helperX, helperY, helperX + (10 >> FlxG.zoomBitShifter), helperY - (( height * mapLayer.map.stackHeight)>> FlxG.zoomBitShifter), 0, mapLayer.map.scrollFactor, false, 0xff0000ff, true, false, true);
					}
				}
			}
		}
		
		override public function GetZText():String
		{
			return currentZText ? ", " + currentZText : "";
		}
		
		override public function GetCurrentObjectProperties():ArrayCollection
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( mapLayer )
			{
				return mapLayer.properties;
			}
			return null;
		}
		
		override protected function Paint( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( !mapLayer.map.visible )
			{
				return;
			}
			
			if ( UsePaintBucket )
			{
				return;
			}
			
			if (UsingDropper && currentTileValid )
			{
				EditorState.SetCurrentTileToTileAtLocation( currentTile.x, currentTile.y );
				return;
			}
			
			var brushData:TileEditorLayerEntry = null;
			if ( App.getApp().brushesWindow && App.getApp().brushesWindow.Active && App.getApp().brushesWindow.ListBrushes.selectedItem!=null)
			{
				brushData = App.getApp().brushesWindow.ListBrushes.selectedItem.entry as TileEditorLayerEntry;
			}
			if ( brushData != null )
			{
				paintBrushInLine( mapLayer, lastHeldTileIdx.x, lastHeldTileIdx.y, currentTile.x, currentTile.y, brushData );
			}
			else
			{
				var tileId:int = App.getApp().myTileList.GetMetaDataAtIndex(App.getApp().myTileList.selectedIndex) as int;
				setAllTilesInLine( mapLayer, lastHeldTileIdx.x, lastHeldTileIdx.y, currentTile.x, currentTile.y, tileId );
			}
		}
		
		override protected function BeginPainting( layer:LayerEntry, leftMouse:Boolean ):void
		{
			super.BeginPainting( layer, leftMouse );
			
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( !mapLayer.map.visible )
			{
				return;
			}
			
			HistoryStack.BeginOperation( new OperationPaintTiles( mapLayer ) );
			
			if ( UsePaintBucket )
			{
				var tileId:int = App.getApp().myTileList.GetMetaDataAtIndex(App.getApp().myTileList.selectedIndex) as int;
				if ( !leftMouse )
				{
					tileId = mapLayer.EraseTileIdx;
				}
				
				var unitMapPosX:int = currentTile.x;
				var unitMapPosY:int = currentTile.y;
				
				if ( unitMapPosX < 0  ||
					unitMapPosY < 0  ||
					unitMapPosX >= mapLayer.map.widthInTiles ||
					unitMapPosY >= mapLayer.map.heightInTiles )
				{
					return;
				}
				
				var fillBmp:BitmapData = SelectUsingMagicWand(mapLayer, null, unitMapPosX, unitMapPosY, true);
				
				if ( fillBmp )
				{
					var ty:int = mapLayer.map.heightInTiles;
					while (ty--)
					{
						var tx:int = mapLayer.map.widthInTiles;
						while (tx--)
						{
							if ( fillBmp.getPixel(tx, ty) == 2 )
							{
								mapLayer.map.setTile( tx, ty, tileId );
								var layerData:TileEditorLayerEntry = FindLayerInSelected( App.getApp().CurrentLayer as LayerMap );
								if ( layerData != null )
								{
									var tileData:TileEditorTileEntry = FindTileInSelectedLayerData(layerData, tx, ty);
									if ( tileData != null )
									{
										tileData.tileId = tileId;
									}
								}
							}
						}
					}
				}
				
			}
			else if (UsingDropper && currentTileValid)
			{
				EditorState.SetCurrentTileToTileAtLocation( currentTile.x, currentTile.y );
			}
		}
		
		override public function OnRightMouseDown():void
		{
			super.OnRightMouseDown();
			
			if ( inSelectionMode )
			{
				ClearSelection();
			}
		}
		
		override protected function PaintSecondary( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( !mapLayer.map.visible )
			{
				return;
			}
			
			if ( UsePaintBucket )
			{
				return;
			}
			
			setAllTilesInLine( mapLayer, lastHeldTileIdx.x, lastHeldTileIdx.y, currentTile.x, currentTile.y, mapLayer.EraseTileIdx );
		}
		
		override protected function SelectUnderCursor( layer:LayerEntry ):Boolean
		{
			if ( ResizeMapMode && inSelectionMode )
			{
				return false;
			}
			if ( !UsePaintBucket && !FlxG.keys.pressed( "CONTROL" ) && !FlxG.keys.pressed( "SHIFT" ) )
			{
				ClearSelection();
			}
			
			var layerEntry:LayerMap = layer as LayerMap;
			if ( layerEntry!=null && layerEntry.visible && layerEntry.map!=null && layerEntry.map.visible )
			{
				var unitMapPosX:int = currentTile.x;
				var unitMapPosY:int = currentTile.y;
				
				// If the layer isn't already in our tile list then add it.
				var layerData:TileEditorLayerEntry = null;
				var layerIndex:uint = selectedTiles.length;
				while( layerIndex-- )
				{
					var testLayerData:TileEditorLayerEntry = selectedTiles[layerIndex];
					if ( testLayerData.layer == layerEntry )
					{
						layerData = testLayerData;
						break;
					}
				}
				
				var addNewLayer:Boolean = false;
				if ( layerData == null )
				{
					layerIndex = selectedTiles.length;
					layerData = new TileEditorLayerEntry( layerEntry, true );
					addNewLayer = true;
				}
				
				if ( UseMagicWand )
				{
					SelectUsingMagicWand(layerEntry, layerData, unitMapPosX, unitMapPosY, false);
					if ( addNewLayer && layerData.rows.length > 0 )
					{
						selectedTiles.push( layerData );
						addNewLayer = false;
					}
				}
				else
				{
					var tileId:int = layerEntry.map.getTile( unitMapPosX, unitMapPosY );
					if ( !SelectHiddenTiles && tileId < layerEntry.map.drawIndex )
					{
						if ( addNewLayer )
						{
							layerEntry.map.selectedTiles = null;
						}
						return false;
					}
					TileEditorRowEntry.xOffset = layerData.xOffset;
					
					// Get the row or insert a new one.
					var rowIndex:uint = layerData.GetRow( unitMapPosY, true, false );
					var rowData:TileEditorRowEntry = layerData.rows[rowIndex] as TileEditorRowEntry;

					if ( addRemoveTile(layerEntry, layerData, layerIndex, rowIndex, rowData, unitMapPosX, unitMapPosY) )
					{
						if ( addNewLayer )
						{
							selectedTiles.push( layerData );
							addNewLayer = false;
						}
					}
		
				}
				return true;
			}
			return false;
		}
		
		override protected function SelectInsideBox( layer:LayerEntry, boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean
		{			
			if ( !FlxG.keys.pressed( "CONTROL" ) && !FlxG.keys.pressed( "SHIFT" ) )
			{
				ClearSelection();
			}
			for each( var group:LayerGroup in App.getApp().layerGroups )
			{
				for each( var layerEntry:LayerEntry in group.children )
				{
					if ( Global.SelectFromCurrentLayerOnly && layer != layerEntry )
					{
						continue;
					}
					if ( layerEntry is LayerMap && layerEntry.visible && layerEntry.map!=null && layerEntry.map.visible )
					{
						var topLeft:FlxPoint = new FlxPoint();
						var bottomRight:FlxPoint = new FlxPoint();
						
						GetTileInfo(layerEntry.map, selectionBoxStart.x - layerEntry.map.x* FlxG.extraZoom, selectionBoxStart.y - layerEntry.map.y* FlxG.extraZoom, topLeft, null);
						GetTileInfo(layerEntry.map, selectionBoxEnd.x - layerEntry.map.x* FlxG.extraZoom, selectionBoxEnd.y - layerEntry.map.y* FlxG.extraZoom, bottomRight, null);
						
						var topLeftUnits:FlxPoint = new FlxPoint(Math.min(topLeft.x,bottomRight.x), Math.min(topLeft.y,bottomRight.y));
						var bottomRightUnits:FlxPoint = new FlxPoint(Math.max(topLeft.x,bottomRight.x), Math.max(topLeft.y,bottomRight.y));
						
						if ( layerEntry.map.xStagger )
						{
							ConvertStaggerPosToIso(layerEntry.map, selectionBoxStart, selectionBoxEnd, selectionBoxTopRight, bottomRight, topLeft, topLeftUnits, bottomRightUnits );
						}
						else
						{
							if ( bottomRightUnits.x < 0  ||
								bottomRightUnits.y < 0  ||
								topLeftUnits.x >= layerEntry.map.widthInTiles ||
								topLeftUnits.y >= layerEntry.map.heightInTiles )
							{
								continue;
							}
						}
						
						// If the layer isn't already in our tile list then add it.
						var layerData:TileEditorLayerEntry = null;
						
						var layerIndex:uint = selectedTiles.length;
						while( layerIndex-- )
						{
							var testLayerData:TileEditorLayerEntry = selectedTiles[layerIndex];
							if ( testLayerData.layer == layerEntry )
							{
								layerData = testLayerData;
								break;
							}
						}
						
						var addNewLayer:Boolean = false;
						if ( layerData == null )
						{
							layerData = new TileEditorLayerEntry( layerEntry as LayerMap, true );
							layerIndex = selectedTiles.length;
							addNewLayer = true;
						}
						
						var addedTileToNewLayer:Boolean = false;
						
						TileEditorRowEntry.xOffset = layerData.xOffset;
						
						if ( layerEntry.map.xStagger )
						{
							var tx:int = topLeft.x;
							var ty:int = topLeft.y;
							var storedPos:FlxPoint = new FlxPoint(tx, ty);
							var evenRow:int = layerEntry.map.xStagger > 0 ? 0 : 1;
							
							for ( var iy:int = topLeftUnits.y; iy <= bottomRightUnits.y; iy++ )
							{
								for ( var ix:int = topLeftUnits.x; ix <= bottomRightUnits.x; ix++)
								{
									if ( layerEntry.map.tileIsValid( tx, ty ) )
									{
										// Get the row or insert a new one.
										var rowIndex:uint = layerData.GetRow( ty, true, false );
										var rowData:TileEditorRowEntry = layerData.rows[rowIndex] as TileEditorRowEntry;

										if ( addRemoveTile(layerEntry, layerData, layerIndex, rowIndex, rowData, tx, ty) )
										{
											if ( addNewLayer )
											{
												selectedTiles.push( layerData );
												addNewLayer = false;
												addedTileToNewLayer = true;
											}
										}
									}
									// if on even then move (0,1), if odd then move (1,1)
									if ( ty % 2 == evenRow )
									{
										ty += 1;
									}
									else
									{
										tx += 1;
										ty += 1;
									}
								}
								
								// if on even then move (-1,1), if odd then move (0,1)
								if ( storedPos.y % 2 == evenRow )
								{
									tx = storedPos.x = storedPos.x - 1;
									ty = storedPos.y = storedPos.y + 1;
								}
								else
								{
									tx = storedPos.x;
									ty = storedPos.y = storedPos.y + 1;
								}
							}
						}
						else
						{
							for ( iy = topLeftUnits.y; iy <= bottomRightUnits.y; iy++ )
							{
								if ( iy >= 0 && iy < layerEntry.map.heightInTiles )
								{
									// Get the row or insert a new one.
									rowIndex = layerData.GetRow( iy, true, false );
									rowData = layerData.rows[rowIndex] as TileEditorRowEntry;
											
									for ( ix = topLeftUnits.x; ix <= bottomRightUnits.x; ix++)
									{
										if ( ix >= 0 && ix < layerEntry.map.widthInTiles )
										{
											if ( addRemoveTile(layerEntry, layerData, layerIndex, rowIndex, rowData, ix, iy) )
											{
												if ( addNewLayer )
												{
													selectedTiles.push( layerData );
													addNewLayer = false;
													addedTileToNewLayer = true;
												}
											}
										}
									}
								}
							}
							
						}
						if ( !addedTileToNewLayer )
						{
							layerEntry.map.selectedTiles = null;
						}
					}
				}
			}
			
			return ( selectedTiles.length > 0 );
		}
		
		// Adds or Removes a tile to the selection.
		private function addRemoveTile( layerEntry:LayerEntry, layerData:TileEditorLayerEntry, layerIndex:uint, rowIndex:uint, rowData:TileEditorRowEntry, tilex:int, tiley:int):Boolean
		{
			if( !layerEntry.map.tileIsValid(tilex,tiley))
			{
				return false;
			}
			var tileIndex:uint = rowData.GetTile( tilex, false, false );
										
			if ( tileIndex >= rowData.tiles.length || ( tileIndex >=0 && tileIndex < rowData.tiles.length && rowData.tiles[tileIndex].startX != tilex ) )
			{
				var tileData:TileEditorTileEntry = new TileEditorTileEntry(tilex);
				tileData.startX = tilex;
				tileData.tileId = layerEntry.map.getTile( tilex, tiley );
				if ( !SelectHiddenTiles && tileData.tileId < layerEntry.map.drawIndex )
				{
					return false;
				}
				
				tileData.replaceTileId = 0;
				if ( layerEntry.map.stackedTiles )
				{
					tileData.SetStack( layerEntry.map.stackedTiles[ (tiley * layerEntry.map.widthInTiles) + tilex ] );
				}
				rowData.tiles.splice( tileIndex, 0, tileData );
				layerEntry.map.selectedTiles[ (tiley * layerEntry.map.widthInTiles) + tilex ] = true; 
				return true;
			}
			else if ( FlxG.keys.pressed( "CONTROL" ) )
			{
				rowData.tiles.splice( tileIndex, 1);
				layerEntry.map.selectedTiles[ (tiley * layerEntry.map.widthInTiles) + tilex ] = false; 
				if ( rowData.tiles.length == 0 )
				{
					layerData.rows.splice( rowIndex, 1 );
				}
				if ( layerData.rows.length == 0 )
				{
					selectedTiles.splice( layerIndex, 1 );
				}
			}
			return false;
		}
		
		override protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint
		{
			if ( ResizeMapMode && inSelectionMode )
			{
				movingMap = false;
				resizingMap = false;
				calculatedMapClips = false;
				
				var x1:int = layer.map.x;
				var x2:int = x1 + layer.map.width;
				var y1:int = layer.map.y;
				var y2:int = y1 + layer.map.height;
				
				// Check corners.
				if ( transformHandles[4].selected )
				{
					resizeHandlePos.create_from_points(0, 0);
					resizingMap = true;
				}
				else if ( transformHandles[5].selected )
				{
					resizeHandlePos.create_from_points(1, 0);
					resizingMap = true;
				}
				else if ( transformHandles[7].selected )
				{
					resizeHandlePos.create_from_points(0, 1);
					resizingMap = true;
				}
				else if ( transformHandles[6].selected )
				{
					resizeHandlePos.create_from_points(1, 1);
					resizingMap = true;
				}
				// Test sides.
				else if ( transformHandles[0].selected )
				{
					resizeHandlePos.create_from_points(0.5, 0);
					resizingMap = true;
				}
				else if ( transformHandles[1].selected )
				{
					resizeHandlePos.create_from_points(1, 0.5);
					resizingMap = true;
				}
				else if ( transformHandles[2].selected )
				{
					resizeHandlePos.create_from_points(0.5, 1);
					resizingMap = true;
				}
				else if ( transformHandles[3].selected )
				{
					resizeHandlePos.create_from_points(0, 0.5);
					resizingMap = true;
				}
				if ( resizingMap )
				{
					return SELECTED_ITEM;
				}
				// Check main box.
				if ( transformHandles[8].selected )
				{
					mapMoveMouseStartPos = FlxPoint.CreateObject(mousePos);
					mapMoveStartPos = FlxPoint.CreateObject(layer.map);
					HistoryStack.BeginOperation( new OperationMoveMap( layer as LayerMap ) );
					movingMap = true;
					return SELECTED_ITEM;
				}
				return SELECTED_NONE;
			}
			if ( !inSelectionMode )
			{
				return SELECTED_NONE;
			}
			if ( FlxG.keys.pressed( "SHIFT" ) )
			{
				return SELECTED_NONE;
			}
			
			var selectedTilesCopy:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
			for each( layerData in selectedTiles )
			{
				selectedTilesCopy.push(layerData.Clone());
			}
			HistoryStack.BeginOperation( new OperationChangeTileSelection( selectedTilesCopy ) );
			
			var layerIndex:uint = selectedTiles.length;
			while( layerIndex-- )
			{
				var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
				
				var unitMapPosX:int = currentTile.x;
				var unitMapPosY:int = currentTile.y;
				
				if ( layer != layerData.layer )
				{
					var tempPt:FlxPoint = new FlxPoint;
					GetTileInfo(layerData.layer.map, mousePos.x - layerData.layer.map.x, mousePos.y - layerData.layer.map.y, tempPt, null );
					unitMapPosX = tempPt.x;
					unitMapPosY = tempPt.y;
				}
			
				TileEditorRowEntry.xOffset = layerData.xOffset;
				
				// Get the row or insert a new one.
				var rowIndex:int = layerData.GetRow( unitMapPosY, false, true );
				if ( rowIndex == -1 )
				{
					continue;
				}
				var rowData:TileEditorRowEntry = layerData.rows[rowIndex] as TileEditorRowEntry;
				
				var tileIndex:int = rowData.GetTile( unitMapPosX, false, true );
				if ( tileIndex == -1 )
				{
					continue;
				}
				if ( FlxG.keys.pressed( "CONTROL" ) )
				{
					/*rowData.tiles.splice( tileIndex, 1);
					if ( rowData.tiles.length == 0 )
					{
						layerData.rows.splice( rowIndex, 1 );
					}
					if ( layerData.rows.length == 0 )
					{
						selectedTiles.splice( layerIndex, 1 );
					}*/
					// It should actually only remove once you release the mouse
					// so that we can determine if it was as click or a box select.
					return SELECTED_AND_REMOVED;
				}
				else
				{
					return SELECTED_ITEM;
				}
			}
			
			// Hold SHIFT to add new items to the selection.
			if (clearIfNoSelection && !FlxG.keys.pressed( "CONTROL" ) )
			{
				ClearSelection();
			}
			return SELECTED_NONE;
		}
		
		override protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			if ( ResizeMapMode )
			{
				return;
			}
			var layerIndex:uint = selectedTiles.length;
			while( layerIndex-- )
			{
				var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
				var map:FlxTilemapExt = layerData.layer.map;
				var tileWidth:uint = map.tileWidth;
				var tileHeight:uint = map.tileHeight;
		
				var xOffset:int = Math.floor( screenOffsetFromOriginalPos.x / map.tileSpacingX );
				var yOffset:int = Math.floor( screenOffsetFromOriginalPos.y / map.tileSpacingY );
				
				if ( map.tileOffsetX || map.tileOffsetY )
				{
					// Perform a simpler version of GetTileInfo.
					// Treat the position where movement started as 0,0 on the map and the offset is the number 
					// of tiles moved in each axis.
					var realOffset:FlxPoint = new FlxPoint;
					// Get the right edge of the map
					var endxx:Number = map.tileSpacingX * map.widthInTiles;
					var endxy:Number = map.tileOffsetY * map.widthInTiles;
					
					Hits.LineRayIntersection(0, 0, endxx, endxy, screenOffsetFromOriginalPos.x, screenOffsetFromOriginalPos.y, screenOffsetFromOriginalPos.x - layerData.layer.map.tileOffsetX, screenOffsetFromOriginalPos.y - layerData.layer.map.tileSpacingY, realOffset);
					realOffset.y = screenOffsetFromOriginalPos.y - realOffset.y;
					
					xOffset = realOffset.x / map.tileSpacingX
					yOffset = realOffset.y / map.tileSpacingY;
					
					// Account for the -0,+0 1 tile error on each axis.
					if ( realOffset.x < 0 )
						xOffset--;
					if ( realOffset.y <= 0 )
						yOffset--;
				}

				if ( xOffset == layerData.xOffset && yOffset == layerData.yOffset )
				{
					continue;
				}
				
				
				
				// First replace all the old tiles. This has to be done in 1 go before painting the new tiles because
				// We will likely be replacing tiles that were already replaced and don't want to get confused results.
				var rowIndex:uint = layerData.rows.length;
				while(rowIndex--)
				{
					var rowData:TileEditorRowEntry = layerData.rows[rowIndex];
					var oldY:int = rowData.startY + layerData.yOffset;
					var diffRow:Boolean = map.xStagger && (Math.abs(oldY % 2) != Math.abs(rowData.startY % 2));
					var tileIndex:uint = rowData.tiles.length;
					while(tileIndex--)
					{
						var tileData:TileEditorTileEntry = rowData.tiles[tileIndex];
						var oldX:int = tileData.startX + layerData.xOffset;
						if ( diffRow )
						{
							if( oldY % 2 )
								oldX += map.xStagger > 0 ? -1 : 1;
						}
						if ( oldX >= 0 && oldY >= 0 && oldX < map.widthInTiles && oldY < map.heightInTiles )
						{
							map.setTile( oldX, oldY, tileData.replaceTileId );
							if( map.selectedTiles )
							{
								map.selectedTiles[ oldY * map.widthInTiles + oldX ] = false;
							}
							if ( layerData.layer.map.stackedTiles )
							{
								var idx:int = oldY * map.widthInTiles + oldX;
								if ( tileData.replaceStack && !map.stackedTiles[ idx ] )
									map.numStackedTiles++;
								else if ( !tileData.replaceStack && map.stackedTiles[ idx ] )
									map.numStackedTiles--;
								map.stackedTiles[ idx ] = tileData.replaceStack;
								if ( !map.stackedTiles[ idx ] )
									delete map.stackedTiles[ idx ];
							}
						}
					}
				}
				
				layerData.xOffset = xOffset;
				layerData.yOffset = yOffset;
				
				// Finally replace the new area under the selection with the tiles in the selection.
				rowIndex = layerData.rows.length;
				while(rowIndex--)
				{
					rowData = layerData.rows[rowIndex];
					var newY:int = rowData.startY + layerData.yOffset;
					diffRow = map.xStagger && (Math.abs(newY % 2) != Math.abs(rowData.startY % 2));
					if ( newY >= 0 && newY < map.heightInTiles )
					{
						tileIndex = rowData.tiles.length;
						while(tileIndex--)
						{
							tileData = rowData.tiles[tileIndex];
							var newX:int = tileData.startX + layerData.xOffset;
							if ( diffRow )
							{
								if( newY % 2 )
									newX += layerData.layer.map.xStagger > 0 ? -1 : 1;
							}
							if ( newX >= 0 && newX < map.widthInTiles )
							{
								tileData.replaceTileId = map.getTile( newX, newY );
								//TODO: should it place a tile down if the new tile is tile 0? Maybe an option to set the invisible tile or an option when moving?
								//if ( tileData.tileId > 0 )
								{
									map.setTile( newX, newY, tileData.tileId );
									map.selectedTiles[ newY * map.widthInTiles + newX ] = true;
								}
								if ( layerData.layer.map.stackedTiles )
								{
									idx = newY * map.widthInTiles + newX;
									tileData.replaceStack = map.stackedTiles[ idx ];
									if ( tileData.tileStack && !map.stackedTiles[ idx ] )
										map.numStackedTiles++;
									else if ( !tileData.tileStack && map.stackedTiles[ idx ] )
										map.numStackedTiles--;
									map.stackedTiles[ idx ] = tileData.tileStack;
									if ( !map.stackedTiles[ idx ] )
										delete map.stackedTiles[ idx ];
								}
							}
						}
					}
				}
			}

		}
		
		override protected function BeginTransformation():void
		{
			if ( ResizeMapMode && inSelectionMode )
			{
				return;
			}
			var selectedTilesCopy:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
			
			for each( var layerData:TileEditorLayerEntry in selectedTiles )
			{
				selectedTilesCopy.push(layerData.Clone());
			}
			HistoryStack.BeginOperation( new OperationMoveTiles( selectedTilesCopy ) );
		}
		
		override protected function ConfirmMovement( ):void
		{
			if ( ResizeMapMode && inSelectionMode )
			{
				if ( resizingMap)
				{
					var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
					if ( calculatedMapClips && 
						( mapLayer.map.clipLeft != 0 || mapLayer.map.clipTop != 0 || mapLayer.map.clipRight != mapLayer.map.widthInTiles || mapLayer.map.clipBottom != mapLayer.map.heightInTiles ) )
					{
						var hAlign:Number = resizeHandlePos.x == 0 ? 1 : 0;
						var vAlign:Number = resizeHandlePos.y == 0 ? 1 : 0;
						HistoryStack.BeginOperation( new OperationResizeMap( mapLayer ) );
						mapLayer.map.resizeMap(mapLayer.map.clipRight - mapLayer.map.clipLeft, mapLayer.map.clipBottom - mapLayer.map.clipTop, mapLayer.map.tileWidth, mapLayer.map.tileHeight, hAlign, vAlign, true);
					}
				}
				movingMap = resizingMap = false;
				return;
			}
			var layerIndex:uint = selectedTiles.length;
			while( layerIndex-- )
			{
				var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
				for each ( var rowData:TileEditorRowEntry in layerData.rows )
				{
					var newY:int = rowData.startY + layerData.yOffset;
					
					var diffRow:Boolean = layerData.layer.map.xStagger && (Math.abs(newY % 2) != Math.abs(rowData.startY % 2));

					for each( var tileData:TileEditorTileEntry in rowData.tiles )
					{
						tileData.startX = tileData.startX + layerData.xOffset;
						if( diffRow )
						{
							if( newY % 2 )
								tileData.startX += layerData.layer.map.xStagger > 0 ? -1 : 1;
						}
					}
					rowData.startY = newY;
				}
				
				layerData.xOffset = 0;
				layerData.yOffset = 0;
			}
		}
		
		public function RestoreSelection( selection:Object, replaceOriginals:Boolean ):void
		{
			// First set any tiles in the current selection to their original values.
			if ( replaceOriginals )
			{
				var layerIndex:uint = selectedTiles.length;
				while( layerIndex-- )
				{
					var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];		
					var map:FlxTilemapExt = layerData.layer.map;
					
					for each ( var rowData:TileEditorRowEntry in layerData.rows )
					{
						var y:int = rowData.startY + layerData.yOffset;
						for each( var tileData:TileEditorTileEntry in rowData.tiles )
						{
							var x:int = tileData.startX + layerData.xOffset;
							if ( x >= 0 && y >= 0 )
							{
								map.setTile( x, y, tileData.replaceTileId );
								if ( map.stackedTiles )
								{
									var idx:int = y * map.widthInTiles + x;
									if ( tileData.replaceStack && !map.stackedTiles[ idx ] )
										map.numStackedTiles++;
									else if ( !tileData.replaceStack && map.stackedTiles[ idx ] )
										map.numStackedTiles--;
									map.stackedTiles[ idx ] = tileData.replaceStack;
									if ( !map.stackedTiles[ idx ] )
										delete map.stackedTiles[ idx ];
								}
							}
						}
					}
				}
			}
			
			// Now restore the saved selection and put the tiles in the correct places on the maps.
			selectedTiles = selection as Vector.<TileEditorLayerEntry>;
			
			layerIndex = selectedTiles.length;
			while( layerIndex-- )
			{
				layerData = selectedTiles[layerIndex];
				map = layerData.layer.map;
				map.selectedTiles = new Vector.<Boolean>(map.totalTiles);
				for each ( rowData in layerData.rows )
				{
					y = rowData.startY + layerData.yOffset;

					for each( tileData in rowData.tiles )
					{
						x = tileData.startX + layerData.xOffset;
						if ( map.tileIsValid(x, y ) )
						{
							idx = y * map.widthInTiles + x;
							map.setTile( x, y, tileData.tileId );
							map.selectedTiles[ idx ] = true; 
							if ( map.stackedTiles )
							{
								if ( tileData.tileStack && !map.stackedTiles[ idx ] )
									map.numStackedTiles++;
								else if ( !tileData.tileStack && map.stackedTiles[ idx ] )
									map.numStackedTiles--;
								map.stackedTiles[ idx ] = tileData.tileStack;
								if ( !map.stackedTiles[ idx ] )
									delete map.stackedTiles[ idx ];
							}
						}
					}
				}
				if( map.numStackedTiles <= 0 )
				{
					map.numStackedTiles = 0;
					map.stackedTiles = null;
				}
			}
		}
		
		override protected function DeleteSelection( ):void
		{
			var selectedTilesCopy:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
			
			for each( layerData in selectedTiles )
			{
				selectedTilesCopy.push(layerData.Clone());
			}
			HistoryStack.BeginOperation( new OperationChangeTileSelection( selectedTilesCopy ) );
			
			var layerIndex:uint = selectedTiles.length;
			while( layerIndex-- )
			{
				var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
				for each ( var rowData:TileEditorRowEntry in layerData.rows )
				{
					var y:int = rowData.startY + layerData.yOffset;
					
					if ( y >= 0 && y < layerData.layer.map.heightInTiles )
					{
						for each( var tileData:TileEditorTileEntry in rowData.tiles )
						{
							var x:int = tileData.startX + layerData.xOffset;
							if ( x >= 0 && x < layerData.layer.map.widthInTiles )
							{
								layerData.layer.map.setTile( x, y, layerData.layer.EraseTileIdx );
								if ( layerData.layer.map.stackedTiles )
								{
									var idx:int = y * layerData.layer.map.widthInTiles + x;
									if ( layerData.layer.map.stackedTiles[ idx ] )
									{
										layerData.layer.map.numStackedTiles--;
										delete layerData.layer.map.stackedTiles[ idx ];
									}
								}
							}
						}
					}
				}
			}
			
			selectedTiles.length = 0;
		}
		
		override public function CopyData():void
		{
			// Can only copy the data from the current layer, unless only 1 layer is selected.
			if ( selectedTiles.length > 1 )
			{
				var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
				
				if ( mapLayer == null )
				{
					return;
				}
				
				var layerIndex:uint = selectedTiles.length;
				while( layerIndex-- )
				{
					var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
					if ( layerData.layer == mapLayer )
					{
						Clipboard.SetData( layerData.Clone() );
					}
				}
				
			}
			else if ( selectedTiles.length == 1 )
			{
				Clipboard.SetData( selectedTiles[0].Clone() );
			}
		}
		
		override public function PasteData():void
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			
			if ( mapLayer == null || !mapLayer.IsVisible() || mapLayer.Locked())
			{
				return;
			}
			
			var layerData:TileEditorLayerEntry = Clipboard.GetData() as TileEditorLayerEntry;
			
			if ( layerData == null)
			{
				return;	// the wrong type of data for this editorType.
			}
			
			var selectedTilesCopy:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
			
			for each( var tempLayer:TileEditorLayerEntry in selectedTiles )
			{
				selectedTilesCopy.push(tempLayer.Clone());
			}
			HistoryStack.BeginOperation( new OperationPasteTiles( selectedTilesCopy ) );
			
			selectedTiles.length = 0;
			selectedTiles.push( layerData );
			layerData.layer.map.selectedTiles = new Vector.<Boolean>(layerData.layer.map.totalTiles);
			
			layerData.layer = mapLayer;
			
			DrawLayerEntry( layerData, currentTile.x, currentTile.y, false );
		}
		
		private function DrawLayerEntry(layerData:TileEditorLayerEntry, xpos:int, ypos:int, ignoreWhiteSpace:Boolean ):void
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			
			if ( mapLayer == null || !mapLayer.IsVisible())
			{
				return;
			}
			
			if ( layerData == null)
			{
				return;	// the wrong type of data for this editorType.
			}
					
			layerData.xOffset = 0;
			layerData.yOffset = 0;
			
			var oldStartY:int = 0;
			var starty:int = 0;
			var startYMod:int = 0;
			
			var setOffset:Boolean = false;
			var map:FlxTilemapExt = mapLayer.map;
			for ( var i:uint = 0; i < layerData.rows.length; i++ )
			{
				var rowData:TileEditorRowEntry = layerData.rows[i];
				if ( setOffset )
				{
					rowData.startY += layerData.yOffset;
					var y:int = rowData.startY;// + layerData.yOffset;
				}

				for ( var j:uint = 0; j < rowData.tiles.length; j++ )
				{
					var tileData:TileEditorTileEntry = rowData.tiles[j];
					if ( !setOffset )
					{
						// The selection is offset so the first tile is where the cursor is.
						setOffset = true;
						
						oldStartY = rowData.startY + layerData.yOffset;
						
						layerData.xOffset = xpos - tileData.startX;
						layerData.yOffset = ypos - rowData.startY;
						
						
						// Need to recalculate y again.
						rowData.startY += layerData.yOffset;
						y = rowData.startY;// + layerData.yOffset;
						starty = y;
						startYMod = starty % 2;
					}
					
					tileData.startX += layerData.xOffset;
					
					if ( mapLayer.map.xStagger && (oldStartY%2 != startYMod ) && (y%2 != startYMod ) )
					{
						var dir:int = startYMod == 0 ? -1 : 1;
						tileData.startX += ( dir * (mapLayer.map.xStagger > 0 ? 1 : -1) );
					}
					
					//var y:int = rowData.startY + layerData.yOffset;
					var x:int = tileData.startX;// + layerData.xOffset;
					
					
					
					if ( xpos < 0  ||
						ypos < 0  ||
						xpos >= map.widthInTiles ||
						ypos >= map.heightInTiles )
					{
						tileData.replaceTileId = 0;
					}
					else if( !ignoreWhiteSpace || tileData.tileId >= map.drawIndex )
					{
						if ( x >= 0 && x < map.widthInTiles && y >= 0 && y < map.heightInTiles )
						{
							tileData.replaceTileId = map.getTile( x, y );
							map.setTile( x, y, tileData.tileId );
							if ( map.selectedTiles )
							{
								map.selectedTiles[ y * map.widthInTiles + x ] = true;
							}
							if ( !map.stackedTiles && tileData.tileStack )
							{
								map.stackedTiles = new Dictionary;
							}
							if ( map.stackedTiles )
							{
								var idx:int = y * map.widthInTiles + x;
								if ( tileData.tileStack && !map.stackedTiles[ idx ] )
									map.numStackedTiles++;
								else if ( !tileData.tileStack && map.stackedTiles[ idx ] )
									map.numStackedTiles--;
								map.stackedTiles[ idx ] = tileData.tileStack;
								if ( !map.stackedTiles[ idx ] )
									delete map.stackedTiles[ idx ];
							}
						}
					}
				}
			}
			layerData.xOffset = 0;
			layerData.yOffset = 0;
		}
		
		public function GetSelection():TileEditorLayerEntry
		{
			var layer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( layer != null )
			{
				var layerIndex:uint = selectedTiles.length;
				while( layerIndex-- )
				{
					var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
					if ( layerData.layer == layer )
					{
						return layerData.Clone();
					}
				}
			}
			return null;
		}
		
		override public function SelectAll():void
		{
			// As this is a select all operation we can safely reset the entire selection.
			selectedTiles.length = 0;
			
			for each( var group:LayerGroup in App.getApp().layerGroups )
			{
				for each( var layerEntry:LayerEntry in group.children )
				{
					if ( Global.SelectFromCurrentLayerOnly && App.getApp().CurrentLayer != layerEntry )
					{
						continue;
					}
					if ( layerEntry is LayerMap && layerEntry.visible && !layerEntry.Locked() && layerEntry.map!=null && layerEntry.map.visible )
					{
						// If the layer isn't already in our tile list then add it.
						var layerData:TileEditorLayerEntry = new TileEditorLayerEntry( layerEntry as LayerMap, true );
						selectedTiles.push( layerData );
						
						TileEditorRowEntry.xOffset = layerData.xOffset;
						
						for ( var iy:int = 0; iy < layerEntry.map.heightInTiles; iy++ )
						{
							// Get the row or insert a new one.
							var rowIndex:uint = layerData.GetRow( iy, true, false );
							var rowData:TileEditorRowEntry = layerData.rows[rowIndex] as TileEditorRowEntry;
									
							for ( var ix:int = 0; ix < layerEntry.map.widthInTiles; ix++)
							{
								var tileIndex:uint = rowData.GetTile( ix, false, false );
								
								if ( tileIndex >= rowData.tiles.length || ( tileIndex >=0 && tileIndex < rowData.tiles.length && rowData.tiles[tileIndex].startX != ix ) )
								{
									var tileId:int = layerEntry.map.getTile( ix, iy );
									if ( !SelectHiddenTiles && tileId < layerEntry.map.drawIndex )
									{
										continue;
									}
									var tileData:TileEditorTileEntry = new TileEditorTileEntry(ix);
									tileData.startX = ix;
									tileData.tileId = tileId;
									tileData.replaceTileId = 0;
									if ( layerEntry.map.stackedTiles )
									{
										tileData.SetStack( layerEntry.map.stackedTiles[ (iy * layerEntry.map.widthInTiles) + ix ] );
									}
									rowData.tiles.splice( tileIndex, 0, tileData );
								}
							}
							var i:int = layerEntry.map.totalTiles;
							while (i--)
							{
								layerEntry.map.selectedTiles[i] = true;
							}
						}
					}
				}
			}
		}
		
		//{ region private
		
		private function FindLayerInSelected( layer:LayerMap):TileEditorLayerEntry
		{
			if( selectedTiles.length > 0 )
			{
				var layerIndex:uint = selectedTiles.length;
				while( layerIndex-- )
				{
					var layerData:TileEditorLayerEntry = selectedTiles[layerIndex];
					if ( layerData.layer == layer )
					{
						return layerData;
					}
				}
			}
			return null;
		}
		
		private function FindTileInSelectedLayerData( layerData:TileEditorLayerEntry, x:int, y:int):TileEditorTileEntry
		{
			if ( layerData == null )
			{
				return null;
			}
			var rowIndex:int = layerData.GetRow( y, false, true );
			if ( rowIndex != -1 )
			{
				var rowData:TileEditorRowEntry = layerData.rows[rowIndex] as TileEditorRowEntry;
				var tileIndex:int = rowData.GetTile( x, false, true );
				if ( tileIndex != -1 )
				{
					// This tile is in the selection.
					var tileData:TileEditorTileEntry = rowData.tiles[tileIndex] as TileEditorTileEntry;
					return tileData;
				}
			}
			return null;
		}
		
		private function drawBrushCallback( x:int, y:int, drawData:Object ):void
		{
			DrawLayerEntry(drawData.brush, x, y,App.getApp().brushesWindow.IgnoreWhiteSpace.selected);
		}
		
		private function paintBrushInLine( layer:LayerMap, x1:int, y1:int, x2:int, y2:int, brush:TileEditorLayerEntry ):void
		{
			var drawData:Object = new Object();
			drawData.brush = brush;
			drawData.layer = layer;
			var map:FlxTilemapExt = layer.map;
			
			if ( layer.map.xStagger )
			{
				// Paint the first and last tiles as they don't need calculating.
				drawBrushCallback( x1, y1, drawData);
				drawBrushCallback( x2, y2, drawData);
				
				if ( lastHeldMousePos.x == -1 || lastHeldMousePos.y == -1 )
					return;
				if ( lastHeldMousePos.x == mousePos.x && lastHeldMousePos.y == mousePos.y )
					return;
				
				// Convert map using real coords.
				var diff:FlxPoint = new FlxPoint( mousePos.x - lastHeldMousePos.x, mousePos.y - lastHeldMousePos.y );
				var norm:FlxPoint = diff.normalized();
				var len:Number = diff.magnitude();
				// Estimate the size of each step. Make it small so we have a better chance of covering each tile.
				var step:Number = Math.min( Math.abs( layer.map.xStagger ) * 0.85, layer.map.tileSpacingY * 0.85 );
				
				var newPos:FlxPoint = new FlxPoint;
				for ( var travelled:Number = step; travelled < len; travelled += step )
				{
					var x:Number = lastHeldMousePos.x + ( travelled * norm.x ) - layer.map.x;
					var y:Number = lastHeldMousePos.y + ( travelled * norm.y ) - layer.map.y;

					if ( GetTileInfo( layer.map, x, y, newPos, null ) )
					{
						if ( ( newPos.x != x1 || newPos.y != y1 ) && ( newPos.x != x2 || newPos.y != y2 ) )
						{
							drawBrushCallback( newPos.x, newPos.y, drawData );
						}
					}
				}
				return;
			}
			
			if ( x1 == -1 || y1 == -1 )
			{
			   drawBrushCallback( x2, y2, drawData);
			   return;
			}
			
			Misc.DrawCustomLine( x1, y1, x2, y2, drawBrushCallback, drawData );
		}
		
		private function drawCallback( x:int, y:int, drawData:Object ):void
		{
			var layerData:TileEditorLayerEntry = FindLayerInSelected( drawData.layer );
			if ( layerData != null )
			{
				var tileData:TileEditorTileEntry = FindTileInSelectedLayerData(layerData, x, y);
				if ( tileData == null )
				{
					// When we have a selection then disallow painting outside the selection.
					return;
				}
				tileData.tileId = drawData.tileId;
			}
			if ( (!drawData.TopMost && (!currentTileHeight || !drawData.layer.map.stackHeight) ) || Global.DrawTilesWithoutHeight )
			{
				drawData.layer.map.setTile( x, y, drawData.tileId);
			}
			else
			{
				drawData.layer.map.setHighTile( x, y, currentTileHeight, drawData.TopMost, InfiniteStacking, drawData.tileId );
			}
		}
		
		private function setAllTilesInLine( layer:LayerMap, x1:int, y1:int, x2:int, y2:int, tileId:uint ):void
		{
			var drawData:Object = new Object();
			drawData.tileId = tileId;
			drawData.layer = layer;
			drawData.TopMost = false;
			
			if ( layer.map.stackHeight )
			{
				var time:uint = getTimer();
				var dist:Number = (x1 == -1 && y1 == -1 ) ? 0 : Math.sqrt( ( (x1 - x2) * (x1 - x2) ) + ( (y1 - y2) * (y1 - y2) ) );
				if ( time - lastTimePlacedstackedTiles < 200 && dist == 0 )
				{
					return;
				}
				lastTimePlacedstackedTiles = time;
				drawData.TopMost = FlxG.keys.Z || (InfiniteStacking && currentTileHeight);
			}
			
			if ( layer.map.xStagger )
			{
				// Paint the first and last tiles as they don't need calculating.
				drawCallback( x1, y1, drawData);
				if( x1 != x2 && y1 != y2 )
					drawCallback( x2, y2, drawData);
				
				if ( lastHeldMousePos.x == -1 || lastHeldMousePos.y == -1 )
					return;
				if ( lastHeldMousePos.x == mousePos.x && lastHeldMousePos.y == mousePos.y )
					return;
				// Convert map using real coords.
				var diff:FlxPoint = new FlxPoint( mousePos.x - lastHeldMousePos.x, mousePos.y - lastHeldMousePos.y );
				var norm:FlxPoint = diff.normalized();
				var len:Number = diff.magnitude();
				// Estimate the size of each step. Make it small so we have a better chance of covering each tile.
				var step:Number = Math.min( Math.abs( layer.map.xStagger ) * 0.85, layer.map.tileSpacingY * 0.85 );
				
				var newPos:FlxPoint = new FlxPoint;
				var lastPos:FlxPoint = new FlxPoint(x1,y1);
				for ( var travelled:Number = step; travelled < len; travelled += step )
				{
					var x:Number = lastHeldMousePos.x + ( travelled * norm.x ) - layer.map.x;
					var y:Number = lastHeldMousePos.y + ( travelled * norm.y ) - layer.map.y;

					if ( GetTileInfo( layer.map, x, y, newPos, null ) )
					{
						if ( ( newPos.x != x1 || newPos.y != y1 ) && ( newPos.x != x2 || newPos.y != y2 ) && !newPos.equals(lastPos) )
						{
							drawCallback( newPos.x, newPos.y, drawData );
							lastPos.x = newPos.x;
							lastPos.y = newPos.y;
						}
					}
				}
				return;
			}
			
			if ( x1 == -1 || y1 == -1 )
			{
				drawCallback( x2, y2, drawData);
				return;
			}
			
			Misc.DrawCustomLine( x1, y1, x2, y2, drawCallback, drawData );
		}
		
		private function SelectUsingMagicWand( layer:LayerMap, selectedLayerData:TileEditorLayerEntry, x:int, y:int, onlyAllowSelected:Boolean ):BitmapData
		{
			openListX.length = 0;
			openListY.length = 0;
			openListIndices.length = 0;
			closedListX.length = 0;
			closedListY.length = 0;
			closedListIndices.length = 0;
			
			var map:FlxTilemapExt = layer.map;
			var testTileId:uint = map.getTile( x, y );
			var layerData:TileEditorLayerEntry = null;
			
			// If we are only scanning selected tiles then early exit if the tile we clicked on isn't selected.
			if ( onlyAllowSelected )
			{
				layerData = FindLayerInSelected( layer );
				if ( layerData != null )
				{
					var tileData:TileEditorTileEntry = FindTileInSelectedLayerData(layerData, x, y);
					if ( tileData == null )
					{
						return null;
					}
				}
			}
			
			var widthInTiles:int = map.widthInTiles;
			
			var bmp:BitmapData = new BitmapData(map.widthInTiles, map.heightInTiles, false, 0);
			var ty:int = map.heightInTiles;
			while (ty--)
			{
				var tx:int = map.widthInTiles;
				while (tx--)
				{
					if ( layerData )
					{
						tileData = FindTileInSelectedLayerData(layerData, tx, ty);
						if ( tileData == null )
						{
							bmp.setPixel(tx, ty, 0);
							continue;
						}
					}
					var tileId:int = map.getTile(tx, ty);
					
					if ( map.getTile(tx, ty) == testTileId )
					{
						bmp.setPixel(tx, ty, 1);
					}
					else
					{
						bmp.setPixel(tx, ty, 0);
					}
				}
			}
			
			bmp.floodFill(x, y, 2);
			
			if ( selectedLayerData == null )
			{
				return bmp;
			}
			
			if ( !SelectHiddenTiles && testTileId < layer.map.drawIndex )
			{
				return bmp;
			}
			
			
			TileEditorRowEntry.xOffset = selectedLayerData.xOffset;
			
			ty = map.heightInTiles;
			while (ty--)
			{
				tx = map.widthInTiles;
				while (tx--)
				{
					if ( bmp.getPixel(tx, ty) == 2 )
					{
						// Get the row or insert a new one.
						var rowIndex:uint = selectedLayerData.GetRow( ty, true, false );
						var rowData:TileEditorRowEntry = selectedLayerData.rows[rowIndex] as TileEditorRowEntry;
						
						var tileIndex:uint = rowData.GetTile( tx, true, false );
						tileData = rowData.tiles[tileIndex] as TileEditorTileEntry;
						
						tileData.startX = tx;
						tileData.tileId = testTileId;
						tileData.replaceTileId = 0;
						if ( layer.map.stackedTiles )
						{
							tileData.SetStack( layer.map.stackedTiles[ (ty * layer.map.widthInTiles) + tx ] );
						}
						layer.map.selectedTiles[ty * layer.map.widthInTiles + tx] = true;
					}
				}
			}
			return bmp;
		}
		
		override public function DeselectInvisible(): void
		{
			var changed:Boolean = false;
			if ( selectedTiles.length > 0 )
			{
				var i:uint = selectedTiles.length;
				while(i--)
				{
					var layerData:TileEditorLayerEntry = selectedTiles[i];
					if ( !layerData.layer.visible )
					{
						if ( !changed )
						{
							/*var selectedTilesCopy:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
							if ( layerData.rows.length > 0 )
							{
								var newLayerData:TileEditorLayerEntry = layerData.Clone();
								if ( newLayerData )
								{
									selectedTilesCopy.push( newLayerData );
								}
							}
							if ( selectedTilesCopy.length > 0 )
							{
								HistoryStack.BeginOperation( new OperationChangeTileSelection( selectedTilesCopy ) );
							}*/
							changed = true;
						}
						selectedTiles.splice(i, 1);
					}
				}
			}
		}
		
		override public function SelectNone():void
		{
			ClearSelection();
		}
		
		private function ClearSelection():void
		{
			var selectedTilesCopy:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
			if ( selectedTiles.length > 0 )
			{
				for each( var layerData:TileEditorLayerEntry in selectedTiles )
				{
					if ( layerData.rows.length > 0 )
					{
						var newLayerData:TileEditorLayerEntry = layerData.Clone();
						if ( newLayerData )
						{
							selectedTilesCopy.push( newLayerData );
						}
					}
					layerData.layer.map.selectedTiles = null;
				}
				if ( selectedTilesCopy.length > 0 )
				{
					HistoryStack.BeginOperation( new OperationChangeTileSelection( selectedTilesCopy ) );
				}
			}
			selectedTiles.length = 0;
		}
		
		//} endregion
		
	}

}