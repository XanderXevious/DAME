package com.Tiles 
{
	import com.EditorState;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileConnections
	{
		public static const TOP_LEFT:uint =		0x10000000;
		public static const TOP_CENTER:uint =	0x01000000;
		public static const TOP_RIGHT:uint =	0x00100000;
		public static const MID_LEFT:uint = 	0x00010000;
		public static const MID_RIGHT:uint =	0x00001000;
		public static const BOTTOM_LEFT:uint =	0x00000100;
		public static const BOTTOM_CENTER:uint = 0x00000010;
		public static const BOTTOM_RIGHT:uint =	0x00000001;
		
		public var lastChanged:uint = 0;
		
		
		private var greenTiles:uint = 0;
		private var redTiles:uint = 0;
		
		public function get GreenTiles():uint { return greenTiles; }
		public function set GreenTiles(tiles:uint):void
		{
			greenTiles = tiles;
			lastChanged = EditorState.FrameNum;
		}
		
		public function get RedTiles():uint { return redTiles; }
		public function set RedTiles(tiles:uint):void
		{
			redTiles = tiles;
			lastChanged = EditorState.FrameNum;
		}
		
		public function TileConnections( green:uint, red:uint ) 
		{
			GreenTiles = green;
			RedTiles = red;
		}
		
		public function InvertGreen( mask:uint ):void
		{
			if ( greenTiles & mask )
			{
				greenTiles &= ~mask;
			}
			else
			{
				greenTiles |= mask;
			}
			lastChanged = EditorState.FrameNum;
		}
		
		public function InvertRed( mask:uint ):void
		{
			if ( redTiles & mask )
			{
				redTiles &= ~mask;
			}
			else
			{
				redTiles |= mask;
			}
			lastChanged = EditorState.FrameNum;
		}
		
		public function CycleRedGreen( mask:uint ):void
		{
			if ( greenTiles & mask )
			{
				greenTiles &= ~mask;
				redTiles |= mask;
			}
			else if( redTiles & mask )
			{
				redTiles &= ~mask;
			}
			else
			{
				redTiles &= ~mask;
				greenTiles |= mask;
			}
			lastChanged = EditorState.FrameNum;
		}
		
		// 1 if valid, 0 if invalid, -1 if ignored.
		public function IsConnectionValid( tileExistsAtConnect:Boolean, mask:uint ):int
		{
			if ( greenTiles & mask )
			{
				return ( tileExistsAtConnect ? 1 : 0 );
			}
			else if ( redTiles & mask )
			{
				return( tileExistsAtConnect ? 0 : 1 );
			}
			else
			{
				return -1;
			}
		}
		
		
	}

}