package com.Utils.DebugDrawShapes 
{
	import com.EditorState;
	import com.Utils.DebugDraw;
	import com.Utils.Misc;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author ...
	 */
	public class DebugDrawShapeBox extends DebugDrawShape
	{
		public var showHandles:Boolean;
		public var filled:Boolean;
		public var angle:Number = 0;
		
		
		
		public function DebugDrawShapeBox(X1:Number,Y1:Number,X2:Number,Y2:Number,Angle:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean,ShowHandles:Boolean,Filled:Boolean) 
		{
			super(X1, Y1, X2, Y2, ScrollFactor, Colour, Stepped, UseShapes, Invert);
			angle = Angle;
			showHandles = ShowHandles;
			filled = Filled;
		}
		
		public function CreateBox(X1:Number,Y1:Number,X2:Number,Y2:Number,Angle:Number,ScrollFactor:FlxPoint,Colour:uint,Stepped:Boolean,UseShapes:Boolean,Invert:Boolean,ShowHandles:Boolean,Filled:Boolean):void
		{
			Create(X1, Y1, X2, Y2, ScrollFactor, Colour, Stepped, UseShapes, Invert);
			angle = Angle;
			showHandles = ShowHandles;
			filled = Filled;
		}
		
		override protected function RenderShape( screenPos:FlxPoint, drawManually:Boolean, shape:Shape ):Boolean
		{
			var sx1:int = screenPos.x + x1;
			var sy1:int = screenPos.y + y1;
			var sx2:int = screenPos.x + x2;
			var sy2:int = screenPos.y + y2;
			var wid:Number = x2 - x1;
			var ht:Number = y2 - y1;
			
			if ( angle != 0)
			{
				// Rotate about the centre.
				var matrix:Matrix = new Matrix;
				var xOffset:Number = (sx1) + (wid * 0.5);
				var yOffset:Number = (sy1) + (ht * 0.5);
				matrix.translate( -xOffset, -yOffset );
				matrix.rotate(angle * Math.PI / 180);
				matrix.translate( xOffset, yOffset );
				
				pt1.x = sx1;
				pt1.y = sy1;
				pt2.x = sx2;
				pt2.y = sy1;
				pt3.x = sx2;
				pt3.y = sy2;
				pt4.x = sx1;
				pt4.y = sy2;
				pt1 = matrix.transformPoint(pt1);
				pt2 = matrix.transformPoint(pt2);
				pt3 = matrix.transformPoint(pt3);
				pt4 = matrix.transformPoint(pt4);
			}
			
			if ( drawManually )
			{
				if ( angle != 0)
				{
					if ( stepped )
					{
						var horizIsHoriz:Boolean = Math.abs(pt1.x - pt2.x) > Math.abs(pt1.y - pt2.y);
						Misc.DrawCustomLine(pt1.x, pt1.y, pt2.x, pt2.y, EditorState.DrawSteppedPixelsOnBufferCallback, horizIsHoriz );
						Misc.DrawCustomLine(pt2.x, pt2.y, pt3.x, pt3.y, EditorState.DrawSteppedPixelsOnBufferCallback, !horizIsHoriz );
						Misc.DrawCustomLine(pt3.x, pt3.y, pt4.x, pt4.y, EditorState.DrawSteppedPixelsOnBufferCallback, horizIsHoriz );
						Misc.DrawCustomLine(pt4.x, pt4.y, pt1.x, pt1.y, EditorState.DrawSteppedPixelsOnBufferCallback, !horizIsHoriz );
					}
					else
					{
						Misc.DrawCustomLine(pt1.x, pt1.y, pt2.x, pt2.y, EditorState.DrawOnBufferCallback, colour );
						Misc.DrawCustomLine(pt2.x, pt2.y, pt3.x, pt3.y, EditorState.DrawOnBufferCallback, colour );
						Misc.DrawCustomLine(pt3.x, pt3.y, pt4.x, pt4.y, EditorState.DrawOnBufferCallback, colour );
						Misc.DrawCustomLine(pt4.x, pt4.y, pt1.x, pt1.y, EditorState.DrawOnBufferCallback, colour );
					}
				}
				else
				{
					if ( stepped )
					{
						Misc.DrawCustomLine( sx1, sy1, sx2, sy1, EditorState.DrawSteppedPixelsOnBufferCallback, true );
						Misc.DrawCustomLine( sx2, sy1, sx2, sy2, EditorState.DrawSteppedPixelsOnBufferCallback, false );
						Misc.DrawCustomLine( sx2, sy2, sx1, sy2, EditorState.DrawSteppedPixelsOnBufferCallback, true );
						Misc.DrawCustomLine( sx1, sy2, sx1, sy1, EditorState.DrawSteppedPixelsOnBufferCallback, false );
					}
					else
					{
						Misc.DrawCustomRect(sx1, sy1, sx2, sy2, EditorState.DrawOnBufferCallback, colour );
					}
				}
			}
			else
			{
				var gfx:Graphics = shape.graphics;
				if ( angle != 0 )
				{
					gfx.clear();
					gfx.lineStyle(lineThickness, colour, alpha);
					gfx.moveTo(0, 0);
					if ( filled )
					{
						gfx.beginFill(colour << 8,alpha);
					}
					gfx.drawRect(sx1, sy1, wid, ht);
					if ( filled )
					{
						gfx.endFill();
					}
					FlxG.buffer.draw(shape, matrix);
				}
				else
				{
					gfx.moveTo(0,0);
					if ( filled )
					{
						gfx.beginFill(colour << 8,alpha);
					}
					gfx.drawRect(sx1, sy1, wid, ht);
					if ( filled )
					{
						gfx.endFill();
					}
				}
			}
			
			if ( showHandles )
			{
				if ( angle == 0 )
				{
					DrawSimpleHandles( DebugDraw.singleton._s, sx1, sy1, sx2, sy2 );
				}
				else
				{
					DrawComplexHandles( DebugDraw.singleton._s );
				}
			}
			return !drawManually || showHandles;
		}
		
		protected function DrawSimpleHandles(shape:Shape, sx1:int, sy1:int, sx2:int, sy2:int):void
		{
			DrawHandleAtLocation(sx1, sy1, shape);
			DrawHandleAtLocation(sx2, sy1, shape);
			DrawHandleAtLocation(sx1, sy2, shape);
			DrawHandleAtLocation(sx2, sy2, shape);
			
			var x1x2:int = sx1 + 0.5 * (sx2 - sx1);
			var y1y2:int = sy1 + 0.5 * (sy2 - sy1);
			DrawHandleAtLocation(x1x2, sy1, shape);
			DrawHandleAtLocation(x1x2, sy2, shape);
			DrawHandleAtLocation(sx1, y1y2, shape);
			DrawHandleAtLocation(sx2, y1y2, shape);
		}
		
	}

}