package com.Utils.DebugDrawShapes 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author ...
	 */
	public class DebugDrawShapeArrow extends DebugDrawShape 
	{
		public var thickness:uint;
		
		public function DebugDrawShapeArrow(fromX:Number,fromY:Number,toX:Number,toY:Number,ScrollFactor:FlxPoint,Colour:uint,Thickness:uint)
		{
			super(fromX, fromY, toX, toY, ScrollFactor, Colour, false, true, false);
			thickness = Thickness;
		}
		
		public function CreateArrow(fromX:Number,fromY:Number,toX:Number,toY:Number,ScrollFactor:FlxPoint,Colour:uint,Thickness:uint):void
		{
			Create(fromX, fromY, toX, toY, ScrollFactor, Colour, false, true, false);
			thickness = Thickness;
		}
		
		override protected function RenderShape( screenPos:FlxPoint, drawManually:Boolean, shape:Shape ):Boolean
		{
			var sx1:int = screenPos.x + x1;
			var sy1:int = screenPos.y + y1;
			var sx2:int = screenPos.x + x2;
			var sy2:int = screenPos.y + y2;
			var wid:Number = x2 - x1;
			var ht:Number = y2 - y1;
			
			if ( drawManually )
			{
				// No current version for manual arrows...
			}
			else
			{
				var dir:Point = new Point(wid, ht);
				var normalR:Point = new Point( -dir.y, dir.x );
				normalR.normalize(thickness);
				var normalL:Point = new Point( dir.y, -dir.x );
				normalL.normalize(thickness);
				dir.normalize(thickness);
				var startPos:Point = new Point( sx2 - dir.x, sy2 - dir.y );
				var gfx:Graphics = shape.graphics;
				gfx.beginFill(colour << 8,alpha);
				gfx.moveTo(sx2, sy2);
				gfx.lineTo(startPos.x + normalL.x, startPos.y + normalL.y);
				gfx.lineTo(startPos.x + normalR.x, startPos.y + normalR.y);
				gfx.lineTo(sx2, sy2);
				gfx.endFill();
				return true;
			}
			return false;
		}
		
	}

}