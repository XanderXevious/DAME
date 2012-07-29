package com.Properties 
{
	import flash.events.ContextMenuEvent;
	import mx.collections.ArrayCollection;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class CustomPropertyType 
	{
		// list of CustomPropertyType
		[Bindable]
		public static var TypesProvider:ArrayCollection = new ArrayCollection();
		
		public var isString:Boolean = true;
		
		public static var currentExportedType:String = "int";
		private var exportedType:String = currentExportedType;
		public function set ExportedType(type:String):void
		{
			currentExportedType = exportedType = type;
		}
		
		public function get ExportedType():String
		{
			return exportedType;
		}
		
		protected var _list:ArrayCollection = null;
		
		public function get list():ArrayCollection
		{
			return _list;
		}
		
		public function set list(List:ArrayCollection):void
		{
			_list = List;
		}
		
		public var name:String;
		
		public var contextMenuCallback:Function = null;
		
		public function CustomPropertyType( Name:String ) 
		{
			_list = new ArrayCollection;
			name = Name;
		}
		
		public function ContextMenuItemSelected(event:ContextMenuEvent):void
		{
			if ( contextMenuCallback != null )
			{
				contextMenuCallback(this);
			}
		}
		
		public static function GetTypeByName(typeName:String):CustomPropertyType
		{
			for each( var type:CustomPropertyType in TypesProvider )
			{
				if ( type.name == typeName )
				{
					return type;
				}
			}
			return null;
		}
		
		public function indexOfData(data:Object):int
		{
			if ( _list != null && data != null )
			{
				var i:int = _list.length;
				while ( i-- )
				{
					var value:CustomPropertyValue = _list[i] as CustomPropertyValue;
					if ( value && value.data == data )
					{
						return i;
					}
				}
			}
			return -1;
		}
		
		public function indexOfLabel(label:String):int
		{
			if ( _list != null )
			{
				var i:int = _list.length;
				while ( i-- )
				{
					var value:CustomPropertyValue = _list[i] as CustomPropertyValue;
					if ( value && value.label == label )
					{
						return i;
					}
				}
			}
			return -1;
		}
		
		static public function SaveAll(parentXml:XML):void
		{
			var typesXml:XML = <customPropertyTypes/>;
			parentXml.appendChild(typesXml);
			
			for ( var i:uint = 0; i < TypesProvider.length; i++ )
			{
				var type:CustomPropertyType = TypesProvider[i] as CustomPropertyType;
				type.Save(typesXml);
			}
		}
		
		public function Save(parentXml:XML):void
		{
			var typeXml:XML = <type name={name} isString={isString} exportedType={ExportedType} />;
			parentXml.appendChild(typeXml);
			
			SaveValueList(typeXml);
		}
		
		protected function SaveValueList(parentXml:XML):void
		{
			if ( _list )
			{
				for ( var i:uint = 0; i < _list.length; i++ )
				{
					var value:CustomPropertyValue = _list[i] as CustomPropertyValue;
					value.Save(parentXml);
				}
			}
		}
		
		public static function LoadAll(parentXml:XML):void
		{
			var typesXml:XMLList = parentXml.customPropertyTypes;
			if ( typesXml)
			{
				if ( typesXml.type.length() )
				{
					for each( var typeXml:XML in typesXml[0].type )
					{
						if ( typeXml.hasOwnProperty("@filter") )
						{
							var filterType:CustomPropertyFilterType = new CustomPropertyFilterType(String(typeXml.@name));
							filterType.Load(typeXml);
							TypesProvider.addItem(filterType);
						}
						else
						{
							var type:CustomPropertyType = new CustomPropertyType(String(typeXml.@name));
							type.Load(typeXml);
							TypesProvider.addItem(type);
						}
					}
				}
			}
		}
		
		public function Load(typeXml:XML):void
		{
			isString = typeXml.@isString == true;
			ExportedType = String(typeXml.@exportedType);
			LoadValueList(typeXml);
		}
		
		public function LoadValueList(parentXml:XML):void
		{
			if ( parentXml.item && parentXml.item.length() )
			{
				_list = new ArrayCollection;
				for each( var itemXml:XML in parentXml.item )
				{
					var value:CustomPropertyValue = new CustomPropertyValue("");
					value.Load(itemXml);
					_list.addItem(value);
				}
			}
		}
		
		// Patch up data refs if neded. Must be done after all loading is finished.
		public static function ConvertDataRefs():void
		{
			for ( var i:uint = 0; i < TypesProvider.length; i++ )
			{
				var type:CustomPropertyFilterType = TypesProvider[i] as CustomPropertyFilterType;
				if ( type )
				{
					type.ConvertDataRefs();
				}
			}
		}
		
	}

}