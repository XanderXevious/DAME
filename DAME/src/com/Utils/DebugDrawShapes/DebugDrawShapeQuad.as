package com.Utils.DebugDrawShapes 
{
	import com.EditorState;
	import com.Utils.DebugDraw;
	import com.Utils.Misc;
	import flash.display.Graphics;
	import flash.display.Shape;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author ...
	 */
	public class DebugDrawShapeQuad extends DebugDrawShape 
	{
		public var showHandles:Boolean;
		public var filled:Boolean;
		public var x3:Number;
		public var y3:Number;
		public var x4:Number;
		public var y4:Number;
		public var fillColour:uint;
		
		public function DebugDrawShapeQuad(X1:Number,Y1:Number,X2:Number,Y2:Number,X3:Number,Y3:Number,X4:Number,Y4:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean,ShowHandles:Boolean,Filled:Boolean,FillColour:uint) 
		{
			super(X1, Y1, X2, Y2, ScrollFactor, Colour, Stepped, UseShapes, Invert);
			x3 = X3;
			y3 = Y3;
			x4 = X4;
			y4 = Y4;
			showHandles = ShowHandles;
			filled = Filled;
			fillColour = FillColour
		}
		
		public function CreateQuad(X1:Number,Y1:Number,X2:Number,Y2:Number,X3:Number,Y3:Number,X4:Number,Y4:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean,ShowHandles:Boolean,Filled:Boolean,FillColour:uint):void
		{
			Create(X1, Y1, X2, Y2, ScrollFactor, Colour, Stepped, UseShapes, Invert);
			x3 = X3;
			y3 = Y3;
			x4 = X4;
			y4 = Y4;
			showHandles = ShowHandles;
			filled = Filled;
			fillColour = FillColour
		}
		
		override protected function RenderShape( screenPos:FlxPoint, drawManually:Boolean, shape:Shape ):Boolean
		{
			var sx1:int = screenPos.x + x1;
			var sy1:int = screenPos.y + y1;
			var sx2:int = screenPos.x + x2;
			var sy2:int = screenPos.y + y2;
			
			if ( drawManually )
			{
				if ( showHandles )
				{
					pt1.x = sx1;
					pt1.y = sy1;
					pt2.x = sx2;
					pt2.y = sy2;
				}
				pt3.x = screenPos.x + x3;
				pt3.y = screenPos.y + y3;
				pt4.x = screenPos.x + x4;
				pt4.y = screenPos.y + y4;
				if ( stepped )
				{
					Misc.DrawCustomLine( sx1, sy1, sx2, sy2, EditorState.DrawSteppedPixelsOnBufferCallback, true );
					Misc.DrawCustomLine( sx2, sy2, pt3.x, pt3.y, EditorState.DrawSteppedPixelsOnBufferCallback, false );
					Misc.DrawCustomLine( pt3.x, pt3.y, pt4.x, pt4.y, EditorState.DrawSteppedPixelsOnBufferCallback, true );
					Misc.DrawCustomLine( pt4.x, pt4.y, sx1, sy1, EditorState.DrawSteppedPixelsOnBufferCallback, false );
				}
				else
				{
					Misc.DrawCustomLine( sx1, sy1, sx2, sy2, EditorState.DrawOnBufferCallback, colour );
					Misc.DrawCustomLine( sx2, sy2, pt3.x, pt3.y, EditorState.DrawOnBufferCallback, colour );
					Misc.DrawCustomLine( pt3.x, pt3.y, pt4.x, pt4.y, EditorState.DrawOnBufferCallback, colour );
					Misc.DrawCustomLine( pt4.x, pt4.y, sx1, sy1, EditorState.DrawOnBufferCallback, colour );
				}
			}
			else
			{
				var gfx:Graphics = shape.graphics;
				if ( filled )
				{
					var fillalpha:uint = (fillColour >> 24)& 0xff;
					gfx.beginFill( fillColour, fillalpha / 255 );
				}
				gfx.moveTo(sx1, sy1);
				gfx.lineTo(sx2, sy2);
				gfx.lineTo(screenPos.x + x3, screenPos.y + y3);
				gfx.lineTo(screenPos.x + x4, screenPos.y + y4);
				gfx.lineTo(sx1, sy1);
				if ( filled )
					gfx.endFill();
			}
			
			if ( showHandles )
			{
				DrawComplexHandles( DebugDraw.singleton._s );
			}
			return !drawManually || showHandles;
		}
		
	}

}