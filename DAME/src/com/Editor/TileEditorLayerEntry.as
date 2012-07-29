package com.Editor 
{
	import com.Layers.LayerMap;
	import com.Utils.Misc;
	import flash.filesystem.File;
	/**
	 * ...
	 * @author Charles Goatley
	 */	
	public class TileEditorLayerEntry
	{
		public var xOffset:int = 0;
		public var yOffset:int = 0;
		public var layer:LayerMap;
		public var rows:Vector.<TileEditorRowEntry>;
		public var isSelection:Boolean;
		
		// Used only when not referencing layer directly.
		public var imageFile:File = null;// String = "";
		
		public function TileEditorLayerEntry( _layer:LayerMap, isSelection:Boolean = false )
		{
			layer = _layer;
			rows = new Vector.<TileEditorRowEntry>();
			if ( isSelection )
			{
				layer.map.selectedTiles = new Vector.<Boolean>(layer.map.totalTiles);
			}
		}
		
		public function Clone( ):TileEditorLayerEntry
		{
			var newLayerEntry:TileEditorLayerEntry = new TileEditorLayerEntry(layer);
			newLayerEntry.imageFile = imageFile;
			newLayerEntry.xOffset = xOffset;
			newLayerEntry.yOffset = yOffset;
			for ( var i:uint = 0; i < rows.length; i++ )
			{
				var row:TileEditorRowEntry = rows[i];
				if ( row.tiles.length > 0 )
				{
					newLayerEntry.rows.push(row.Clone());
				}
			}
			if ( rows.length == 0 )
			{
				return null;
			}
			return newLayerEntry;
		}
		
		private function evalPositionOfRow( row:TileEditorRowEntry ):int
		{
			return row.startY + yOffset;
		}
		
		public function GetRow( y:int, insertIfNotExist:Boolean, returnMinusOneIfNotExist:Boolean ):int
		{
			var index:int = Misc.binarySearch( rows, y, evalPositionOfRow, false);
			if ( insertIfNotExist || returnMinusOneIfNotExist)
			{
				if ( index >= rows.length || ( index >= 0 && index < rows.length && rows[index].startY + yOffset != y ) )
				{
					if ( insertIfNotExist )
					{
						rows.splice( index, 0, new TileEditorRowEntry(y) );
					}
					else if ( returnMinusOneIfNotExist)
					{
						index = -1;
					}
				}
			}
			return index;
		}
		
		public function HasTiles():Boolean
		{
			var i:uint = rows.length;
			while (i--)
			{
				var row:TileEditorRowEntry = rows[i];
				if ( row.tiles.length )
				{
					return true;
				}
			}
			return false;
		}
	}

}