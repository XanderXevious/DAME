package com.Utils.DebugDrawShapes 
{
	import com.Utils.Global;
	import flash.display.Shape;
	import flash.geom.Point;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author ...
	 */
	public class DebugDrawShape 
	{
		public var type:uint;
		public var x1:Number;
		public var y1:Number;
		public var x2:Number;
		public var y2:Number;
		public var scrollFactor:FlxPoint;
		public var colour:uint = 0xffffffff;
		public var stepped:Boolean = false;
		public var useShapes:Boolean = true;
		public var invert:Boolean = false;
		public var id:String = null;
		
		protected static var pt1:Point = new Point();
		protected static var pt2:Point = new Point();
		protected static var pt3:Point = new Point();
		protected static var pt4:Point = new Point();
		
		public static var noSteps:Boolean = false;
		public static var lineThickness:int = 1;
		
		protected var alpha:Number = 1;
		
		// Save this shape in the cache
		public var cache:Boolean = false;
		
		public function DebugDrawShape(X1:Number,Y1:Number,X2:Number,Y2:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean)
		{
			x1 = X1;
			y1 = Y1;
			x2 = X2;
			y2 = Y2;
			scrollFactor = ScrollFactor.copy();
			colour = Colour;
			stepped = Stepped;
			useShapes = UseShapes;
			invert = Invert;
			cache = false;
		}
		
		public function Create(X1:Number,Y1:Number,X2:Number,Y2:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean):void
		{
			x1 = X1;
			y1 = Y1;
			x2 = X2;
			y2 = Y2;
			scrollFactor.copyFrom(ScrollFactor)
			colour = Colour;
			stepped = Stepped;
			useShapes = UseShapes;
			invert = Invert;
			cache = false;
		}
		
		protected function DrawHandleAtLocation(x:int, y:int, shape:Shape):void
		{
			shape.graphics.beginFill(0x000000,0.6);
			shape.graphics.drawRect(x - 2, y - 2, 5, 5);
			shape.graphics.endFill();
			shape.graphics.beginFill(0xffffff);
			shape.graphics.drawRect(x - 1, y - 1, 3, 3);
			shape.graphics.endFill();
		}
		
		protected function RenderShape( screenPos:FlxPoint, drawManually:Boolean, shape:Shape ):Boolean
		{
			return false;
		}
		
		// Returns true if it drew a flash shape.
		public function Render( screenPos:FlxPoint, shape:Shape ):Boolean
		{
			var drawManually:Boolean = !( ( (stepped && noSteps) || (Global.UseFlashShapeRenderer || useShapes || lineThickness > 0) ) );
			
			if ( !drawManually )
			{
				alpha = ((colour >> 24) & 0xff) / 255;
				shape.graphics.lineStyle(lineThickness, colour, alpha);	
				return RenderShape(screenPos, false, shape );
			}
			else
			{
				// Draw shapes manually.
				return RenderShape(screenPos, true, shape );
			}
		}
		
		protected function DrawComplexHandles(shape:Shape):void
		{
			DrawHandleAtLocation(pt1.x, pt1.y, shape);
			DrawHandleAtLocation(pt2.x, pt2.y, shape);
			DrawHandleAtLocation(pt3.x, pt3.y, shape);
			DrawHandleAtLocation(pt4.x, pt4.y, shape);
			
			DrawHandleAtLocation(pt1.x + 0.5 * (pt2.x-pt1.x), pt1.y + 0.5 * (pt2.y-pt1.y), shape);
			DrawHandleAtLocation(pt2.x + 0.5 * (pt3.x-pt2.x), pt2.y + 0.5 * (pt3.y-pt2.y), shape);
			DrawHandleAtLocation(pt3.x + 0.5 * (pt4.x-pt3.x), pt3.y + 0.5 * (pt4.y-pt3.y), shape);
			DrawHandleAtLocation(pt4.x + 0.5 * (pt1.x-pt4.x), pt4.y + 0.5 * (pt1.y-pt4.y), shape);
		}
		
	}

}