package com.Utils.DebugDrawShapes 
{
	import com.EditorState;
	import com.Utils.Misc;
	import flash.display.Shape;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author ...
	 */
	public class DebugDrawShapeLine extends DebugDrawShape
	{
		
		public function DebugDrawShapeLine(X1:Number,Y1:Number,X2:Number,Y2:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean) 
		{
			super(X1, Y1, X2, Y2, ScrollFactor, Colour, Stepped, UseShapes, Invert);
		}
		
		public function CreateLine(X1:Number,Y1:Number,X2:Number,Y2:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean):void
		{
			Create(X1, Y1, X2, Y2, ScrollFactor, Colour, Stepped, UseShapes, Invert);
		}
		
		override protected function RenderShape( screenPos:FlxPoint, drawManually:Boolean, shape:Shape ):Boolean
		{
			var sx1:int = screenPos.x + x1;
			var sy1:int = screenPos.y + y1;
			var sx2:int = screenPos.x + x2;
			var sy2:int = screenPos.y + y2;
			
			if ( drawManually )
			{
				if ( stepped )
				{
					Misc.DrawCustomLine(sx1, sy1, sx2, sy2, EditorState.DrawSteppedPixelsOnBufferCallback, x2 - x1 != 0 );
				}
				else
				{
					Misc.DrawCustomLine(sx1, sy1, sx2, sy2, EditorState.DrawOnBufferCallback, colour );
				}
			}
			else
			{
				shape.graphics.moveTo(sx1, sy1);
				shape.graphics.lineTo(sx2, sy2);
				return true;
			}
			return false;
		}
		
	}

}