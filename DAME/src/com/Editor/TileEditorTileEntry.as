package com.Editor 
{
	import com.Tiles.StackTileInfo;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileEditorTileEntry
	{
		public var startX:int;
		
		public var tileId:uint = 0;
		public var replaceTileId:uint = 0;
		public var tileStack:StackTileInfo = null;
		public var replaceStack:StackTileInfo = null;
		
		public function TileEditorTileEntry(x:int)
		{
			startX = x;
		}
		
		public function Clone():TileEditorTileEntry
		{
			var newTileEntry:TileEditorTileEntry = new TileEditorTileEntry(startX);
			newTileEntry.tileId = tileId;
			newTileEntry.replaceTileId = replaceTileId;
			newTileEntry.tileStack = tileStack ? tileStack.Clone() : null;
			newTileEntry.replaceStack = replaceStack ? replaceStack.Clone() : null;
			return newTileEntry;
		}
		
		public function SetStack( stack:StackTileInfo):void
		{
			tileStack = stack ? stack.Clone() : null;
		}
	}

}