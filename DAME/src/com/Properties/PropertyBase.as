package com.Properties 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PropertyBase
	{
		// Used when sharing multiple object's properties, to know when one haas changed which ones to update.
		// Doesn't need to be saved as only temporary.
		public var sharedId:uint = 0;
		
		public function get Type():Class
		{
			return null;
		}
		
		public function set Value(_value:Object ):void
		{
		}
		
		public function get Value():Object
		{
			return null; 
		}
		
		public function set TextValue(_value:Object ):void
		{
			Value = _value;
		}
		
		public function get TextValue():Object
		{
			var typeValue:CustomPropertyValue = Value as CustomPropertyValue;
			if ( typeValue )
			{
				return typeValue.label;
			}
			return Value;
		}
		
		public function get ExportedValue():Object
		{
			var typeValue:CustomPropertyValue = Value as CustomPropertyValue;
			if ( typeValue )
			{
				return typeValue.exported.length ? typeValue.exported : typeValue.label;
			}
			return Value;
		}
		
		public function get Name():String
		{
			return "";
		}
		
		public function set Name(_name:String): void
		{
		}
		
		public function get Hidden():Boolean
		{
			return false;
		}
		
		public function set Hidden(hide:Boolean): void
		{
		}
		
		public function PropertyBase() 
		{
			
		}
		
		public function Clone():PropertyBase
		{
			return null;
		}
		
		public function GetTypeObj():CustomPropertyType
		{
			return null;
		}
		
		public function IsAStringType():Boolean
		{
			if ( Type == String )
				return true;
			var customType:CustomPropertyType = GetTypeObj();
			return ( customType && customType.isString );
		}
		
	}

}