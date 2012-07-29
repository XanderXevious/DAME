package com.Tiles 
{
	import com.Game.Avatar;
	import com.Layers.LayerMap;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import org.flixel.*;
	import com.Utils.DebugDraw;
	
	
	public class FlxTilemapExt extends FlxTilemap
	{
		[Embed(source='../../../assets/selectionImage.png')] private var ImgSelectedTile:Class;
		private var alpha:Number;
		public var desiredAlpha:Number = 1;
		
		protected var _storedPixels:BitmapData = null;
		
		public function getData(): Array { return _data; }
		public function getRects(): Array { return _rects; }
		
		public static var handleScreenResize:Boolean = false;
		
		public function get tileWidth(): uint
		{
			return _tileWidth;
		}
		
		public function get tileHeight(): uint
		{
			return _tileHeight;
		}
		
		public var tileCount:uint;
		
		public var highlightTileIndexForThisFrame:int = -1;	// Cleared after each render
		public static var highlightCollidableTiles:Boolean = false;
		public var clipRender:Boolean = false;
		public var clipLeft:int = 0;
		public var clipRight:int = 0;
		public var clipTop:int = 0;
		public var clipBottom:int = 0;
		
		public var selectionBmp:BitmapData = null;
		protected var quarterSelectionBmp:BitmapData;
		protected var eighthSelectionBmp:BitmapData;
		protected var noHeightBmp:BitmapData = null;
		protected var tintBmp:BitmapData = null;
		
		public var selectedTiles:Vector.<Boolean> = null;	// More efficient to be vector since likely that all tiles could be selected.
		public var stickyTiles:Dictionary = null;	// More efficient as dictionary since few tiles will ever be sticky.
		
		// Cached values to know if we need to update the screen size
		private var lastScreenWidth:int = 0;
		private var lastScreenHeight:int = 0;
		
		public var drawTileAboveTileId:int = -1;
		
		public var tileAnims:Vector.<TileAnim> = null;
		public static var sharedTileAnims:Dictionary = new Dictionary;
		
		// Tile properties
		public var propertyList:Vector.<ArrayCollection> = new Vector.<ArrayCollection>;
		public static var sharedProperties:Dictionary = new Dictionary;
		
		public static const E_DisablePlayAnimsReason_Drawing:uint = 0x01;
		public static var DisablePlayAnims:uint = 0;
		
		protected var tileIdRects:Array = null;
		
		public var stackedTiles:Dictionary = null;	// List of StackTileInfo data indexed by the tile idx
		public var numStackedTiles:int = 0;
		public var stackHeight:int = 0;	// The height at which high tiles can be placed. Must be > 0
		public var highestStack:int = 0;
		public static const MAX_STACKED_TILES:int = 20;
		
		
		
		public function FlxTilemapExt() 
		{
			alpha = 1;
			
			super();		
		}
		
		override public function update():void
		{
			if (!_pixels)
			{
				return;
			}
			
			if ( Global.PlayAnims && !DisablePlayAnims && tileAnims )
			{
				var animId:uint = tileAnims.length;
				while (animId--)
				{
					tileAnims[animId].Update(FlxG.elapsed);
				}
			}
			
			super.update();
			
			if ( lastScreenWidth != FlxG.width || lastScreenHeight != FlxG.height || lastZoomRenderSize != FlxG.extraZoom)
			{
				lastScreenWidth = FlxG.width;
				lastScreenHeight = FlxG.height;
				UpdateScreenSize();
			}
		}
		
		public function loadExternalMap(MapData:String, TileGraphic:BitmapData, TileWidth:uint = 0, TileHeight:uint = 0):FlxTilemap
		{
			_data = new Array();
			_rects = new Array();
			// Pass in Unique=true so that we can fade these tiles separately, even if the graphics are shared among maps.
			isUnique = true;	// Gets handled by addBitmap within loadMap
			_storedPixels = _pixels = TileGraphic;
			// requires that my modification to cope with a null TileGraphic by not loading the graphic class is in there...
			super.loadMap( MapData, null, TileWidth, TileHeight );
			tileCount = ( _pixels.width / tileWidth ) * (_pixels.height / tileHeight );
			initBaseGraphics();
			
			return this;
		}
		
		public function importMapData(MapData:String ):FlxTilemap
		{
			_data = new Array();
			_rects = new Array();
			widthInTiles = 0;
			super.loadMap( MapData, null, tileWidth, tileHeight );
			tileCount = ( _pixels.width / tileWidth ) * (_pixels.height / tileHeight );
			initBaseGraphics();
			
			return this;
		}
		
		public function GetTileIdDataArray():Array
		{
			return _data;
		}
		
		public function SetTileIdData( newData:Array, _widthInTiles:uint = 0, _heightInTiles:uint = 0, newTileWidth:uint = 0, newTileHeight:uint = 0 ):void
		{
			if ( _widthInTiles != 0 || _heightInTiles != 0 || newTileWidth !=0 || newTileHeight != 0 )
			{
				// We're changing dimensions;
				var changeSize:Boolean = true;
			}
			if ( !changeSize && _data.length != newData.length )
			{
				return;
			}
			if( newTileWidth )
				_tileWidth = newTileWidth;
			if( newTileHeight )
				_tileHeight = newTileHeight;
			_data = newData;
			
			if ( changeSize )
			{
				widthInTiles = _widthInTiles;
				heightInTiles = _heightInTiles;
				totalTiles = widthInTiles * heightInTiles;
				
				//Then go through and create the actual map
				width = ((widthInTiles-1)*tileSpacingX) + _tileWidth;
				height = ((heightInTiles-1)*tileSpacingY) + _tileHeight;
				UpdateScreenSize();
				
				CalculationDimensions();
			}
			
			_rects = new Array(totalTiles);
				for(var i:uint = 0; i < totalTiles; i++)
					updateTile(i);
			
			refreshHulls();
			
			initBaseGraphics();
		}
		
		public function changeMapGraphic( TileGraphic:BitmapData, TileWidth:uint = 0, TileHeight:uint = 0):void
		{
			if ( TileWidth )
			{
				_tileWidth = TileWidth;
			}
			if ( TileHeight )
			{
				_tileHeight = TileHeight;
			}
			
			_storedPixels = _pixels = TileGraphic;
			
			tileCount = ( _pixels.width / tileWidth ) * (_pixels.height / tileHeight );
			
			//Then go through and create the actual map
			width = ((widthInTiles-1)*tileSpacingX) + _tileWidth;
			height = ((heightInTiles - 1) * tileSpacingY) + _tileHeight;
			CalculationDimensions();
			_rects = new Array(totalTiles);
			for(var i:uint = 0; i < totalTiles; i++)
				updateTile(i);

			UpdateScreenSize();
			
			refreshHulls();
			
			initBaseGraphics();
		}
		
		public override function loadMap(MapData:String, TileGraphic:Class, TileWidth:uint = 0, TileHeight:uint = 0):FlxTilemap
		{
			_data = new Array();
			_rects = new Array();
			// Pass in Unique=true so that we can fade these tiles separately, even if the graphics are shared among maps.
			isUnique = true;	// Gets handled by addBitmap within loadMap
			super.loadMap( MapData, TileGraphic, TileWidth, TileHeight );
			_storedPixels = _pixels;
			tileCount = ( _pixels.width / tileWidth ) * (_pixels.height / tileHeight );
			initBaseGraphics();
			
			return this;
		}
		
		protected function UpdateTileIdRects():void
		{
			tileIdRects = new Array( tileCount );
			var i:uint = 0;
			while(i < tileCount)
				updateTileForId(i++);
		}
		
		public function InitPixels():void
		{
			_storedPixels = _pixels;
		}
		
		protected function drawSmallerTilePixels():void
		{
			var tempBmp:BitmapData;
			var mat:Matrix = new Matrix;
			
			// quarter bitmap...
			
			mat.scale(0.25, 0.25);
			quarterPixels.draw(_pixels, mat, null, null, null, true);
			tempBmp = quarterPixels.clone();
			// Paste this a couple of times so that edge pixels are not empty.
			// This prevents there being empty pixels making the image noisy.
			var pt:Point = new Point(-1, 0);
			quarterPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			pt.x = 1;
			quarterPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			pt.x = 0; pt.y = -1;
			quarterPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			pt.y = 1;
			quarterPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			
			// Eighth bitmap...
			
			mat.identity();
			mat.scale(0.125, 0.125);
			eighthPixels.draw(_pixels, mat, null, null, null, true);
			tempBmp = eighthPixels.clone();
			pt.x = -1; pt.y = 0;
			eighthPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			pt.x = 1;
			eighthPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			pt.x = 0; pt.y = -1;
			eighthPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
			pt.y = 1;
			eighthPixels.copyPixels(tempBmp, tempBmp.rect, pt, null, null, true);
		}
		
		private function initBaseGraphics():void
		{
			_pixels = _storedPixels.clone();
			
			quarterPixels = new BitmapData(Math.ceil(_pixels.width * 0.25), Math.ceil(_pixels.height * 0.25), true, 0x00000000);
			eighthPixels = new BitmapData(Math.ceil(_pixels.width * 0.125), Math.ceil(_pixels.height * 0.125), true, 0x00000000);
			
			drawSmallerTilePixels();
			
			var mat:Matrix = new Matrix;
			
			// quarter bitmap...
			mat.scale(0.25, 0.25);
			quarterSelectionBmp = new BitmapData(Math.ceil(selectionBmp.width * 0.25), Math.ceil(selectionBmp.height * 0.25), true, 0x00000000);
			quarterSelectionBmp.draw(selectionBmp, mat, null, null, null, true);
			
			// Eighth bitmap...
			mat.identity();
			mat.scale(0.125, 0.125);
			eighthSelectionBmp = new BitmapData(Math.ceil(selectionBmp.width * 0.125), Math.ceil(selectionBmp.height * 0.125), true, 0x00000000);
			eighthSelectionBmp.draw(selectionBmp, mat,null,null,null,true);
			
			// For the latest version of flixel. 2.43....
			UpdateTileIdRects();
			
			
		}
		
		public static function GenerateFloorTileShapeFromCorners( shape:Shape, x1:int, y1:int, x2:int, y2:int, x3:int, y3:int, x4:int, y4:int ):void
		{
			shape.graphics.moveTo( x1 , y1 );
			shape.graphics.lineTo( x2, y2 );
			shape.graphics.lineTo( x3, y3 );
			shape.graphics.lineTo( x4, y4 );
			shape.graphics.lineTo( x1, y1 );
		}
		
		public static function GenerateIsoTileShape(shape:Shape, tileWidth:int, tileHeight:int, tileOffsetX:int, tileOffsetY:int, tileSpacingX:int, tileSpacingY:int):Boolean
		{
			if ( tileOffsetX || tileOffsetY )
			{
				var bot:int = ( 0 + tileHeight );
				
				var topLeftX:int = 0;
				var topLeftY:int = bot - tileSpacingY;
				var topRightX:int = 0 + tileSpacingX;
				var topRightY:int = bot - tileSpacingY;
				var botLeftX:int = 0;
				var botLeftY:int = bot;
				var botRightX:int = 0 + tileSpacingX;
				var botRightY:int = bot;
				
				if ( tileOffsetX < 0 ) // Slant to the up and right.
				{
					topLeftX -= tileOffsetX;
					topRightX -= tileOffsetX;
				}
				else if ( tileOffsetX > 0 ) // Slant to the up and left.
				{
					botLeftX += tileOffsetX;
					botRightX += tileOffsetX;
				}
				
				if ( tileOffsetY < 0 )	// Tile going up and to the right.
				{
					topRightY += tileOffsetY;
					botRightY += tileOffsetY;
				}
				else if ( tileOffsetY > 0 ) // Tile going down and to the right.
				{
					topLeftY -= tileOffsetY;
					botLeftY -= tileOffsetY;
				}

				GenerateFloorTileShapeFromCorners( shape, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
				return true;
			}
			return false;
		}
		
		// Pass in a shape that has already had a beginFill called on it.
		public function GenerateFloorTileBitmap(shape:Shape, color:uint):BitmapData
		{
			shape.graphics.beginFill(color);
			var sx:int = tileWidth - tileSpacingX;
			var sy:int = tileHeight - tileSpacingY;
			if ( tileOffsetX || tileOffsetY )
			{
				GenerateIsoTileShape(shape, tileWidth, tileHeight, tileOffsetX, tileOffsetY, tileSpacingX, tileSpacingY);
			}
			else if ( xStagger )
			{
				var realHeight:int = tileSpacingY * 2;
				
				var bot:int = ( sy + tileSpacingY );
				
				var halfWidth:int = tileSpacingX * 0.5;

				var topLeftX:int = 0 + halfWidth;
				var topLeftY:int = bot - realHeight;
				var topRightX:int = 0 + tileSpacingX;
				var topRightY:int = bot - tileSpacingY;
				var botLeftX:int = 0;
				var botLeftY:int = bot - tileSpacingY;
				var botRightX:int = 0 + halfWidth;
				var botRightY:int = bot;

				GenerateFloorTileShapeFromCorners( shape, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
			}
			else
			{
				shape.graphics.drawRect(sx, sy, tileSpacingX, tileSpacingY );
			}
			shape.graphics.endFill();
			
			// The bmp that is used to highlight selected tiles.			
			var bmp:BitmapData = new BitmapData(tileWidth, tileHeight,true,0x00000000);
			bmp.draw(shape);
			
			
			// remove any antialiasing from the shape drawn.
			bmp.threshold(bmp, bmp.rect, new Point, ">", 0x00000000, 0xff000000|color, 0xff000000);
			
			return bmp;
		}
		
		override protected function CalculationDimensions():void
		{
			super.CalculationDimensions();
			
			// Render the bmps for 2.5D tiles
			
			var shape:Shape = new Shape;
			var shape2:Shape = new Shape;
			var shape3:Shape = new Shape;
			var sx:int = tileWidth - tileSpacingX;
			var sy:int = tileHeight - tileSpacingY;

			shape.graphics.beginBitmapFill(new ImgSelectedTile().bitmapData, null, true);
			shape2.graphics.beginFill(0xffffff);
			shape3.graphics.beginFill(Global.TileTintColour,Global.TileTintAlpha);	// yellow
			
			if ( tileOffsetX || tileOffsetY )
			{
				var bot:int = ( 0 + tileHeight );
				
				var topLeftX:int = 0;
				var topLeftY:int = bot - tileSpacingY;
				var topRightX:int = 0 + tileSpacingX;
				var topRightY:int = bot - tileSpacingY;
				var botLeftX:int = 0;
				var botLeftY:int = bot;
				var botRightX:int = 0 + tileSpacingX;
				var botRightY:int = bot;
				
				if ( tileOffsetX < 0 ) // Slant to the up and right.
				{
					topLeftX -= tileOffsetX;
					topRightX -= tileOffsetX;
				}
				else if ( tileOffsetX > 0 ) // Slant to the up and left.
				{
					botLeftX += tileOffsetX;
					botRightX += tileOffsetX;
				}
				
				if ( tileOffsetY < 0 )	// Tile going up and to the right.
				{
					topRightY += tileOffsetY;
					botRightY += tileOffsetY;
				}
				else if ( tileOffsetY > 0 ) // Tile going down and to the right.
				{
					topLeftY -= tileOffsetY;
					botLeftY -= tileOffsetY;
				}

				GenerateFloorTileShapeFromCorners( shape, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
				GenerateFloorTileShapeFromCorners( shape2, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
				GenerateFloorTileShapeFromCorners( shape3, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
			}
			else if ( xStagger )
			{
				var realHeight:int = tileSpacingY * 2;
				
				bot = ( sy + tileSpacingY );
				
				var halfWidth:int = tileSpacingX * 0.5;

				topLeftX = 0 + halfWidth;
				topLeftY = bot - realHeight;
				topRightX = 0 + tileSpacingX;
				topRightY = bot - tileSpacingY;
				botLeftX = 0;
				botLeftY = bot - tileSpacingY;
				botRightX = 0 + halfWidth;
				botRightY = bot;

				GenerateFloorTileShapeFromCorners( shape, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
				GenerateFloorTileShapeFromCorners( shape2, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
				GenerateFloorTileShapeFromCorners( shape3, topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY );
			}
			else
			{
				shape.graphics.drawRect(sx, sy, tileSpacingX, tileSpacingY );
				shape2.graphics.drawRect(sx, sy, tileSpacingX, tileSpacingY );
				shape3.graphics.drawRect(sx, sy, tileSpacingX, tileSpacingY );
			}
			shape.graphics.endFill();
			shape2.graphics.endFill();
			shape3.graphics.endFill();
			
			// The bmp that is used to highlight selected tiles.			
			selectionBmp = new BitmapData(tileWidth, tileHeight,true,0x00000000);
			selectionBmp.draw(shape);
			
			// The bmp used when wanted to only draw the tile that covers the base, and ignore the height
			noHeightBmp = new BitmapData(tileWidth, tileHeight,true,0x00000000);
			noHeightBmp.draw(shape2);
			
			tintBmp = new BitmapData(tileWidth, tileHeight, true, 0x00000000);
			tintBmp.draw(shape3);
		}
		
		override public function render():void
		{
			if (!_pixels)
			{
				return;
			}
			super.render();
		}
		
		override protected function renderTilemap():void
		{
			var doClip:Boolean = clipRender;
			clipRender = false;
			var layer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			var doCollideHighlight:Boolean = highlightCollidableTiles && layer && layer.map == this && layer.HasHits;
			var doAnim:Boolean = Global.PlayAnims && !DisablePlayAnims && tileAnims != null;
			
			getScreenXY(_point);
			
			// Quick exit if the tilemap is off screen.
			if ( (!repeatingX && (_point.x > FlxG.width || _point.x + width < 0)) || 
				(!repeatingY && (_point.y - ( stackHeight * highestStack ) > FlxG.height || _point.y + height < 0 )) )
			{
				return;
			}
			
			if ( !doAnim && selectedTiles == null && stickyTiles == null && highlightTileIndexForThisFrame == -1 && !doCollideHighlight && !doClip && !repeatingX && !repeatingY && stackedTiles == null && !Global.DrawTilesWithoutHeight)
			{
				if( drawTileAboveTileId == -1 || (!tileOffsetX && !tileOffsetY && !xStagger && tileSpacingY == tileHeight ) )
				{
					super.renderTilemap();
					return;
				}
			}
			
			// Combine what renderTilemap does with a highlight.
			
			//_buffer.fillRect(_flashRect,0);
			
			// Apply a highlight to all tiles of the specified index for this frame only.
			
			var ct:ColorTransform = new ColorTransform();
			ct.blueOffset = -80;	// This ensures the highlight is always shown, whatever the current background colour.
			ct.redOffset = 80;
			ct.greenOffset = 80;
			
			var rect:Rectangle = new Rectangle;
			
			rect.x = _point.x;
			rect.y = _point.y;
			rect.width = _tileWidth;
			rect.height = _tileHeight;
			getRenderStartValues(_point);
			
			var selectionRect:Rectangle = new Rectangle(0, 0, tileWidth, tileHeight);
			
			var tRect:Rectangle = new Rectangle(0,0,_tileWidth,_tileHeight);
			var spacingX:Number = tileSpacingX;
			var spacingY:Number = tileSpacingY;
			var offsetX:Number = tileOffsetX;
			var offsetY:Number = tileOffsetY;
			var staggerX:Number = xStagger;
			var startX:Number = tilesStartX;
			var startY:Number = tilesStartY;
			var stackY:Number = stackHeight;
			var tileBitShifter:int = FlxG.zoomBitShifter;
			if ( FlxG.extraZoom < 1 )
			{
				tRect.width = _tileWidth * FlxG.extraZoom;
				tRect.height = _tileHeight * FlxG.extraZoom;
				spacingX = spacingX * FlxG.extraZoom;
				spacingY = spacingY * FlxG.extraZoom;
				offsetX = offsetX * FlxG.extraZoom;
				offsetY = offsetY * FlxG.extraZoom;
				staggerX = staggerX * FlxG.extraZoom;
				startX = startX >> tileBitShifter;
				startY = startY >> tileBitShifter;
				stackY = stackY * FlxG.extraZoom;
				selectionRect.width = selectionRect.width * FlxG.extraZoom;
				selectionRect.height = selectionRect.height * FlxG.extraZoom;
			}
			
			var c:int;
			var cri:int;
			var tint:Boolean;
			
			// If background is light then make the tint dark.
			// Note this only looks at the background. Not on a per pixel basis.
			var tintColor:uint = FlxState.bgColor & 0xff;
			tintColor = ( tintColor > 0xaa ) ? 0x44000000 : 0x44ffffff;
			
			
			var alphaBmp:BitmapData = Global.DrawTilesWithoutHeight ? noHeightBmp : null;
			
			var highlightPass:int = 1;
			var numPasses:int = 1;
			if ( selectedTiles || stickyTiles || highlightTileIndexForThisFrame != -1 || doCollideHighlight )
			{
				if ( tileSpacingY < tileHeight )
					numPasses = 2;
				else
					highlightPass = 0;	// Can do this all in 1 pass if the tiles have no height.
			}
			
			var drawAboveRect:Rectangle = null;
			var drawAbovePoint:Point = null;
			
			var rx:int = renderX;
			var ry:int = renderY;
			
			if ( repeatingX )
			{
				// Find out the actual tile coords to start from.
				if ( rx < 0 )
				{
					rx = rx % widthInTiles;
					if ( rx < 0 )
					{
						rx += widthInTiles;
					}
				}
				else if ( rx >= widthInTiles )
				{
					rx = rx % widthInTiles;
				}
			}
			if ( repeatingY )
			{
				if ( ry < 0 )
				{
					ry = ry % heightInTiles;
					if ( ry < 0 )
					{
						ry += heightInTiles;
					}
				}
				else if ( ry >= heightInTiles )
				{
					ry = ry % heightInTiles;
				}
			}
			
			var hasstackedTiles:Boolean = Global.DrawTilesWithoutHeight ? false : stackedTiles != null;
			
			var currentPixels:BitmapData = _pixels;
			var selectionImage:BitmapData = selectionBmp;
			if ( FlxG.extraZoom == 0.25 )
			{
				currentPixels = quarterPixels;
				selectionImage = quarterSelectionBmp;
			}
			else if ( FlxG.extraZoom == 0.125 )
			{
				currentPixels = eighthPixels;
				selectionImage = eighthSelectionBmp;
			}
			
			for ( var pass:int = 0; pass < numPasses; pass++ )
			{
				var storedX:Number = startX + _point.x + renderX*spacingX + renderY*offsetX;
				var iy:int = ry;
				var ri:int = ry * widthInTiles + rx;
				rect.y = startY + _point.y + renderY*spacingY + renderX*offsetY;
				for ( var r:int = 0; r < _screenRows; r++ )
				{
					cri = ri;
					c = 0;
					var ix:int = rx;
					rect.x = storedX;
					if ( xStagger && iy%2==1)
					{
						rect.x += staggerX;
					}
					var storedY:Number = rect.y;
					while(c < _screenCols)
					{
						if ( !doClip || (ix >= clipLeft && ix < clipRight && iy >= clipTop && iy < clipBottom) )
						{
							if ( cri >= 0 && cri < totalTiles )
							{
								var id:int = _data[cri];
								tint = ( id == highlightTileIndexForThisFrame ) || (doCollideHighlight && id >= collideIndex);
								_flashPoint.x = rect.x;
								_flashPoint.y = rect.y;
								if ( pass == 0 )
								{
									_flashRect = _rects[cri] as Rectangle;
									
									if ( doAnim )
									{
										var animId:uint = tileAnims.length;
										while (animId--)
										{
											if ( tileAnims[animId].tiles[0] == id )
											{
												var frameId:int = tileAnims[animId].currentFrame;
												_flashRect = tileIdRects[frameId];
												break;
											}
										}
									}
									
									if (_flashRect != null)
									{
										if ( tileBitShifter )
										{
											tRect.x = _flashRect.x >> tileBitShifter;
											tRect.y = _flashRect.y >> tileBitShifter;
											FlxG.buffer.copyPixels(currentPixels, tRect, _flashPoint, alphaBmp, null, true);
										}
										else
										{
											FlxG.buffer.copyPixels(_pixels, _flashRect, _flashPoint, alphaBmp, null, true);
										}
										if ( drawTileAboveTileId == cri )
										{
											drawAboveRect = _flashRect;
											drawAbovePoint = _flashPoint.clone();
										}
									}
									
									if ( hasstackedTiles )
									{
										var tileInfo:StackTileInfo = stackedTiles[cri];
										if ( tileInfo )
										{
											var fpy:int = _flashPoint.y;
											for( var tileKey:Object in tileInfo.tiles )
											{
												var tileIdx:int = int(tileKey);
												_flashPoint.y = fpy - ( tileIdx * stackY );
												id = tileInfo.tiles[tileIdx];
												if ( id >= drawIndex )
												{
													_flashRect = tileIdRects[id];
													if ( doAnim )
													{
														animId = tileAnims.length;
														while (animId--)
														{
															if ( tileAnims[animId].tiles[0] == id )
															{
																frameId = tileAnims[animId].currentFrame;
																_flashRect = tileIdRects[frameId];
																break;
															}
														}
													}
													if ( _flashRect )
													{
														if ( tileBitShifter )
														{
															tRect.x = _flashRect.x >> tileBitShifter;
															tRect.y = _flashRect.y >> tileBitShifter;
															FlxG.buffer.copyPixels(currentPixels, tRect, _flashPoint, alphaBmp, null, true);
														}
														else
														{
															FlxG.buffer.copyPixels(_pixels, _flashRect, _flashPoint, alphaBmp, null, true);
														}
													}
												}
											}
										}
									}
								}
								if ( pass == highlightPass )
								{
									// When resizing maps don't highlight selections as they're index based and we're changing the index.
									if ( stickyTiles && stickyTiles[cri] == true )
									{
										// Slightly more expensive to draw but not used frequently and saves creating yet more bitmaps.
										// Just draw the selectionBmp but in Red!
										var stickyMat:Matrix = new Matrix(FlxG.extraZoom, 0, 0, FlxG.extraZoom, _flashPoint.x, _flashPoint.y);
										FlxG.buffer.draw(selectionBmp, stickyMat, new ColorTransform(1, 0, 0, 1, 0, 100, 100, 0) );
									}
									else
									{
										if ( !doClip && selectedTiles && cri < selectedTiles.length && selectedTiles[cri] == true )
											FlxG.buffer.copyPixels(selectionImage, selectionRect, _flashPoint, null, null, true);
										if ( tint)
											FlxG.buffer.copyPixels(tintBmp, selectionRect, _flashPoint, null, null, true);
									}
								}
							}
						}
						ix++;
						cri++;
						if ( ix >= widthInTiles )
						{
							ix -= widthInTiles;
							cri -= widthInTiles;
						}
						rect.x += spacingX;
						rect.y += offsetY;
						c++;
						
					}
					iy++;
					if ( iy >= heightInTiles )
					{
						iy -= heightInTiles;
						ri = iy * widthInTiles + rx;
					}
					else
					{
						ri += widthInTiles;
					}
					rect.y = storedY + spacingY;
					storedX += offsetX;
					
				}
			}
			
			if ( drawTileAboveTileId != -1 && drawAboveRect != null )
			{
				if ( tileBitShifter )
				{
					tRect.x = drawAboveRect.x >> tileBitShifter;
					tRect.y = drawAboveRect.y >> tileBitShifter;
					FlxG.buffer.copyPixels(currentPixels, tRect, drawAbovePoint, null, null, true);
				}
				else
				{
					FlxG.buffer.copyPixels(_pixels, drawAboveRect, drawAbovePoint, null, null, true);
				}
				
				if ( hasstackedTiles )
				{
					tileInfo = stackedTiles[drawTileAboveTileId];
					if ( tileInfo )
					{
						fpy = drawAbovePoint.y;
						for( tileKey in tileInfo.tiles )
						{
							tileIdx = int(tileKey);
							drawAbovePoint.y = fpy - ( tileIdx * stackHeight );
							id = tileInfo.tiles[tileIdx];
							if ( id >= drawIndex )
							{
								_flashRect = tileIdRects[id];
								if ( tileBitShifter )
								{
									tRect.x = _flashRect.x >> tileBitShifter;
									tRect.y = _flashRect.y >> tileBitShifter;
									FlxG.buffer.copyPixels(currentPixels, tRect, drawAbovePoint, alphaBmp, null, true);
								}
								else
								{
									FlxG.buffer.copyPixels(_pixels, _flashRect, drawAbovePoint, alphaBmp, null, true);
								}
							}
						}
					}
				}
			}
			_flashRect = _flashRect2;
			
			highlightTileIndexForThisFrame = -1;
			drawTileAboveTileId = -1;
		}
		
		// loads a source map into the current map. The source map can be offset within the new map.
		public function replaceMapSection( sourceMap:FlxTilemapExt, xOffset:uint, yOffset:uint ):void
		{
			if ( xOffset + sourceMap.widthInTiles > widthInTiles)
			{
				throw new Error("Unable to replace map section as " + xOffset + " + " +  sourceMap.widthInTiles + " > " + widthInTiles );
				return;
			}
			if ( yOffset + sourceMap.heightInTiles > heightInTiles)
			{
				throw new Error("Unable to replace map section as " + yOffset + " + " +  sourceMap.heightInTiles + " > " + heightInTiles );
				return;
			}
			
			var col:uint;
			var tileId:uint;
			var i:uint = 0;
			var index:uint;
			

			// Scan each tile to see if either the left or right side is free of transitions.
			for(var row:uint = 0; row < sourceMap.heightInTiles; row++)
			{
				index = (yOffset + row) * widthInTiles + xOffset;
				for (col = 0; col < sourceMap.widthInTiles; col++)
				{
					tileId = sourceMap._data[i] as uint;
					if ( tileId )
					{
						setTileByIndex(index, tileId, true);
					}
					i++;
					index++;
				}
			}
			
			refreshHulls();
			initBaseGraphics();
		}
		
		// hAlign and vAlign are values 0 to 1 that specify where the old map should be within the new map.
		public function resizeMap( newWidth:uint, newHeight:uint, newTileWidth:uint, newTileHeight:uint, hAlign:Number, vAlign:Number, preserveTilePositions:Boolean = false ):void
		{
			var col:uint;
			var tileId:uint;
			var i:uint = 0;
			var index:uint;
			
			/*if ( newWidth == widthInTiles && newHeight == heightInTiles && newTileWidth == _tileWidth && newTileHeight == _tileHeight )
			{
				return;
			}*/
			
			var newData:Array = new Array();
			
			var wDiff:int = newWidth - widthInTiles;
			var hDiff:int = newHeight - heightInTiles;
			var startX:int = hAlign * wDiff;
			var endX:int = startX + widthInTiles;
			var startY:int = vAlign * hDiff;
			var endY:int = startY + heightInTiles;
			
			var newSelection:Vector.<Boolean> = selectedTiles != null ? new Vector.<Boolean>(newWidth * newHeight) : null;
			
			var newStack:Dictionary = stackedTiles ? new Dictionary : null;
			
			// Generate the new data array.
			for ( var row:uint = 0; row < newHeight; row++ )
			{
				var rowIndex:uint = (( -startY + row) * widthInTiles);
				for (col = 0; col < newWidth; col++)
				{
					if ( row >= startY && row < endY && col >= startX && col < endX )
					{
						i = rowIndex - startX + col;
						newData.push( _data[i] );
						if ( newSelection && i < selectedTiles.length )
							newSelection[newData.length - 1] = selectedTiles[i];
						if ( newStack && i < stackedTiles.length && stackedTiles[i] )
						{
							newStack[ newData.length - 1 ] = stackedTiles[i];
						}
					}
					else
					{
						newData.push( 0 );
					}
				}
			}
			
			stackedTiles = newStack;
			
			_data = newData;
			selectedTiles = newSelection
			
			if ( preserveTilePositions )
			{
				if ( tileOffsetX || tileOffsetY )
				{
					x -= startX * tileSpacingX;
					
					if( tileOffsetY > 0 )
						y -= startX * tileOffsetY;
					else if ( tileOffsetY < 0 && startX == 0 )
						y += wDiff * tileOffsetY;
						
					if( tileOffsetX > 0 )
						x -= startY * tileOffsetX;
					else if ( tileOffsetX < 0 && startY == 0 )
						x += hDiff * tileOffsetX;
					
					y -= startY * tileSpacingY;
				}
				else
				{
					x -= startX * tileSpacingX;
					y -= startY * tileSpacingY;
				}
			}
			
			var tileSizeChanged:Boolean = _tileWidth != newTileWidth || _tileHeight != newTileHeight;
			_tileWidth = newTileWidth;
			_tileHeight = newTileHeight;
			
			widthInTiles = newWidth;
			heightInTiles = newHeight;
			totalTiles = widthInTiles * heightInTiles;
			
			if( tileSizeChanged )
				tileCount = ( _pixels.width / tileWidth ) * (_pixels.height / tileHeight );
			
			// A lot of this is taken from FlxTilemap.loadMap
			
			//Then go through and create the actual map
			CalculationDimensions();
			_rects = new Array(totalTiles);
			for(i = 0; i < totalTiles; i++)
				updateTile(i);

			UpdateScreenSize();
			
			refreshHulls();
			
			initBaseGraphics();
		}
		
		public function UpdateDrawIndex( newIndex:uint):void
		{
			if ( newIndex != drawIndex )
			{
				drawIndex = newIndex;
				for ( var i:uint = 0; i < totalTiles; i++)
				{
					updateTile(i);
				}
			}
		}
		
		public function getAlpha():Number
		{
			return alpha;
		}
		
		public function setAlpha( newAlpha:Number, force:Boolean = false ) : void
		{
			desiredAlpha = newAlpha;
			if ( _pixels == null || (alpha == newAlpha && !force) )
			{
				return;
			}
			alpha = newAlpha;
			var rec:Rectangle = new Rectangle(0, 0, _pixels.width, _pixels.height);
			var ct:ColorTransform = new ColorTransform();
			ct.alphaMultiplier = alpha; 
			_flashPoint.x = _flashPoint.y = 0;

			_pixels = _storedPixels.clone();
			_pixels.colorTransform( rec, ct);
			
			drawSmallerTilePixels();
			
			quarterPixels.fillRect(quarterPixels.rect, 0x00000000);
			/*var mat:Matrix = new Matrix;
			mat.scale(0.25, 0.25);
			quarterPixels.draw(_pixels, mat,null,null,null,true);*/
			
			eighthPixels.fillRect(eighthPixels.rect, 0x00000000);
			/*mat.identity();
			mat.scale(0.125, 0.125);
			eighthPixels.draw(_pixels, mat,null,null,null,true);*/
			
			drawSmallerTilePixels();
		}
		
		public function tileIsValid( x:int, y:int ):Boolean
		{
			return x >= 0 && y >= 0 && x < widthInTiles && y < heightInTiles;
		}
		
		public function setHighTile(X:uint,Y:uint,tileHeight:uint, drawTopMost:Boolean, noStackLimits:Boolean, Tile:uint,UpdateGraphics:Boolean=true):Boolean
		{
			if((X >= widthInTiles) || (Y >= heightInTiles))
				return false;
			var index:int = Y * widthInTiles + X;
			if( index >= _data.length )
				return false;
			if ( !stackedTiles )
			{
				stackedTiles = new Dictionary;
			}
			var tileInfo:StackTileInfo = stackedTiles[index];
			// First do the tile removals.
			if ( Tile < drawIndex )
			{
				if ( !tileInfo )
				{
					if ( noStackLimits )
						return false;
					return setTile( X, Y, Tile);
				}
				// Always remove from the top tile.
				if( !noStackLimits && (drawTopMost || tileHeight > tileInfo.GetHeight()) )
					tileHeight = tileInfo.GetHeight();
				tileInfo.ClearTile(tileHeight);
				if ( tileInfo.GetHeight() == 0)
				{
					delete stackedTiles[index];
					numStackedTiles--;
					if ( numStackedTiles == 0 )
					{
						stackedTiles = null;
					}
				}
				return true;
			}
			if ( (!tileInfo && (!noStackLimits && (!drawTopMost || _data[index] < drawIndex ) ) ) || (!drawTopMost && !tileHeight) )
			{
				return setTile( X, Y, Tile);
			}
			if ( !tileInfo )
			{
				tileInfo = new StackTileInfo;
				numStackedTiles++;
			}
			
			// Only allow adding tiles 1 above the current tile height
			if ( !noStackLimits )
			{
				if ( drawTopMost )
				{
					tileHeight = Math.min( tileInfo.GetHeight() + 1, MAX_STACKED_TILES );
				}
				else if ( tileHeight > tileInfo.GetHeight())
				{
					tileHeight = tileInfo.GetHeight();
				}
			}
			tileInfo.SetTile(tileHeight, Tile);
			// Only increase the stack. Too much calculation involved to decrease the stack.
			highestStack = Math.max( highestStack, tileInfo.GetHeight() );
			stackedTiles[ index ] = tileInfo;
			refresh = UpdateGraphics;
			return true;
		}
		
		public function GetTileBitmap( tileIndex:uint ):BitmapData
		{
			return Misc.GetTileBitmap( _storedPixels, tileIndex, _tileWidth, _tileHeight );
		}
		
		public function SetTileBitmap( tileIndex:uint, newTile:BitmapData ):void
		{
			Misc.SetTileBitmap( _storedPixels, tileIndex, _tileWidth, _tileHeight, newTile, _pixels ); 
			
			if ( alpha < 1 )
			{
				setAlpha(alpha, true);
			}
		}
		
		public function removeTileAndShuntDown( tileId:uint, changeGraphic:Boolean, graphicFile:Bitmap ):void
		{
			var i:uint;
			
			if ( tileCount == 0 )
			{
				return;
			}
			
			if ( tileAnims != null )
			{
				for each( var anim:TileAnim in tileAnims )
				{
					i = anim.tiles.length;
					while ( i-- )
					{
						if ( anim.tiles[i] > tileId )
						{
							anim.tiles[i]--;
						}
						else if ( anim.tiles[i] == tileId )
						{
							anim.tiles.splice(i, 1);
						}
					}
				}
			}
			
			if ( propertyList.length >= tileId )
			{
				propertyList.splice(tileId, 1);
			}
			
			if ( stackedTiles )
			{
				for (var key:Object in stackedTiles)
				{
					var tileInfo:StackTileInfo = stackedTiles[key];
					for ( var key2:Object in tileInfo.tiles )
					{
						if ( tileInfo.tiles[key2] > tileId )
						{
							tileInfo.tiles[key2]--;
						}
						else if ( tileInfo.tiles[key2] == tileId )
						{
							tileInfo.ClearTile(uint(key2));
							if ( tileInfo.GetHeight() == 0 )
							{
								delete stackedTiles[key];
								numStackedTiles = 0;
							}
						}
					}
				}
			}

			if ( changeGraphic )
			{
				_storedPixels = Misc.removeTileAndShuntDown( _storedPixels, tileId, _tileWidth, _tileHeight, tileCount );
				graphicFile.bitmapData = _storedPixels;
			}
			else if ( graphicFile )
			{
				_storedPixels = graphicFile.bitmapData;
			}
			tileCount--;
			
			for ( i = 0; i < _data.length; i++ )
			{
				if ( _data[i] == tileId )
				{
					setTileByIndex( i, 0, true);
				}
				else if ( _data[i] > tileId )
				{
					setTileByIndex( i, _data[i]-1, true);
				}
			}
			
			refreshHulls();
			initBaseGraphics();
		}
		
		public function insertNewTile( sourceTileId:int, insertAfterTileId:int, changeGraphic:Boolean, graphicFile:Bitmap ):void
		{
			var i:int;
			
			if ( tileAnims != null )
			{
				for each( var anim:TileAnim in tileAnims )
				{
					i = anim.tiles.length;
					while ( i-- )
					{
						if ( anim.tiles[i] > insertAfterTileId )
						{
							anim.tiles[i]++;
						}
					}
				}
			}
			
			if ( propertyList.length >= insertAfterTileId + 2 )
			{
				propertyList.splice(insertAfterTileId + 1, 0, new ArrayCollection() );
			}
			
			if ( stackedTiles )
			{
				for (var key:Object in stackedTiles)
				{
					var tileInfo:StackTileInfo = stackedTiles[key];
					for ( var key2:Object in tileInfo.tiles )
					{
						if ( tileInfo.tiles[key2] > insertAfterTileId )
						{
							tileInfo.tiles[key2]++;
						}
					}
				}
			}

			if ( changeGraphic )
			{
				_storedPixels = Misc.insertNewTile( _storedPixels, sourceTileId, insertAfterTileId, _tileWidth, _tileHeight, tileCount );
				graphicFile.bitmapData = _storedPixels;
			}
			else if( graphicFile )
			{
				_storedPixels = graphicFile.bitmapData;
			}
			tileCount++;
			
			for ( i = 0; i < _data.length; i++ )
			{
				if ( _data[i] > insertAfterTileId )
				{
					setTileByIndex( i, _data[i]+1, true);
				}
			}
			
			refreshHulls();
			initBaseGraphics();
		}
		
		public function GetPixelData():BitmapData
		{
			return _storedPixels;
		}
		
		public function RefreshPixelData():void
		{
			InitPixels();
			initBaseGraphics();
			if ( alpha < 1 )
			{
				setAlpha(alpha, true);
			}
		}
		
		public function ClearMap():void
		{
			for ( var i:uint = 0; i < _data.length; i++ )
			{
				setTileByIndex(i, 0, true);
			}
		}
		
		public function getTileBitmapCoords(tileIndex:uint, ptOUT:FlxPoint):void
		{
			var rx:uint = (tileIndex-startingIndex)*_tileWidth;
			var ry:uint = 0;
			if(rx >= _pixels.width)
			{
				ry = uint(rx/_pixels.width)*_tileHeight;
				rx %= _pixels.width;
			}
			ptOUT.create_from_points(rx, ry);
		}
		
		protected function updateTileForId(tileId:uint):void
		{
			var rx:uint = (tileId-startingIndex)*_tileWidth;
			var ry:uint = 0;
			if(rx >= _pixels.width)
			{
				ry = uint(rx/_pixels.width)*_tileHeight;
				rx %= _pixels.width;
			}
			tileIdRects[tileId] = (new Rectangle(rx,ry,_tileWidth,_tileHeight)); 
		}
		
		static public function ResetSharedData():void
		{
			sharedProperties = new Dictionary;
			sharedTileAnims = new Dictionary;
		}
	}

}
