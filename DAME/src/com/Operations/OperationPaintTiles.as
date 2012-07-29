package com.Operations 
{
	import com.Layers.LayerMap;
	import com.Tiles.StackTileInfo;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationPaintTiles extends IOperation
	{
		private var layer:LayerMap;
		private var tileData:Array;
		private var stackedTiles:Dictionary = null;
		private var numStackedTiles:int = 0;
		
		public function OperationPaintTiles( _layer:LayerMap ) 
		{
			layer = _layer;
			tileData = layer.map.GetTileIdDataArray();
			tileData = tileData.slice(0, tileData.length );	// Ensure we have a copy and not a reference.
			if ( layer.map.stackedTiles )
			{
				var oldStack:Dictionary = layer.map.stackedTiles;
				stackedTiles = new Dictionary;
				for (var key:Object in oldStack)
				{
					var newKey:uint = (uint)(key);
					stackedTiles[newKey] = oldStack[key].Clone();
				}
				numStackedTiles = layer.map.numStackedTiles;
			}
		}
		
		override public function Undo():void
		{
			// Doesn't resize map
			layer.map.SetTileIdData( tileData );
			layer.map.stackedTiles = stackedTiles;
			layer.map.numStackedTiles = numStackedTiles;
		}
		
	}

}