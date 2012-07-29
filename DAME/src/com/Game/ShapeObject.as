package com.Game 
{
	import com.EditorState;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerMap;
	import com.Utils.DebugDraw;
	import com.Utils.Global;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class ShapeObject extends EditorAvatar
	{		
		protected var shape:Shape;
		
		public var isEllipse:Boolean = false;
		
		public var forceRedraw:Boolean = false;
		
		protected var topLeftOuterCorner:FlxPoint = new FlxPoint(0, 0);
		
		public static const originalSize:Number = 50;
		
		private var masterLayerCached:LayerMap = null;
		
		public var colourOverriden:Boolean = false;
		public var fillColour:uint = 0;
		public var alphaValue:Number = 1;
		
		public function ShapeObject(X:Number,Y:Number,ellipse:Boolean, layer:LayerAvatarBase) 
		{
			super(X, Y, layer );
			SetFromBitmap(new Bitmap(new BitmapData(1, 1)), originalSize, originalSize);
			
			isEllipse = ellipse;
			
			//Invalidate();
			shape = new Shape();
		}
		
		protected function renderPixels():void
		{
			super.renderSprite();
		}
		
		override protected function renderSprite():void
		{			
			var topLeft:FlxPoint;					
			var bottomRight:FlxPoint;
			
			var masterLayer:LayerMap = SkewAlignment() ? layer.parent.FindMasterLayer() : null;
			
			if ( masterLayer )
			{
				angle = 0;	// Due to weirdness from rotating with skewed transformations disallow rotations when aligned.
			}
			else if ( masterLayerCached && isEllipse)
			{
				width = height = scale.x * originalSize;
			}
			
			//var topLeftOuterCorner:FlxPoint;
			var avatarTopLeft:FlxPoint = EditorState.getScreenXYFromMapXY( left, top, scrollFactor.x, scrollFactor.y );
			var avatarBottomRight:FlxPoint = EditorState.getScreenXYFromMapXY( right, bottom, scrollFactor.x, scrollFactor.y );
			
			if ( angle != 0 )
			{
				_mtx.identity();
				var xOffset:Number = (avatarTopLeft.x) + ((width * 0.5)>>FlxG.zoomBitShifter);
				var yOffset:Number = (avatarTopLeft.y) + ((height * 0.5)>>FlxG.zoomBitShifter);
				_mtx.translate( -xOffset, -yOffset );
				_mtx.rotate(angle * Math.PI / 180);
				_mtx.translate( xOffset, yOffset );
				
				var pt1:Point = new Point(avatarTopLeft.x, avatarTopLeft.y);
				var pt2:Point = new Point(avatarBottomRight.x, avatarTopLeft.y);
				var pt3:Point = new Point(avatarBottomRight.x, avatarBottomRight.y);
				var pt4:Point = new Point(avatarTopLeft.x, avatarBottomRight.y);
				pt1 = _mtx.transformPoint(pt1);
				pt2 = _mtx.transformPoint(pt2);
				pt3 = _mtx.transformPoint(pt3);
				pt4 = _mtx.transformPoint(pt4);
				
				topLeftOuterCorner = new FlxPoint( 0, pt1 );
			
				topLeft = new FlxPoint( Math.min(pt1.x, Math.min(pt2.x, Math.min(pt3.x, pt4.x))), 
										Math.min(pt1.y, Math.min(pt2.y, Math.min(pt3.y, pt4.y))) );
													
				bottomRight= new FlxPoint( Math.max(pt1.x, Math.max(pt2.x, Math.max(pt3.x, pt4.x))), 
											Math.max(pt1.y, Math.max(pt2.y, Math.max(pt3.y, pt4.y))) );
			}
			else
			{
				topLeft = avatarTopLeft;
				bottomRight = avatarBottomRight;
				//if ( !FlxG.forceRefresh )
				{
					topLeftOuterCorner = topLeft;
				}
			}
			
			renderHeightLine();
			selected = false;

			if ( bakedBitmap == null || lastBakedBitmapAngle != angle || !lastBakedBitmapScale.equals(scale) || lastBakedAlpha != alpha || masterLayerCached != masterLayer || forceRedraw)
			{
				//Advanced render
				_mtx.identity();
				
				if (angle != 0)
				{
					_mtx.rotate(Math.PI * 2 * (angle / 360));
				}
				_mtx.translate( 1 -(topLeft.x - topLeftOuterCorner.x)*FlxG.invExtraZoom, 1 -(topLeft.y - topLeftOuterCorner.y)*FlxG.invExtraZoom );
				
				masterLayerCached = masterLayer;
				
				if ( masterLayer )
				{
					// Note, that rotation is disallowed for iso aligned shapes.
					// Skewing does not perform as expected with rotation.
					_mtx.scale( masterLayer.map.tileSpacingX / originalSize, masterLayer.map.tileSpacingY / originalSize );
					_mtx.c = masterLayer.map.tileOffsetX / originalSize;
					_mtx.b = masterLayer.map.tileOffsetY / originalSize;
					if ( masterLayer.map.tileOffsetX < 0 )
						_mtx.translate( -masterLayer.map.tileOffsetX * scale.y, 0 );
					if ( masterLayer.map.tileOffsetY < 0 )
						_mtx.translate( 0, -masterLayer.map.tileOffsetY * scale.x );
					bakedBitmap = new BitmapData( 3 + ( originalSize * ( ( _mtx.a * scale.x ) + ( Math.abs(_mtx.c) * scale.y ) ) ),
						3 + ( originalSize * ( ( _mtx.d * scale.y ) + ( Math.abs(_mtx.b) * scale.x ) ) ), true, 0x00000000);
					width = bakedBitmap.width;
					height = bakedBitmap.height;
				}
				else
				{
					// Bitmap is slightly larger and shape is offset by 1 pixel so the outline is not clipped.
					bakedBitmap = new BitmapData(3 + (bottomRight.x - topLeft.x)*FlxG.invExtraZoom, 3 + (bottomRight.y - topLeft.y)*FlxG.invExtraZoom, true, 0x00000000);
				}
				
				shape.graphics.clear();
				var alphaVal:Number = colourOverriden ? alphaValue : Global.ShapeAlpha;
				shape.graphics.lineStyle(2, Global.ShapeOutlineColour, Math.min(1,(alphaVal + 0.2)*alpha),false);
				shape.graphics.moveTo(1, 1);
				shape.graphics.beginFill( colourOverriden ? fillColour : Global.ShapeColour, alphaVal * alpha);
				
				var screenPos:FlxPoint = EditorState.getScreenXYFromMapXY(0, 0, scrollFactor.x, scrollFactor.y);
				screenPos.addTo(this);
				
				if ( isEllipse )
				{
					shape.graphics.drawEllipse(0, 0, originalSize * scale.x, originalSize * scale.y );
				}
				else if ( masterLayer )
				{
					shape.graphics.drawRect(0, 0, originalSize * scale.x, originalSize * scale.y );
				}
				else
				{
					shape.graphics.drawRect(0, 0, width, height);
				}
				shape.graphics.endFill();
				bakedBitmap.draw(shape,_mtx);
			
				lastBakedBitmapScale.copyFrom( scale );
				lastBakedBitmapAngle = angle;
				lastBakedAlpha = _alpha;
				lastBakedFrameNum = EditorState.FrameNum;
				forceRedraw = false;
				
				redrawScaledBitmaps(bakedBitmap);
			}
			
			var pt:Point = new Point(topLeft.x, topLeft.y);
			var drawBmp:BitmapData = getDrawBitmap(bakedBitmap);
			FlxG.buffer.copyPixels(drawBmp, drawBmp.rect, pt, null, null, true);
			
		}
		
		override public function render():void
		{
			if ( !IsWithinScreenArea( true ) )
			{
				return;
			}
			
			renderSprite();
		}
		
		override public function CopyData(destAvatar:EditorAvatar):void
		{
			super.CopyData(destAvatar);
			
			var newShapeObj:ShapeObject = destAvatar as ShapeObject;
			newShapeObj.colourOverriden = colourOverriden;
			newShapeObj.fillColour = fillColour;
			newShapeObj.alphaValue = alphaValue;
		}
		
		override public function CreateClipboardCopy():EditorAvatar
		{
			var newAvatar:ShapeObject = new ShapeObject(x, y, isEllipse, layer);
			newAvatar.CreateGUID();
			CopyData(newAvatar);
			// Can copy everything except the attachment data.
			return newAvatar;
		}
		
		override public function AlwaysScaleUniformly():Boolean
		{
			return isEllipse;
		}
		
		override public function CanRotate():Boolean
		{
			return !isEllipse && !layer.AlignedWithMasterLayer;
		}
		
		override public function SkewAlignment():Boolean
		{
			return layer.AlignedWithMasterLayer;
		}
		
		override public function DrawBoundingBox( colour:uint, stepped:Boolean, showHandles:Boolean = false ):void
		{
			var masterLayer:LayerMap;
			
			if ( SkewAlignment() && ( masterLayer = layer.parent.FindMasterLayer() ) )
			{
				var x1:int = x + ( ( masterLayer.map.tileOffsetX < 0 ) ? - masterLayer.map.tileOffsetX * scale.y : 0 );
				var y1:int = y + ( ( masterLayer.map.tileOffsetY < 0 ) ? - masterLayer.map.tileOffsetY * scale.x : 0 );
				var x2:int = x1 + ( masterLayer.map.tileSpacingX * scale.x );
				var y2:int = y1 + ( masterLayer.map.tileOffsetY * scale.x );
				var x3:int = x2 + ( masterLayer.map.tileOffsetX * scale.y );
				var y3:int = y2 + ( masterLayer.map.tileSpacingY * scale.y );
				var x4:int = x1 + ( masterLayer.map.tileOffsetX * scale.y );
				var y4:int = y1 + ( masterLayer.map.tileSpacingY * scale.y );
				
				DebugDraw.DrawQuad( x1, y1, x2, y2, x3, y3, x4, y4, scrollFactor, colour, false, 0, stepped, showHandles );
			}
			else
			{
				super.DrawBoundingBox( colour, stepped, showHandles );
			}
		}
		
	}

}