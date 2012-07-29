package com.Game.SpriteFrames 
{
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpriteShapeData extends FlxPoint
	{
		public var radius:int = 0;
		public var width:int = 0;
		public var height:int = 0;
		public var name:String = "";
		
		public static const SHAPE_POINT:uint = 0;
		public static const SHAPE_BOX:uint = 1;
		public static const SHAPE_CIRCLE:uint = 2;
		public static const SHAPE_LINE:uint = 3;
		
		public var type:uint = SHAPE_POINT;
		
		public function SpriteShapeData() 
		{
			
		}
		
		public function CopyFrom( other:SpriteShapeData ):void
		{
			radius = other.radius;
			width = other.width;
			height = other.height;
			name = other.name;
			type = other.type;
		}
		
	}

}