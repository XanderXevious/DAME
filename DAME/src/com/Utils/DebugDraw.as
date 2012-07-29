package com.Utils 
{
	import com.EditorState;
	import com.Layers.LayerEntry;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import org.flixel.FlxObject;
	import org.flixel.FlxPoint;
	import org.flixel.FlxG;
	import flash.display.Shape;
	import com.Utils.DebugDrawShapes.*;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class DebugDraw extends FlxObject
	{
		public static var singleton:DebugDraw = null;
		private var shapes:Vector.<DebugDrawShape> = new Vector.<DebugDrawShape>();
		private var linePool:Vector.<DebugDrawShapeLine> = new Vector.<DebugDrawShapeLine>();
		private var boxPool:Vector.<DebugDrawShapeBox> = new Vector.<DebugDrawShapeBox>();
		private var arrowPool:Vector.<DebugDrawShapeArrow> = new Vector.<DebugDrawShapeArrow>();
		private var quadPool:Vector.<DebugDrawShapeQuad> = new Vector.<DebugDrawShapeQuad>();
		private var numLines:uint = 0;
		private var numBoxes:uint = 0;
		private var numArrows:uint = 0;
		private var numQuads:uint = 0;
		private var numShapes:uint = 0;
		public var _s:Shape;
		private var invertShape:Shape;
		private var boxShape:Shape;
		private static var instantShape:Shape;
		private var pixelEstimate:uint = 0;
		private static var tempPos:FlxPoint = new FlxPoint;
		
		// Cache
		private var cachedShape:Shape = new Shape;
		public var cachedShapeBmp:BitmapData;
		private var cachedShapeDrawn:Boolean = false;
		private var hasCachedShape:Boolean = false;
		public function get HasCachedShape():Boolean { return hasCachedShape; }
		public function set HasCachedShape(hasIt:Boolean):void
		{
			if ( hasIt != hasCachedShape )
			{
				cachedShape.graphics.clear();
				hasCachedShape = hasIt;
				cachedShapeDrawn = false;
			}
		}
		public var cachedScreenPos:Point = new Point;
		public var cachedLayer:LayerEntry = null;
		
		public function DebugDraw() 
		{
			super();
			singleton = this;
			_s = new Shape();
			invertShape = new Shape;
			boxShape = new Shape;
			instantShape = new Shape;
		}
		
		static public function DrawLine( x1:Number, y1:Number, x2:Number, y2: Number, scrollFactor:FlxPoint, stepped:Boolean, colour:uint, useShapes:Boolean, invert:Boolean = false, instant:Boolean = false) : DebugDrawShapeLine
		{
			if ( instant )
			{
				var lineThickness:int = ( FlxG.zoomScale == 2 ) ? 2 : 0;
				instantShape.graphics.clear();
				var alpha:Number = ((colour >> 24) & 0xff) / 255;
				instantShape.graphics.lineStyle(lineThickness, colour, alpha);
				singleton.scrollFactor.copyFrom( scrollFactor );
				singleton.getScreenXY( tempPos );
				instantShape.graphics.moveTo(tempPos.x + x1, tempPos.y + y1);
				instantShape.graphics.lineTo(tempPos.x + x2, tempPos.y + y2);
				if ( invert )
				{
					FlxG.buffer.draw(instantShape, null, null, "difference");
				}
				else
				{
					FlxG.buffer.draw(instantShape);
				}
				return null;
			}
			var line:DebugDrawShapeLine;
			if ( singleton.numLines < singleton.linePool.length )
			{
				line = singleton.linePool[singleton.numLines];
				line.CreateLine(x1,y1,x2,y2,scrollFactor,colour,stepped,useShapes,invert);
			}
			else
			{
				line = new DebugDrawShapeLine(x1, y1, x2, y2, scrollFactor, colour, stepped, useShapes, invert);
				singleton.linePool.push(line);
			}
			if ( singleton.numShapes < singleton.shapes.length )
			{
				singleton.shapes[singleton.numShapes] = line;
			}
			else
			{
				singleton.shapes.push(line);
			}
			if ( !line.useShapes && line.stepped )
			{
				singleton.pixelEstimate += Math.abs(x1 - x2) + Math.abs(y1 - y2);
			}
			
			++singleton.numShapes;
			++singleton.numLines;
			return line;
		}
		
		static public function DrawBox( x1:Number, y1:Number, x2:Number, y2: Number, angle: Number, scrollFactor:FlxPoint, stepped:Boolean, colour:uint, useShapes:Boolean, showHandles:Boolean = false, filled:Boolean = false, invert:Boolean = false ) : DebugDrawShapeBox
		{
			var box:DebugDrawShapeBox;
			
			if ( singleton.numBoxes < singleton.boxPool.length )
			{
				box = singleton.boxPool[singleton.numBoxes];
				box.CreateBox(x1,y1,x2,y2,angle,scrollFactor,colour,stepped,useShapes,invert,showHandles,filled);
			}
			else
			{
				box = new DebugDrawShapeBox(x1,y1,x2,y2,angle,scrollFactor,colour,stepped,useShapes,invert,showHandles,filled);
				singleton.boxPool.push(box);
			}
			if ( singleton.numShapes < singleton.shapes.length )
			{
				singleton.shapes[singleton.numShapes] = box;
			}
			else
			{
				singleton.shapes.push(box);
			}
			if ( !box.useShapes && box.stepped )
			{
				singleton.pixelEstimate += ( ( Math.abs(x1 - x2) + Math.abs(y1 - y2) ) * 2 );
			}
			
			++singleton.numShapes;
			++singleton.numBoxes;
			return box;
		}
		
		static public function DrawQuad( x1:Number, y1:Number, x2:Number, y2: Number, x3:Number, y3:Number, x4:Number, y4:Number, scrollFactor:FlxPoint, colour:uint, filled:Boolean = false, fillColour:uint = 0, stepped:Boolean = false, showHandles:Boolean = false, invert:Boolean = false ) : DebugDrawShapeQuad
		{
			var box:DebugDrawShapeQuad;
			
			if ( singleton.numQuads < singleton.quadPool.length )
			{
				box = singleton.quadPool[singleton.numQuads];
				box.CreateQuad(x1,y1,x2,y2,x3,y3,x4,y4,scrollFactor,colour,stepped,!stepped,invert,showHandles,filled,fillColour);
				
			}
			else
			{
				box = new DebugDrawShapeQuad(x1,y1,x2,y2,x3,y3,x4,y4,scrollFactor,colour,stepped,!stepped,invert,showHandles,filled,fillColour);
				singleton.quadPool.push(box);
			}
			if ( singleton.numShapes < singleton.shapes.length )
			{
				singleton.shapes[singleton.numShapes] = box;
			}
			else
			{
				singleton.shapes.push(box);
			}
			
			++singleton.numShapes;
			++singleton.numQuads;
			return box;
		}
		
		static public function DrawArrow( fromX:Number, fromY:Number, toX:Number, toY:Number, scrollFactor:FlxPoint, colour:uint, thickness:uint ):DebugDrawShapeArrow
		{
			var arrow:DebugDrawShapeArrow;
			
			if ( singleton.numArrows < singleton.arrowPool.length )
			{
				arrow = singleton.arrowPool[singleton.numArrows];
				arrow.CreateArrow(fromX,fromY,toX,toY,scrollFactor,colour,thickness);
			}
			else
			{
				arrow = new DebugDrawShapeArrow(fromX,fromY,toX,toY,scrollFactor,colour,thickness);
				singleton.arrowPool.push(arrow);
			}
			if ( singleton.numShapes < singleton.shapes.length )
			{
				singleton.shapes[singleton.numShapes] = arrow;
			}
			else
			{
				singleton.shapes.push(arrow);
			}
			
			++singleton.numShapes;
			++singleton.numArrows;
			return arrow;
		}
		
		override public function update():void
		{
			numShapes = 0;
			numLines = 0;
			numBoxes = 0;
			numQuads = 0;
			numArrows = 0;
			pixelEstimate = 0;
			
		}
	
		override public function render():void
		{
			if (!visible)
				return;
				
			var pos:FlxPoint = new FlxPoint(0,0);
			
			_s.graphics.clear();
			invertShape.graphics.clear();
			
			var lastScrollFactor:FlxPoint = null;
			var currentScrollFactor:FlxPoint;
			
			var flashShapesDrawn:uint = 0;
			var invertShapesDrawn:uint = 0;
			
			if ( numShapes == 0 )
			{
				return;
			}
			
			DebugDrawShape.lineThickness = ( FlxG.zoomScale == 0.5 ) ? 2 : 0;
			
			DebugDrawShape.noSteps = pixelEstimate > 15000 || FlxG.extraZoom < 1;
			
			FlxG.buffer.lock();
			for ( var i:uint = 0; i < numShapes; i++ )
			{
				var shape:DebugDrawShape = shapes[i];
				currentScrollFactor = shape.scrollFactor;
				if ( lastScrollFactor == null || !currentScrollFactor.equals(lastScrollFactor ) )
				{
					// As the DebugDraw is an object we can make it use its own scrollFactor to calculate its position.
					scrollFactor.copyFrom( currentScrollFactor );
					lastScrollFactor = currentScrollFactor;
					getScreenXY( pos );
				}
				
				var curShape:Shape = _s;
				if ( shape.cache )
				{
					curShape = cachedShape;
					hasCachedShape = true;
				}
				else if ( shape.invert )
				{
					curShape = invertShape;
					invertShapesDrawn++;
				}
				else if ( shape is DebugDrawShapeBox && (shape as DebugDrawShapeBox).angle != 0 )
				{
					curShape = boxShape;
				}
				if ( shape.Render(pos, curShape) )
				{
					if ( shape.invert )
					{
						invertShapesDrawn++;
					}
					else
					{
						flashShapesDrawn++;
					}
				}
			}
			
			// Must be done last
			if ( invertShapesDrawn > 0 )
			{
				FlxG.buffer.draw(invertShape, null, null, "difference");
			}
			
			/*var bitmapWrapper:Sprite = new Sprite();
			bitmapWrapper.addChild(_s);
			//_s.cacheAsBitmap = true;
			FlxG.buffer.draw(bitmapWrapper);// , null, null, "difference");*/
			if ( Global.UseFlashShapeRenderer || flashShapesDrawn > 0)
			{
				FlxG.buffer.draw(_s);
			}
			
			if ( hasCachedShape )
			{
				if ( !cachedShapeDrawn )
				{
					cachedShapeBmp.draw(cachedShape);
					cachedShapeDrawn = true;
				}
				FlxG.buffer.copyPixels(cachedShapeBmp,cachedShapeBmp.rect,new Point,null,null,true);
			}
			
			FlxG.buffer.unlock();
		}
	}

}