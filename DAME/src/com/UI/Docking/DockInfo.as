package com.UI.Docking 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class DockInfo
	{
		public var m_dock:DockablePage;
		public var m_location:String;
		
		public function DockInfo( dock:DockablePage, location:String = "center" ) 
		{
			m_dock = dock;
			m_location = location;
		}
		
	}

}