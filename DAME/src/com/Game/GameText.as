package com.Game 
{
	import flash.text.TextFormat;
	import org.flixel.FlxText;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class GameText extends FlxText
	{
		
		public function GameText(X:Number, Y:Number, Width:uint, Text:String=null, EmbeddedFont:Boolean=true)
		{
			super(X, Y, Width, Text, EmbeddedFont);
		}
		
		public function Resize(Width:Number, Height:Number ):void
		{
			width = _tf.width = Width;
			height = _tf.height = Height;
			_regen = true;
			calcFrame();
		}
		
		public function Regen():void
		{
			_regen = true;
		}
		
		public function getTextFormat():TextFormat
		{
			return _tf.getTextFormat();
		}
		
		override public function setFormat(Font:String=null,Size:Number=8,Color:uint=0xffffff,Alignment:String=null,ShadowColor:uint=0):FlxText
		{
			if (Font == "system" || Font == null || Font == "" )
			{
				Font = "system";
				this._tf.embedFonts = true;
			}
			else
			{
				this._tf.embedFonts = false;
			}
			return super.setFormat(Font,Size,Color,Alignment,ShadowColor);
		}
		
	}

}