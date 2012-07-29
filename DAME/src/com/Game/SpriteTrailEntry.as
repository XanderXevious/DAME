package com.Game 
{
	import com.Tiles.SpriteEntry;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpriteTrailEntry
	{
		public var sprite:SpriteEntry;
		public var frame:int = 0;
		public var offset:FlxPoint = null;
		public var dims:FlxPoint = null;
		public var anchor:FlxPoint = null;
		
		public function SpriteTrailEntry( spriteEntry:SpriteEntry ) 
		{
			sprite = spriteEntry;
		}
		
	}

}