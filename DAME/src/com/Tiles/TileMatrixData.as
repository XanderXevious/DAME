package com.Tiles 
{
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Utils.Misc;
	import flash.filesystem.File;
	import mx.collections.ArrayCollection;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileMatrixData
	{
		public var numRows:uint = 1;
		public var numColumns:uint = 1;
		public var tileIds:Vector.<uint> = new Vector.<uint>;
		public var name:String = "";
		public var IgnoreClearTiles:Boolean;
		public var IgnoreMapEdges:Boolean;
		public var RandomizeMiddleTiles:Boolean;
		public var AllowSpecialTiles:Boolean;
		public var SpecialTileRows:Vector.<SpecialTileRowData> = new Vector.<SpecialTileRowData>;
		public var HasConnectionData:Boolean = false;	// The vector can be empty and this true. This is just for backwards compatibility.

		// The map associated with this matrix. Use this along with image so that if the current map
		// doesn't have this file it uses the layer instead.
		public var tilesetLayer:LayerMap = null;
		
		// The tileset associated with this matrix.
		public var tilesetImageFile:File = null;
		
		public function TileMatrixData() 
		{
			
		}
		
		public function Clone():TileMatrixData
		{
			var matrix:TileMatrixData = new TileMatrixData;
			matrix.numRows = numRows;
			matrix.numColumns = numColumns;
			matrix.tileIds = tileIds.slice(0, tileIds.length);
			matrix.name = name;
			matrix.IgnoreClearTiles = IgnoreClearTiles;
			matrix.RandomizeMiddleTiles = RandomizeMiddleTiles;
			matrix.AllowSpecialTiles = AllowSpecialTiles;
			for each( var tileRow:SpecialTileRowData in SpecialTileRows )
			{
				matrix.SpecialTileRows.push(tileRow.Clone());
			}
			matrix.HasConnectionData = HasConnectionData;
			matrix.tilesetImageFile = tilesetImageFile;
			matrix.tilesetLayer = tilesetLayer;
			return matrix;
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