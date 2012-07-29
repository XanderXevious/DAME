package com.Utils 
{
	import flash.utils.Dictionary;
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    public class OrderedHash extends Proxy
    {
        private var _props:Array = new Array();
        private var _values:Dictionary = new Dictionary();
		
		public var isUInt:Boolean = true;
        
        public function OrderedHash()
        {
            super();
        }
/**
 * Proxy overrides
 */
        
        flash_proxy override function deleteProperty(name:*):Boolean
        {
            var i:int = _props.indexOf(name.localName);
            
            if(i < 0) return false;
            
            _props.splice(i,1);
            delete _values[name];
            
            return true;
        }
        
        
        flash_proxy override function getProperty(name:*):*
        {
            return _values[name];
        }
        
        flash_proxy override function hasProperty(name:*):Boolean
        {
            return _props.indexOf(name.localName) >= 0;
        }
        
        
        flash_proxy override function nextName(index:int):String
        {
            return _props[index - 1];
        }
        
        flash_proxy override function nextNameIndex(index:int):int
        {
            if(index < _props.length) return index + 1;
            else return 0;
        }
        
        flash_proxy override function nextValue(index:int):*
        {
            return _values[ _props[index - 1] ];
        }
		
		private function sortOnUInt(a:uint, b:uint):Number
		{
			if(a > b)
				return 1;
			else if(a < b)
				return -1;
			else //a == b
				return 0;
		}

        
        flash_proxy override function setProperty(name:*, value:*):void
        {
            if (_props.indexOf(name) < 0)
			{
				_props.push(name);
				if( isUInt )
					_props.sort(sortOnUInt);
				else
					_props.sort();
			}
            
            _values[name] = value;
        }
    }


}