package com.Tiles 
{
	import mx.collections.ArrayCollection;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileConnectionList
	{
		public static const RemoveRowLabel:String = "--REMOVE ROW--";
		public static const RemoveRowItem:Object = { label:RemoveRowLabel };
		
		public static const RenameSetLabel:String = "--RENAME SET--";
		public static const RenameSetItem:Object = { label:RenameSetLabel };
		
		public static const RemoveSetLabel:String = "--REMOVE SET--";
		public static const RemoveSetItem:Object = { label:RemoveSetLabel };
		
		[Bindable]
		public static var tileConnectionLists:ArrayCollection = new ArrayCollection();
		
		
		public var tiles:Vector.<TileConnections>;
		public var label:String;
		
		public function TileConnectionList( name:String, connections:Vector.<TileConnections> = null ) 
		{
			label = name;
			if ( connections == null )
			{
				tiles = new Vector.<TileConnections>();
				tiles.push(new TileConnections(0x01011010, 0x00000000));
				tiles.push(new TileConnections(0x00000000, 0x00000000));
				tiles.push(new TileConnections(0x00000000, 0x00000000));
				tiles.push(new TileConnections(0x00000000, 0x00000000));
			}
			else
			{
				tiles = connections;
			}
		}
		
		public static function AddDefaults():void
		{
			tileConnectionLists.removeAll();
			
			var tiles:Vector.<TileConnections>;
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x01111111, 0x10000000));
			tiles.push(new TileConnections(0x11011111, 0x00100000));
			tiles.push(new TileConnections(0x11111110, 0x00000001));
			tiles.push(new TileConnections(0x11111011, 0x00000100));
			tileConnectionLists.addItemAt(new TileConnectionList("Single Inside Corners", tiles), 0);
			
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x01011111, 0x10100000));
			tiles.push(new TileConnections(0x11011110, 0x00100001));
			tiles.push(new TileConnections(0x11111010, 0x00000101));
			tiles.push(new TileConnections(0x01111011, 0x10000100));
			tileConnectionLists.addItemAt(new TileConnectionList("Double Inside Corners", tiles), 1);
			
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x01011011, 0x10100100));
			tiles.push(new TileConnections(0x01011110, 0x10100001));
			tiles.push(new TileConnections(0x11011010, 0x00100101));
			tiles.push(new TileConnections(0x01111010, 0x10000101));
			tileConnectionLists.addItemAt(new TileConnectionList("Triple Inside Corners", tiles), 2);
			
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x01011010, 0x10100101));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tileConnectionLists.addItemAt(new TileConnectionList("Quad Inside Corners", tiles), 3);
			
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x00000010, 0x01011000));
			tiles.push(new TileConnections(0x00001000, 0x01010010));
			tiles.push(new TileConnections(0x01000000, 0x00011010));
			tiles.push(new TileConnections(0x00010000, 0x01001010));
			tileConnectionLists.addItemAt(new TileConnectionList("Double Outside Corners", tiles), 4);
			
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x01000010, 0x00011000));
			tiles.push(new TileConnections(0x00011000, 0x01000010));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tileConnectionLists.addItemAt(new TileConnectionList("Double Outside Edges", tiles), 5);
			
			tiles = new Vector.<TileConnections>();
			tiles.push(new TileConnections(0x01111110, 0x10000001));
			tiles.push(new TileConnections(0x11011011, 0x00100100));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tiles.push(new TileConnections(0x00000000, 0x00000000));
			tileConnectionLists.addItemAt(new TileConnectionList("Opposing Double Inside Corners", tiles), 6);
		}
		
	}

}