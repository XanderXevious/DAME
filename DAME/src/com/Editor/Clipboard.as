package com.Editor 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Clipboard
	{
		static private var clipData:Object = null;
		
		static public function SetData( data:Object ):void
		{
			clipData = data;
		}
		
		static public function GetData():Object
		{
			return clipData;
		}
		
	}

}