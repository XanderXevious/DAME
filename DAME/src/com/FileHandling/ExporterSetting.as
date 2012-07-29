package com.FileHandling 
{
	/**
	 * Stores info about each setting within the current exporter.
	 * @author Charles Goatley
	 */
	public class ExporterSetting
	{
		public var name:String;
		public var value:String;
		
		public function ExporterSetting( _name:String, _value:String) 
		{
			name = _name;
			value = _value;
		}
		
	}

}