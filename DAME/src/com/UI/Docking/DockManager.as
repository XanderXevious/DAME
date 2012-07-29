package com.UI.Docking 
{
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.geom.Point;
	import mx.events.FlexEvent;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class DockManager
	{
		private var m_docks:Vector.<DockData> = new Vector.<DockData>;
		
		public function DockManager() 
		{
		}
		
		public function RegisterDock( dock:DockablePage ):void
		{
			m_docks.push( new DockData( dock ) );
		}
		
		public function UnregisterDock( dock:DockablePage ):void
		{
			var index:int = m_docks.indexOf( dock );
			if ( index > -1 )
			{
				m_docks.splice( index, 1 );
			}
		}
		
		public function FindDockAtLocation( screenX:int, screenY:int, currentDock:DockablePage, checkMainStage:Boolean = false ):DockInfo
		{
			var i:int = m_docks.length;
			var mainStage:Stage = App.getApp().stage;
			while ( i-- )
			{
				var dock:DockablePage = m_docks[i].m_dock;
				// prioritise the popup windows over the main stage as they're likely to be above the main stage.
				// Unfortunately Air doesn't give us a way of finding out the current display order of the windows.
				if ( !checkMainStage )
				{
					if( dock.stage == mainStage )
						continue;
				}
				else if ( dock.stage != mainStage )
					continue;
					
				if ( dock.CanDockInto() && dock != currentDock )
				{
					if ( Misc.IsPosOverObject( dock.dockTopBmp, screenX, screenY ) )
					{
						return new DockInfo(dock, DockablePage.TOP );
					}
					else if ( Misc.IsPosOverObject( dock.dockBottomBmp, screenX, screenY ) )
					{
						return new DockInfo(dock, DockablePage.BOTTOM );
					}
					else if ( Misc.IsPosOverObject( dock.dockLeftBmp, screenX, screenY ) )
					{
						return new DockInfo(dock, DockablePage.LEFT );
					}
					else if ( Misc.IsPosOverObject( dock.dockRightBmp, screenX, screenY ) )
					{
						return new DockInfo(dock, DockablePage.RIGHT );
					}
					else if ( dock.AllowCenterDock && Misc.IsPosOverObject( dock.dockCenterBmp, screenX, screenY ) )
					{
						return new DockInfo(dock, DockablePage.CENTER );
					}
					else if ( Misc.IsPosOverObject( dock, screenX, screenY ) )
					{
						return new DockInfo( dock, DockablePage.AREA );
					}
				}
			}
			if ( !checkMainStage )
				return FindDockAtLocation(screenX, screenY, currentDock, true );
			return null;
		}
		
		public static function CreateWindow( contents:DisplayObject, title:String ):DockableWindow
		{
			var window:DockableWindow = App.CreatePopupWindow(DockableWindow, false) as DockableWindow;
			window.title = title;
			if ( contents is DockablePage )
			{
				window.container.addChild( contents );
			}
			else
			{
				var dock:DockablePage = new DockablePage();
				dock.addChild(contents);
				contents.visible = true;
				window.container.addChild( dock );
				dock.percentHeight = 100;
				dock.percentWidth = 100;
			}
			return window;
		}
		
	}

}

import com.UI.Docking.*;

internal class DockData
{
	public var m_dock:DockablePage;
	
	public function DockData( dock:DockablePage )
	{
		m_dock = dock;
	}
}