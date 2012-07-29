package com.UI 
{
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.UI.Tiles.TileGrid;
	import com.Utils.Misc;
	import flash.filesystem.File;
	import mx.collections.ArrayCollection;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileMatrixGrid extends TileGrid
	{
		// The map associated with this matrix. Use this along with image so that if the current map
		// doesn't have this file it uses the layer instead.
		public var tilesetLayer:LayerMap = null;
		
		// The tileset associated with this matrix.
		public var tilesetImageFile:File = null;
		
		public function TileMatrixGrid( wid:uint, ht:uint, numColumns:uint, numRows:uint) 
		{
			super(wid, ht, numColumns, numRows);
		}
		
		override public function OnDragDrop():void
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( mapLayer )
			{
				tilesetImageFile = mapLayer.imageFileObj;
			}
		}
		
		// Find a map with the same image layer, just so we can draw the tiles when the current layer is not suitable.
		// If we pass in a layer id then it will try and look for that first.
		public function MatchToFirstSuitableMap( layerID:int = -1 ):void
		{	
			var groups:ArrayCollection = App.getApp().layerGroups;
			
			for each( var group:LayerGroup in groups )
			{
				for ( var i:uint = 0; i < group.children.length; i++ )
				{
					var mapLayer:LayerMap = group.children[i] as LayerMap;
					if ( mapLayer )
					{
						if ( Misc.FilesMatch(mapLayer.imageFileObj, tilesetImageFile) )
						{
							if ( layerID == -1 || layerID == mapLayer.id )
							{
								tilesetLayer = mapLayer;
								return;
							}
						}
					}
				}
			}
			if ( layerID != -1 )
			{
				// Not found a match... try again but this time without a layerID.
				MatchToFirstSuitableMap();
			}
		}
		
	}

}