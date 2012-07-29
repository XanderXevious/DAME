package com.UI 
{
	import com.UI.PopupWindow;
	import flash.display.NativeWindow;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PopupWindowManager
	{
		// List of popups that have no restrictions about visual hierarchy.
		private static var normalPopups:Vector.<PopupWindow> = new Vector.<PopupWindow>();
		// List of tool windows that must be above the main window but modeless.
		public static var toolPopups:Vector.<PopupWindow> = new Vector.<PopupWindow>();
		// List of modal popups - must be in front of everything
		private static var modalPopups:Vector.<PopupWindow> = new Vector.<PopupWindow>();
		
		public static const NORMAL:uint = 0;
		public static const TOOL:uint = 2;
		public static const MODAL:uint = 3;
		
		public static function RegisterPopup( popup:PopupWindow, type:int ):void
		{
			if ( type == NORMAL )
			{
				normalPopups.push( popup );
			}
			else if ( type == TOOL )
			{
				toolPopups.push( popup );
			}
			else if ( type == MODAL )
			{
				modalPopups.push( popup );
			}
			popup.addEventListener( Event.CLOSE, onPopupClosed, false, 0, true);
		}
		
		public static function UnregisterPopup( popup:PopupWindow ):void
		{
			var index:int;
			if ( ( index = normalPopups.indexOf(popup) ) != -1 )
			{
				normalPopups.splice(index, 1);
			}
			else if ( ( index = toolPopups.indexOf(popup) ) != -1 )
			{
				toolPopups.splice(index, 1);
			}
			else if ( ( index = modalPopups.indexOf(popup) ) != -1 )
			{
				modalPopups.splice(index, 1);
				var topWindow:PopupWindow = GetTopModalWindow();
				if ( topWindow )
				{
					topWindow.ReenforceModality();
				}
			}
			popup.removeEventListener( Event.CLOSE, onPopupClosed);
		}
		
		private static function onPopupClosed(event:Event):void
		{
			var popup:PopupWindow = event.target as PopupWindow;
			
			UnregisterPopup( popup );
		}
		
		public static function GetTopModalWindow():PopupWindow
		{
			if ( modalPopups.length == 0 )
			{
				return null;
			}
			return modalPopups[modalPopups.length - 1 ];
		}
		
		public static function GetModalWindowPriority( popup:PopupWindow):uint
		{
			var index:int = modalPopups.indexOf(popup);
			if ( index == -1 )
			{
				index = 0;
			}
			return index;
		}
		
		public static function RecenterAllWindows():void
		{
			for each( var popup:PopupWindow in normalPopups )
			{
				popup.CenterWindow();
			}
			
			for each( popup in toolPopups )
			{
				popup.CenterWindow();
			}
		}
		
	}

}