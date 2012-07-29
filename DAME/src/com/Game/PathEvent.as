package com.Game 
{
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Utils.Global;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	
	/**
	 * PathEvent - loosely based off ShapeObject
	 * @author Charles Goatley
	 */
	public class PathEvent extends EditorAvatar
	{
		protected var shape:Shape;
		private static const originalSize:Number = 10;
		
		public var pathObj:PathObject;
		
		public var forceRedraw:Boolean = false;
		
		public var colourOverriden:Boolean = false;
		public var fillColour:uint = 0;
		public var alphaValue:Number = 1;
		
		public var segmentNumber:int = 0;
		public var percentInSegment:Number = 0;
		private var lastHighlight:Boolean = false;
		public var highlighted:Boolean = false;
		
		private var flashCounter:int = 0;
		public function set flashThisFrame( flash:Boolean ):void
		{
			if ( flash )
			{
				flashCounter = 2;
			}
		}
		
		public function PathEvent(X:Number,Y:Number, layer:LayerAvatarBase, path:PathObject) 
		{
			super(X, Y, layer );
			SetFromBitmap(new Bitmap(new BitmapData(1, 1)), originalSize, originalSize);
			pathObj = path;
			
			shape = new Shape();
		}
		
		override protected function renderSprite():void
		{			
			var topLeft:FlxPoint;					
			var bottomRight:FlxPoint;
			
			var avatarTopLeft:FlxPoint = EditorState.getScreenXYFromMapXY( left, top, scrollFactor.x, scrollFactor.y );
			var avatarBottomRight:FlxPoint = EditorState.getScreenXYFromMapXY( right, bottom, scrollFactor.x, scrollFactor.y );
			
			topLeft = avatarTopLeft;
			bottomRight = avatarBottomRight;
			//if ( !FlxG.forceRefresh )
			//{
				//topLeftOuterCorner = topLeft;
			//}
			
			selected = false;
			
			var radius:Number = originalSize * 0.5;
			var scalar:Number = 1;
			if ( highlighted )
			{
				scalar = 2;
				radius *= 2;
			}
			
			if ( flashCounter )
			{
				alphaPulseEnabled = true;
				updateAlphaPulse();
				flashCounter--;
				if ( flashCounter == 0 )
				{
					alphaPulseEnabled = false;
				}
			}

			if ( bakedBitmap == null  || !lastBakedBitmapScale.equals(scale) || lastBakedAlpha != alpha || forceRedraw || lastHighlight != highlighted)
			{
				
				// Bitmap is slightly larger and shape is offset by 1 pixel so the outline is not clipped.
				bakedBitmap = new BitmapData(3 + ( bottomRight.x - topLeft.x) * scalar, 3 + ( bottomRight.y - topLeft.y) * scalar, true, 0x00000000);
				
				shape.graphics.clear();
				//var alphaVal:Number = colourOverriden ? alphaValue : Global.ShapeAlpha;
				shape.graphics.lineStyle(2, Global.PathEventOutlineColour, Math.min(1,(alphaValue + 0.2)*alpha),false);
				shape.graphics.moveTo(2, 2);
				shape.graphics.beginFill( colourOverriden ? fillColour : Global.PathEventColour, alphaValue * alpha);
				
				var screenPos:FlxPoint = EditorState.getScreenXYFromMapXY(0, 0, scrollFactor.x, scrollFactor.y);
				screenPos.addTo(this);
				
				
				shape.graphics.drawCircle(radius+1, radius+1, radius );
				shape.graphics.endFill();
				shape.graphics.drawCircle(radius+1, radius+1, 1 );
				bakedBitmap.draw(shape);
				//bakedBitmap.setPixel32(bakedBitmap.width * 0.5, bakedBitmap.height * 0.5, Global.PathEventOutlineColour);
			
				lastBakedBitmapScale.copyFrom( scale );
				lastBakedBitmapAngle = angle;
				lastBakedAlpha = _alpha;
				lastBakedFrameNum = EditorState.FrameNum;
				forceRedraw = false;
			}
			
			var pt:Point = new Point(topLeft.x - (radius+1), topLeft.y - (radius+1));
			FlxG.buffer.copyPixels(bakedBitmap, bakedBitmap.rect, pt, null, null, true);
			
			lastHighlight = highlighted;
			highlighted = false;
			
		}
		
		override public function render():void
		{
			if ( !IsWithinScreenArea( true ) )
			{
				return;
			}
			
			renderSprite();
		}
		
		override public function CanRotate():Boolean
		{
			return false;
		}
		
		override public function CanScale():Boolean
		{
			return false;
		}
		
		static public function GetSize():Number
		{
			return originalSize;// / FlxG.zoomScale;
		}
		
		override public function UpdateAttachment():void
		{
			if ( pathObj )
			{
				var closestPt:FlxPoint = pathObj.GetClosestPoint( this, this, "percentInSegment", "segmentNumber" );
				x = closestPt.x;
				y = closestPt.y;
				pathObj.redrawPathEvents = true;
			}
		}
		
	}

}