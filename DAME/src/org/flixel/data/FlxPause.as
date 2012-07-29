package org.flixel.data
{
	import org.flixel.*;

	/**
	 * This is the default flixel pause screen.
	 * It can be overridden with your own <code>FlxLayer</code> object.
	 */
	public class FlxPause extends FlxGroup
	{
		/**
		 * Constructor.
		 */
		public function FlxPause()
		{
			super();
			scrollFactor.x = 0;
			scrollFactor.y = 0;
			var w:uint = 80;
			var h:uint = 92;
			x = (FlxG.width-w)/2;
			y = (FlxG.height-h)/2;
		}
	}
}