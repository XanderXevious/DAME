package com.FileHandling 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	import com.EditorState;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Utils.Misc;
	import flash.events.*;
	import flash.filesystem.File;
	import flash.net.*;
	
	import org.flixel.*;
	
	public class TMX
	{
		public var my_req:URLRequest;
        public var loader:URLLoader;
		public var CSV:String = new String("9,9,9,9"); //if don't work show this
		public var filename:String = "";
		public var file:File;
		public var group:LayerGroup = null;
		
		
		public function TMX(directory:String = "") 
		{
			if(directory != "")
			{
				Load(directory);
			}   
			trace("TMX load ATTIVA!");      
		}
		
		public function Load(directory:String):void //import tmx file from user pc or internet
		{
			this.filename = Misc.FixMacFilePaths(directory);
			file = new File(filename);
			this.loader = new URLLoader();
			this.loader.addEventListener(Event.COMPLETE, loading);  
			
			this.loader.load(new URLRequest(this.filename));   
			trace("file loaded: " + this.filename);
		}

		public function loading(e:Event):void
		{
			//trace("load percentage: " + this.loader.bytesLoaded + "/" + this.loader.bytesTotal);		
			var xmlData:XML = new XML(e.target.data);
			//trace("show data: " + xmlData.toXMLString());
			//trace(xmlData);
			var mapList:XMLList = xmlData.map;
			
			//mapLayer.CreateMapFromString( imageFile, mapString, xml.@tileWidth, xml.@tileHeight, tileSpacingX, tileSpacingY, xStagger, tileOffsetX, tileOffsetY );
					
			var mapCount:int = mapList.length();
			
			if ( !mapCount )
			{
				return;
			}
		
			group = new LayerGroup("TMX_Group");
			for ( var i:int = 0; i < mapCount; i++)
			{
				var map:XML = mapList[i];
				loadLayer(map);
				//trace("maybe some iteration?");
			} 
			
			var app:App = App.getApp();
			app.layerGroups.addItem( group );
			app.layerTree.selectedItem = group;
			var currentState:EditorState = FlxG.state as EditorState;
			currentState.UpdateMapList();
			currentState.UpdateCurrentTileList( app.CurrentLayer );
			app.layerChangedCallback();
			/* var objectGroupList:XMLList = xmlData.objectgroup;
			var objectGroupCount:int = objectGroupList.length();
			for (i = 0; i < objectGroupCount; i++)
			{
				var objectGroup:XML = objectGroupList[i];
				loadObjectGroup(objectGroup);
			} */
		}
		
// ====================================================================
		
		public function loadLayer(layerXml:XML, tilesetXml:XML):void
		{
			var layerXml:XML = xml.layer[0];
			var tilesetXml:XML = xml.tileset[0];
			
			var mapLayer:LayerMap = new LayerMap( group, layerXml.@name );
			var imageFile:File = file.parent.resolvePath(tilesetXml.image.@source);
			
			var width:uint = layerXml.@width;
			var height:uint = layerXml.@height;
			trace("loadLayer: width: " + width + " " + "height: " + height);
			var layerString:String = "";
			if ( layerXml.data.hasOwnProperty("@encoding") )
			{
				trace("Does not currently support encoded data in TMX files");
				if ( layerXml.data.@encoding == "base64" )
				{
					
				}
			}
			else
			{
				var tileList:XMLList = layerXml.data.tile;
				var i:uint = 0;
				for each (var tile:XML in tileList)
				{
					var gid:int = tile.@gid;
							
					// tiled's index starts at 1 so ajust.
					gid--;
							
					layerString += gid;
						
					if ( i % width == width -1)
					{
						layerString += "\n";
					}
					else
					{
						layerString += ","
					}
					i++;
				}
			}
			trace("layerString:" + layerString);
			
			mapLayer.CreateMapFromString( imageFile, layerString, xml.@tilewidth, xml.@tileheight, xml.@tilewidth, xml.@tileheight, 0, 0, 0 );
					
			group.children.addItem( mapLayer );
		}

	}

}