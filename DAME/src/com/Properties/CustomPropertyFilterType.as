package com.Properties 
{
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerImage;
	import com.Layers.LayerMap;
	import com.Layers.LayerPaths;
	import com.Layers.LayerShapes;
	import com.Layers.LayerSprites;
	import com.Tiles.SpriteEntry;
	import mx.collections.ArrayCollection;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class CustomPropertyFilterType extends CustomPropertyType
	{
		public static const FILTER_NONE:uint		= 0;
		public static const FILTER_TILEMAP:uint 	= 0x0001;
		public static const FILTER_SPRITELAYER:uint	= 0x0002;
		public static const FILTER_SHAPELAYER:uint	= 0x0004;
		public static const FILTER_PATHLAYER:uint	= 0x0008;
		public static const FILTER_IMAGELAYER:uint  = 0x0010;
		public static const FILTER_ALL_LAYERS:uint	= FILTER_TILEMAP & FILTER_SPRITELAYER & FILTER_SHAPELAYER & FILTER_PATHLAYER & FILTER_IMAGELAYER;
		public static const FILTER_GROUPS:uint		= 0x0020;
		public static const FILTER_SPRITES:uint 	= 0x0040;
		public static const FILTER_ALL:uint			= FILTER_ALL_LAYERS & FILTER_GROUPS;
		
		public var filters:uint = FILTER_GROUPS;
		public var pattern:String = "Level_%groupname%";
		public static const spriteNamePattern:String = "%spritename%";
		
		public function CustomPropertyFilterType( Name:String) 
		{
			super(Name);
		}
		
		public function ParseTypeList():void
		{
			var newList:ArrayCollection = new ArrayCollection;
			
			var isSprites:Boolean = (filters & FILTER_SPRITES) ? true : false;
			
			var groups:ArrayCollection = isSprites ? App.getApp().spriteData : App.getApp().layerGroups;
			
			if ( isSprites )
			{
				for each( var sprite:SpriteEntry in groups )
				{
					ParseSprite(sprite, newList);
				}
			}
			else
			{
				for each( var layer:LayerEntry in groups )
				{
					ParseLayer(layer, newList);
				}
			}
			_list = newList;
		}
		
		private function ParseSprite( sprite:SpriteEntry, newList:ArrayCollection ):void
		{
			if ( sprite.children )
			{
				for each( var sprite:SpriteEntry in sprite.children )
				{
					ParseSprite(sprite, newList);
				}
			}
			else
			{
				var label:String = ReplaceKeyword(pattern, "%spritename%", sprite.name );
				var value:CustomPropertyValue = null;
				// Only create a new value if there wasn't already an entry pointing to the same data.
				if ( _list )
				{
					var index:int = indexOfData(sprite);
					if ( index != -1 )
					{
						value = _list[index];
						value.label = label;
					}
				}
				if ( value == null )
				{
					value = new CustomPropertyValue(label );
					value.data = sprite;
				}
				
				newList.addItem( value );
			}
		}
		
		private function ParseLayer( layer:LayerEntry, newList:ArrayCollection ):void
		{
			var group:LayerGroup = layer as LayerGroup;
			
			var label:String = pattern;
			
			var valid:Boolean = false;
				
			if ( filters & FILTER_GROUPS )
			{
				var name:String = "";
				if ( group )
					name = group.name;
				else if ( layer.parent )
					name = layer.parent.name;
				label = ReplaceKeyword(label, "%groupname%", name );
				valid = valid || (group!=null);
			}
			else
			{
				label = ReplaceKeyword(label, "%groupname%", layer.parent ? layer.parent.name : "" );
			}

			if ( filters & FILTER_ALL_LAYERS )
			{
				label = ReplaceKeyword(label, "%layername%", group ? "" : layer.name );
				label = ReplaceKeyword(label, "%name%", layer.name );
				valid = true;
			}
			else
			{
				var validForLayer:Boolean = false;
				if ( filters & FILTER_TILEMAP )
				{
					validForLayer = validForLayer || (layer is LayerMap);
				}
				if ( filters & FILTER_SPRITELAYER )
				{
					validForLayer = validForLayer || (layer is LayerSprites);
				}
				if ( filters & FILTER_SHAPELAYER )
				{
					validForLayer = validForLayer || (layer is LayerShapes);
				}
				if ( filters & FILTER_PATHLAYER )
				{
					validForLayer = validForLayer || (layer is LayerPaths);
				}
				if ( filters & FILTER_IMAGELAYER )
				{
					validForLayer = validForLayer || (layer is LayerImage);
				}
				label = ReplaceKeyword(label, "%layername%", validForLayer ? layer.name : "" );
				label = ReplaceKeyword(label, "%name%", validForLayer ? layer.name : "" );
				valid = valid || validForLayer;
			}

			if ( group )
			{
				for each( var childLayer:LayerEntry in group.children )
				{
					ParseLayer(childLayer, newList);
				}
			}
			
			if ( valid )
			{
				var value:CustomPropertyValue = null;
				// Only create a new value if there wasn't already an entry pointing to the same data.
				if ( _list )
				{
					var index:int = indexOfData(layer);
					if ( index != -1 )
					{
						value = _list[index];
						value.label = label;
					}
				}
				if ( value == null )
				{
					value = new CustomPropertyValue(label );
					value.data = layer;
				}
				
				newList.addItem( value );
			}
		}
		
		private function ReplaceKeyword( source:String, keyword:String, replaceText:String):String
		{
			while (source.indexOf(keyword) != -1)
			{  
				source = source.replace(keyword, replaceText );  
			}
			return source;
		}
		
		override public function Save(parentXml:XML):void
		{
			var typeXml:XML = <type name={name} isString={isString} exportedType={ExportedType} pattern={pattern} filter={"0x" + filters.toString(16)}/>;
			parentXml.appendChild(typeXml);
			
			ParseTypeList();
			
			SaveValueList(typeXml);
		}
		
		override public function Load(typeXml:XML):void
		{
			isString = typeXml.@isString == true;
			ExportedType = String(typeXml.@exportedType);
			pattern = String(typeXml.@pattern);
			filters = uint(typeXml.@filter);
			
			LoadValueList(typeXml);
			
			// The data must be converted from layer id to layer reference once all the layers are loaded...
		}
		
		public function ConvertDataRefs():void
		{
			var isSprites:Boolean = (filters & FILTER_SPRITES) ? true : false;
			var groups:ArrayCollection;
			
			if ( isSprites )
			{
				groups = App.getApp().spriteData;
				for (var i:uint = 0; i < _list.length; i++ )
				{
					var value:CustomPropertyValue = _list[i] as CustomPropertyValue;
					for each( var sprite:SpriteEntry in groups )
					{
						ConvertSpriteDataRefs( sprite, value )
					}
				}
			}
			else
			{
				groups = App.getApp().layerGroups;
				for (i = 0; i < _list.length; i++ )
				{
					value = _list[i] as CustomPropertyValue;
					
					for each( var group:LayerEntry in groups )
					{
						if ( uint(value.data) == group.id )
						{
							value.data = group;
						}
						else
						{
							for each( var layer:LayerEntry in group.children )
							{
								if ( uint(value.data) == layer.id )
								{
									value.data = layer;
								}
							}
						}
					}
				}
			}
		}
		
		private function ConvertSpriteDataRefs( sprite:SpriteEntry, value:CustomPropertyValue ):void
		{
			if ( sprite.children )
			{
				for each( var sprite:SpriteEntry in sprite.children )
				{
					ConvertSpriteDataRefs(sprite, value);
				}
			}
			else
			{
				if ( uint(value.data) == sprite.id )
				{
					value.data = sprite;
				}
			}
		}
		
	}

}