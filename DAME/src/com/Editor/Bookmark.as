package com.Editor 
{
	import com.EditorState;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Bookmark
	{
		public var addMenu:NativeMenuItem;
		public var gotoMenu:NativeMenuItem;
		public var location:FlxPoint = null;
		
		public function Bookmark( ) 
		{
		}
		
		public function handleMenuShortcut(shiftPressed:Boolean ):void
		{
			if ( shiftPressed )
			{
				gotoBookmarkSelected(null);
			}
			else
			{
				addBookmarkSelected(null);
			}
		}
		
		public function addBookmarkSelected(event:Event):void
		{
			gotoMenu.enabled = true;
			location = new FlxPoint( FlxG.scroll.x, FlxG.scroll.y);
		}
		
		public function gotoBookmarkSelected(event:Event):void
		{
			if ( location && gotoMenu.enabled )
			{
				var editor:EditorState = FlxG.state as EditorState;
				editor.MoveCameraToLocationExact(location, 1, 1);
			}
		}
		
	}

}