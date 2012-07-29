package com
{
	import com.Game.GamePause;
	import com.UI.PopupWindowManager;
	import flash.events.Event;
	import flash.ui.Mouse;
	import org.flixel.FlxGame;
	import com.EditorState;
	import org.flixel.FlxG;
	
	
	
	[SWF(width = "800", height = "600", backgroundColor = "#000000")]
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class MainGame extends FlxGame
	{
		private var hasFocus:Boolean = true;
		
		static public var flxGame:MainGame = null;
		public function MainGame( maxWidth:Number, maxHeight:Number ):void
		{
			FlxG.canHideSystemCursor = false;
			flxGame = this;
			super(maxWidth, maxHeight, EditorState, 1);
			// Resize after as the constructor creates a load of stuff that takes up lots of mem like FlxFade and FlxFlash
			FlxG.width = 1600;
			FlxG.height = 1000;
			useDefaultHotKeys = false;
			pause = new GamePause();
			noConsole = true;
		}
		
		override protected function update(event:Event):void
		{
			if ( PopupWindowManager.GetTopModalWindow() != null )
			{
				super.onFocusLost(event);
			}
			if ( hasFocus )
			{
				super.update(event);
			}
		}
		
		// Override the onFocus handler so we can prevent flixel from hiding the mouse.
		override protected function onFocus(event:Event=null):void
		{
			hasFocus = true;
			if( event )
				super.onFocus(event);
			Mouse.show();
		}
		
		public function restoreFocus():void
		{
			hasFocus = true;
		}
		
		override protected function onMouseDown(event:Event = null):void
		{
			onFocus(event);
		}
		
		override protected function onFocusLost(event:Event=null):void
		{
			hasFocus = false;
			super.onFocusLost(event);
		}
		
		override public function showSoundTray(Silent:Boolean = false):void
		{
			// Do nothing. Disable the sound tray from ever showing.
		}
		
	}

}