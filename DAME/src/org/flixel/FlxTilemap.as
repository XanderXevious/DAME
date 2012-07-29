package org.flixel
{
	import com.Tiles.IsoHelper;
	import com.Utils.Hits;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	public class FlxTilemap extends FlxObject
	{
		
		/**
		 * No auto-tiling.
		 */
		static public const OFF:uint = 0;
		/**
		 * Platformer-friendly auto-tiling.
		 */
		static public const AUTO:uint = 1;
		/**
		 * Top-down auto-tiling.
		 */
		static public const ALT:uint = 2;
		
		/**
		 * What tile index will you start colliding with (default: 1).
		 */
		public var collideIndex:uint;
		/**
		 * The first index of your tile sheet (default: 0) If you want to change it, do so before calling loadMap().
		 */
		public var startingIndex:uint;
		/**
		 * What tile index will you start drawing with (default: 1)  NOTE: should always be >= startingIndex.
		 * If you want to change it, do so before calling loadMap().
		 */
		public var drawIndex:uint;
		/**
		 * Set this flag to use one of the 16-tile binary auto-tile algorithms (OFF, AUTO, or ALT).
		 */
		public var auto:uint;
		/**
		 * Set this flag to true to force the tilemap buffer to refresh on the next render frame.
		 */
		public var refresh:Boolean;
		
		/**
		 * Read-only variable, do NOT recommend changing after the map is loaded!
		 */
		public var widthInTiles:uint;
		/**
		 * Read-only variable, do NOT recommend changing after the map is loaded!
		 */
		public var heightInTiles:uint;
		/**
		 * Read-only variable, do NOT recommend changing after the map is loaded!
		 */
		public var totalTiles:uint;
		/**
		 * Rendering helper.
		 */
		protected var _flashRect:Rectangle;
		protected var _flashRect2:Rectangle;
		
		protected var _pixels:BitmapData;
		protected var quarterPixels:BitmapData;
		protected var eighthPixels:BitmapData;
		//protected var _buffer:BitmapData;
		//protected var _bufferLoc:FlxPoint;
		protected var _bbKey:String;
		protected var _data:Array;
		protected var _rects:Array;
		
		protected var _tileWidth:uint;
		protected var _tileHeight:uint;
		protected var _block:FlxObject;
		protected var _callbacks:Array;
		protected var _screenRows:uint;
		protected var _screenCols:uint;
		public static var disableWhenInactive:Boolean = true;
		
		// The base size of each tile for the collisions. Ie a 2.5d block may be drawn larger than the base tile spacing size.
		public var tileSpacingX:uint = 0;
		public var tileSpacingY:uint = 0;
		
		// Every other row will be offset by this many pixels.
		public var xStagger:int = 0;
		// Each row will be offset by this many additional pixels.
		public var tileOffsetX:int = 0;
		// Each column will be offset by this many additional pixels.
		public var tileOffsetY:int = 0;
		
		// Where the rendering of the tiles actually starts from the topleft of the bmp.
		public var tilesStartX:int = 0;
		public var tilesStartY:int = 0;
		
		// Helper values to make it easy to project from screen to world space for iso maps.
		// They equate to if I move x in Screen space how much have I moved in world space and vice-versa.
		// From that we can go from any screen position to a world position without having to do an expensive projection.
		// Note that for staggered maps they are treated as normal iso.
		protected var xScreenToWorld:FlxPoint = new FlxPoint(1, 0);
		protected var yScreenToWorld:FlxPoint = new FlxPoint(0, 1);
		
		// These are used during the render loop.
		protected var renderX:int;
		protected var renderY:int;
		
		/*
		 * Specifies if the graphics can be treated as unique even if shared by other maps.
		 */
		protected var isUnique:Boolean;
		
		public var repeatingX:Boolean = false;
		public var repeatingY:Boolean = false;
		
		protected var lastZoomRenderSize:int = 1;
		
		/**
		 * The tilemap constructor just initializes some basic variables.
		 */
		public function FlxTilemap()
		{
			super();
			auto = OFF;
			collideIndex = 1;
			startingIndex = 0;
			drawIndex = 1;
			widthInTiles = 0;
			heightInTiles = 0;
			totalTiles = 0;
			//_buffer = null;
			//_bufferLoc = new FlxPoint();
			_flashRect2 = new Rectangle();
			_flashRect = _flashRect2;
			_data = null;
			_tileWidth = 0;
			_tileHeight = 0;
			_rects = null;
			_pixels = null;
			_block = new FlxObject();
			_block.width = _block.height = 0;
			_block.fixed = true;
			_callbacks = new Array();
			fixed = true;
			isUnique = false;
		}
		
		/**
		 * Load the tilemap with string data and a tile graphic.
		 * 
		 * @param	MapData			A string of comma and line-return delineated indices indicating what order the tiles should go in.
		 * @param	TileGraphic		All the tiles you want to use, arranged in a strip corresponding to the numbers in MapData.
		 * @param	TileWidth		The width of your tiles (e.g. 8) - defaults to height of the tile graphic if unspecified.
		 * @param	TileHeight		The height of your tiles (e.g. 8) - defaults to width if unspecified.
		 * 
		 * @return	A pointer this instance of FlxTilemap, for chaining as usual :)
		 */
		public function loadMap(MapData:String, TileGraphic:Class, TileWidth:uint=0, TileHeight:uint=0):FlxTilemap
		{
			refresh = true;
			
			//Figure out the map dimensions based on the data string
			var cols:Array;
			var rows:Array = MapData.split("\n");
			heightInTiles = rows.length;
			_data = new Array();
			var r:uint = 0;
			var c:uint;
			while(r < heightInTiles)
			{
				cols = rows[r++].split(",");
				if(cols.length == 0 || (cols.length == 1 && cols[0]=="") )
				{
					heightInTiles--;
					continue;
				}
				if(widthInTiles == 0)
					widthInTiles = cols.length;
				c = 0;
				while(c < widthInTiles)
					_data.push(uint(cols[c++]));
			}
			
			//Pre-process the map data if it's auto-tiled
			var i:uint;
			totalTiles = widthInTiles*heightInTiles;

			//Figure out the size of the tiles
			if( TileGraphic != null )
				_pixels = FlxG.addBitmap(TileGraphic,false,isUnique);
			_tileWidth = TileWidth;
			if(_tileWidth == 0)
				_tileWidth = _pixels.height;
			_tileHeight = TileHeight;
			if(_tileHeight == 0)
				_tileHeight = _tileWidth;
			_block.width = _tileWidth;
			_block.height = _tileHeight;
			
			//Then go through and create the actual map
			CalculationDimensions();
			_rects = new Array(totalTiles);
			i = 0;
			while(i < totalTiles)
				updateTile(i++);
			
			//Also need to allocate a buffer to hold the rendered tiles
			var bw:uint = (FlxU.ceil(FlxG.width / _tileWidth) + 1)*_tileWidth;
			var bh:uint = (FlxU.ceil(FlxG.height / _tileHeight) + 1)*_tileHeight;
			//_buffer = new BitmapData(bw,bh,true,0);

			//Pre-set some helper variables for later
			UpdateScreenSize();
			
			_bbKey = String(TileGraphic);
			refreshHulls();
			
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = bw;// _buffer.width;
			_flashRect.height = bh;// _buffer.height;
			
			return this;
		}
		
		public function IsIso():Boolean
		{
			return tileOffsetX != 0 || tileOffsetY != 0 || tileSpacingY < _tileHeight;
		}
		
		protected function CalculationDimensions():void
		{
			// Calculate the start point of the top left tile, so we know where the render will begin.
			tilesStartY = (widthInTiles - 1) * -tileOffsetY;
			tilesStartX = (heightInTiles - 1) * -tileOffsetX;
			
			width = ((widthInTiles-1)*tileSpacingX) + _tileWidth;
			height = ((heightInTiles - 1) * tileSpacingY) + _tileHeight;
			
			height += Math.abs(tilesStartY);
			tilesStartY = Math.max(0, tilesStartY );

			width += Math.abs(tilesStartX);
			tilesStartX = Math.max(0, tilesStartX );
			
			if ( xStagger )
			{
				width += Math.abs(xStagger);
				tilesStartX += Math.max(0, -xStagger );
			}
			
			// Calculate the screen to world space helpers.
			if ( tileOffsetX || tileOffsetY )
			{
				IsoHelper.helper.ResetValues( tileSpacingX, tileSpacingY, tileOffsetX, tileOffsetY, x, y, tilesStartX, tilesStartY, xStagger, _tileHeight, widthInTiles, heightInTiles );
				var origin:FlxPoint = new FlxPoint;
				IsoHelper.helper.GetTileInfo( 0, 0, origin, null, true );
				IsoHelper.helper.GetTileInfo( 1, 0, xScreenToWorld, null, true );
				IsoHelper.helper.GetTileInfo( 0, 1, yScreenToWorld, null, true );
				xScreenToWorld.subFrom(origin);
				yScreenToWorld.subFrom(origin);
			}
			else
			{
				xScreenToWorld.create_from_points(1, 0);
				yScreenToWorld.create_from_points(0, 1);
			}
			
		}
		
		public function UpdateScreenSize( fillToEnd:Boolean = false ):void
		{
			lastZoomRenderSize = FlxG.extraZoom;
			_screenRows = Math.ceil(FlxG.height / (tileSpacingY>>FlxG.zoomBitShifter)) + 1;
			_screenCols = Math.ceil(FlxG.width / (tileSpacingX>>FlxG.zoomBitShifter)) + 1;
			
			if ( fillToEnd )
			{
				return;
			}
			
			if ( tileOffsetY || tileOffsetX )
			{
				// Isometric tiles need some extra calculations.
				var sample:FlxPoint = new FlxPoint;
				var minx:int = 0;
				var miny:int = 0;
				var maxx:int = 0;
				var maxy:int = 0;
				
				// Sample top right of screen
				GetTileInfo( FlxG.width + tilesStartX, 0 + tilesStartY, sample, null);
				maxx = Math.max(sample.x, maxx);
				maxy = Math.max(sample.y, maxy);
				minx = Math.min(sample.x, minx);
				miny = Math.min(sample.y, miny);
				
				// Sample bottom right of screen
				GetTileInfo( FlxG.width + tilesStartX, FlxG.height + tilesStartY, sample, null);
				maxx = Math.max(sample.x, maxx);
				maxy = Math.max(sample.y, maxy);
				minx = Math.min(sample.x, minx);
				miny = Math.min(sample.y, miny);
				
				// Sample bottom left of screen
				GetTileInfo( 0 + tilesStartX, FlxG.height + tilesStartY, sample, null);
				maxx = Math.max(sample.x, maxx);
				maxy = Math.max(sample.y, maxy);
				minx = Math.min(sample.x, minx);
				miny = Math.min(sample.y, miny);
				
				// Add magic number to account for impression. No idea why this works :s
				_screenCols = (maxx - minx) + 5;
				_screenRows = (maxy - miny) + 5;
			}
			else if ( xStagger )
			{
				_screenCols++;
				_screenRows++;
			}
			
			// When zoomed out the bottom may need to render a bit more so that the top of high tiles are drawn
			// at the edge where the quadrants meet.
			if ( _tileHeight > tileSpacingY )
			{
				var space:Number = _tileHeight - tileSpacingY;
				_screenRows += Math.ceil( space / tileSpacingY);
			}
			
			// Limit the screen size only when not repeating as we don't want to restrict the amount drawn in those cases.
			if( !repeatingY && _screenRows > heightInTiles)
				_screenRows = heightInTiles;
			if( !repeatingX && _screenCols > widthInTiles)
				_screenCols = widthInTiles;
		}
		
		protected function getRenderStartValues(screenPos:FlxPoint):void
		{			
			// Calculate the points we must sample to find the starting tile to draw for iso tiles
			if ( tileOffsetY || tileOffsetY )
			{
				var sample:FlxPoint = new FlxPoint;
			
				// Sample top left of screen
				GetTileInfo( -screenPos.x, -screenPos.y, sample, null);
				renderX = sample.x;
				renderY = sample.y;
				
				if ( tileOffsetY > 0 )
				{
					// Sample top right of screen.
					GetTileInfo( -screenPos.x + FlxG.width, -screenPos.y, sample, null );
					renderX = Math.min(sample.x, renderX);
					renderY= Math.min(sample.y, renderY);
				}
				else if ( tileOffsetX > 0 )
				{
					// Sample bottom left of screen.
					GetTileInfo( -screenPos.x, -screenPos.y + FlxG.height, sample, null );
					renderX = Math.min(sample.x, renderX);
					renderY = Math.min(sample.y, renderY);
				}
			}
			else
			{
				renderX = Math.floor( -screenPos.x / (tileSpacingX>>FlxG.zoomBitShifter));
				renderY = Math.floor( ( -screenPos.y - ((_tileHeight - tileSpacingY)>>FlxG.zoomBitShifter)) ) / (tileSpacingY>>FlxG.zoomBitShifter);
				if ( xStagger )
				{
					renderX--;
					renderY--;
				}
			}
			
			if ( !repeatingX )
			{
				if (renderX < 0)
					renderX = 0;
				if (renderX > widthInTiles - _screenCols)
					renderX = widthInTiles - _screenCols;
			}
			if ( !repeatingY )
			{
				if (renderY < 0)
					renderY = 0;
				if (renderY > heightInTiles - _screenRows)
					renderY = heightInTiles - _screenRows;
			}
		}
		
		/**
		 * Internal function that actually renders the tilemap to the tilemap buffer.  Called by render().
		 */
		protected function renderTilemap():void
		{
			//Copy tile images into the tile buffer
			getScreenXY(_point);
			_flashPoint.x = _point.x;
			_flashPoint.y = _point.y;
			getRenderStartValues(_point);

			var ri:int = renderY*widthInTiles+renderX;
			
			var row:uint = 0;
			var col:uint;
			var cri:int;
			var iy:uint = renderY;
			
			
			var tRect:Rectangle = new Rectangle(0,0,_tileWidth,_tileHeight);
			var spacingX:Number = tileSpacingX;
			var spacingY:Number = tileSpacingY;
			var offsetX:Number = tileOffsetX;
			var offsetY:Number = tileOffsetY;
			var staggerX:Number = xStagger;
			var startX:Number = tilesStartX;
			var startY:Number = tilesStartY;
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
				startX = startX * FlxG.extraZoom;
				startY = startY * FlxG.extraZoom;
			}
			
			_flashPoint.y = startY + _point.y + renderY * spacingY + renderX * offsetY;
			
			var currentPixels:BitmapData = _pixels;
			if ( FlxG.extraZoom == 0.25 )
			{
				currentPixels = quarterPixels;
			}
			else if ( FlxG.extraZoom == 0.125 )
			{
				currentPixels = eighthPixels;
			}
			
			var storedX:Number = startX + _point.x +renderX*spacingX + renderY*offsetX;
			while(row < _screenRows)
			{
				cri = ri;
				col = 0;
				_flashPoint.x = storedX;
				if ( xStagger && iy%2==1)
				{
					_flashPoint.x += staggerX;
				}
				var storedY:Number = _flashPoint.y;
				while(col < _screenCols)
				{
					if ( cri >= 0 && cri < totalTiles )
					{
						_flashRect = _rects[cri] as Rectangle;
						
						if (_flashRect != null)
						{
							if ( tileBitShifter )
							{
								tRect.x = _flashRect.x >> tileBitShifter;
								tRect.y = _flashRect.y >> tileBitShifter;
								FlxG.buffer.copyPixels(currentPixels, tRect, _flashPoint, null, null, true);
							}
							else
							{
								FlxG.buffer.copyPixels(_pixels, _flashRect, _flashPoint, null, null, true);
							}
						}
					}
					_flashPoint.x += spacingX;
					_flashPoint.y += offsetY;
					col++;
					cri++;
				}
				ri += widthInTiles;
				_flashPoint.y = storedY + spacingY;
				storedX += offsetX;
				row++;
				iy++;
			}
			_flashRect = _flashRect2;
		}
		
		// This doesn't return the real world pos. It just returns a consistent value so that depth sorting can work correctly.
		public function GetPseudoWorldFromScreenPos( xpos:Number, ypos:Number, result:FlxPoint ):void
		{
			result.x = ( xpos * xScreenToWorld.x ) + ( ypos * yScreenToWorld.x );
			result.y = ( xpos * xScreenToWorld.y ) + ( ypos * yScreenToWorld.y );
		}
		
		public function GetTileWorldFromUnitPos( xpos:Number, ypos:Number, result:FlxPoint, fromOrigin:Boolean = false ):void
		{
			IsoHelper.helper.ResetValues( tileSpacingX, tileSpacingY, tileOffsetX, tileOffsetY, x, y, tilesStartX, tilesStartY, xStagger, _tileHeight, widthInTiles, heightInTiles );
			IsoHelper.helper.GetTileWorldFromUnitPos( xpos, ypos, result, fromOrigin );
		}
		
		// Returns true if the coordinates are over a tile.
		public function GetTileInfo( worldx:Number, worldy:Number, unitTilePos:FlxPoint, tilePos:FlxPoint, allowFloats:Boolean = false):Boolean
		{
			IsoHelper.helper.ResetValues( tileSpacingX, tileSpacingY, tileOffsetX, tileOffsetY, x, y, tilesStartX, tilesStartY, xStagger, _tileHeight, widthInTiles, heightInTiles );
			return IsoHelper.helper.GetTileInfo( worldx, worldy, unitTilePos, tilePos, allowFloats );
		}
		
		/**
		 * Checks to see if the tilemap needs to be refreshed or not.
		 */
		override public function update():void
		{
			super.update();
			getScreenXY(_point);
			//_point.x += _bufferLoc.x;
			//_point.y += _bufferLoc.y;

			refresh = true;
		}
		
		/**
		 * Draws the tilemap.
		 */
		override public function render():void
		{
			if( FlxG.forceRefresh)
				refresh = true;
			
			//Redraw the tilemap buffer if necessary
			if(refresh)
			{
				renderTilemap();
				refresh = false;
			}
			
			//Render the buffer no matter what
			getScreenXY(_point);
			//_flashPoint.x = _point.x + _bufferLoc.x;
			//_flashPoint.y = _point.y + _bufferLoc.y;
			//FlxG.buffer.copyPixels(_buffer,_flashRect,_flashPoint,null,null,true);
		}
		
		/**
		 * @private
		 */
		override public function set solid(Solid:Boolean):void
		{
			var os:Boolean = _solid;
			_solid = Solid;
		}
		
		/**
		 * @private
		 */
		override public function set fixed(Fixed:Boolean):void
		{
			var of:Boolean = _fixed;
			_fixed = Fixed;
		}
		
		/**
		 * Called by <code>FlxObject.updateMotion()</code> and some constructors to
		 * rebuild the basic collision data for this object.
		 */
		override public function refreshHulls():void
		{
			colHullX.x = 0;
			colHullX.y = 0;
			colHullX.width = _tileWidth;
			colHullX.height = _tileHeight;
			colHullY.x = 0;
			colHullY.y = 0;
			colHullY.width = _tileWidth;
			colHullY.height = _tileHeight;
		}
		
		/**
		 * Check the value of a particular tile.
		 * 
		 * @param	X		The X coordinate of the tile (in tiles, not pixels).
		 * @param	Y		The Y coordinate of the tile (in tiles, not pixels).
		 * 
		 * @return	A uint containing the value of the tile at this spot in the array.
		 */
		public function getTile(X:uint,Y:uint):uint
		{
			return getTileByIndex(Y * widthInTiles + X);
		}
		
		/**
		 * Get the value of a tile in the tilemap by index.
		 * 
		 * @param	Index	The slot in the data array (Y * widthInTiles + X) where this tile is stored.
		 * 
		 * @return	A uint containing the value of the tile at this spot in the array.
		 */
		public function getTileByIndex(Index:uint):uint
		{
			return _data[Index] as uint;
		}
		
		/**
		 * Change the data and graphic of a tile in the tilemap.
		 * 
		 * @param	X				The X coordinate of the tile (in tiles, not pixels).
		 * @param	Y				The Y coordinate of the tile (in tiles, not pixels).
		 * @param	Tile			The new integer data you wish to inject.
		 * @param	UpdateGraphics	Whether the graphical representation of this tile should change.
		 * 
		 * @return	Whether or not the tile was actually changed.
		 */ 
		public function setTile(X:uint,Y:uint,Tile:uint,UpdateGraphics:Boolean=true):Boolean
		{
			if((X >= widthInTiles) || (Y >= heightInTiles))
				return false;
			return setTileByIndex(Y * widthInTiles + X,Tile,UpdateGraphics);
		}
		
		/**
		 * Change the data and graphic of a tile in the tilemap.
		 * 
		 * @param	Index			The slot in the data array (Y * widthInTiles + X) where this tile is stored.
		 * @param	Tile			The new integer data you wish to inject.
		 * @param	UpdateGraphics	Whether the graphical representation of this tile should change.
		 * 
		 * @return	Whether or not the tile was actually changed.
		 */
		public function setTileByIndex(Index:uint,Tile:uint,UpdateGraphics:Boolean=true):Boolean
		{
			if(Index >= _data.length)
				return false;
			
			var ok:Boolean = true;
			_data[Index] = Tile;
			
			if(!UpdateGraphics)
				return ok;
			
			refresh = true;
			
			if(auto == OFF)
			{
				updateTile(Index);
				return ok;
			}
			
			return ok;
		}
		
		/**
		 * Bind a function Callback(Core:FlxCore,X:uint,Y:uint,Tile:uint) to a range of tiles.
		 * 
		 * @param	Tile		The tile to trigger the callback.
		 * @param	Callback	The function to trigger.  Parameters should be <code>(Core:FlxCore,X:uint,Y:uint,Tile:uint)</code>.
		 * @param	Range		If you want this callback to work for a bunch of different tiles, input the range here.  Default value is 1.
		 */
		public function setCallback(Tile:uint,Callback:Function,Range:uint=1):void
		{
			FlxG.log("WARNING: FlxTilemap.setCallback()\nhas been temporarily deprecated.");
			//if(Range <= 0) return;
			//for(var i:uint = Tile; i < Tile+Range; i++)
			//	_callbacks[i] = Callback;
		}
		
		/**
		 * Call this function to lock the automatic camera to the map's edges.
		 * 
		 * @param	Border		Adjusts the camera follow boundary by whatever number of tiles you specify here.  Handy for blocking off deadends that are offscreen, etc.  Use a negative number to add padding instead of hiding the edges.
		 */
		public function follow(Border:int=0):void
		{
			FlxG.followBounds(x+Border*tileSpacingX,y+Border*tileSpacingY,width-Border*tileSpacingX,height-Border*tileSpacingY);
		}
		
		/**
		 * Converts a one-dimensional array of tile data to a comma-separated string.
		 * 
		 * @param	Data		An array full of integer tile references.
		 * @param	Width		The number of tiles in each row.
		 * 
		 * @return	A comma-separated string containing the level data in a <code>FlxTilemap</code>-friendly format.
		 */
		static public function arrayToCSV(Data:Array,Width:int):String
		{
			var r:uint = 0;
			var c:uint;
			var csv:String;
			var Height:int = Data.length / Width;
			while(r < Height)
			{
				c = 0;
				while(c < Width)
				{
					if(c == 0)
					{
						if(r == 0)
							csv += Data[0];
						else
							csv += "\n"+Data[r*Width];
					}
					else
						csv += ", "+Data[r*Width+c];
					c++;
				}
				r++;
			}
			return csv;
		}
		
		/**
		 * Converts a <code>BitmapData</code> object to a comma-separated string.
		 * Black pixels are flagged as 'solid' by default,
		 * non-black pixels are set as non-colliding.
		 * Black pixels must be PURE BLACK.
		 * 
		 * @param	PNGFile		An embedded graphic, preferably black and white.
		 * @param	Invert		Load white pixels as solid instead.
		 * 
		 * @return	A comma-separated string containing the level data in a <code>FlxTilemap</code>-friendly format.
		 */
		static public function bitmapToCSV(bitmapData:BitmapData,Invert:Boolean=false,Scale:uint=1):String
		{
			//Import and scale image if necessary
			if(Scale > 1)
			{
				var bd:BitmapData = bitmapData;
				bitmapData = new BitmapData(bitmapData.width*Scale,bitmapData.height*Scale);
				var mtx:Matrix = new Matrix();
				mtx.scale(Scale,Scale);
				bitmapData.draw(bd,mtx);
			}
			
			//Walk image and export pixel values
			var r:uint = 0;
			var c:uint;
			var p:uint;
			var csv:String;
			var w:uint = bitmapData.width;
			var h:uint = bitmapData.height;
			while(r < h)
			{
				c = 0;
				while(c < w)
				{
					//Decide if this pixel/tile is solid (1) or not (0)
					p = bitmapData.getPixel(c,r);
					if((Invert && (p > 0)) || (!Invert && (p == 0)))
						p = 1;
					else
						p = 0;
					
					//Write the result to the string
					if(c == 0)
					{
						if(r == 0)
							csv += p;
						else
							csv += "\n"+p;
					}
					else
						csv += ", "+p;
					c++;
				}
				r++;
			}
			return csv;
		}
		
		/**
		 * Converts a resource image file to a comma-separated string.
		 * Black pixels are flagged as 'solid' by default,
		 * non-black pixels are set as non-colliding.
		 * Black pixels must be PURE BLACK.
		 * 
		 * @param	PNGFile		An embedded graphic, preferably black and white.
		 * @param	Invert		Load white pixels as solid instead.
		 * 
		 * @return	A comma-separated string containing the level data in a <code>FlxTilemap</code>-friendly format.
		 */
		static public function imageToCSV(ImageFile:Class,Invert:Boolean=false,Scale:uint=1):String
		{
			return bitmapToCSV((new ImageFile).bitmapData,Invert,Scale);
		}
		
		
		/**
		 * Internal function used in setTileByIndex() and the constructor to update the map.
		 * 
		 * @param	Index		The index of the tile you want to update.
		 */
		protected function updateTile(Index:uint):void
		{
			if(_data[Index] < drawIndex)
			{
				_rects[Index] = null;
				return;
			}
			var rx:uint = (_data[Index]-startingIndex)*_tileWidth;
			var ry:uint = 0;
			if(rx >= _pixels.width)
			{
				ry = uint(rx/_pixels.width)*_tileHeight;
				rx %= _pixels.width;
			}
			_rects[Index] = (new Rectangle(rx,ry,_tileWidth,_tileHeight));
		}
	}
}
