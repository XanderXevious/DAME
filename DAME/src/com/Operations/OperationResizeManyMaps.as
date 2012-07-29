package com.Operations 
{
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Operations.IOperation;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationResizeManyMaps extends IOperation
	{
		private var layers:Vector.<ResizeMapLayerData> = new Vector.<ResizeMapLayerData>;
		
		public function OperationResizeManyMaps( group:LayerGroup ) 
		{
			for ( var i:uint = 0; i < group.children.length; i++ )
			{
				var mapLayer:LayerMap = group.children[i] as LayerMap;
				if ( mapLayer )
				{
					layers.push(new ResizeMapLayerData(mapLayer));
				}
			}
		}
		
		override public function Undo():void
		{
			for each( var layerData:ResizeMapLayerData in layers )
			{
				layerData.layer.map.x = layerData.x;
				layerData.layer.map.y = layerData.y;
				layerData.layer.map.SetTileIdData(layerData.tileData, layerData.width, layerData.height);
			}
		}
		
	}

}

import com.Layers.LayerMap;

internal class ResizeMapLayerData
{
	public var layer:LayerMap;
	public var tileData:Array;
	public var width:uint;
	public var height:uint;
	public var x:Number;
	public var y:Number;
	
	public function ResizeMapLayerData( _layer:LayerMap )
	{
		layer = _layer;
		tileData = layer.map.GetTileIdDataArray();
		tileData = tileData.slice(0, tileData.length );	// Ensure we have a copy and not a reference.
		width = layer.map.widthInTiles;
		height = layer.map.heightInTiles;
		x = _layer.map.x;
		y = _layer.map.y;
	}
}