package com.Editor 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Layers.LayerSprites;
	import com.Operations.HistoryStack;
	import com.Operations.OperationDraw;
	import com.Operations.OperationDrawChangeSelection;
	import com.Operations.OperationModifyTiles;
	import com.Operations.OperationPaintTiles;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import com.Tiles.TileAnim;
	import com.Utils.BitmapUtils;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.desktop.ClipboardFormats;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.CapsStyle;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Shader;
	import flash.display.Shape;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BitmapFilterType;
	import flash.filters.GradientGlowFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import org.flixel.FlxGroup;
	import org.flixel.FlxPoint;
	import com.Utils.DebugDraw;
	import org.flixel.FlxG;

	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeDraw extends EditorType
	{
		public static var DrawColor:uint = 0xffffff;
		public static var DrawAlpha:Number = 1;
		public static var LineThickness:uint = 1;
		public static var UsingDropper:Boolean = false;
		public static var LockedTileMode:Boolean = false;
		public static var DrawNoise:Boolean = false;
		public static var DrawPerlin:Boolean = false;
		public static var PerlinScale:Number = 1;
		public static var DrawOnBaseOnly:Boolean = false;
		public static var DrawLines:Boolean = false;
		public static var DrawCircles:Boolean = false;
		public static var DrawEllipses:Boolean = false;
		public static var DrawBoxes:Boolean = false;
		public static var DrawPolyLines:Boolean = false;
		public static var ShapeFillAlpha:Number = 0;
		public static var ShapeFillColor:uint = 0xffffff;
		public static var Eraser:Boolean = false;
		public static var FloodFill:Boolean = false;
		public static var FloodFillTolerance:int = 5;
		public static var DrawNewTiles:Boolean = false;
		
		private var polylinePoints:Vector.<FlxPoint> = new Vector.<FlxPoint>;
		
		public static function get DrawFreehand():Boolean
		{
			return !DrawCircles && !DrawLines && !DrawBoxes && !DrawPolyLines && !DrawEllipses;
		}
		
		public static const DRAW_ALWAYS:uint = 0;
		public static const DRAW_ABOVE:uint = 1;
		public static const DRAW_BEHIND:uint = 2;
		
		public static var drawOrderMode:uint = DRAW_ALWAYS;
		
		private var _s:Shape;
		private var _drawnTiles:Vector.<DrawTileData>;
		
		private var noiseBitmap:Bitmap = new Bitmap();
		
		private var drawBoxBlend:Number = 0;
		private var drawBoxBlendDirection:int = 1;
		
		public var LockTileUnderCursor:Boolean = false;
		public var currentLockedTile:FlxPoint = new FlxPoint();
		public var currentLockedTilePos:FlxPoint = new FlxPoint();
		
		private var lastShapePos:FlxPoint = new FlxPoint();
		
		private var baseTileMask:BitmapData = null;
		
		[Embed(source="../../../assets/eyeDropperCursor.png")]
        private static var eyeDropperCursor:Class;
		
		[Embed(source="../../../assets/paintCursor.png")]
        private static var paintCursor:Class;
		
		private var selectionBitmap:BitmapData = null;
		private var selectionBitmapCopy:BitmapData = null;
		private var selectionTopLeft:FlxPoint = null;	// world pos of selection
		private var selectionBotRight:FlxPoint = null;
		private var selectionTopLeftBeforeMove:FlxPoint = new FlxPoint;
		private var drawingLayer:LayerMap = null;
		protected static var _isActive:Boolean = false;
		
		private var lineStartPos:FlxPoint = new FlxPoint;
		
		private var storedSelectionWidth:int;
		private var storedSelectionHeight:int;
		
		private var selectedSprite:EditorAvatar = null;
		private var waitForSelect:Boolean = false;
		private var hasStartedDrawing:Boolean = false;
		private var spriteForSelection:EditorAvatar = null;
		private var spriteForSelectionScale:FlxPoint = new FlxPoint;
		private var spriteForSelectionAngle:Number = 0;
		
		private var shapesGroup:ShapeDrawingGroup = new ShapeDrawingGroup;
		private static var newTileModeTileIds:Vector.<uint> = new Vector.<uint>;
		private var lastTilemapDrawn:LayerMap = null;
		private var shownDrawPolylinesPrompt:Boolean = false;
		
		private var dropperText:String = "";
		
		public function EditorTypeDraw( editor:EditorState ) 
		{
			super( editor );
			
			allowContinuousPainting = true;
			
			selectionEnabled = true;
			
			_s = new Shape();
			_drawnTiles = new Vector.<DrawTileData>();
			
			selectionAlignedWithMap = false;
			
			allowScaling = true;
			
			contextMenu = new NativeMenu();
			TileListHasBlankFirstTile = false;
		}
		
		public static function IsActiveEditor():Boolean { return _isActive; };
		
		override public function Update(isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			_isActive = isActive;
			
			if ( isActive)
			{
				FlxTilemapExt.DisablePlayAnims |= FlxTilemapExt.E_DisablePlayAnimsReason_Drawing;
				var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
				
				if ( mapLayer )
				{
					UpdateCurrentTile( mapLayer.map, mousePos.x - mapLayer.map.x * FlxG.extraZoom, mousePos.y - mapLayer.map.y * FlxG.extraZoom );
				}
				else if ( spriteForSelection )
				{
					if ( spriteForSelection.angle != spriteForSelectionAngle || !spriteForSelectionScale.equals(spriteForSelection.scale) )
					{
						spriteForSelection = null;
						_drawnTiles.length = 0;
						selectionBitmap = selectionBitmapCopy = null;
					}
				}
				
				if ( FlxG.keys.justPressed("E"))
				{
					Eraser = !Eraser;
					Global.windowedApp.EditModeDrawEraser.selected = Eraser;
				}
				if ( FlxG.keys.justPressed("L"))
				{
					if ( !Global.windowedApp.IsEditingProperty && !FlxG.keys.CONTROL && !FlxG.keys.ALT )
					{
						LockTileUnderCursor = !LockTileUnderCursor;
						currentLockedTile.copyFrom(currentTile);
						currentLockedTilePos.copyFrom(currentTileWorldPos);
					}
				}
				if ( FlxG.keys.SPACE )
				{
					if ( mapLayer || App.getApp().CurrentLayer is LayerSprites )
					{
						ApplyEyeDropper(App.getApp().CurrentLayer);
					}
				}
				
				if ( mapLayer && Global.DrawCurrentTileAbove )
				{
					var x:int = currentTile.x;
					var y:int = currentTile.y;
					var valid:Boolean;
					if ( LockTileUnderCursor )
					{
						valid = mapLayer.map.tileIsValid(currentLockedTile.x, currentLockedTile.y);
						if ( valid )
						{
							x = currentLockedTile.x;
							y = currentLockedTile.y;
						}
						else
							valid = currentTileValid;
					}
					else
						valid = currentTileValid;
					if( valid )
						mapLayer.map.drawTileAboveTileId = y * mapLayer.map.widthInTiles + x;
				}
			}
			else
			{
				shapesGroup.Disable();
				FlxTilemapExt.DisablePlayAnims &= ~FlxTilemapExt.E_DisablePlayAnimsReason_Drawing;
				if( shownDrawPolylinesPrompt )
				{
					shownDrawPolylinesPrompt = false;
					PromptManager.manager.HidePromptById("PolylineDrag");
				}
			}
			if ( waitForSelect && (!isActive || !(App.getApp().CurrentLayer is LayerSprites)) )
			{
				waitForSelect = false;
				PromptManager.manager.HidePrompt("Click on a sprite to select it.");
			}
		}
		
		override protected function UpdateDisplay( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			var spriteLayer:LayerSprites = layer as LayerSprites;
			var tileEntry:DrawTileData = null;
			var bitmap:BitmapData = null;
			
			if ( (mapLayer == null && spriteLayer == null ) || !layer.visible )
			{
				RemoveCurrentCursor();
				return;
			}
			
			if( mouseScreenPos.x > 0 && mouseScreenPos.y > 0 && mouseScreenPos.x < FlxG.width && mouseScreenPos.y < FlxG.height )
			{
				if( UsingDropper )
				{
					SetCurrentCursor(eyeDropperCursor, 0, -17);
					ApplyEyeDropper(layer, true);
				}
				else
				{
					SetCurrentCursor(paintCursor, 0, -17);
					dropperText = "";
				}
			}
			else
			{
				RemoveCurrentCursor();
				dropperText = "";
			}
			
			if ( spriteLayer )
			{
				var state:EditorState = FlxG.state as EditorState;
				
				if ( selectedSprite )
				{
					if ( selectedSprite.markForDeletion )
					{
						selectedSprite.RemoveAnimOverride();
						selectedSprite = null;
					}
					else
					{
						if ( App.getApp().myTileList.CustomData != selectedSprite.spriteEntry || App.getApp().myTileList.HasEmptyFirstTile )
						{
							updateTileListForSprite( selectedSprite.spriteEntry, false, null, ModifySprites);
						}
						selectedSprite.DrawBoundingBox( layer == selectedSprite.layer ? Global.SelectionColour : Global.SelectionColourOtherLayer, false, false );
					}
				}
				if ( selectionBitmap )
				{
					var scroll:FlxPoint = new FlxPoint(spriteLayer.xScroll, spriteLayer.yScroll);
					if ( isMovingItems )
						DebugDraw.DrawBox( selectionTopLeft.x, selectionTopLeft.y, selectionBotRight.x, selectionBotRight.y, 0, scroll, false, boxColour, false );
					else
						DebugDraw.DrawBox( selectionTopLeft.x, selectionTopLeft.y, selectionBotRight.x, selectionBotRight.y, 0, scroll, true, Global.MapBoundsColour, false );
					return;
				}
				for each( tileEntry in _drawnTiles )
				{
					var sprite:EditorAvatar = tileEntry.sprite;
					if ( sprite )
					{
						bitmap = UpdateBitmap(tileEntry);
						sprite.ReplaceCurrentFrameBitmap(bitmap);
						//set spriteEntry for current sprite - needs to be done just for flipped sprites.
						sprite.SetFromSpriteEntry( sprite.spriteEntry, true, true );
					}
				}
				return;
			}
			
			if ( HighlightCurrentTile )
			{
				mapLayer.map.highlightTileIndexForThisFrame = App.getApp().myTileList.GetMetaDataAtIndex(App.getApp().myTileList.selectedIndex) as int;
			}
			
			var boxColour:uint = LockTileUnderCursor ? 0x88ffff00 : Global.TileUnderCursorColour;
			if ( hasLeftMouseDown )//|| hasRightMouseDown )
			{
				drawBoxBlend += FlxG.elapsed * drawBoxBlendDirection * 0.5;
				if ( drawBoxBlend > 1 )
				{
					drawBoxBlend = 1;
					drawBoxBlendDirection = -1;
				}
				else if (drawBoxBlend <= 0 )
				{
					drawBoxBlend = 0;
					drawBoxBlendDirection = 1;
				}
				
				boxColour = Misc.blendARGB(Global.TileDrawnColour1, Global.TileDrawnColour2, drawBoxBlend);
			}
			else
			{
				drawBoxBlend = 0;
			}
			DebugDraw.DrawBox( mapLayer.map.x>>FlxG.zoomBitShifter, mapLayer.map.y>>FlxG.zoomBitShifter, (mapLayer.map.x + mapLayer.map.width)>>FlxG.zoomBitShifter, (mapLayer.map.y + mapLayer.map.height)>>FlxG.zoomBitShifter, 0, mapLayer.map.scrollFactor, false, Global.MapBoundsColour, true);
			
			if ( LockTileUnderCursor )
			{
				if ( mapLayer.map.tileIsValid(currentLockedTile.x, currentLockedTile.y ) )
					DrawBoxAroundTile( mapLayer.map, currentLockedTilePos.x, currentLockedTilePos.y, boxColour, 0 );
			}
			else if( currentTileValid )
				DrawBoxAroundTile( mapLayer.map, currentTileWorldPos.x, currentTileWorldPos.y, boxColour, 0, true );
				
			if ( selectionBitmap )
			{
				if ( isMovingItems )
					DebugDraw.DrawBox( selectionTopLeft.x + layer.map.x, selectionTopLeft.y + layer.map.y, selectionBotRight.x + layer.map.x, selectionBotRight.y + layer.map.y, 0, mapLayer.map.scrollFactor, false, boxColour, false );
				else
					DebugDraw.DrawBox( selectionTopLeft.x + layer.map.x, selectionTopLeft.y + layer.map.y, selectionBotRight.x + layer.map.x, selectionBotRight.y + layer.map.y, 0, mapLayer.map.scrollFactor, true, Global.MapBoundsColour, false );
				return;
			}
			
			for each( tileEntry in _drawnTiles )
			{
				bitmap = UpdateBitmap(tileEntry);
				layer.map.SetTileBitmap(tileEntry.tileId, bitmap );
			}
		}
		
		private function UpdateBitmap(tileEntry:DrawTileData):BitmapData
		{
			// Ensure that each tile is rendered up to date as single continuous line with the desired alpha.
			// If we had just painted directly onto the tiles then the alpha would be irregular.
			
			var bitmap:BitmapData = tileEntry.sourceBitmap.clone();
			bitmap.lock();
			var brushBitmap:BitmapData = tileEntry.fakeBitmap;
			var bmp:Bitmap;
			// To use the blend modes properly need to wrap up the bitmapdata in bitmap.
			if ( ( DrawNoise || DrawPerlin ) && noiseBitmap!=null )
			{
				brushBitmap = tileEntry.fakeBitmap.clone();
				bmp = new Bitmap(brushBitmap);
				bmp.bitmapData.draw(noiseBitmap, null, null, "alpha");
			}
			else
			{
				bmp = new Bitmap(brushBitmap);
			}
			if ( (DrawOnBaseOnly || Global.DrawTilesWithoutHeight ) && baseTileMask )
			{
				var newBmp:BitmapData = new BitmapData(bmp.width, bmp.height,true,0x00000000);
				newBmp.copyPixels(bmp.bitmapData, bmp.getRect(null), new Point, baseTileMask, null, true);
				bmp.bitmapData = newBmp;
			}
			if ( !Eraser )
			{
				if ( drawOrderMode == DRAW_ALWAYS )
				{
					bitmap.draw( bmp, null, new ColorTransform(1, 1, 1, DrawAlpha));
				}
				else if ( drawOrderMode == DRAW_ABOVE )
				{
					var tempBmp:BitmapData = new BitmapData(bmp.width, bmp.height, true, 0x00000000);
					tempBmp.copyPixels(bmp.bitmapData, bmp.getRect(null), new Point, bitmap, new Point, true);
					bitmap.draw( tempBmp, null, new ColorTransform(1, 1, 1, DrawAlpha));
				}
				else if ( drawOrderMode == DRAW_BEHIND )
				{
					tempBmp = new BitmapData(bmp.width, bmp.height, true, 0x00000000);
					tempBmp.draw( bmp.bitmapData, null, new ColorTransform(1, 1, 1, DrawAlpha));
					tempBmp.draw(bitmap);
					bitmap.copyPixels(tempBmp, bmp.getRect(null), new Point);
				}
				
			}
			else
			{
				bitmap.draw( bmp, null, new ColorTransform(1, 1, 1, DrawAlpha), "erase");
			}
			
			bitmap.unlock();
			return bitmap;
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
		
		private function SelectDrawItemUnderMouse(spriteLayer:LayerSprites):void
		{
			waitForSelect = false;
			PromptManager.manager.HidePrompt("Click on a sprite to select it.");
			if ( spriteLayer )
			{
				var newSprite:EditorAvatar = GetSpriteUnderCursor( spriteLayer );
				if ( selectedSprite && newSprite != selectedSprite )
				{
					selectedSprite.RemoveAnimOverride();
				}
				selectedSprite = newSprite;
				updateTileListForSprite( selectedSprite ? selectedSprite.spriteEntry : null, false, null, ModifySprites );
				if ( App.getApp().animEditor )
				{
					App.getApp().animEditor.UpdateData();
				}
			}
		}
		
		override protected function BeginPainting( layer:LayerEntry, leftMouse:Boolean ):void
		{
			hasStartedDrawing = false;
			if ( !leftMouse )
				return;
				
			var mapLayer:LayerMap = layer as LayerMap;
			var spriteLayer:LayerSprites = layer as LayerSprites;
			
			if ( mapLayer != lastTilemapDrawn )
			{
				ApplyNewTileStroke();
			}
				
			SelectNone();
			
			lastTilemapDrawn = mapLayer;
			
			if ( (mapLayer == null || spriteLayer == null ) && !layer.IsVisible() )
			{
				return;
			}
			
			if ( waitForSelect )
			{
				SelectDrawItemUnderMouse(spriteLayer);
				return;
			}
			
			hasStartedDrawing = true;
			
			var drawPos:FlxPoint;
			
			var tileWidth:int;
			var tileHeight:int;
			
			if ( !DrawFreehand )
			{
				if ( DrawNewTiles && (!DrawPolyLines || polylinePoints.length == 0) )
				{
					shapesGroup.EnableForLayer(layer);
				}
				if( DrawPolyLines )
				{
					if ( polylinePoints.length == 0 )
					{
						PromptManager.manager.ShowPrompt("Press Enter to add new lines.\nDrag to move.", true, "PolylineDrag");
						shownDrawPolylinesPrompt = true;
						if( mapLayer )
							polylinePoints.push(convertScreenPosToMapPos( mapLayer.map, mouseScreenPos.x, mouseScreenPos.y ));
					}
					if( mapLayer )
						polylinePoints.push(mouseScreenPos.copy());
				}
			}
			else if( shownDrawPolylinesPrompt )
			{
				shownDrawPolylinesPrompt = false;
				PromptManager.manager.HidePromptById("PolylineDrag");
			}
			
			if ( spriteLayer )
			{
				var spriteData:SpritePosData = new SpritePosData;
				GetSpriteDrawPos( spriteLayer, spriteData, true );
				
				var sprite:EditorAvatar = spriteData._avatar;
				if ( !sprite )
					return;
				sprite.PauseAnim();
				if ( App.getApp().animEditor )
				{
					App.getApp().animEditor.StopPlaying();
				}
				drawPos = spriteData._pos;
				tileWidth = sprite.frameWidth;
				tileHeight = sprite.frameHeight;
			}
			else
			{
				if ( DrawNewTiles && (!FloodFill || !UsingDropper) )
				{
					if ( DrawFreehand )
					{
						HistoryStack.BeginOperation(new OperationModifyTiles( mapLayer ) );
					}
				}
				
				drawPos = convertScreenPosToMapPos( layer.map, mouseScreenPos.x, mouseScreenPos.y );
				tileWidth = mapLayer.map.tileWidth;
				tileHeight = mapLayer.map.tileHeight;
			}
			
			if ( ( DrawOnBaseOnly || Global.DrawTilesWithoutHeight ) && layer.map )
			{
				var baseShape:Shape = new Shape;
				baseTileMask = layer.map.GenerateFloorTileBitmap(baseShape, 0xffffff);
			}
			
			if ( FloodFill )
			{
				var spriteEntry:SpriteEntry = null;
				if ( spriteLayer )
				{
					spriteEntry = sprite.spriteEntry;
				}
				HistoryStack.BeginOperation(new OperationDraw( layer, spriteEntry ) );
				if ( mapLayer )
				{
					var pixelOffset:FlxPoint = new FlxPoint();
					var tileId:int;
					if ( LockTileUnderCursor )
					{
						tileId = layer.map.getTile(currentLockedTile.x, currentLockedTile.y);
						pixelOffset.x = drawPos.x - currentLockedTilePos.x;
						pixelOffset.y = drawPos.y - currentLockedTilePos.y;
					}
					else
					{
						tileId = getPixelOffsetsAndTileId(layer.map, drawPos.x, drawPos.y, pixelOffset, true );
					}
					if ( tileId >= layer.map.drawIndex )
					{
						var bitmap:BitmapData = layer.map.GetTileBitmap(tileId);
						if ( DoFloodFill(bitmap, pixelOffset ) )
						{
							layer.map.SetTileBitmap(tileId, bitmap );
						}
					}
				}
				else if ( spriteLayer )
				{
					bitmap = sprite.GetBitmap();
					if ( DoFloodFill(bitmap, drawPos ) )
					{
						sprite.ReplaceCurrentFrameBitmap(bitmap);
					}
				}
				return;
			}
			
			spriteEntry = null;
			if ( spriteLayer )
			{
				spriteEntry = sprite.spriteEntry;
			}
			
			_s.graphics.clear();
			
			if ( LineThickness > 1)
			{
				// Draw the first pixel in case we don't actually move the mouse before releasing.
				_s.graphics.lineStyle(0, DrawColor, 1, true);
				_s.graphics.beginFill(DrawColor, 1);
				// For single pixels we must use DrawRect. Shapes are always larger than I want them to be!
				_s.graphics.drawCircle(drawPos.x, drawPos.y, LineThickness * 0.25 );
				_s.graphics.endFill();
			}
			else
			{
				// For single pixels draw a square without a border.
				_s.graphics.lineStyle(0, DrawColor, 0, true);
				_s.graphics.beginFill(DrawColor, 1);
				_s.graphics.drawRect(drawPos.x, drawPos.y, 1, 1 );
				_s.graphics.endFill();
			}
			
			_s.graphics.lineStyle( GetRealLineThickness(), DrawColor, 1, true);
			_s.graphics.moveTo(drawPos.x, drawPos.y);
			lastShapePos.copyFrom(drawPos);
			lineStartPos.copyFrom(lastShapePos);
			
			if ( !spriteEntry )
			{
				// Sprites are handled in drawSmoothLines
				HistoryStack.BeginOperation(new OperationDraw( layer, null ) );
			}
			
			if ( DrawNoise || DrawPerlin )
			{
				noiseBitmap.bitmapData = new BitmapData(tileWidth, tileHeight, true, 0x00000000 );
				if ( DrawNoise )
				{
					// The combination of channel and grayscale values ensure we are just setting the alpha
					// so that the noise is overlayed above the shape texture.
					noiseBitmap.bitmapData.noise(Math.random()*500, 0, 255, 0x00ffffff, true);
				}
				else if ( DrawPerlin )
				{
					noiseBitmap.bitmapData.perlinNoise(tileWidth * PerlinScale, tileHeight * PerlinScale, 3, Math.random()*500, true, true, 0x00ffffff, true);
				}
			}
			
		}
		
		private function DoFloodFill( bitmap:BitmapData, pos:FlxPoint ):Boolean
		{
			if ( bitmap )
			{
				// Floodfill with tolerance function from http://www.multimediacollege.be/2010/04/optimizing-the-floodfill-method/
				var color:uint = Eraser ? 0 : DrawColor | ((DrawAlpha * 255) << 24);
				var fillBmp:BitmapData = BitmapUtils.floodFill(bitmap, pos.x, pos.y, color, FloodFillTolerance, true );
				// copy fill back into bitmap
				bitmap.copyPixels(fillBmp, fillBmp.rect, new Point(0, 0),null,null,true);
				if ( (DrawOnBaseOnly || Global.DrawTilesWithoutHeight ) && baseTileMask )
				{
					var newBmp:BitmapData = new BitmapData(bitmap.width, bitmap.height,true,0x00000000);
					newBmp.copyPixels(bitmap, bitmap.rect, new Point, baseTileMask, null, true);
					bitmap = newBmp;
				}
				return true;
			}
			return false;
		}
		
		override protected function EndPainting( layer:LayerEntry ):void
		{
			var currentState:EditorState = FlxG.state as EditorState;
			
			var mapLayer:LayerMap = layer as LayerMap;
			var spriteLayer:LayerSprites = layer as LayerSprites;
			
			if ( UsingDropper || FloodFill)
			{
				return;
			}
			
			if ( mapLayer && DrawNewTiles )
			{
				if ( !DrawFreehand )
				{
					var tileEntry:DrawTileData;
					// Reset all the drawn tiles (just in case) and draw the shape onto our bitmap.
					var i:int = _drawnTiles.length;
					while(i--)
					{
						tileEntry = _drawnTiles[i];
						tileEntry.fakeBitmap.fillRect(tileEntry.fakeBitmap.rect, 0x00000000);
						layer.map.SetTileBitmap(tileEntry.tileId, tileEntry.sourceBitmap );
					}
					_drawnTiles.length = 0;
					lastShapePos.copyFrom(lineStartPos);
					lastHeldMousePos.copyFrom(lineStartPos);
					lastHeldMousePos.addTo(layer.map);
				
					HistoryStack.BeginOperation(new OperationModifyTiles( mapLayer ) );
					DrawSmoothLines(layer, true);
				}
				
				for each( tileEntry in _drawnTiles )
				{
					var bitmap:BitmapData = UpdateBitmap(tileEntry);
					layer.map.SetTileBitmap(tileEntry.tileId, bitmap );
				}
				
				currentState.UpdateCurrentTileList( mapLayer );
				
				shapesGroup.Disable();
			}
			
			if ( spriteLayer )
			{
				updateTileListForSprite( selectedSprite ? selectedSprite.spriteEntry : null, false, null, ModifySprites );
			}
			else
			{
				currentState.UpdateCurrentTileList(layer);
			}
			_s.graphics.clear();
			
			if ( (!mapLayer && !spriteLayer ) || !layer.visible )
			{
				_drawnTiles.length = 0;
				return;
			}
			
			var app:App = App.getApp();
			
			if ( mapLayer )
			{
				var tileCounts:Dictionary = new Dictionary(true);

				for each( var group:LayerGroup in app.layerGroups )
				{
					for each( var layer:LayerEntry in group.children )
					{
						var testMapLayer:LayerMap = layer as LayerMap;
						
						if ( testMapLayer != null && Misc.FilesMatch(mapLayer.imageFileObj, testMapLayer.imageFileObj ) )
						{
							tileCounts[testMapLayer] = testMapLayer.map.tileCount;
						}
					}
				}
				ImageBank.MarkImageAsChanged( mapLayer.imageFileObj, mapLayer.imageData );
				// As the image changed callback resets the tileCount based on the dimensions, ensure the tile count is kept up to date.
				for ( var key:Object in tileCounts )
				{
					testMapLayer = key as LayerMap;
					testMapLayer.map.tileCount = tileCounts[testMapLayer];
				}
				if ( app.brushesWindow && app.brushesWindow.visible )
				{
					app.brushesWindow.recalcPreview();
				}
			}
			else
			{
				for each( tileEntry in _drawnTiles )
				{
					var sprite:EditorAvatar = tileEntry.sprite;
					sprite.spriteEntry.dontRefreshSpriteDims = true;
					ImageBank.MarkImageAsChanged( sprite.spriteEntry.imageFile, sprite.spriteEntry.bitmap );
					sprite.spriteEntry.dontRefreshSpriteDims = false;
				}
				if ( app.animEditor )
				{
					app.animEditor.UpdateData();
				}
			}
			_drawnTiles.length = 0;
			polylinePoints.length = 0;
		}
		
		override protected function Paint( layer:LayerEntry ):void
		{
			if ( !hasStartedDrawing )
			{
				return;
			}
			
			var mapLayer:LayerMap = layer as LayerMap;
			var spriteLayer:LayerSprites = layer as LayerSprites;
			
			if ( ( mapLayer == null && spriteLayer == null ) || !layer.visible )
			{
				return;
			}
			
			if ( FloodFill )
				return;

			if ( UsingDropper )
			{
				ApplyEyeDropper(layer);
			}
			else
			{
				DrawSmoothLines(layer);
			}
		}
		
		private function ApplyEyeDropper( layer:LayerEntry, updateTextOnly:Boolean = false ):void
		{
			if ( !layer.visible )
			{
				return;
			}
			var mapLayer:LayerMap = layer as LayerMap;
			var spriteLayer:LayerSprites = layer as LayerSprites;
			var bitmap:BitmapData = null;
			var pixelOffset:FlxPoint = null;
			if ( spriteLayer )
			{
				var spriteData:SpritePosData = new SpritePosData;
				if ( GetSpriteDrawPos( spriteLayer, spriteData, true ) )
				{
					bitmap = spriteData._avatar.GetBitmap();
					pixelOffset = spriteData._pos;
				}
			}
			else
			{
				var mapPos:FlxPoint = convertScreenPosToMapPos( mapLayer.map, mouseScreenPos.x, mouseScreenPos.y );
				pixelOffset = new FlxPoint();
				var tileId:int = getPixelOffsetsAndTileId(mapLayer.map, mapPos.x, mapPos.y, pixelOffset, false );
				if ( tileId >= mapLayer.map.drawIndex )
				{
					bitmap = mapLayer.map.GetTileBitmap(tileId);
				}
			}
			if ( bitmap )
			{
				if ( updateTextOnly )
				{
					var col:uint = bitmap.getPixel32(pixelOffset.x, pixelOffset.y);
					dropperText = Misc.uintToHexStr8Digits(col);
				}
				else
				{
					DrawColor = bitmap.getPixel(pixelOffset.x, pixelOffset.y);
					Global.windowedApp.colorPick.setStyle("backgroundColor", DrawColor);
				}
			}
		}
		
		protected function Erase( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( mapLayer == null || !mapLayer.map.visible )
			{
				return;
			}
			
			DrawSmoothLines(layer);
		}
		
		private function CopyDrawnTiles():Vector.<DrawTileData>
		{
			var drawnTilesCopy:Vector.<DrawTileData> = new Vector.<DrawTileData>;
			for ( var i:int = 0; i < _drawnTiles.length; i++ )
			{
				var tileEntry:DrawTileData = new DrawTileData;
				tileEntry.sourceBitmap = _drawnTiles[i].sourceBitmap.clone();
				tileEntry.fakeBitmap = _drawnTiles[i].fakeBitmap.clone();
				tileEntry.tileId = _drawnTiles[i].tileId;
				tileEntry.sprite = _drawnTiles[i].sprite;
				drawnTilesCopy.push(tileEntry);
			}
			return drawnTilesCopy;
		}
		
		override protected function SelectInsideBox( layer:LayerEntry, boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean
		{
			SelectNone();
			
			var mapLayer:LayerMap = layer as LayerMap;
			if ( mapLayer != null )
			{
				var startPos:FlxPoint =  selectionBoxStart.v_sub(layer.map);
				var endPos:FlxPoint = selectionBoxEnd.v_sub(layer.map);
			}
			else
			{
				var spriteLayer:LayerSprites = layer as LayerSprites;
				if ( spriteLayer == null )
				{
					return false;
				}
				startPos = selectionBoxStart;
				endPos = selectionBoxEnd;
			}
			
			var topLeft:FlxPoint = new FlxPoint(Math.min(startPos.x,endPos.x), Math.min(startPos.y,endPos.y));
			var botRight:FlxPoint = new FlxPoint(Math.max(startPos.x,endPos.x), Math.max(startPos.y,endPos.y));
			if ( botRight.x - topLeft.x < 1 || botRight.y - topLeft.y < 1 )
			{
				return false;
			}
			
			if ( spriteLayer )
			{	
				var topLeftScreen:FlxPoint = EditorState.getScreenXYFromMapXY( topLeft.x, topLeft.y, spriteLayer.xScroll, spriteLayer.yScroll );
				var botRightScreen:FlxPoint = EditorState.getScreenXYFromMapXY( botRight.x, botRight.y, spriteLayer.xScroll, spriteLayer.yScroll );
				var avatar:EditorAvatar = GetSpriteWithinSelectionBox( spriteLayer, topLeftScreen, botRightScreen );
				if ( !avatar )
				{
					return false;
				}
			}
			
			var drawnTilesCopy:Vector.<DrawTileData> = CopyDrawnTiles();
			if( mapLayer )
			{
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( mapLayer, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
				SelectBitmapOnMapLayer( mapLayer, topLeft, botRight );
				spriteForSelection = null;
			}
			else
			{
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( avatar, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
				
				var worldPos:FlxPoint = avatar;
				selectionBitmap = new BitmapData(botRight.x-topLeft.x,botRight.y-topLeft.y, true, 0x00000000 );
				if ( avatar.angle != 0 && avatar.bakedBitmap )
				{
					worldPos = EditorState.getMapXYFromScreenXY(avatar.bakedBitmapPt.x, avatar.bakedBitmapPt.y, spriteLayer.xScroll, spriteLayer.yScroll);
					var rect:Rectangle = new Rectangle(topLeft.x - worldPos.x, topLeft.y - worldPos.y, botRight.x - topLeft.x, botRight.y - topLeft.y);
					selectionBitmap.copyPixels( avatar.bakedBitmap, rect, new Point(0, 0), null, null, true);
				}
				else
				{
					rect = new Rectangle(topLeft.x - worldPos.x, topLeft.y - worldPos.y, botRight.x - topLeft.x, botRight.y - topLeft.y);
					rect.x /= avatar.scale.x;
					rect.y /= avatar.scale.y;
					rect.width /= avatar.scale.x;
					rect.height /= avatar.scale.y;
					selectionBitmap.copyPixels( avatar.GetBitmap(), rect, new Point(0, 0), null, null, true);
				}
				
				selectionBitmapCopy = selectionBitmap.clone();
				selectionTopLeft = topLeft;
				selectionBotRight = botRight;
				spriteForSelection = avatar;
				spriteForSelectionAngle = avatar.angle;
				spriteForSelectionScale = avatar.scale.copy();
				drawingLayer = null;
				selectedSprite = avatar;
				updateTileListForSprite( selectedSprite.spriteEntry, false, null, ModifySprites );
				
				
				var tileEntry:DrawTileData = new DrawTileData;
				tileEntry.sprite = spriteForSelection;
				// Store the source bitmap for this tile BEFORE we make any modifications to it.
				var sourceBitmap:BitmapData = spriteForSelection.GetBitmap();
				tileEntry.sourceBitmap = new BitmapData(sourceBitmap.width, sourceBitmap.height, true, 0x00000000 );
				tileEntry.sourceBitmap.copyPixels(sourceBitmap, sourceBitmap.rect, new Point, null, null, true);
				tileEntry.fakeBitmap = tileEntry.sourceBitmap.clone();
				
				if ( spriteForSelection.angle == 0 )
				{
					// Clear the portion of the bitmap we're selecting, so when we move it there's empty space.
					tileEntry.sourceBitmap.fillRect(rect, 0x00000000);
				}
				else
				{
					//TODO: Fix the rectangle size and pos when the sprite is scaled.
					var matrix:Matrix = GetAngledSpriteDrawRotationMatrix(spriteForSelection, topLeftScreen);
					
					var bmp:Bitmap = new Bitmap(new BitmapData(selectionBitmap.width, selectionBitmap.height, true, 0xffffffff) );
					tileEntry.sourceBitmap.draw(bmp, matrix, null, BlendMode.ERASE);
				}
				_drawnTiles.length = 0;
				_drawnTiles.push( tileEntry );
			}
			
			return ( selectionBitmap != null );
		}
		
		private function GetAngledSpriteDrawRotationMatrix(sprite:EditorAvatar, screenDrawPos:FlxPoint):Matrix
		{
			// Get the drawn pos of the top left of the sprite.
			var screenPos:FlxPoint = EditorState.getScreenXYFromMapXY(sprite.x, sprite.y, sprite.layer.xScroll, sprite.layer.yScroll);
			var matrix:Matrix = sprite.GetTransformMatrixForRealPosToDrawnPos(screenPos, sprite.angle);
			var screenDrawTopLeft:FlxPoint = new FlxPoint(0, matrix.transformPoint(new Point(screenPos.x, screenPos.y)));
			
			// Work out the matrix required to rotate this rect and place it in the bmp at the correct angle.
			matrix.identity();
			matrix.translate(screenDrawPos.x - screenDrawTopLeft.x, screenDrawPos.y - screenDrawTopLeft.y);
			matrix.rotate(-sprite.angle * Math.PI / 180 );
			return matrix;
		}
		
		override protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint
		{
			if ( waitForSelect )
			{
				SelectDrawItemUnderMouse(layer as LayerSprites);
				return SELECTED_ITEM;
			}
			
			var mapLayer:LayerMap = layer as LayerMap;
			if ( mapLayer == null )
			{
				if ( spriteForSelection && spriteForSelection.layer == layer && selectionBitmap )
				{
					var worldPos:FlxPoint = EditorState.getMapXYFromScreenXY(mouseScreenPos.x, mouseScreenPos.y, layer.xScroll, layer.yScroll );
					if ( worldPos.x > selectionTopLeft.x && worldPos.x < selectionBotRight.x && worldPos.y > selectionTopLeft.y && worldPos.y < selectionBotRight.y )
					{
						var drawnTilesCopy:Vector.<DrawTileData> = CopyDrawnTiles();
						HistoryStack.BeginOperation(new OperationDrawChangeSelection( spriteForSelection, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
				
						selectionTopLeftBeforeMove = selectionTopLeft.copy();
						storedSelectionWidth = selectionBitmap.width;
						storedSelectionHeight = selectionBitmap.height;
						return SELECTED_ITEM;
					}
				}
				return SELECTED_NONE;
			}
			var mapPos:FlxPoint = convertScreenPosToMapPos( mapLayer.map, mouseScreenPos.x, mouseScreenPos.y );
			if ( selectionBitmap && mapPos.x > selectionTopLeft.x && mapPos.x < selectionBotRight.x && mapPos.y > selectionTopLeft.y && mapPos.y < selectionBotRight.y )
			{
				drawnTilesCopy = CopyDrawnTiles();
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( mapLayer, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
				selectionTopLeftBeforeMove = selectionTopLeft.copy();
				storedSelectionWidth = selectionBitmap.width;
				storedSelectionHeight = selectionBitmap.height;
				return SELECTED_ITEM;
			}
			
			SelectNone();
			return SELECTED_NONE;
		}
		
		override protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			var spriteLayer:LayerSprites = App.getApp().CurrentLayer as LayerSprites;
			if ( spriteLayer )
			{
				if ( spriteForSelection && _drawnTiles.length )
				{
					selectionTopLeft = selectionTopLeftBeforeMove.v_add( screenOffsetFromOriginalPos );
					
					PaintSelectionOnSprite(selectionBitmap, spriteForSelection, selectionTopLeft );
				}
			}
			else
			{
				var i:int = _drawnTiles.length;
			
				// Clear up the previously drawn tiles.
				while(i--)
				{
					var tileEntry:DrawTileData = _drawnTiles[i];
					
					// TODO: If we're in locked tile mode then it should only reset the tile that is locked.
					drawingLayer.map.SetTileBitmap(tileEntry.tileId, tileEntry.sourceBitmap );
				}
				_drawnTiles.length = 0;
			
				// Now draw the selection in the new location.
				
				selectionTopLeft = selectionTopLeftBeforeMove.v_add( screenOffsetFromOriginalPos );
				
				PaintSelection( selectionBitmap, drawingLayer, selectionTopLeft );
			}
			if ( selectionTopLeft && selectionBitmap )
			{
				selectionBotRight.x = selectionTopLeft.x + selectionBitmap.width;
				selectionBotRight.y = selectionTopLeft.y + selectionBitmap.height;
			}
		}
		
		override protected function ConfirmMovement():void
		{
			var app:App = App.getApp();
			if ( drawingLayer )
			{
				var currentState:EditorState = FlxG.state as EditorState;
				currentState.UpdateCurrentTileList(drawingLayer);
				
				ImageBank.MarkImageAsChanged( drawingLayer.imageFileObj, drawingLayer.imageData );
				
				if ( app.brushesWindow && app.brushesWindow.visible )
				{
					app.brushesWindow.recalcPreview();
				}
			}
			else
			{
				for each( var tileEntry:DrawTileData in _drawnTiles )
				{
					var sprite:EditorAvatar = tileEntry.sprite;
					sprite.spriteEntry.dontRefreshSpriteDims = true;
					ImageBank.MarkImageAsChanged( sprite.spriteEntry.imageFile, sprite.spriteEntry.bitmap );
					sprite.spriteEntry.dontRefreshSpriteDims = false;
				}
				updateTileListForSprite( selectedSprite ? selectedSprite.spriteEntry : null, false, null, ModifySprites );
				if ( app.animEditor )
				{
					app.animEditor.UpdateData();
				}
			}
		}
		
		override protected function ScaleSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			if ( !selectionBitmap )
				return;
			var anchorFrac:FlxPoint = new FlxPoint(0.5, 0.5);
			var storedAnchorPos:FlxPoint = new FlxPoint(storedSelectionWidth * 0.5, storedSelectionHeight * 0.5 );
			var anchorPos:FlxPoint = new FlxPoint(selectionBitmap.width * 0.5, selectionBitmap.height * 0.5 );
			
			anchorPos.x = storedAnchorPos.x + selectionTopLeftBeforeMove.x;
			anchorPos.y = storedAnchorPos.y + selectionTopLeftBeforeMove.y;
			var worldPos:FlxPoint = mousePos.copy();
			if ( drawingLayer )
			{
				worldPos.subFrom(drawingLayer.map);
			}
			var originalOffsetX:Number = (worldPos.x-screenOffsetFromOriginalPos.x) - anchorPos.x;
			var originalOffsetY:Number = (worldPos.y-screenOffsetFromOriginalPos.y) - anchorPos.y;
			var currentOffsetX:Number = worldPos.x - anchorPos.x;
			var currentOffsetY:Number = worldPos.y - anchorPos.y;
			
			var frameWidth:Number = selectionBitmap.width;
			var frameHeight:Number = selectionBitmap.height;
			
			// If we start scaling too close to the centre then do nothing until the mouse has moved far enough from the centre.
			// This prevents it from scaling up too quickly.
			if ( Math.abs( originalOffsetX / storedSelectionWidth ) < 0.2  )
			{
				var newOriginalOffsetX:Number = storedSelectionWidth * 0.2;
				currentOffsetX = Math.max( newOriginalOffsetX, Math.abs(currentOffsetX) ) * Misc.sign(currentOffsetX);
				originalOffsetX = newOriginalOffsetX * Misc.sign(originalOffsetX);
			}
			if ( Math.abs( originalOffsetY / storedSelectionHeight ) < 0.2  )
			{
				var newOriginalOffsetY:Number = storedSelectionHeight * 0.2;
				currentOffsetY = Math.max( newOriginalOffsetY, Math.abs(currentOffsetY) ) * Misc.sign(currentOffsetY);
				originalOffsetY = newOriginalOffsetY * Misc.sign(originalOffsetY);
			}
			
			var scaleDiffX:Number = originalOffsetX ? Math.abs( currentOffsetX / originalOffsetX ): 1;
			var scaleDiffY:Number = originalOffsetY ? Math.abs( currentOffsetY / originalOffsetY ): 1;
			
			if ( FlxG.keys.pressed("S") )
			{
				// Handle uniform scaling.
				scaleDiffX = scaleDiffY = Math.max(scaleDiffX, scaleDiffY);
			}
			
			var newWidth:int = storedSelectionWidth * scaleDiffX;
			var newHeight:int = storedSelectionHeight * scaleDiffY;
			newWidth = Math.max(4, newWidth );
			newWidth = Math.min( newWidth, Math.max( 5000, selectionBitmapCopy.width ) );
			newHeight = Math.max(4, newHeight );
			newHeight = Math.min( newHeight, Math.max( 5000, selectionBitmapCopy.height ) );
			var scaleX:Number = newWidth / selectionBitmapCopy.width;
			var scaleY:Number = newHeight / selectionBitmapCopy.height;
			
			selectionBitmap = new BitmapData(newWidth, newHeight, true, 0x00000000);
			var mat:Matrix = new Matrix;
			mat.scale(scaleX, scaleY);
			selectionBitmap.draw(selectionBitmapCopy, mat);

			// Simulate scaling on the centre axis by moving it so the centre stays in the same place.
			selectionTopLeft.x = selectionTopLeftBeforeMove.x - ( selectionBitmap.width - storedSelectionWidth ) * 0.5;
			selectionTopLeft.y = selectionTopLeftBeforeMove.y - ( selectionBitmap.height - storedSelectionHeight ) * 0.5;
			
			// Clear up the previously drawn tiles.
			var i:int = _drawnTiles.length;
			while(i--)
			{
				var tileEntry:DrawTileData = _drawnTiles[i];
				if ( drawingLayer )
				{
					drawingLayer.map.SetTileBitmap(tileEntry.tileId, tileEntry.sourceBitmap );
				}
				else if ( spriteForSelection )
				{
					spriteForSelection.ReplaceCurrentFrameBitmap(tileEntry.sourceBitmap );
				}
			}
			
			
			
			if ( drawingLayer )
			{
				_drawnTiles.length = 0;
				PaintSelection( selectionBitmap, drawingLayer, selectionTopLeft );
			}
			else
			{
				PaintSelectionOnSprite( selectionBitmap, spriteForSelection, selectionTopLeft );
			}
			
			selectionBotRight.x = selectionTopLeft.x + selectionBitmap.width;
			selectionBotRight.y = selectionTopLeft.y + selectionBitmap.height;
		}
		
		override public function SelectNone(): void
		{
			if ( selectionBitmap )
			{
				var drawnTilesCopy:Vector.<DrawTileData> = CopyDrawnTiles();
				var selectedObj:Object = spriteForSelection ? spriteForSelection : drawingLayer;
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( drawingLayer, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
			}
			
			selectionTopLeft = selectionBotRight = null;
			selectionBitmap = null;
			selectionBitmapCopy = null;
			drawingLayer = null;
			spriteForSelection = null;
			_drawnTiles.length = 0;
		}
		
		//{ region private
		
		private function Drawshapes( spawnNewTiles:Boolean, lastPos:FlxPoint, newPos:FlxPoint ):void
		{
			var shapeAlpha:Number = spawnNewTiles ? 1 : DrawAlpha;
			if( DrawLines )
				shapesGroup.DrawLine(lastPos, newPos, DrawColor, 1, GetRealLineThickness());
			else if ( DrawCircles )
				shapesGroup.DrawCircle(lastPos, newPos, DrawColor, shapeAlpha, GetRealLineThickness(), ShapeFillColor, ShapeFillAlpha);
			else if ( DrawEllipses )
				shapesGroup.DrawEllipse(lastPos, newPos, DrawColor, shapeAlpha, GetRealLineThickness(), ShapeFillColor, ShapeFillAlpha);
			else if ( DrawBoxes )
				shapesGroup.DrawBox(lastPos, newPos, DrawColor, shapeAlpha, GetRealLineThickness(), ShapeFillColor, ShapeFillAlpha);
			else if ( DrawPolyLines )
			{
				polylinePoints[polylinePoints.length - 1].copyFrom(newPos);
				shapesGroup.DrawPolyLine(polylinePoints, DrawColor, 1, GetRealLineThickness(), ShapeFillColor, ShapeFillAlpha);
			}
		}
		
		private function GetRealLineThickness():uint
		{
			return LineThickness;// (LineThickness + 1) * 0.6;
		}
		
		private function DrawSmoothLines( layer:LayerEntry, spawnNewTiles:Boolean = false ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			var tileId:int;
			
			var oldPos:FlxPoint;
			var origin:FlxPoint = mapLayer ? mapLayer.map : new FlxPoint;
			var mapPos:FlxPoint = mapLayer ? convertScreenPosToMapPos( mapLayer.map, mouseScreenPos.x, mouseScreenPos.y ) : mouseScreenPos;

			if ( lastHeldMousePos.x == -1 || lastHeldMousePos.y == -1 )
			{
				var currentUnitPos:FlxPoint = new FlxPoint();
				oldPos = FlxPoint.CreateObject(mapPos);
			}
			else
			{
				_s.graphics.clear();
				oldPos = new FlxPoint(lastHeldMousePos.x, lastHeldMousePos.y);
				oldPos.subFrom(origin);
			}
			
			var tileEntry:DrawTileData;
			var drawShape:Shape = _s;
			
			if ( !DrawFreehand )
			{
				lastShapePos.copyFrom(lineStartPos);
				oldPos.copyFrom(lineStartPos);
				// Clear up the previously drawn tiles.
				if ( mapLayer )
				{
					var i:int = _drawnTiles.length;
					while(i--)
					{
						tileEntry = _drawnTiles[i];
						tileEntry.fakeBitmap.fillRect(tileEntry.fakeBitmap.rect, 0x00000000);
					}
					
					if( DrawPolyLines && FlxG.keys.justPressed("ENTER") )
						polylinePoints.push(mapPos);
					
					Drawshapes(spawnNewTiles, lastShapePos, mapPos);
				}
				
				
					
				if ( DrawNewTiles && !spawnNewTiles )
				{
					return;
				}
				
				drawShape = shapesGroup.GetShape();
				if ( mapLayer && DrawCircles )
				{
					var radius:Number = mapPos.distance_to(lastShapePos);
					mapPos.x = oldPos.x + radius;
					mapPos.y = oldPos.y + radius;
					oldPos.x = oldPos.x - radius;
					oldPos.y = oldPos.y - radius;
				}
			}
			else if ( DrawNewTiles )
			{
				spawnNewTiles = true;
			}

			//TODO - Can't get 1 pixel thick lines to be solid/not anti-aliased.
			_s.graphics.lineStyle( GetRealLineThickness(), DrawColor, 1, true);
			
			// Calculate tile ids that the line passes over (approx but a generous estimate).
			var topLeft:FlxPoint = new FlxPoint();
			var bottomRight:FlxPoint = new FlxPoint();
			
			//trace( oldPos.x + "," + oldPos.y + " -> " + mapPos.x + "," + mapPos.y );
		
			var startUnitTilePos:FlxPoint = new FlxPoint();
			var endUnitTilePos:FlxPoint = new FlxPoint();
			if (mapLayer )
			{
				_s.graphics.moveTo(lastShapePos.x, lastShapePos.y);
				_s.graphics.lineTo(mapPos.x, mapPos.y);
				lastShapePos.copyFrom(mapPos);
				
				topLeft.x = Math.min( oldPos.x, mapPos.x ) - LineThickness;
				topLeft.y = Math.min( oldPos.y, mapPos.y ) - LineThickness;
				bottomRight.x = Math.max( oldPos.x, mapPos.x ) + LineThickness;
				bottomRight.y = Math.max( oldPos.y, mapPos.y ) + LineThickness;
				
				getPixelOffsetsAndTileId(mapLayer.map, topLeft.x, topLeft.y, null, true, startUnitTilePos );
				getPixelOffsetsAndTileId(mapLayer.map, bottomRight.x, bottomRight.y, null, true, endUnitTilePos );
				if ( mapLayer.map.IsIso() )
				{
					var tempPos1:FlxPoint = new FlxPoint;
					getPixelOffsetsAndTileId(mapLayer.map, topLeft.x, bottomRight.y, null, true, tempPos1 );
					var tempPos2:FlxPoint = new FlxPoint;
					getPixelOffsetsAndTileId(mapLayer.map, bottomRight.x, topLeft.y, null, true, tempPos2 );
					var tempPos3:FlxPoint = startUnitTilePos.copy();
					var tempPos4:FlxPoint = endUnitTilePos.copy();
					startUnitTilePos.x = Math.min(tempPos1.x, tempPos2.x, tempPos3.x, tempPos4.x );
					startUnitTilePos.y = Math.min(tempPos1.y, tempPos2.y, tempPos3.y, tempPos4.y );
					endUnitTilePos.x = Math.max(tempPos1.x, tempPos2.x, tempPos3.x, tempPos4.x );
					endUnitTilePos.y = Math.max(tempPos1.y, tempPos2.y, tempPos3.y, tempPos4.y );
				}
			}
			else
			{
				var spriteData:SpritePosData = new SpritePosData;
				if ( _drawnTiles.length )
				{
					spriteData._avatar = _drawnTiles[0].sprite;
				}
				var hadSprite:Boolean = spriteData._avatar != null;
				if( GetSpriteDrawPos( layer as LayerSprites, spriteData, false ) || spriteData._avatar!=null )
				{
					if ( !hadSprite )
					{
						lastShapePos.copyFrom(spriteData._pos);
						lineStartPos.copyFrom(lastShapePos);
						if ( DrawPolyLines )
						{
							if ( polylinePoints.length == 0 )
							{
								polylinePoints.push(spriteData._pos.copy());
							}
							polylinePoints.push(spriteData._pos.copy());
						}
						HistoryStack.BeginOperation(new OperationDraw( layer, spriteData._avatar.spriteEntry ) );
					}
					else if( FlxG.keys.justPressed("ENTER") )
						polylinePoints.push(spriteData._pos.copy());
					if ( !_drawnTiles.length )
					{
						tileEntry = new DrawTileData;
						tileEntry.sprite = spriteData._avatar;
						// Store the source bitmap for this tile BEFORE we make any modifications to it.
						tileEntry.sourceBitmap = spriteData._avatar.GetBitmap();
						
						tileEntry.fakeBitmap = new BitmapData(tileEntry.sourceBitmap.width, tileEntry.sourceBitmap.height, true,0x00000000 );
						_drawnTiles.push( tileEntry );
					}
					else
					{
						tileEntry = _drawnTiles[0];
						if ( !DrawFreehand )
						{
							// Clear up the previous drawing.
							tileEntry.fakeBitmap.fillRect(tileEntry.fakeBitmap.rect, 0x00000000);
						}
					}
					
					if ( tileEntry != null )
					{
						Drawshapes(spawnNewTiles, lastShapePos,  spriteData._pos);
						_s.graphics.moveTo(lastShapePos.x, lastShapePos.y);
						_s.graphics.lineTo(spriteData._pos.x, spriteData._pos.y);
						lastShapePos.copyFrom(spriteData._pos);
						
						tileEntry.fakeBitmap.draw(drawShape);
						
						removeAntialiasingFromBitmap(tileEntry.fakeBitmap);
					}
				}
				else if ( spriteData._avatar )
				{
					lastShapePos.copyFrom(spriteData._pos);
				}
				return;
			}
			
			if ( LockTileUnderCursor )
			{
				currentUnitPos = currentLockedTile;
				startUnitTilePos.copyFrom( currentLockedTile );
				endUnitTilePos.copyFrom( currentLockedTile );
			}
			else if ( LockedTileMode )
			{
				currentUnitPos = startUnitTilePos.copy();
			}
			
			for ( var y: uint = startUnitTilePos.y; y <= endUnitTilePos.y; y++ )
			{
				for ( var x: uint = startUnitTilePos.x; x <= endUnitTilePos.x; x++ )
				{
					if ( mapLayer.map.tileIsValid( x, y ) )
					{
						tileId = layer.map.getTile(x, y);
						
						// Find an existing entry for this tile. If not, then create one.
						
						tileEntry = null;
						for each( var tempTileEntry:DrawTileData in _drawnTiles )
						{
							if ( tempTileEntry.tileId == tileId )
							{
								if ( (!LockedTileMode && !LockTileUnderCursor) || ( x == tempTileEntry.initX && y == tempTileEntry.initY ) )
								{
									tileEntry = tempTileEntry;
								}
								break;
							}
						}
						
						var createNewTile:Boolean = false;
						
						if ( tileEntry == null && (!LockedTileMode || 
							(_drawnTiles.length == 0 && currentUnitPos && x==currentUnitPos.x && y==currentUnitPos.y) ) )
						{
							createNewTile = spawnNewTiles;
							
							if ( tileId >= mapLayer.map.drawIndex || createNewTile )
							{
								tileEntry = new DrawTileData;
								tileEntry.tileId = tileId;
								if ( LockedTileMode || LockTileUnderCursor)
								{
									tileEntry.initX = currentUnitPos.x;
									tileEntry.initY = currentUnitPos.y;
								}
								// Store the source bitmap for this tile BEFORE we make any modifications to it.
								tileEntry.sourceBitmap = layer.map.GetTileBitmap(tileId);
								
								tileEntry.fakeBitmap = new BitmapData(tileEntry.sourceBitmap.width, tileEntry.sourceBitmap.height, true,0x00000000 );
								_drawnTiles.push( tileEntry );
							}
						}
						
						if ( tileEntry != null )
						{
							// Paint on our fake tile so that we know exactly which pixels have been modified.
							// It doesn't matter if we do this many times (ie if the tile is repeated). This should give the
							// result we expect visually.
							var translateMatrix:Matrix = new Matrix();
							var tilePos:FlxPoint = new FlxPoint;
							layer.map.GetTileWorldFromUnitPos(x, y, tilePos);
							translateMatrix.translate( -(tilePos.x - layer.map.x), -(tilePos.y - layer.map.y) );
							
							if ( createNewTile )
							{
								var blankBmp:BitmapData = tileEntry.fakeBitmap.clone();
							}
	
							tileEntry.fakeBitmap.draw(drawShape, translateMatrix);
							removeAntialiasingFromBitmap(tileEntry.fakeBitmap);
							
							if ( createNewTile && newTileModeTileIds.indexOf(tileId) == -1 )
							{
								if ( DrawOnBaseOnly )
								{
									var newBmp:BitmapData = new BitmapData(tileEntry.fakeBitmap.width, tileEntry.fakeBitmap.height,true,0x00000000);
									newBmp.copyPixels(tileEntry.fakeBitmap, tileEntry.fakeBitmap.rect, new Point, baseTileMask, null, true);
									tileEntry.fakeBitmap = newBmp;
								}
								// Only create the tile if it is different to the original
								// eg lines drawn diagonally will cover many tiles that aren't changed because the rect is larger.
								var cmp:BitmapData = blankBmp.compare(tileEntry.fakeBitmap) as BitmapData;
								if( cmp != null )
								{
									var state:EditorState = FlxG.state as EditorState;
									state.ModifyTiles(true, true, false, false, false, false,tileId, layer.map.tileCount - 1, false);
									layer.map.setTile( x, y, layer.map.tileCount - 1);
									tileId = tileEntry.tileId = layer.map.tileCount - 1;
									newTileModeTileIds.push(tileId);
								}
								else
								{
									_drawnTiles.splice( _drawnTiles.indexOf(tileEntry),1 );
								}
							}
						}
					}
				}
			}

		}
		
		private function removeAntialiasingFromBitmap(bmp:BitmapData):void
		{
			if ( DrawLines || DrawFreehand)
			{
				// remove any antialiasing from the shape drawn.
				
				// Freehand gets more low alpha than normal so use a lower threshold.
				var threshold:uint = DrawFreehand ? 0x44000000 : 0x66000000;
				bmp.threshold(bmp, bmp.rect, new Point, "<=", threshold, 0x00000000, 0xff000000);
				bmp.threshold(bmp, bmp.rect, new Point, ">", threshold, 0xff000000|DrawColor, 0xff000000);
			}
		}
		
		private function GetSpriteWithinSelectionBox( layer:LayerSprites, boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):EditorAvatar
		{
			var app:App = App.getApp();
			var i:uint = app.layerGroups.length;
			if ( selectedSprite && selectedSprite.layer == layer && selectedSprite.IsUnderScreenBox( boxTopLeft, boxBottomRight ) )
			{
				return selectedSprite;
			}
			while( i-- )
			{
				var group:LayerGroup = app.layerGroups[i];
				var j:uint = group.children.length;
				while( j-- )
				{
					var layerEntry:LayerEntry = group.children[j];
					if ( Global.SelectFromCurrentLayerOnly && layerEntry != layer )
					{
						continue;
					}
					if ( layerEntry is LayerSprites && layerEntry.IsVisible() )
					{
						var spriteLayer:LayerSprites = layerEntry as LayerSprites;
						var k:uint = spriteLayer.sprites.members.length;
						while( k-- )
						{
							var avatar:EditorAvatar = spriteLayer.sprites.members[k];
							if ( avatar.IsUnderScreenBox( boxTopLeft, boxBottomRight ) )
							{
								return avatar;
							}
						}
					}
				}
			}
			return null;
		}
		
		private function GetSpriteUnderCursor( layer:LayerSprites, boundsExtend:int = 0 ):EditorAvatar
		{
			var app:App = App.getApp();
			var i:uint = app.layerGroups.length;
			if ( selectedSprite && selectedSprite.layer == layer && selectedSprite.IsOverScreenPos( mouseScreenPos ) )
			{
				return selectedSprite;
			}
			while( i-- )
			{
				var group:LayerGroup = app.layerGroups[i];
				var j:uint = group.children.length;
				while( j-- )
				{
					var layerEntry:LayerEntry = group.children[j];
					if ( Global.SelectFromCurrentLayerOnly && layerEntry != layer )
					{
						continue;
					}
					if ( layerEntry is LayerSprites && layerEntry.IsVisible() )
					{
						var spriteLayer:LayerSprites = layerEntry as LayerSprites;
						var k:uint = spriteLayer.sprites.members.length;
						while( k-- )
						{
							var avatar:EditorAvatar = spriteLayer.sprites.members[k];
							if ( avatar.IsOverScreenPos( mouseScreenPos, false, boundsExtend ) )
							{
								return avatar;
							}
						}
					}
				}
			}
			return null;
		}
		
		private function GetSpriteDrawPos( spriteLayer:LayerSprites, spriteData:SpritePosData, getNewSprite:Boolean ):Boolean
		{
			var boundsExtend:int = LineThickness - 1;
			if ( getNewSprite || spriteData._avatar == null )
			{
				spriteData._avatar = GetSpriteUnderCursor( spriteLayer, boundsExtend );
			}
			if ( spriteData._avatar == null )
			{
				return false;
			}
			
			spriteData._pos = new FlxPoint;
			var isOver:Boolean = spriteData._avatar.IsOverScreenPos( mouseScreenPos, false, boundsExtend, spriteData._pos );
			spriteData._pos.x *= (spriteData._avatar.frameWidth + boundsExtend + boundsExtend);
			spriteData._pos.x -= boundsExtend;
			spriteData._pos.y *= (spriteData._avatar.frameHeight + boundsExtend + boundsExtend);
			spriteData._pos.y -= boundsExtend;
			return isOver;
		}
		
		private function convertScreenPosToMapPos( map:FlxTilemapExt, x:int, y:int ):FlxPoint
		{
			var mapPos:FlxPoint = EditorState.getMapXYFromScreenXY(x * FlxG.invExtraZoom, y * FlxG.invExtraZoom, map.scrollFactor.x, map.scrollFactor.y );
			mapPos.subFrom(map);
			return mapPos;
		}
		

		private function getPixelOffsetsAndTileId( map:FlxTilemapExt, x:int, y:int, pixelOffsets:FlxPoint, clampValues:Boolean, unitTilePos:FlxPoint = null ):int
		{			
			var testPos:FlxPoint = new FlxPoint;
			var testWorldPos:FlxPoint = new FlxPoint;
			var valid:Boolean = map.GetTileInfo(x, y, testPos, testWorldPos );
			var tx:int = testPos.x;
			var ty:int = testPos.y;
			
			if ( clampValues )
			{
				tx = Math.min(Math.max(tx, 0), map.widthInTiles-1);
				ty = Math.min(Math.max(ty, 0), map.heightInTiles - 1);
				valid = true;
			}
			
			if ( valid )
			{
				if ( unitTilePos )
				{
					unitTilePos.create_from_points( tx, ty );
				}
				
				var tileId:uint = map.getTile( tx, ty );
			}

			
			if ( pixelOffsets )
			{
				//pixelOffsets.x = x % map.tileWidth;
				//pixelOffsets.y = y % map.tileHeight;
				pixelOffsets.x = (x - (testWorldPos.x - map.x));// % map.tileWidth;
				pixelOffsets.y = (y - (testWorldPos.y - map.y));// % map.tileHeight;
			}
			
			return valid ? tileId : -1;
		}
		
		private function SelectBitmapOnMapLayer( mapLayer:LayerMap, topLeft:FlxPoint, botRight:FlxPoint ):void
		{			
			var startUnitTilePos:FlxPoint = new FlxPoint();
			getPixelOffsetsAndTileId(mapLayer.map, topLeft.x, topLeft.y, null, true, startUnitTilePos );
			var endUnitTilePos:FlxPoint = new FlxPoint();
			getPixelOffsetsAndTileId(mapLayer.map, botRight.x, botRight.y, null, true, endUnitTilePos );
			
			// Expand further to cope for isometric tilemaps.
			var extraTilePos:FlxPoint = new FlxPoint();
			getPixelOffsetsAndTileId(mapLayer.map, topLeft.x, botRight.y, null, true, extraTilePos );
			startUnitTilePos.x = Math.min( startUnitTilePos.x, extraTilePos.x );
			startUnitTilePos.y = Math.min( startUnitTilePos.y, extraTilePos.y );
			endUnitTilePos.x = Math.max( endUnitTilePos.x, extraTilePos.x );
			endUnitTilePos.y = Math.max( endUnitTilePos.y, extraTilePos.y );
			getPixelOffsetsAndTileId(mapLayer.map, botRight.x, topLeft.y, null, true, extraTilePos );
			startUnitTilePos.x = Math.min( startUnitTilePos.x, extraTilePos.x );
			startUnitTilePos.y = Math.min( startUnitTilePos.y, extraTilePos.y );
			endUnitTilePos.x = Math.max( endUnitTilePos.x, extraTilePos.x );
			endUnitTilePos.y = Math.max( endUnitTilePos.y, extraTilePos.y );
			
			_drawnTiles.length = 0;
			
			selectionBitmap = new BitmapData(botRight.x - topLeft.x, botRight.y - topLeft.y, true, 0x00000000 );
			
			
			selectionTopLeft = topLeft;
			selectionBotRight = botRight;
			drawingLayer = mapLayer;
			
			
			for ( var y: uint = startUnitTilePos.y; y <= endUnitTilePos.y; y++ )
			{
				for ( var x: uint = startUnitTilePos.x; x <= endUnitTilePos.x; x++ )
				{
					if ( mapLayer.map.tileIsValid( x, y ) )
					{
						var tileId:int = mapLayer.map.getTile(x, y);
						
						// Find this entry if it's already in there.
						var tileEntry:DrawTileData = null;
						var j:int = _drawnTiles.length;
						while( j-- )
						{
							var tempTileEntry:DrawTileData = _drawnTiles[j];
							if ( tempTileEntry.tileId == tileId )
							{
								tileEntry = tempTileEntry;
								break;
							}
						}
						if ( tileEntry == null )
						{
							tileEntry = new DrawTileData;
							tileEntry.sourceBitmap = mapLayer.map.GetTileBitmap(tileId);
							tileEntry.fakeBitmap = tileEntry.sourceBitmap.clone();
							tileEntry.tileId = tileId;
							_drawnTiles.push( tileEntry );
						}
						
						var pos:FlxPoint = new FlxPoint;
						mapLayer.map.GetTileWorldFromUnitPos(x, y, pos);
						
						// Construct the overall selection bitmap from the region of each tile inside the selection.
						var rect:Rectangle = new Rectangle( 0, 0, mapLayer.map.tileWidth, mapLayer.map.tileHeight );
						var dest:Point = new Point( ( pos.x - mapLayer.map.x ) - topLeft.x, ( pos.y - mapLayer.map.y ) - topLeft.y );
						selectionBitmap.copyPixels( tileEntry.sourceBitmap, rect, dest, null, null, true);
						
						// The fake bitmap contains the actual data for this tile
						//dest = new Point( topLeft.x - ( pos.x - mapLayer.map.x ), topLeft.y - ( pos.y - mapLayer.map.y ) );
						//tileEntry.fakeBitmap.copyPixels(selectionBitmap, selectionBitmap.rect, dest, null, null, true);
						if ( (!LockedTileMode && !LockTileUnderCursor) || (currentLockedTile.x == x && currentLockedTile.y == y ) )
						{
							// When selecting an area moving the selection removes the original image, 
							// so set the area under the selection to empty.
							rect.x = topLeft.x - ( pos.x - mapLayer.map.x );
							rect.y = topLeft.y - ( pos.y - mapLayer.map.y );
							rect.width = selectionBitmap.width;
							rect.height = selectionBitmap.height;
							tileEntry.sourceBitmap.fillRect(rect, 0x00000000);
						}
					}
				}
			}
			selectionBitmapCopy = selectionBitmap.clone();
			
		}
		
		private function PaintSelectionOnSprite( bmp:BitmapData, sprite:EditorAvatar, topLeft:FlxPoint ):void
		{
			var newBitmap:BitmapData = _drawnTiles[0].sourceBitmap.clone();
			var pos:Point = new Point( selectionTopLeft.x - spriteForSelection.x, selectionTopLeft.y - spriteForSelection.y );
			bmp = bmp.clone();
			bmp.colorTransform(bmp.rect, new ColorTransform(1, 1, 1, DrawAlpha));
			if ( sprite.angle == 0 )
			{
				pos.x /= spriteForSelection.scale.x;
				pos.y /= spriteForSelection.scale.y;
				newBitmap.copyPixels(bmp, selectionBitmap.rect, pos, null, null, true);
			}
			else
			{
				var screenPos:FlxPoint = EditorState.getScreenXYFromMapXY(topLeft.x, topLeft.y, spriteForSelection.layer.xScroll, spriteForSelection.layer.yScroll);
				
				var matrix:Matrix = GetAngledSpriteDrawRotationMatrix(spriteForSelection, screenPos);
				
				newBitmap.draw(bmp, matrix );
			}
			sprite.ReplaceCurrentFrameBitmap(newBitmap);
			sprite.SetFromSpriteEntry( sprite.spriteEntry, true, true );
		}
		
		// Draw bmp on the mapLayer at the given pos.
		private function PaintSelection( bmp:BitmapData, mapLayer:LayerMap, topLeft:FlxPoint, spawnNewTiles:Boolean = false ):void
		{
			var endPos:FlxPoint = new FlxPoint(topLeft.x + bmp.width, topLeft.y + bmp.height);
			
			var startUnitTilePos:FlxPoint = new FlxPoint();
			getPixelOffsetsAndTileId(mapLayer.map, topLeft.x, topLeft.y, null, true, startUnitTilePos );
			var endUnitTilePos:FlxPoint = new FlxPoint();
			getPixelOffsetsAndTileId(mapLayer.map, endPos.x, endPos.y, null, true, endUnitTilePos );
			
			// Expand further to cope for isometric tilemaps.
			var extraTilePos:FlxPoint = new FlxPoint();
			getPixelOffsetsAndTileId(mapLayer.map, topLeft.x, endPos.y, null, true, extraTilePos );
			startUnitTilePos.x = Math.min( startUnitTilePos.x, extraTilePos.x );
			startUnitTilePos.y = Math.min( startUnitTilePos.y, extraTilePos.y );
			endUnitTilePos.x = Math.max( endUnitTilePos.x, extraTilePos.x );
			endUnitTilePos.y = Math.max( endUnitTilePos.y, extraTilePos.y );
			getPixelOffsetsAndTileId(mapLayer.map, endPos.x, topLeft.y, null, true, extraTilePos );
			startUnitTilePos.x = Math.min( startUnitTilePos.x, extraTilePos.x );
			startUnitTilePos.y = Math.min( startUnitTilePos.y, extraTilePos.y );
			endUnitTilePos.x = Math.max( endUnitTilePos.x, extraTilePos.x );
			endUnitTilePos.y = Math.max( endUnitTilePos.y, extraTilePos.y );
			
			if ( !_drawnTiles )
				_drawnTiles = new Vector.<DrawTileData>;
			_drawnTiles.length = 0;
			
			if ( DrawOnBaseOnly || Global.DrawTilesWithoutHeight )
			{
				var baseShape:Shape = new Shape;
				baseTileMask = mapLayer.map.GenerateFloorTileBitmap(baseShape, 0xffffff);
			}
			
			if ( LockTileUnderCursor )
			{
				startUnitTilePos.copyFrom( currentLockedTile );
				endUnitTilePos.copyFrom( currentLockedTile );
			}
			
			bmp = bmp.clone();
			bmp.colorTransform(bmp.rect, new ColorTransform(1, 1, 1, DrawAlpha));
			
			for ( var y: uint = startUnitTilePos.y; y <= endUnitTilePos.y; y++ )
			{
				for ( var x: uint = startUnitTilePos.x; x <= endUnitTilePos.x; x++ )
				{
					if ( mapLayer.map.tileIsValid( x, y ) )
					{
						var tileId:int = mapLayer.map.getTile(x, y);
						
						if ( tileId < mapLayer.map.drawIndex && !spawnNewTiles )
							continue;
							
						if ( (LockedTileMode || LockTileUnderCursor) && (currentLockedTile.x != x && currentLockedTile.y != y ) )
							continue;
							
						// Find an existing entry for this tile. If not, then create one.
						
						var tileEntry:DrawTileData = null;
						var j:int = _drawnTiles.length;
						var tileBmp:BitmapData;
						while( j-- )
						{
							var tempTileEntry:DrawTileData = _drawnTiles[j];
							if ( tempTileEntry.tileId == tileId )
							{
								tileEntry = tempTileEntry;
								tileBmp = tileEntry.fakeBitmap;
								break;
							}
						}
						
						if ( !tileEntry )
						{
							tileEntry = new DrawTileData;
							tileEntry.sourceBitmap = mapLayer.map.GetTileBitmap(tileId);
							tileBmp = tileEntry.fakeBitmap = tileEntry.sourceBitmap.clone();
							tileEntry.tileId = tileId;
							_drawnTiles.push( tileEntry );
						}
						
						if ( spawnNewTiles )
						{
							var blankBmp:BitmapData = tileEntry.fakeBitmap.clone();
						}
						
						var pos:FlxPoint = new FlxPoint;
						mapLayer.map.GetTileWorldFromUnitPos(x, y, pos);
						
						var dest:Point = new Point( topLeft.x - ( pos.x - mapLayer.map.x ), topLeft.y - ( pos.y - mapLayer.map.y ) );

						if ( (DrawOnBaseOnly || Global.DrawTilesWithoutHeight ) && baseTileMask )
						{
							var newBmp:BitmapData = new BitmapData(tileBmp.width, tileBmp.height,true,0x00000000);
							if ( drawOrderMode == DRAW_ABOVE )
							{
								newBmp.copyPixels(bmp, bmp.rect, dest, baseTileMask, dest, true);
								tileBmp.copyPixels(newBmp, newBmp.rect, new Point, tileBmp, null, true);
							}
							else if ( drawOrderMode == DRAW_BEHIND )
							{
								newBmp.copyPixels(bmp, bmp.rect, dest, baseTileMask, dest, true);
								
								newBmp.copyPixels(tileBmp, tileBmp.rect, new Point, null, null, true);
								tileBmp = tileEntry.fakeBitmap = newBmp;
							}
							else
							{
								tileBmp.copyPixels(bmp, bmp.rect, dest, baseTileMask, dest, true);
							}
						}
						else
						{
							if ( drawOrderMode == DRAW_ABOVE )
							{
								tileBmp.copyPixels(bmp, bmp.rect, dest, tileBmp, dest, true);
							}
							else if ( drawOrderMode == DRAW_BEHIND )
							{
								newBmp = new BitmapData(tileBmp.width, tileBmp.height, true, 0x00000000);
								
								newBmp.copyPixels(bmp, bmp.rect, dest, null, null, true);
								newBmp.copyPixels(tileBmp, tileBmp.rect, new Point, null, null, true);
								tileBmp = tileEntry.fakeBitmap = newBmp;
							}
							else
							{
								tileBmp.copyPixels(bmp, bmp.rect, dest, null, null, true);
							}
						}
						
						
						
						if ( spawnNewTiles )
						{
							// Only create the tile if it is different to the original
							// eg lines drawn diagonally will cover many tiles that aren't changed because the rect is larger.
							if ( blankBmp.compare(tileEntry.fakeBitmap) != 0 )
							{
								var state:EditorState = FlxG.state as EditorState;
								state.ModifyTiles(true, true, false, false, false, false, tileId, mapLayer.map.tileCount - 1, false);
								tileId = tileEntry.tileId = mapLayer.map.tileCount - 1;
								mapLayer.map.setTile( x, y, tileId);
							}
							else
							{
								_drawnTiles.splice( _drawnTiles.indexOf(tileEntry),1 );
							}
						}

						mapLayer.map.SetTileBitmap(tileId, tileBmp );
					}
				}
			}
		}
		
		override public function CopyData():void
		{
			if ( selectionBitmap )
			{
				// When we copy and paste internally we can use the transparencies in the bitmap.
				// but going between different software removes the transparency.
				flash.desktop.Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT, selectionBitmap);
				Clipboard.SetData( selectionBitmap );
			}
		}
		
		override public function PasteData():void
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			var spriteLayer:LayerSprites = App.getApp().CurrentLayer as LayerSprites;
			
			if ( mapLayer == null && spriteLayer == null )
				return;
			
			if( !flash.desktop.Clipboard.generalClipboard.hasFormat(ClipboardFormats.BITMAP_FORMAT))
				return;
				
			var systemBmp:BitmapData = BitmapData(flash.desktop.Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT));
			var internalBmp:BitmapData = Clipboard.GetData() as BitmapData;
			var bmp:BitmapData = systemBmp;
			
			if ( internalBmp )
			{
				if ( systemBmp )
				{
					// Remove alpha from the internal bmp when doing the comparison, so we can make a good guess that this
					// is the same bmp as the one on the system clipboard.
					var tempBmp:BitmapData = new BitmapData(bmp.width, bmp.height,false,0);
					tempBmp.copyPixels( internalBmp, internalBmp.rect, new Point );
					if ( systemBmp.compare(tempBmp) == 0 )
					{
						// Use the internal bmp as they're 99% certain to be identical.
						bmp = internalBmp;
					}
				}
				else
				{
					bmp = internalBmp;
				}
			}

			// If we select paste from the menu instead of shortcut then need to ensure it is pasted in the center of the screen.
			if ( mouseScreenPos.x < 0 || mouseScreenPos.x > FlxG.width)
				mouseScreenPos.x = FlxG.width / 2;
			if ( mouseScreenPos.y < 0 || mouseScreenPos.y > FlxG.height)
				mouseScreenPos.y = FlxG.height / 2;
				
			if ( mapLayer )
			{
				var mapPos:FlxPoint = convertScreenPosToMapPos( mapLayer.map, mouseScreenPos.x, mouseScreenPos.y );
				
				var drawnTilesCopy:Vector.<DrawTileData> = CopyDrawnTiles();
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( mapLayer, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
				
				selectionBitmap = new BitmapData(bmp.width, bmp.height, true, 0x00000000);
				selectionBitmap.copyPixels(bmp, bmp.rect, new Point);
				selectionBitmapCopy = selectionBitmap.clone();
				
				PaintSelection( selectionBitmap, mapLayer, mapPos );
				var endPos:FlxPoint = new FlxPoint(mapPos.x + bmp.width, mapPos.y + bmp.height);
				
				selectionTopLeft = mapPos;
				selectionBotRight = endPos;
				drawingLayer = mapLayer;
				spriteForSelection = null;
				var currentState:EditorState = FlxG.state as EditorState;
				currentState.UpdateCurrentTileList(mapLayer);
				ImageBank.MarkImageAsChanged( mapLayer.imageFileObj, mapLayer.imageData );
				var app:App = App.getApp();
				if ( app.brushesWindow && app.brushesWindow.visible )
				{
					app.brushesWindow.recalcPreview();
				}
			}
			else
			{
				var avatar:EditorAvatar = GetSpriteUnderCursor( spriteLayer );
				if ( avatar )
				{
					drawnTilesCopy = CopyDrawnTiles();
					HistoryStack.BeginOperation(new OperationDrawChangeSelection( avatar, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );
				
					selectionBitmap = new BitmapData(bmp.width, bmp.height, true, 0x00000000);
					selectionBitmap.copyPixels(bmp, bmp.rect, new Point);
					selectionBitmapCopy = selectionBitmap.clone();
					
					var topLeft:FlxPoint = EditorState.getMapXYFromScreenXY(mouseScreenPos.x, mouseScreenPos.y, avatar.layer.xScroll, avatar.layer.yScroll);
					var botRight:FlxPoint = new FlxPoint( topLeft.x + selectionBitmap.width, topLeft.y + selectionBitmap.height );
					var worldPos:FlxPoint;
					if ( avatar.angle != 0 && avatar.bakedBitmap )
					{
						worldPos = EditorState.getMapXYFromScreenXY(avatar.bakedBitmapPt.x, avatar.bakedBitmapPt.y, avatar.layer.xScroll, avatar.layer.yScroll);
					}
					else
					{
						worldPos = avatar; 
					}
					var rect:Rectangle = new Rectangle(topLeft.x - worldPos.x, topLeft.y - worldPos.y, botRight.x - topLeft.x, botRight.y - topLeft.y);

					selectionTopLeft = topLeft;
					selectionBotRight = botRight;
					
					
					var tileEntry:DrawTileData = new DrawTileData;
					tileEntry.sprite = spriteForSelection = selectedSprite = avatar;
					spriteForSelectionAngle = avatar.angle;
					spriteForSelectionScale = avatar.scale.copy();
					// Store the source bitmap for this tile BEFORE we make any modifications to it.
					var sourceBitmap:BitmapData = spriteForSelection.GetBitmap();
					tileEntry.sourceBitmap = new BitmapData(sourceBitmap.width, sourceBitmap.height, true,0x00000000 );
					tileEntry.sourceBitmap.copyPixels(sourceBitmap, sourceBitmap.rect, new Point, null, null, true);
					tileEntry.fakeBitmap = tileEntry.sourceBitmap.clone();
					_drawnTiles.length = 0;
					_drawnTiles.push( tileEntry );
					
					drawingLayer = null;
					//selectionTopLeft = selectionTopLeftBeforeMove.v_add( screenOffsetFromOriginalPos );
					PaintSelectionOnSprite(selectionBitmap, spriteForSelection, selectionTopLeft );
					updateTileListForSprite( spriteForSelection.spriteEntry, false, null, ModifySprites );
					if ( App.getApp().animEditor )
					{
						App.getApp().animEditor.UpdateData();
					}
					ImageBank.MarkImageAsChanged( spriteForSelection.spriteEntry.imageFile, spriteForSelection.spriteEntry.bitmap );
				}
			}
		}
		

		//} endregion
		
		override protected function DeleteSelection( ):void
		{
			var drawnTilesCopy:Vector.<DrawTileData> = CopyDrawnTiles();
			if ( spriteForSelection )
			{
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( spriteForSelection, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );

				spriteForSelection.ReplaceCurrentFrameBitmap(_drawnTiles[0].sourceBitmap);
				spriteForSelection.SetFromSpriteEntry( spriteForSelection.spriteEntry, true, true );
				updateTileListForSprite( spriteForSelection.spriteEntry, false, null, ModifySprites );
				if ( App.getApp().animEditor )
				{
					App.getApp().animEditor.UpdateData();
				}
				ImageBank.MarkImageAsChanged( spriteForSelection.spriteEntry.imageFile, spriteForSelection.spriteEntry.bitmap );
			}
			else if ( drawingLayer )
			{
				HistoryStack.BeginOperation(new OperationDrawChangeSelection( drawingLayer, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );

				selectionBitmap = new BitmapData(selectionBitmap.width, selectionBitmap.height, true, 0x00000000);
				//PaintSelection(selectionBitmap, mapLayer, selectionTopLeft);
				var i:int = _drawnTiles.length;
		
				// Clear up the previously drawn tiles.
				while(i--)
				{
					var tileEntry:DrawTileData = _drawnTiles[i];
		
					drawingLayer.map.SetTileBitmap(tileEntry.tileId, tileEntry.sourceBitmap );
				}
				(FlxG.state as EditorState).UpdateCurrentTileList(drawingLayer);
				ImageBank.MarkImageAsChanged( drawingLayer.imageFileObj, drawingLayer.imageData );
			}
			_drawnTiles.length = 0;
			selectionBitmap = selectionBitmapCopy = null;
		}
		
		public function RestoreSelection( topLeftSelection:FlxPoint, botRightSelection:FlxPoint, bmp:BitmapData, selectedObj:Object, drawnTiles:Vector.<DrawTileData> ):void
		{
			selectionTopLeft = topLeftSelection;
			selectionBotRight = botRightSelection;
			selectionBitmap = bmp;
			selectionBitmapCopy = bmp ? bmp.clone() : null;
			spriteForSelection = selectedObj as EditorAvatar;
			if ( spriteForSelection )
			{
				spriteForSelectionAngle = spriteForSelection.angle;
				spriteForSelectionScale = spriteForSelection.scale.copy();
			}
			drawingLayer = selectedObj as LayerMap;
			var i:int = drawnTiles.length;
			
			// Clear up the previously drawn tiles.
			while(i--)
			{
				var tileEntry:DrawTileData = drawnTiles[i] as DrawTileData;
				if ( drawingLayer )
				{
					drawingLayer.map.SetTileBitmap(tileEntry.tileId, tileEntry.sourceBitmap );
				}
				else if ( spriteForSelection )
				{
					spriteForSelection.ReplaceCurrentFrameBitmap(tileEntry.sourceBitmap);
				}
			}
			_drawnTiles = drawnTiles as Vector.<DrawTileData>;
			
			if ( selectionBitmap )
			{
				if( drawingLayer )
					PaintSelection( selectionBitmap, drawingLayer, selectionTopLeft );
				else if ( spriteForSelection )
					PaintSelectionOnSprite( selectionBitmap, spriteForSelection, selectionTopLeft );
			}
		}
		
		override protected function DecideContextMenuActivation( ):void
		{
			contextMenu.removeAllItems();
			var currentLayer:LayerEntry = App.getApp().CurrentLayer;
			if ( currentLayer is LayerMap )
			{
				var item:NativeMenuItem = addNewContextMenuItem(contextMenu, "Lock Tile Under Cursor", contextMenuHandler );
				item.checked = LockTileUnderCursor;
				addNewContextMenuItem(contextMenu, "Insert Blank Tile", contextMenuHandler);
				addNewContextMenuItem(contextMenu, "Insert Copy Of Tile", contextMenuHandler);
				if ( selectionBitmap )
				{
					addNewContextMenuItem(contextMenu, "Spawn New Tiles Under Selection", contextMenuHandler );
				}
			}
			else if ( currentLayer is LayerSprites )
			{
				if ( currentLayer )
				{
					var tempSprite:EditorAvatar = GetSpriteUnderCursor( currentLayer as LayerSprites );
					if ( tempSprite && tempSprite.spriteEntry )
					{
						addNewContextMenuItem(contextMenu, "Select Sprite", contextMenuHandler);
					}
				}
				if ( selectedSprite )
				{
					addNewContextMenuItem(contextMenu, "Unselect Sprite", contextMenuHandler);
				}
			}
			if ( Eraser )
				addNewContextMenuItem(contextMenu, "Use Brush", contextMenuHandler);
			else
				addNewContextMenuItem(contextMenu, "Use Eraser", contextMenuHandler);
			
			
			contextMenu.display( FlxG.stage, FlxG.stage.mouseX, FlxG.stage.mouseY );
		}
		
		protected function contextMenuHandler(event:Event):void
		{			
			var app:App = App.getApp();
			switch( event.target.label )
			{
			case "Select Sprite":
				{
					var currentLayer:LayerSprites = app.CurrentLayer as LayerSprites;
					if ( currentLayer )
					{
						var newSprite:EditorAvatar = GetSpriteUnderCursor( currentLayer );
						if ( selectedSprite && newSprite != selectedSprite && selectedSprite.spriteEntry )
						{
							selectedSprite.RemoveAnimOverride();
						}
						selectedSprite = newSprite;
						updateTileListForSprite( selectedSprite ? selectedSprite.spriteEntry : null, false, null, ModifySprites );
						if ( app.animEditor )
						{
							app.animEditor.UpdateData();
						}
					}
				}
				break;
				
			case "Unselect Sprite":
				if ( selectedSprite )
				{
					selectedSprite.RemoveAnimOverride();
					selectedSprite = null;
					updateTileListForSprite( null, false, null, ModifySprites );
				}
				break;
				
			case "Lock Tile Under Cursor":
				LockTileUnderCursor = !LockTileUnderCursor;
				currentLockedTile.copyFrom(currentTile);
				currentLockedTilePos.copyFrom(currentTileWorldPos);
				break;
				
			case "Use Brush":
			case "Use Eraser":
				Eraser = !Eraser;
				Global.windowedApp.EditModeDrawEraser.selected = Eraser;
				break;
				
			case "Insert Blank Tile":
				var state:EditorState = FlxG.state as EditorState;
				var mapLayer:LayerMap = app.CurrentLayer as LayerMap;
				if ( mapLayer )
				{
					state.ModifyTiles(true, false, false, false, false, false,mapLayer.map.getTile( currentTile.x, currentTile.y ), mapLayer.map.tileCount - 1);
					mapLayer.map.setTile( currentTile.x, currentTile.y, mapLayer.map.tileCount - 1);
				}
				break;
				
			case "Insert Copy Of Tile":
				state = FlxG.state as EditorState;
				mapLayer = app.CurrentLayer as LayerMap;
				if ( mapLayer )
				{
					state.ModifyTiles(true, true, false, false, false, false,mapLayer.map.getTile( currentTile.x, currentTile.y ), mapLayer.map.tileCount - 1);
					mapLayer.map.setTile( currentTile.x, currentTile.y, mapLayer.map.tileCount - 1);
				}
				break;
				
			case "Spawn New Tiles Under Selection":
				mapLayer = App.getApp().CurrentLayer as LayerMap;
				if ( mapLayer && selectionBitmap)
				{
					HistoryStack.BeginOperation(new OperationModifyTiles( mapLayer ) );
					// Clear up previously drawn tiles:
					var i:int = _drawnTiles.length;
					while(i--)
					{
						drawingLayer.map.SetTileBitmap(_drawnTiles[i].tileId, _drawnTiles[i].sourceBitmap );
					}
					PaintSelection(selectionBitmap, mapLayer, selectionTopLeft, true);
					
					var tileCounts:Dictionary = new Dictionary(true);

					for each( var group:LayerGroup in app.layerGroups )
					{
						for each( var layer:LayerEntry in group.children )
						{
							var testMapLayer:LayerMap = layer as LayerMap;
							
							if ( testMapLayer != null && Misc.FilesMatch(mapLayer.imageFileObj, testMapLayer.imageFileObj ) )
							{
								tileCounts[testMapLayer] = testMapLayer.map.tileCount;
							}
						}
					}
					ImageBank.MarkImageAsChanged( mapLayer.imageFileObj, mapLayer.imageData );
					// As the image changed callback resets the tileCount based on the dimensions, ensure the tile count is kept up to date.
					for ( var key:Object in tileCounts )
					{
						testMapLayer = key as LayerMap;
						testMapLayer.map.tileCount = tileCounts[testMapLayer];
					}
					state = FlxG.state as EditorState;
					state.UpdateCurrentTileList(mapLayer);
				}
				break;
			}
		}
		
		public function WaitForSelect():void
		{
			PromptManager.manager.ShowPrompt("Click on a sprite to select it.");
			waitForSelect = true;
		}

		public function CanModifySpriteFrames():Boolean
		{
			return selectedSprite != null;
		}
		
		public function GetSelectedSprite():EditorAvatar
		{
			return selectedSprite;
		}
		
		override public function GetSelectedSpriteEntry():SpriteEntry
		{
			return (selectedSprite ? selectedSprite.spriteEntry : null );
		}
		
		public function ClearSelectedSprites():void
		{
			selectedSprite = null;
			spriteForSelection = null;
		}
		
		public function FlipSelection():void
		{
			if ( selectionBitmap )
			{
				var drawnTilesCopy:Vector.<DrawTileData> = CopyDrawnTiles();
				
				var mat:Matrix = new Matrix;
				mat.scale( -1, 1);
				mat.translate( selectionBitmap.width, 0);
				var newBmp:BitmapData = new BitmapData(selectionBitmap.width, selectionBitmap.height, true, 0x00000000);
				newBmp.draw(selectionBitmap, mat);
				
				
				if ( spriteForSelection && _drawnTiles.length )
				{
					HistoryStack.BeginOperation(new OperationDrawChangeSelection( spriteForSelection, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );

					selectionBitmap = selectionBitmapCopy = newBmp.clone();
					PaintSelectionOnSprite(selectionBitmap, spriteForSelection, selectionTopLeft );
					updateTileListForSprite( spriteForSelection.spriteEntry, false, null, ModifySprites );
					if ( App.getApp().animEditor )
					{
						App.getApp().animEditor.UpdateData();
					}
					ImageBank.MarkImageAsChanged( spriteForSelection.spriteEntry.imageFile, spriteForSelection.spriteEntry.bitmap );
				}
				else if ( drawingLayer )
				{
					HistoryStack.BeginOperation(new OperationDrawChangeSelection( drawingLayer, selectionTopLeft, selectionBotRight, selectionBitmap, drawnTilesCopy ) );

					selectionBitmap = selectionBitmapCopy = newBmp.clone();
					PaintSelection( selectionBitmap, drawingLayer, selectionTopLeft );
					(FlxG.state as EditorState).UpdateCurrentTileList(drawingLayer);
					ImageBank.MarkImageAsChanged( drawingLayer.imageFileObj, drawingLayer.imageData );
				}
			}
		}
		
		public static function ApplyNewTileStroke():void
		{
			newTileModeTileIds.length = 0;
		}
		
		public function getDropperText():String
		{
			return dropperText;
		}
		
	}

}

import com.Game.EditorAvatar;
import org.flixel.FlxPoint;

internal class SpritePosData
{
	public var _avatar:EditorAvatar;
	public var _pos:FlxPoint;
	
	public function SpritePosData( avatar:EditorAvatar = null, pos:FlxPoint = null )
	{
		_avatar = avatar;
		_pos = pos;
	}
}

