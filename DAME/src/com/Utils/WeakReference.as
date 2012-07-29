package com.Utils 
{
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	
	// To clear a reference object set it to undefined, not null.
	// Eg.
	// ref = new WeakReference(foo);
	// ref = null; // will not remove the reference.
	// ref = undefined;	// that will do it and getObject should return null.
	
	public class WeakReference
	{ 
		private var reference:Dictionary = new Dictionary(true);

		public function WeakReference(object:Object)
		{
			reference[object] = null;
		}

		public function getObject():Object
		{
			for (var object:Object in reference)
				return object;

			return null;
		}
	}


}