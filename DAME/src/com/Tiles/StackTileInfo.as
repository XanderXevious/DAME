package com.Tiles 
{
	import com.Utils.OrderedHash;
	//import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class StackTileInfo
	{
		public var tiles:OrderedHash;	// height based (so starts at 1)
		private var _height:int = 0;
		public function GetHeight():int { return _height; }
		
		public function StackTileInfo() 
		{
			tiles = new OrderedHash;
		}
		
		public function ClearTile( height:uint ):void
		{
			if ( tiles[height] )
			{
				delete tiles[height];
				// Need to readjust _height to the highest tile.
				_height = 0;
				for (var key:Object in tiles)
				{
					_height = int(key);
				}
			}
		}
		
		public function SetTile( height:int, tile:int ):void
		{
			if ( tiles[height] == null )
			{
				if( height > _height )
					_height = height;
			}
			tiles[height] = tile;
		}
		
		public function Clone( ):StackTileInfo
		{
			var newStack:StackTileInfo = new StackTileInfo;
			newStack._height = _height;
			for (var key:Object in tiles)
			{
				// Need to recast the key so that if we delete the oldkey it's not referenced
				// by the old Object.
				var newKey:uint = (uint)(key);
				newStack.tiles[newKey] = tiles[key];
			}
			return newStack;
		}
		
		public function SetHeight( newHeight:int ):void
		{
			_height = newHeight;
		}
	}

}