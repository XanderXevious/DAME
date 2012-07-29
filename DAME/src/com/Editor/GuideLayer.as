package com.Editor
{
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerMap;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.IsoHelper;
	import com.Utils.DebugDraw;
	import com.Utils.DebugDrawShapes.DebugDrawShape;
	import com.Utils.Global;
	import flash.display.BitmapData;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class GuideLayer
	{
		static public var XStart:int = 0;
		static public var YStart:int = 0;
		static public var XSpacing:int = 30;
		static public var YSpacing:int = 30;
		static public var Visible:Boolean = false;
		static public var SnappingEnabled:Boolean = false;
		static public var PaintContinuouslyWhenSnapped:Boolean = false;
		static public var ShowGameRegion:Boolean = false;
		static public var RegionWidth:uint = 400;
		static public var RegionHeight:uint = 400;
		static public var RegionOpacity:Number = 0.5;
		static public var RegionCentered:Boolean = false;
		static public var ShowRegionGrid:Boolean = false;
		static public var RegionGridXStart:int = 0;
		static public var RegionGridYStart:int = 0;
		
		static public var MinGridSpace:int = 10;
		
		// Must start at 0 and go up in increments of 1.
		public static const SnapPosType_Anchor:uint = 0;
		public static const SnapPosType_Center:uint = 1;
		public static const SnapPosType_TopLeft:uint = 2;
		public static const SnapPosType_BoundsTopLeft:uint = 3;
		public static const SnapPosType_BottomLeft:uint = 4;
		public static const SnapPosType_BoundsBottomLeft:uint = 5;
		
		static public var SnapPosType:uint = SnapPosType_Anchor;
		
		static public function DrawRegionGrid( ):void
		{
			if ( !ShowRegionGrid )
			{
				return;
			}
			
			var xStart:int = RegionGridXStart * FlxG.extraZoom;
			var yStart:int = RegionGridYStart * FlxG.extraZoom;
			var xSpacing:Number = RegionWidth * FlxG.extraZoom;
			var ySpacing:Number = RegionHeight * FlxG.extraZoom;
			
			var i:Number;
			var xScroll:Number = FlxG.scroll.x * FlxG.extraZoom;
			var yScroll:Number = FlxG.scroll.y * FlxG.extraZoom;
			
			// The screen scroll position rounded to tiles.
			var startx:int = (xScroll - (xScroll % xSpacing));
			var starty:int = (yScroll - (yScroll % ySpacing));
			
			var extraScale:int = FlxG.zoomScale == 0.5 ? 2 : 1;
			var endx:int = -xScroll + ((FlxG.width * FlxG.invExtraZoom) + 2) * extraScale;// make a little larger as it seems slightly short
			var endy:int = -yScroll + (FlxG.height * FlxG.invExtraZoom) * extraScale;
			var scrollPt:FlxPoint = new FlxPoint(1, 1);
			
			var lineStartX:Number = xStart;
			var lineStartY:Number = yStart;
			
			var newStartX:int =  (lineStartX - startx) - (Math.round(lineStartX / xSpacing ) * xSpacing ) - xSpacing;
			var newStartY:int =  (lineStartY - starty) - (Math.round(lineStartY / ySpacing ) * ySpacing ) - ySpacing;
			
			// Draw vertical lines.			
			for ( i = newStartX; i < endx; i+=xSpacing )
			{
				DebugDraw.DrawLine(i, -yScroll, i, endy, scrollPt, false, Global.RegionGridLineColour, true );
			}

			// Draw horizontal lines.
			for ( i = newStartY ; i < endy; i += ySpacing )
			{
				DebugDraw.DrawLine( -xScroll, i, endx, i, scrollPt, false, Global.RegionGridLineColour, true );
			}
		}
		
		static public function DrawGuidelines( currentLayer:LayerEntry ):void
		{
			DrawRegionGrid();
			if ( !Visible )
			{
				DebugDraw.singleton.HasCachedShape = false;
				return;
			}
			if ( FlxG.zoomScale < 1 )
			{
				DebugDraw.singleton.HasCachedShape = false;
				return;	// Too costly.
			}
			
			var map:FlxTilemapExt = currentLayer.map;
			var mapLayer:LayerMap = currentLayer as LayerMap;
			
			
			var avatarLayer:LayerAvatarBase = currentLayer as LayerAvatarBase;
			
			if ( DebugDraw.singleton.HasCachedShape )
			{
				if( DebugDraw.singleton.cachedLayer != currentLayer
					|| !DebugDraw.singleton.cachedShapeBmp
					|| DebugDraw.singleton.cachedShapeBmp.width != FlxG.width
					|| DebugDraw.singleton.cachedShapeBmp.height != FlxG.height
					|| !DebugDraw.singleton.cachedScreenPos.equals( FlxG.scroll ) )
				{
					DebugDraw.singleton.HasCachedShape = false;
				}
				else
				{
					return;
				}
			}
			
			if( !DebugDraw.singleton.HasCachedShape )
			{
				DebugDraw.singleton.cachedLayer = currentLayer;
				if( !DebugDraw.singleton.cachedShapeBmp
					|| DebugDraw.singleton.cachedShapeBmp.width != FlxG.width
					|| DebugDraw.singleton.cachedShapeBmp.height != FlxG.height )
				{
					DebugDraw.singleton.cachedShapeBmp = new BitmapData(FlxG.width, FlxG.height, true, 0x00000000);
				}
				else
				{
					DebugDraw.singleton.cachedShapeBmp.fillRect(DebugDraw.singleton.cachedShapeBmp.rect, 0x00000000);
				}
				DebugDraw.singleton.cachedScreenPos = FlxG.scroll.clone();
			}
			
			if ( avatarLayer && avatarLayer.AlignedWithMasterLayer )
			{
				var layer:LayerMap = avatarLayer.parent.FindMasterLayer();
				if ( layer )
				{
					map = layer.map;
					mapLayer = layer;
				}
			}
			
			var xOffset:Number = map ? map.tileOffsetX : 0;
			var yOffset:Number = map ? map.tileOffsetY : 0;
			var xStart:Number = map ? map.x : XStart;
			var yStart:Number = map ? map.y : YStart;
			var xSpace:Number = map ? map.tileSpacingX : XSpacing;
			var ySpace:Number = map ? map.tileSpacingY : YSpacing;
			
			if ( map && mapLayer)
			{
				if ( mapLayer.tilemapType == LayerMap.TileTypeDiamond)
				{
					yStart += ( map.tileHeight - ( map.tileSpacingY * 2 ) );
				}
				else
				{
					yStart += ( map.tileHeight - map.tileSpacingY );
				}
			}
			
			if ( map && map.xStagger )
			{
				xSpace = xSpace * 0.5;
				ySpace = ySpace * 0.5;
				xOffset = -xSpace;
				yOffset = ySpace;
			}
			
			var xSpacing:Number = xSpace;
			var ySpacing:Number = ySpace;
			var xOff:int = xOffset;
			var yOff:int = yOffset;
			
			
			// Keep adding extra tiles if our spacing is too small.
			while ( xSpacing < MinGridSpace )
			{
				xSpacing += xSpace;
				yOffset += yOff;
			}
			while ( ySpacing < MinGridSpace )
			{
				ySpacing += ySpace;
				xOffset += xOff;
			}
			
			// Modify the start pos so that it anchors to a tile corner.
			
			if ( xOffset && yOffset && map)
			{
				xStart += map.tilesStartX - xOffset;
			}
			else
			{
				if ( xOffset < 0 )
				{
					xStart -= xOffset;
				}
				if ( yOffset < 0 )
				{
					yStart -= yOffset;
				}
			}
			
			var xRatio:Number = xOffset / ySpacing;
			var yRatio:Number = yOffset / xSpacing;
			
			xSpacing += (-xRatio * yOffset);
			ySpacing += (-yRatio * xOffset);
			
			var i:Number;
			var xScroll:Number = FlxG.scroll.x * currentLayer.xScroll;
			var yScroll:Number = FlxG.scroll.y * currentLayer.yScroll;
			
			// The screen scroll position rounded to tiles.
			var startx:int = (xScroll - (xScroll % xSpacing));
			var starty:int = (yScroll - (yScroll % ySpacing));
			var endy:int = -yScroll + FlxG.height;
			var endx:int = -xScroll + FlxG.width + 2;// make a little larger as it seems slightly short
			var scrollPt:FlxPoint = new FlxPoint(currentLayer.xScroll, currentLayer.yScroll);
			
			// This helps align the grid to the tiles by mapping the origin corner of the tilemap to the grid.
			var lineStartX:Number = xStart - ( yStart * xRatio );
			var lineStartY:Number = yStart - ( xStart * yRatio );
			
			var newStartX:int =  (lineStartX - startx) - (Math.round(lineStartX / xSpacing ) * xSpacing );
			var newStartY:int =  (lineStartY - starty) - (Math.round(lineStartY / ySpacing ) * ySpacing );
			
			// Iso lines are drawn so that when you move horizontally the lines actually move vertically and vice-versa
			// (which causes a slight rounding error). This means that even with very steep but non vertical
			// lines the lines always behave correctly and don't end up misaligned. Ie when you move and cause it to round and shift
			// back it needs to move the lines so that they are where they should be. When moving the lines in the direction the view has
			// moved in steep lines will require the line to be shifted greatly, so moving the lines in the other axis only ever requires
			// them to be redrawn in one shift. (It makes sense on paper!!)
			
			// Draw vertical lines.
			var offsetDiff:Number = ( -yScroll - endy) * xRatio;
			var offsetDiffRounded:int = Math.round( offsetDiff / xSpacing ) * xSpacing;
			var newEndX:int = endx;
			if ( xOffset > 0 )
			{
				newStartX += offsetDiffRounded;
			}
			else if( xOffset < 0 )
			{
				newEndX += offsetDiffRounded;
			}
			
			var startAxisOffset:Number =  ( -yScroll * xRatio) % xSpacing;
			for ( i = newStartX + startAxisOffset; i < newEndX; i+=xSpacing )
			{
				var drawnLine:DebugDrawShape = DebugDraw.DrawLine(i, -yScroll, i - offsetDiff, endy, scrollPt, false, Global.GridLineColour, true );
				drawnLine.cache = true;
			}

			// Draw horizontal lines.
			offsetDiff = ( -xScroll - endx) * yRatio;
			offsetDiffRounded = Math.round( offsetDiff / ySpacing ) * ySpacing;
			var newEndY:int = endy;
			if ( yOffset > 0 )
			{
				newStartY += offsetDiffRounded;
			}
			else if( yOffset < 0 )
			{
				newEndY += offsetDiffRounded;
			}
			startAxisOffset = ( -xScroll * yRatio) % ySpacing;
			for ( i = newStartY + startAxisOffset; i < newEndY; i += ySpacing )
			{
				drawnLine = DebugDraw.DrawLine( -xScroll, i, endx, i - offsetDiff, scrollPt, false, Global.GridLineColour, true );
				drawnLine.cache = true;
			}
		}
		
		static public function GetSnappedPos( currentLayer:LayerEntry, x:Number, y:Number, posOUT:FlxPoint, tilePos:FlxPoint = null ):FlxPoint
		{
			if ( !SnappingEnabled )
			{
				posOUT.x = x;
				posOUT.y = y;
				return posOUT;
			}
			var map:FlxTilemapExt = currentLayer ? currentLayer.map : null;
			var avatarLayer:LayerAvatarBase = currentLayer as LayerAvatarBase;
			if ( avatarLayer && avatarLayer.AlignedWithMasterLayer )
			{
				var layer:LayerMap = avatarLayer.parent.FindMasterLayer();
				if ( layer )
				{
					map = layer.map;
				}
			}
			
			var xOffset:int = map ? map.tileOffsetX : 0;
			var yOffset:int = map ? map.tileOffsetY : 0;
			var xStart:int = map ? map.x : XStart;
			var yStart:int = map ? map.y : YStart;
			var xSpace:int = map ? map.tileSpacingX : XSpacing;
			var ySpace:int = map ? map.tileSpacingY : YSpacing;
			
			IsoHelper.helper.ResetValues( xSpace, ySpace, xOffset, yOffset, xStart, yStart, map ? map.tilesStartX : 0, map ? map.tilesStartY : 0, map ? map.xStagger : 0, map ? map.tileHeight : ySpace, 10, 10 );
			var oldZoomShift:int = FlxG.zoomBitShifter;
			FlxG.zoomBitShifter = 0;
			IsoHelper.helper.GetTileInfo( x - xStart, y - yStart, posOUT, null);
			FlxG.zoomBitShifter = oldZoomShift;
			
			if ( tilePos )
			{
				tilePos.copyFrom( posOUT );
			}
			IsoHelper.helper.GetTileWorldFromUnitPos(posOUT.x, posOUT.y, posOUT, true );
			
			return posOUT;
		}
		
	}

}