package com.Properties 
{
	import com.Layers.LayerEntry;
	import com.Tiles.SpriteEntry;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class CustomPropertyValue 
	{
		public var label:String;
		public var exported:String = "";
		public var data:Object = null;	// only used with metadata (eg. layer reference)
		
		public function CustomPropertyValue( Label:String ) 
		{
			label = Label;
		}
		
		public function Save(parentXml:XML):void
		{
			var itemXml:XML = <item label={label} exported={exported} />;
			
			if ( data )
			{
				var layer:LayerEntry = data as LayerEntry;
				if ( layer )
				{
					itemXml[ "@id" ] = layer.id;
				}
				else
				{
					var sprite:SpriteEntry = data as SpriteEntry;
					if ( sprite )
					{
						itemXml[ "@id" ] = sprite.id;
					}
				}
			}
			
			parentXml.appendChild(itemXml);
		}
		
		public function Load(itemXml:XML):void
		{
			label = String(itemXml.@label);
			exported = String(itemXml.@exported);
			if ( itemXml.hasOwnProperty("@id") )
			{
				data = uint(itemXml.@id);
			}
		}
		
	}

}