package com.UI 
{
	/**
	 * ...
	 * http://flexscript.wordpress.com/2008/07/24/flex-image-repeating-canvas-container/
	 */
	
	/*
		The ImageRepeatCanvas provides a container in which
		embeded images can be repeated
		as designers do in html tables.
	*/
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import mx.containers.Canvas;

	/**
	 *  The ImageRepeatCanvas container gives a way of creating
	 * one image that repeat
	 *  across either directions.
	 *
	 *  @mxml
	 *
	 *
<pre>
	 *  <namespace:ImageRepeatCanvas
	 *       repeatImage="{EmbededImage Class Reference}"
	 *       repeatDirection="horizantal|horizantal"
	 *    />
	 *</pre>
*/

	public class ImageRepeatCanvas extends Canvas
	{
		//-------------------------------------------------------------
	    //  Variables
	    //-------------------------------------------------------------
		private var bgImg:Bitmap = new Bitmap();
		private var direction:String;
		public var repeatImage:Class;

		//--------------------------------------------------------------
	    //  Constants
	    //--------------------------------------------------------------
		public static var REPEAT_HORIZONTAL:String = "horizontal";
		public static var REPEAT_VERTICAL:String = "vertical";
		public static var REPEAT_BOTH:String = "both";

	    //---------------------------------------------------------------
	    //  Constructor
	    //---------------------------------------------------------------
		public function ImageRepeatCanvas()
		{
			super();

		}

		/**
	     *  A setter method to set the direction for repeation of image
	     */
		[Inspectable(category="General", enumeration="horizontal,vertical,both", defaultValue="both")]
		public function set repeatDirection(val:String):void
		{
			direction = val;
		}
		
		private var _active:Boolean = true;
		public function get active():Boolean { return _active; }
		public function set active(val:Boolean):void
		{
			_active = val;
			invalidateDisplayList();
		}
		private var _overrideColor:uint = 0xffffff;
		public function get overrideColor():uint { return _overrideColor; }
		public function set overrideColor(col:uint):void
		{
			_overrideColor = col;
			invalidateDisplayList();
		}

		/**
	     *  @private
	     */
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			if ( !_active )
			{
				graphics.clear();
				graphics.beginFill(_overrideColor, 1);
				graphics.drawRect(0, 0, w, h);
				graphics.endFill();
				
				return;
			}
			bgImg.bitmapData = new repeatImage().bitmapData;
			if (bgImg)
			{
				switch(direction)
				{
					case ImageRepeatCanvas.REPEAT_HORIZONTAL:
									h = bgImg.height;
									break;
					case ImageRepeatCanvas.REPEAT_VERTICAL:
									w = bgImg.width;
									break;
					case ImageRepeatCanvas.REPEAT_BOTH:
									break;
				}
				var Grpx:Graphics = graphics;
				Grpx.clear();

				Grpx.beginBitmapFill(new repeatImage().bitmapData);
				drawRoundRect(0,0,w,h);
				Grpx.endFill();
			}
		}
	}
}