package com.Properties 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PropertyData extends PropertyBase
	{
		public var BaseProperty:PropertyType = null;
		override public function get Type():Class
		{
			if ( BaseProperty )
			{
				return BaseProperty.Type;
			}
			return null;
		}
		
		public var UsingDefaultValue:Boolean = true;
		
		private var value:Object = null;
		override public function set Value(_value:Object ):void
		{
			value = _value;
			UsingDefaultValue = ( value == BaseProperty.Value );
			
		}
		override public function get Value():Object
		{
			return ( UsingDefaultValue ? BaseProperty.Value : value ); 
		}
		
		override public function get Name():String
		{
			return BaseProperty.Name;
		}
		override public function set Name(_name:String): void
		{
			BaseProperty.Name = _name;
		}
		
		public function PropertyData( _base:PropertyType ) 
		{
			BaseProperty = _base;
		}
		
		override public function get Hidden():Boolean
		{
			return ( BaseProperty ? BaseProperty.Hidden : false ); 
		}
		
		/*override public function set Hidden(hide:Boolean): void
		{
			if ( BaseProperty )
			{
				BaseProperty.Hidden = hide;
			}
		}*/
		
		// If the cloned property persists for a long time there is no guarantee that the base property
		// still exists and hasn't been deleted. Will need to look for _base.Deleted.
		override public function Clone():PropertyBase
		{
			var newprop:PropertyData = new PropertyData(BaseProperty);
			newprop.Value = Value;
			return newprop;
		}
		
		override public function GetTypeObj():CustomPropertyType
		{
			if ( BaseProperty )
			{
				return BaseProperty.GetTypeObj();
			}
			return null;
		}
		
	}

}