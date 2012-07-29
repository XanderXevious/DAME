package com.Tiles 
{
	import com.Utils.Hits;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class IsoHelper
	{
		private var tileSpacingX:uint = 1;
		private var tileSpacingY:uint = 1;
		private var tileOffsetX:int = 0;
		private var tileOffsetY:int = 0;
		private var x:int = 0;
		private var y:int = 0; 
		private var tilesStartX:int = 0;
		private var tilesStartY:int = 0;
		private var xStagger:int = 0;
		private var tileHeight:int = 1;
		//private var tileWidth:int = 1;
		private var widthInTiles:int = 1;
		private var heightInTiles:int = 1;
		
		public static var helper:IsoHelper = new IsoHelper;
		
		public function IsoHelper() 
		{
		}
		
		public function ResetValues(TileSpacingX:uint, TileSpacingY:uint, TileOffsetX:int, TileOffsetY:int, X:int, Y:int, TilesStartX:int, TilesStartY:int, XStagger:int, TileHeight:int, WidthInTiles:int, HeightInTiles:int):void
		{
			tileSpacingX = TileSpacingX;
			tileSpacingY = TileSpacingY;
			tileOffsetX = TileOffsetX;
			tileOffsetY = TileOffsetY;
			x = X;
			y = Y;
			tilesStartX = TilesStartX;
			tilesStartY = TilesStartY;
			xStagger = XStagger;
			tileHeight = TileHeight;
			widthInTiles = WidthInTiles;
			heightInTiles = HeightInTiles;
		}
		
		// Gets the actual screen relative world position from the map position.
		public function GetTileWorldFromUnitPos( xpos:Number, ypos:Number, result:FlxPoint, fromOrigin:Boolean = false ):void
		{
			if ( result == null )
			{
				return;
			}
			
			if ( tileOffsetX || tileOffsetY )
			{
				var newX:Number = (xpos * tileSpacingX) + (ypos * tileOffsetX);
				var newY:Number = (xpos * tileOffsetY) + (ypos * tileSpacingY);

				newX += x;
				newY += y;

				newX += tilesStartX;
				newY += tilesStartY;
				
				if ( fromOrigin )
				{
					newY += ( tileHeight - tileSpacingY );
					if ( tileOffsetX < 0 )
					{
						newX -= tileOffsetX;
					}
					if ( tileOffsetY > 0 )
					{
						newY -= tileOffsetY;
					}
				}
				
				result.create_from_points( newX, newY );
			}
			else if ( xStagger )
			{
				newX = xpos * tileSpacingX;
				newY = ypos * tileSpacingY;
				
				var tileStartY:int = tileHeight - tileSpacingY;
				newX += tilesStartX;
				newY += tileStartY;
				newY -= tileSpacingY;
				
				if( ypos%2!=0)
				{
					newX += xStagger;
				}
			
				newX += x;
				newY += y;
				
				if ( fromOrigin )
				{
					newX += ( tileSpacingX * 0.5 );
					newY += ( tileHeight - tileSpacingY );
				}
				
				result.create_from_points( newX, newY - ( tileHeight - ( tileSpacingY * 2 ) ) );
			}
			else
			{
				tileStartY = tileHeight - tileSpacingY;
				// Scale up back into world pos.
				newX = xpos * tileSpacingX;
				newY = ypos * tileSpacingY;
				
				newY += tileStartY;
			
				newX += x;
				newY += y;
				
				if ( fromOrigin )
				{
					newY += ( tileHeight - tileSpacingY );
				}
				
				result.create_from_points( newX, newY - ( tileHeight - tileSpacingY ) );
			}
		}
		
		// Returns true if the coordinates are over a tile.
		// worldx and worldy = screen position relative to top-left of map.
		// unitTilePos(OUT) = pos on the map, rounded if allowFloats is false
		// tilePos(OUT) = actual screen position of tile, not relative to map.
		public function GetTileInfo( worldx:Number, worldy:Number, unitTilePos:FlxPoint, tilePos:FlxPoint, allowFloats:Boolean = false):Boolean
		{
			worldx = worldx << FlxG.zoomBitShifter;
			worldy = worldy << FlxG.zoomBitShifter;
			unitTilePos.create_from_points( -1, -1);
			
			worldx -= tilesStartX;
			
			// Check standard or skewed isometric tilemaps.
			if ( tileOffsetX || tileOffsetY )
			{
				// Get position relative to the start of the tile that equates to x = 0, y = 0
				// Imagine rotating the tilemap so it is normal 2d, and worldx|y should match the top left of the tilemap.
				
				worldy -= ( tilesStartY + (tileHeight - tileSpacingY) );
				worldx += tileOffsetX;
				if ( tileOffsetY > 0 )
				{
					// -ive tileOffset is going up, which means the origin of the map is where the tile is.
					worldy += tileOffsetY;
				}
				if ( tileOffsetX > 0 )
				{
					worldx -= tileOffsetX;
				}
				
				// Get the right edge of the map
				var endxx:Number = tileSpacingX * widthInTiles;
				var endxy:Number = tileOffsetY * widthInTiles;
				
				// Get location on x-axis where world pos lies.
				var pt:FlxPoint = new FlxPoint;
				var intersects:Boolean = Hits.LineRayIntersection(0, 0, endxx, endxy, worldx, worldy, worldx - tileOffsetX, worldy - tileSpacingY, pt);
				
				var offX:Number = pt.x;
			
				// Get location on y-axis where world pos lies.
				// This is just the difference between world pos and x-axis intersection
				// Will not work if height differences are 0, ie map is rotated 90 degrees.
				var offY:Number = worldy - pt.y;
				
				var xpos:Number;
				var ypos:Number;
				
				xpos = offX / tileSpacingX;
				ypos = offY / tileSpacingY;
				var iXpos:int = int(xpos);
				var iYpos:int = int(ypos);
				
				intersects = intersects && ( offY >= 0 && iYpos < heightInTiles );
				
				// Account for the -0,+0 1 tile rounding error on each axis.
				if ( offX < 0 )
					iXpos--;
				if ( offY <= 0 )
					iYpos--;
					
				if ( !allowFloats )
				{
					xpos = iXpos;
					ypos = iYpos;
				}
					
				unitTilePos.create_from_points( xpos, ypos );
				
				GetTileWorldFromUnitPos(xpos, ypos, tilePos );
				return ( intersects && ( offY >= 0 && offY <= tileSpacingY * heightInTiles ) );
			}
			
			var tileStartY:int = tileHeight - tileSpacingY;
			if ( tileStartY > 0 )
			{
				worldy -= tileStartY;
			}
			
			
			if ( xStagger )
			{
				// Staggered tilemaps are diamond isometric where rows alternative with an offset.
				// As it's a perfect diamond the corners always meet halfway in the width and height.
				var realHeight:int = tileSpacingY * 2;
				
				worldy += tileSpacingY;
				
				var xFlip:Boolean = worldx < 0;
				var yFlip:Boolean = worldy < 0;
				/*if ( xFlip && xStagger < 0 )
				{
					worldx += tilesStartX;
					xFlip = worldx < 0;
				}*/
				if ( xFlip )
				{
					
					worldx = -worldx;
				}
				if ( yFlip )
				{
					worldy = -worldy;
				}
				

				// scale down into tile units.
				xpos = int(worldx / tileSpacingX);
				ypos = int(worldy / realHeight);
				
				var absStagger:int = Math.abs(xStagger);
				
				ypos *= 2;
				
				// Scale up back into world pos.
				var newX:int = xpos * tileSpacingX;
				var newY:int = ypos * tileSpacingY;
				
				// No floats allowed for staggered map - too complicated and unreliable when each row shifts.
				// Plus difficult to decide what direction each fraction added moves in.
				
				// Find out which side of the diamond we're on for each of its 4 sides to determine which square we're on.
				
				var xdir:int = 0;
				//if ( worldy >= 0 )
				{
					// Bottom left
					if( Hits.LinePointSide( newX, newY + tileSpacingY, newX + absStagger, newY, worldx, worldy ) <= 0 )
					{
						//trace("top left");
						ypos--;
						xdir = -1;
					}
					else if ( Hits.LinePointSide( newX, newY + tileSpacingY, newX + absStagger, newY + realHeight, worldx, worldy ) >= 0 )
					{
						//trace("bottom left");
						ypos++;
						xdir = -1;
					}
					else if( Hits.LinePointSide( newX + tileSpacingX, newY + tileSpacingY, newX + absStagger, newY, worldx, worldy ) >= 0 )
					{
						//trace("top right");
						ypos--;
						xdir = 1;
					}
					else if ( Hits.LinePointSide( newX + tileSpacingX, newY + tileSpacingY, newX + absStagger, newY + realHeight, worldx, worldy ) <= 0 )
					{
						//trace("bottom right");
						ypos++;
						xdir = 1;
					}
					if ( xdir == -1 )
					{
						if ( xStagger > 0 )
						{
							xpos--;
						}
					}
					else if ( xdir == 1 )
					{
						if ( xStagger < 0 )
						{
							xpos++
						}
					}
				}
				
				if ( xFlip )
				{
					xpos = -xpos;
					var evenRow:int = xStagger > 0 ? 0 : 1;
					if ( ypos % 2 == evenRow )
					{
						xpos -= 1;
					}
					else
					{
						xpos -= 2;
					}
				}
				if ( yFlip )
				{
					ypos = -ypos - 2;
				}
				
				unitTilePos.create_from_points( xpos, ypos );
				
				GetTileWorldFromUnitPos(xpos, ypos, tilePos );
				
				
				return ( xpos >= 0 && ypos >= 0 && xpos < widthInTiles && ypos < heightInTiles );
			}
			
			// Fail case - 2d aligned map.
			
			// scale down into tile units.
			xpos = worldx / tileSpacingX;
			ypos = worldy / tileSpacingY;
			iXpos = int(xpos);
			iYpos = int(ypos);
			
			// Account for the -0,+0 1 tile rounding error on each axis.
			if ( worldx < 0 )
				iXpos--;
			if ( worldy <= 0 )
				iYpos--;
				
			if ( !allowFloats )
			{
				xpos = iXpos;
				ypos = iYpos;
			}
			
			unitTilePos.create_from_points( xpos, ypos );
			
			GetTileWorldFromUnitPos(xpos, ypos, tilePos );
			return ( xpos >= 0 && ypos >= 0 && xpos < widthInTiles && ypos < heightInTiles );
		}
		
	}

}