package com.Operations 
{
	import com.Layers.LayerMap;
	import com.Operations.IOperation;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationResizeMap extends IOperation
	{
		private var layer:LayerMap;
		private var tileData:Array;
		private var width:uint;
		private var height:uint;
		public var x:Number;
		public var y:Number;
		private var tileWidth:uint;
		private var tileHeight:uint;
		private var stackedTiles:Dictionary = null;
		private var numStackedTiles:int = 0;
		
		public function OperationResizeMap( _layer:LayerMap ) 
		{
			layer = _layer;
			tileData = layer.map.GetTileIdDataArray();
			tileData = tileData.slice(0, tileData.length );	// Ensure we have a copy and not a reference.
			width = layer.map.widthInTiles;
			height = layer.map.heightInTiles;
			x = layer.map.x;
			y = layer.map.y;
			tileWidth = layer.map.tileWidth;
			tileHeight = layer.map.tileHeight;
			
			if ( layer.map.stackedTiles )
			{
				var oldStack:Dictionary = layer.map.stackedTiles;
				stackedTiles = new Dictionary;
				for (var key:Object in oldStack)
				{
					stackedTiles[key] = oldStack[key].Clone();
				}
				numStackedTiles = layer.map.numStackedTiles;
			}
		}
		
		override public function Undo():void
		{
			layer.map.x = x;
			layer.map.y = y;
			layer.map.SetTileIdData(tileData, width, height, tileWidth, tileHeight);
			
			layer.map.stackedTiles = stackedTiles;
			layer.map.numStackedTiles = numStackedTiles;
		}
		
	}

}