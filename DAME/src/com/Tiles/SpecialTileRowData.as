package com.Tiles 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpecialTileRowData
	{
		public var tiles:Vector.<uint> = new Vector.<uint>;
		public var set:TileConnectionList = null;
		
		public function SpecialTileRowData() 
		{
			
		}
		
		public function Clone():SpecialTileRowData
		{
			var rowData:SpecialTileRowData = new SpecialTileRowData;
			rowData.tiles = tiles.slice(0, tiles.length);
			rowData.set = set;
			return rowData;
		}
		
	}

}