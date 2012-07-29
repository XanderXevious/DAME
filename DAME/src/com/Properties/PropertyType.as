package com.Properties 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PropertyType extends PropertyBase
	{
		public var name:String = "";
		public var value:Object = null;
		// Base Property will be set if this Property inherits from another. I.e. the base is the default.
		public var Deleted:Boolean = false;
		public var hidden:Boolean = false;
		protected var type:Class;
		// TypeObj - e.g. used to point to a customPropertyType
		protected var typeObj:CustomPropertyType = null;
		
		override public function get Type():Class { return type; }
		
		override public function set Value(_value:Object ):void
		{
			value = _value;
		}
		
		override public function get Value():Object
		{
			return value; 
		}
		
		override public function set Name(_name:String): void
		{
			name = _name;
		}
		
		override public function get Name():String
		{
			return name;
		}
		
		override public function get Hidden():Boolean
		{
			return hidden;
		}
		
		override public function set Hidden(hide:Boolean): void
		{
			hidden = hide;
		}
		
		public function PropertyType( _type:Class, _name:String, _value:Object, _typeObj:CustomPropertyType = null ) 
		{
			type = _type;
			name = _name;
			value = _value;
			if ( _typeObj != null )
			{
				typeObj = _typeObj;
			}
		}
		
		override public function Clone():PropertyBase
		{
			return new PropertyType(type, name, value, typeObj );
		}
		
		override public function GetTypeObj():CustomPropertyType
		{
			return typeObj;
		}
		
	}

}