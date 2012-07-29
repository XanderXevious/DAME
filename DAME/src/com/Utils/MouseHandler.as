package com.Utils 
{
	import flash.events.MouseEvent;
	import flash.events.Event;
	import com.MainGame;
	import org.flixel.FlxPoint;
	import org.flixel.FlxG;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class MouseHandler
	{
		static public const LEFT:uint = 1;
		static public const MIDDLE:uint = 2;
		static public const RIGHT:uint = 3;
		
		private var _mouseDown:Boolean = false;
		public function get mouseDown():Boolean { return _mouseDown; }
		
		private var _mouseOffStage:Boolean = false;
		public function get mouseOnStage():Boolean { return !_mouseOffStage; }
		
		private var _mouseButton:uint;
		private var _mouseUpEvent:String;
		
		private var _mousePressedPos:FlxPoint = new FlxPoint(0, 0);
		public function get mousePressedPos():FlxPoint { return _mousePressedPos; }
		
		private var _mouseDownCallback:Function;
		private var _mouseUpCallback:Function;
		
		public function MouseHandler( mouseButton:uint = LEFT, mouseDownCallback:Function = null, mouseUpCallback:Function = null ) 
		{
			_mouseButton = mouseButton;
			_mouseDownCallback = mouseDownCallback;
			_mouseUpCallback = mouseUpCallback;
			
			switch( _mouseButton )
			{
				case LEFT:
				_mouseUpEvent = MouseEvent.MOUSE_UP;
				MainGame.flxGame.addEventListener(MouseEvent.MOUSE_DOWN, mousePressed );
				break;
				
				case MIDDLE:
				_mouseUpEvent = MouseEvent.MIDDLE_MOUSE_UP;
				MainGame.flxGame.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, mousePressed );
				break;
				
				case RIGHT:
				// The right mouse events don't handle stage exit as well, so need to be dealt with differently.
				// With flash there is no way to detect if the RIGHT mouse is released off stage.
				_mouseUpEvent = MouseEvent.RIGHT_MOUSE_UP;
				MainGame.flxGame.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMousePressed );
				break;
			}
			
			
		}
			
		private function stopDrag():void
		{
			if ( _mouseUpCallback != null )
			{
				_mouseUpCallback();
			}
			MainGame.flxGame.stage.removeEventListener(Event.MOUSE_LEAVE, mouseLeave);
			MainGame.flxGame.stage.removeEventListener(_mouseUpEvent, mouseUp);
			MainGame.flxGame.stage.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			MainGame.flxGame.stage.removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			_mouseDown = false;
		}
		
		private function mousePressed(event:MouseEvent):void
		{
			//trace("mouse down");
			if ( _mouseDownCallback != null)
			{
				_mouseDownCallback();
			}
			MainGame.flxGame.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
			MainGame.flxGame.stage.addEventListener(_mouseUpEvent, mouseUp);
			MainGame.flxGame.stage.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			MainGame.flxGame.stage.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			
			_mousePressedPos.create_from_points(event.stageX, event.stageY );
			
			
			_mouseDown = true;
		}
		
		private function rightMousePressed(event:MouseEvent):void
		{
			_mouseDown = true;
			if ( _mouseDownCallback != null)
			{
				_mouseDownCallback();
			}
			MainGame.flxGame.stage.addEventListener(_mouseUpEvent, mouseUp);
		}
		
		private function mouseUp(e:MouseEvent) :void
		{
			//trace("Mouse Up On Stage")
			stopDrag()
		}
		
		private function rmouseUp(e:MouseEvent) :void
		{
			//trace("RIGHT Mouse Up On Stage")
			stopDrag()
		}

		private function mouseLeave(e:Event) :void
		{
			if (_mouseOffStage)
			{
				//trace("mouse up and off stage");
				stopDrag();
			}
			else
			{
				//trace("mouse has left the stage1");
				//no reason to stop drag here as the user hasn't released the mouse yet
			}
		}

		private function mouseOut(e:MouseEvent) :void
		{
			_mouseOffStage = true;
			//trace("mouse has left the stage2")
		}

		private function mouseOver(e:MouseEvent) :void
		{
			_mouseOffStage = false;
			//trace("mouse has come back on stage");
		}
		
	}

}