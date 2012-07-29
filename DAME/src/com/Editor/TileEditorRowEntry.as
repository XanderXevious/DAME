package com.Editor 
{
	import com.Utils.Misc;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileEditorRowEntry
	{
		public var startY:int = 0;
		public var tiles:Vector.<TileEditorTileEntry>;
		static public var xOffset:int = 0;	// Must be set before calling GetTile
		
		public function TileEditorRowEntry(y:int)
		{
			startY = y;
			tiles = new Vector.<TileEditorTileEntry>();
		}
		
		public function Clone( ):TileEditorRowEntry
		{
			var newRowEntry:TileEditorRowEntry = new TileEditorRowEntry(startY);
			newRowEntry.startY = startY;
			for ( var i:uint = 0; i < tiles.length; i++ )
			{
				newRowEntry.tiles.push(tiles[i].Clone());
			}
			return newRowEntry;
		}
		
		private function evalPositionOfTile( tile:TileEditorTileEntry ):int
		{
			return tile.startX + xOffset;
		}
		
		public function GetTile( x:int, insertIfNotExist:Boolean, returnMinusOneIfNotExist:Boolean ):int
		{
			var index:int = Misc.binarySearch( tiles, x, evalPositionOfTile, false );
			if ( insertIfNotExist || returnMinusOneIfNotExist )
			{
				if ( index >= tiles.length || ( index >=0 && index < tiles.length && tiles[index].startX + xOffset != x ) )
				{
					if ( insertIfNotExist )
					{
						tiles.splice( index, 0, new TileEditorTileEntry(x) );
					}
					else if ( returnMinusOneIfNotExist )
					{
						index = -1;
					}
				}
			}
			return index;
		}
	}

}