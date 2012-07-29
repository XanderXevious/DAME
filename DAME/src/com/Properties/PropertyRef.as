package com.Properties 
{
	/**
	 * PropertyRef - just used for the UI to reference the original property.
	 * @author Charles Goatley
	 */
	public class PropertyRef extends PropertyType
	{
		public var refProperty:PropertyType = null;
		
		public function PropertyRef( _type:Class, _name:String, _value:Object, typeObj:CustomPropertyType = null ) 
		{
			super(_type, _name, _value, typeObj);
		}
		
		override public function Clone():PropertyBase
		{
			var newprop:PropertyRef = new PropertyRef(Type, Name, Value, typeObj);
			newprop.refProperty = refProperty;
			newprop.Hidden = Hidden;
			return newprop;
		}
		
	}

}