package com.Game 
{
	import com.EditorState;
	import com.Game.GameText;
	import com.Layers.LayerAvatarBase;
	import com.photonstorm.flixel.FlxBitmapFont;
	import flash.text.TextFormat;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TextObject extends ShapeObject
	{
		public var text:GameText;	
		public var bmpText:FlxBitmapFont;
		
		private var storedTopLeft:FlxPoint = new FlxPoint;
		
		private var isDrawn:Boolean = false;
		
		public function TextObject(X:int, Y:int, _text:String, layer:LayerAvatarBase ) 
		{
			super(X, Y, false, layer);
			
			text = new GameText(0, 0, 1, _text);
			text.setFormat("system", 8, 0xffffff, "center", 0x233e58);
			topLeftOuterCorner.x = storedTopLeft.x = X;
			topLeftOuterCorner.y = storedTopLeft.y = Y;
		}
		
		override public function render():void
		{
			if ( FlxG.zoomScale < 1 )
			{
				if ( !FlxG.forceRefresh )
				{
					// The position for text must be calculated on the first quadrant
					// so we must force the text to draw if it is at all visible in any quad.
					if ( !isDrawn && !IsWithinScreenArea( true ) )
					{
						return;
					}
					isDrawn = false;
					renderSprite();
				}
				else
				{
					if ( !IsWithinScreenArea( true ) )
					{
						return;
					}
					else
					{
						isDrawn = isDrawn || true;
						renderSprite();
					}
				}
				return;
			}
			
			super.render();
		}
		
		override protected function renderSprite():void
		{
			super.renderSprite();
			
			//if ( FlxG.forceRefresh )
			// It seems that this should always be done or sometimes
			// (especially in export to image) it is drawn in the wrong place.
			{
				storedTopLeft.x = topLeftOuterCorner.x;
				storedTopLeft.y = topLeftOuterCorner.y;
			}
			
			if ( bmpText )
			{
				if ( int(bmpText.width) != int(width) || int(bmpText.height) != int(height) )
				{
					bmpText.width = width;
					bmpText.height = height;
					bmpText.buildBitmapFontText();
					bmpText.bakedBitmap = null;
				}
				bmpText.scrollFactor.copyFrom(scrollFactor);
				bmpText.x = x;
				bmpText.y = y;
				bmpText.angle = angle;
				bmpText.alpha = alpha;
				bmpText.render();
				return;
			}
			
			var newPos:FlxPoint = EditorState.getMapXYFromScreenXY((storedTopLeft.x - FlxG.extraScroll.x)/FlxG.extraZoom, (storedTopLeft.y - FlxG.extraScroll.y)/FlxG.extraZoom, scrollFactor.x, scrollFactor.y);
			
			text.scrollFactor.copyFrom(scrollFactor);
			text.x = newPos.x;
			text.y = newPos.y;
			text.angle = angle;
			text.alpha = alpha;
			if ( text.width != width || text.height != height )
			{
				text.Resize(width, height);
			}
			text.render();
		}
		
		override public function CopyData(destAvatar:EditorAvatar):void
		{
			super.CopyData(destAvatar);
			
			var newTextObj:TextObject = destAvatar as TextObject;
			if ( bmpText )
			{
				newTextObj.bmpText = new FlxBitmapFont(bmpText.fontSet, bmpText.characterWidth, bmpText.characterHeight, bmpText.characterSet, 0 );
				newTextObj.bmpText.width = bmpText.width;
				newTextObj.bmpText.height = bmpText.height;
				newTextObj.bmpText.scaler = bmpText.scaler;
				newTextObj.bmpText.autoTrim = bmpText.autoTrim;
				newTextObj.bmpText.setText( bmpText.text, true, bmpText.customSpacingX, bmpText.customSpacingY, bmpText.align, false);
				newTextObj.bmpText.bmpFile = bmpText.bmpFile;
				newTextObj.bmpText.characterSetType = bmpText.characterSetType;
				newTextObj.bmpText.characterSet = bmpText.characterSet;
			}
			else
			{
				newTextObj.text.setFormat( text.font, text.size, text.color, text.alignment, 0x233e58);
			}
		}
		
		override public function CreateClipboardCopy():EditorAvatar
		{
			var newAvatar:TextObject = new TextObject(x, y, text.text, layer);
			newAvatar.CreateGUID();
			CopyData(newAvatar);
			// Can copy everything except the attachment data.
			return newAvatar;
		}
		
		override public function SkewAlignment():Boolean
		{
			return false;
		}
		
	}

}