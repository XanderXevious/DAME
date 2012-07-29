package org.flixel.data
{
	import flash.events.KeyboardEvent;
	
	public class FlxInput
	{
		/**
		 * @private
		 */
		internal var _lookup:Object;
		/**
		 * @private
		 */
		internal var _map:Array;
		/**
		 * @private
		 */
		internal const _t:uint = 256;
		
		private const REGISTERED_PRESS:int = 4;
		private const PRESSED_NOW:int = 1;
		private const HELD_DOWN:int = 2;
		private const HELD_DOWN_LAST_FRAME:int = 3;
		private const JUST_RELEASED:int = -1;
		
		/**
		 * Constructor
		 */
		public function FlxInput()
		{
			_lookup = new Object();
			_map = new Array(_t);
		}
		
		/**
		 * Updates the key states (for tracking just pressed, just released, etc).
		 */
		public function update():void
		{
			var i:uint = 0;
			while(i < _t)
			{
				var o:Object = _map[i++];
				if (o == null || !o.current)
					continue;
				if ( o.current == REGISTERED_PRESS )
				{
					o.current = PRESSED_NOW;
				}
				if ((o.last == JUST_RELEASED) && (o.current == JUST_RELEASED))
				{
					o.current = 0;
				}
				else if ((o.last == PRESSED_NOW) && (o.current == PRESSED_NOW))
					o.current = HELD_DOWN;
				/*else if ((o.last == HELD_DOWN) && (o.current == HELD_DOWN))
				{
					// KeyUp isn't 100% reliable if window focus changes so if no keypress this frame
					// then assume the key was released (or at least about to be released).
					o.current = HELD_DOWN_LAST_FRAME;
				}
				else if ( o.current == HELD_DOWN_LAST_FRAME )
				{
					this[o.name] = false;
					o.current = JUST_RELEASED;
				}*/
				o.last = o.current;
			}
		}
		
		/**
		 * Resets all the keys.
		 */
		public function reset():void
		{
			var i:uint = 0;
			while(i < _t)
			{
				var o:Object = _map[i++];
				if (o == null)
					continue;
				this[o.name] = false;
				o.current = 0;
				o.last = 0;
			}
		}
		
		/**
		 * Check to see if this key is pressed.
		 * 
		 * @param	Key		One of the key constants listed above (e.g. "LEFT" or "A").
		 * 
		 * @return	Whether the key is pressed
		 */
		public function pressed(Key:String):Boolean { return this[Key]; }
		
		/**
		 * Check to see if this key was just pressed.
		 * 
		 * @param	Key		One of the key constants listed above (e.g. "LEFT" or "A").
		 * 
		 * @return	Whether the key was just pressed
		 */
		public function justPressed(Key:String):Boolean { return _map[_lookup[Key]].current == PRESSED_NOW; }
		
		/**
		 * Check to see if this key is just released.
		 * 
		 * @param	Key		One of the key constants listed above (e.g. "LEFT" or "A").
		 * 
		 * @return	Whether the key is just released.
		 */
		public function justReleased(Key:String):Boolean { return _map[_lookup[Key]].current == JUST_RELEASED; }
		
		/**
		 * Event handler so FlxGame can toggle keys.
		 * 
		 * @param	event	A <code>KeyboardEvent</code> object.
		 */
		public function handleKeyDown(event:KeyboardEvent):void
		{
			var o:Object = _map[event.keyCode];
			if (o == null)
				return;
			if (o.current > 0)
				o.current = HELD_DOWN;	// held down.
			else 
				o.current = REGISTERED_PRESS;	// just pressed
			this[o.name] = true;
		}
		
		/**
		 * Event handler so FlxGame can toggle keys.
		 * 
		 * @param	event	A <code>KeyboardEvent</code> object.
		 */
		public function handleKeyUp(event:KeyboardEvent):void
		{
			var o:Object = _map[event.keyCode];
			if (o == null)
				return;
			if (o.current > 0)
				o.current = JUST_RELEASED;
			else
				o.current = 0;
			this[o.name] = false;
		}
		
		/**
		 * An internal helper function used to build the key array.
		 * 
		 * @param	KeyName		String name of the key (e.g. "LEFT" or "A")
		 * @param	KeyCode		The numeric Flash code for this key.
		 */
		internal function addKey(KeyName:String,KeyCode:uint):void
		{
			_lookup[KeyName] = KeyCode;
			_map[KeyCode] = { name: KeyName, current: 0, last: 0 };
		}
	}
}
