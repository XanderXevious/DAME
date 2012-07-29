package com.Game 
{
	import com.Editor.GuideLayer;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerMap;
	import com.Tiles.FlxTilemapExt;
	import com.Properties.PropertyData;
	import com.Properties.PropertyType;
	import com.Tiles.SpriteEntry;
	import com.Utils.DebugDraw;
	import com.Utils.Global;
	import com.Utils.Hits;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import mx.collections.ArrayCollection;
	import org.flixel.data.FlxAnim;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import org.flixel.FlxSprite;
	import com.EditorState;
	import com.Utils.GUID;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorAvatar extends Avatar
	{
		private static var ScreenRectValue:Rectangle = new Rectangle(0, 0, 0, 0);
		public var spriteEntry:SpriteEntry = null;
		
		public var overrideAlpha:Number = 1;
		public var alphaPulseDirection:int = 1;
		private var _alphaPulseEnabled:Boolean = false;
		public var spriteTrailOwner:EditorAvatar = null;
		
		public function set alphaPulseEnabled(enable:Boolean):void
		{
			if ( !enable && _alphaPulseEnabled )
			{
				alpha = 1;
			}
			_alphaPulseEnabled = enable;
		}
		public function get alphaPulseEnabled():Boolean { return _alphaPulseEnabled; }
		
		// Values to set per avatar whenever needed.
		public var storedAvatarPos:FlxPoint = new FlxPoint();
		public var storedAvatarAngle:Number = 0;
		public var storedAvatarScale:FlxPoint = new FlxPoint(1, 1);
		public var storedWidth:Number = 0;
		public var storedHeight:Number = 0;
		
		private var _markForDeletion:Boolean = false;
		public function get markForDeletion():Boolean { return _markForDeletion; }
		public function set markForDeletion( mark:Boolean ):void { _markForDeletion = mark; }
		
		public var properties:ArrayCollection = new ArrayCollection();
		private var currentNumBaseProperties:uint = 0;
		
		public var isTileSprite:Boolean = false;
		
		private var recalcFlipFrame:Boolean = false;
		private var lastAlpha:Number = 1;
		
		private var guid:String = "";
		
		public var layer:LayerAvatarBase = null;
		
		public var alwaysDraw:Boolean = false;
		public var wasDrawn:Boolean = true;
		
		public var bakedBitmap:BitmapData = null;
		protected var lastBakedBitmapScale:FlxPoint = new FlxPoint;
		protected var lastBakedBitmapAngle:Number = 0;
		protected var lastBakedAlpha:Number = 1;
		protected var lastBakedFrameNum:uint = 0;
		protected var lastBakedFacing:uint = FlxSprite.LEFT;
		public var bakedBitmapPt:Point = new Point;
		
		// Links from this to other avatars.
		public var linksTo:Vector.<AvatarLink> = new Vector.<AvatarLink>;
		// Links to this from other avatars.
		public var linksFrom:Vector.<AvatarLink> = new Vector.<AvatarLink>;
		public var selected:Boolean = false;
		
		public var animIndex:int = -1;
		
		public var TileOrigin:FlxPoint = null;
		public var TileDims:FlxPoint = null;
		
		private var savedAnim:FlxAnim = null;
		private var hasAnimOverride:Boolean = false;
		private var animOverrideLooped:Boolean;
		
		// The image used when drawing a ghost of the previous frame.
		private var onionSkinFramePixels:BitmapData = null;
		private var showPreviousFrameOnionSkin:Boolean = false;
		private var showNextFrameOnionSkin:Boolean = false;
		private var currentOnionNextFrame:int = -1;
		private var currentOnionPrevFrame:int = -1;
		private var drawOnionSkinAbove:Boolean = false;
		private var onionSkinAlpha:Number = 0.5;
		
		public function EditorAvatar(X:Number,Y:Number, _layer:LayerAvatarBase) 
		{
			layer = _layer;
			
			super(X, Y);
			if ( layer )
			{
				layer.UpdateMinMax( this );
			}
		}
		
		public function SetAnimIndex( newIndex:int ):void
		{
			if ( !hasAnimOverride )
			{
				_animations.length = 0;
				var animIndices:Array = [ newIndex == -1 ? spriteEntry.previewIndex : newIndex ];
				addAnimation("base", animIndices, 0.001);
			
				//animIndex = newIndex;
				play( "base", true );
			}
			else if( savedAnim )
			{
				_animations.push( savedAnim );
				_caf = savedAnim.frames[ _curFrame ];
				calcFrame();
			}
			animIndex = newIndex;
		}
		
		public function SetupAnimOverride( frames:Array, fps:Number, looped:Boolean ):void
		{
			_animations.length = 0;
			addAnimation( "override", frames, fps, true );
			hasAnimOverride = true;
			savedAnim = _animations[0];
			animOverrideLooped = looped;
			_curFrame = 0;
		}
		
		public function PlayAnimOverride():void
		{
			_curAnim = null;
			play("override" );
			paused = false;
		}
		
		public function RemoveAnimOverride():void
		{
			hasAnimOverride = false;
			savedAnim = null;
			SetAnimIndex(animIndex);
		}
		
		public function PauseAnim():void
		{
			if ( hasAnimOverride )
			{
				paused = true;
			}
		}
		
		public function SetCurrentAnimFrameIndex( frameIndex:int ):void
		{
			if ( _animations.length )
			{
				var anim:FlxAnim = _animations[0];
				if ( anim != savedAnim )
				{
					_animations[0] = anim = savedAnim;
				}
				var index:int = anim ? Misc.clamp( frameIndex, 0, anim.frames.length - 1 ) : 0;
				_curFrame = index;
				_caf = anim ? anim.frames[ index ] : 0;
				calcFrame();
				bakedBitmap = null;	// force an update of the render.
			}
		}
		
		public function GetCurrentAnimFrameIndex():uint
		{
			return _curFrame;
		}
		
		public function ShowPreviousFrameOnionSkin():Boolean { return showPreviousFrameOnionSkin; }
		public function ShowNextFrameOnionSkin():Boolean { return showNextFrameOnionSkin; }
		
		public function SetOnionSkin(showPrevious:Boolean, showNext:Boolean, drawAbove:Boolean, alpha:Number ):void
		{
			showPreviousFrameOnionSkin = showPrevious;
			showNextFrameOnionSkin = showNext;
			currentOnionPrevFrame = -1;	// Forces a redraw.
			currentOnionNextFrame = -1;
			drawOnionSkinAbove = drawAbove;
			onionSkinAlpha = alpha;
			bakedBitmap = null;	// force an update of the render.
		}
		
		public function SetFromSpriteEntry(sprite:SpriteEntry,Animated:Boolean=false,Reverse:Boolean=false,Unique:Boolean=false):FlxSprite
		{
			spriteEntry = sprite;
			
			if ( !sprite || !sprite.bitmap || !sprite.previewBitmap )
			{
				return this;
			}
			
			if ( sprite.dontRefreshSpriteDims )
			{
				var savedWidth:Number = width;
				var savedHeight:Number = height;
			}
			SetFromBitmap(sprite.bitmap, sprite.previewBitmap.width, sprite.previewBitmap.height, Animated, Reverse, Unique, sprite.imageFile.nativePath );
			width = sprite.previewBitmap.width * scale.x;
			height = sprite.previewBitmap.height * scale.y;
			if ( sprite.dontRefreshSpriteDims )
			{
				width = savedWidth;
				height = savedHeight;
			}
			
			// Set the correct preview frame.			
			_animations.length = 0;
			
			if ( sprite.IsTileSprite )
			{
				SetAsTile();
				calcFrame();
			}
			else
			{
				isTileSprite = false;
				SetAnimIndex( animIndex );
			}
			
			// Ensure we have matching entries for all base properties.
			
			// First remove any deleted base properties.
			
			var j:uint;
			for ( j = 0; j < properties.length; j++)
			{
				var prop:PropertyData = properties[j] as PropertyData;
				if ( prop && prop.BaseProperty.Deleted )
				{
					properties.removeItemAt( j );
					j--;
					currentNumBaseProperties--;
				}
			}
			
			// Now add any new properties.
			
			var len:uint = spriteEntry.properties.length;
			
			for ( var i:uint = 0; i < len; i++ )
			{
				var baseProp:PropertyType = spriteEntry.properties[i] as PropertyType;
				j = properties.length;
				var found:Boolean = false;
				while( j-- )
				{
					prop = properties[j] as PropertyData;
					if ( prop && prop.BaseProperty == baseProp )
					{
						found = true;
						break;
					}
				}
				if ( !found )
				{
					properties.addItemAt( new PropertyData( baseProp ), i );
					currentNumBaseProperties++;
				}
			}
			
			properties.refresh();
			
			// Force it to redraw.
			bakedBitmap = null;
			
			return this;
		}
		
		public function SetFromBitmap(Graphic:Bitmap,Width:uint,Height:uint,Animated:Boolean=false,Reverse:Boolean=false,Unique:Boolean=false, Key:String = null):void
		{
			_bakedRotation = 0;
			if (Reverse)
			{
				_pixels = FlxG.createBitmap(Graphic.width << 1, Graphic.height, 0x00FFFFFF, Unique, Key);
				_pixels.fillRect(_pixels.rect, 0);	// ensure it's clear before drawing, in case we found an existing image.
				_pixels.draw(Graphic);
				var mtx:Matrix = new Matrix();
				mtx.scale( -1, 1);
				mtx.translate(Graphic.width << 1, 0);
				_pixels.draw(Graphic, mtx);
				_flipped = _pixels.width >> 1;
			}
			else
			{
				_pixels = FlxG.createBitmap(Graphic.width, Graphic.height, 0x00FFFFFF, Unique, Key);
				_pixels.fillRect(_pixels.rect, 0);	// ensure it's clear before drawing, in case we found an existing image.
				_pixels.draw(Graphic);
				_flipped = 0;
			}
			if(Width == 0)
			{
				if(Animated)
					Width = _pixels.height;
				else if(_flipped > 0)
					Width = _pixels.width/2;
				else
					Width = _pixels.width;
			}
			width = frameWidth = Width;
			if(Height == 0)
			{
				if(Animated)
					Height = width;
				else
					Height = _pixels.height;
			}
			height = frameHeight = Height;
			resetHelpers();
			
		}
		
		public function SetAsTile():void
		{
			isTileSprite = true;
			_flashRect.x = TileOrigin ? TileOrigin.x : spriteEntry.TileOrigin.x;
			_flashRect.y = TileOrigin ? TileOrigin.y : spriteEntry.TileOrigin.y;
			_flashRect.width = frameWidth;
			_flashRect.height = frameHeight;
			_flashRect2.x = 0;
			_flashRect2.y = 0;
			_flashRect2.width = _pixels.width;
			_flashRect2.height = _pixels.height;
			if((_framePixels == null) || (_framePixels.width != spriteEntry.previewBitmap.width) || (_framePixels.height != spriteEntry.previewBitmap.height))
				_framePixels = new BitmapData(spriteEntry.previewBitmap.width,spriteEntry.previewBitmap.height);
			origin.x = frameWidth / 2;
			origin.y = frameHeight / 2;
			_framePixels.fillRect(_framePixels.rect, 0x00000000);
			
			if ( TileDims )
			{
				var mat:Matrix = new Matrix;
				mat.translate(-_flashRect.x, -_flashRect.y);
				if ( TileDims.x != _framePixels.width || TileDims.y != _framePixels.height )
					_framePixels = new BitmapData(TileDims.x, TileDims.y, true, 0x00000000);
				_flashRect.width = frameWidth = TileDims.x;
				_flashRect.height = frameHeight = TileDims.y;
				var tempRect:Rectangle = new Rectangle( -_flashRect.x, -_flashRect.y, spriteEntry.bitmap.width, spriteEntry.bitmap.height );
				_framePixels.draw(_pixels, mat, null, null, tempRect, false );
			}
			else
			{
				if ( TileOrigin )
				{
					tempRect = _flashRect.clone();
					tempRect.right = Math.min( tempRect.right, spriteEntry.bitmap.width );
					tempRect.bottom = Math.min( tempRect.bottom, spriteEntry.bitmap.height );
				}
				else
				{
					tempRect = _flashRect;
				}
				_framePixels.copyPixels(_pixels, tempRect, _flashPointZero);
			}
			_flashRect.x = 0;
			_flashRect.y = 0;
			_caf = 0;
			refreshHulls();
			bakedBitmap = null;
			recalcFlipFrame = true;
		}
		
		public function ReplaceCurrentFrameBitmap(bitmap:BitmapData):void
		{
			_framePixels = bitmap;
			bakedBitmap = null;
			calcFrameCoords(_point);
			var pt:Point = new Point( _point.x, _point.y );
			var rect:Rectangle;
			
			// Insert the modified frame into the full bitmap.
			if ( isTileSprite )
			{
				var xOff:int = TileOrigin ? TileOrigin.x : spriteEntry.TileOrigin.x;
				var yOff:int = TileOrigin ? TileOrigin.y : spriteEntry.TileOrigin.y;
			}
			
			if ( Flipped )
			{
				var storedFlipped:uint = _flipped;
				//_flipped = 0;
				calcFrameCoords(_point);
				//_flipped = storedFlipped;
				if(_flipped && (_facing == LEFT))
				{
					_point.x = (_flipped<<1)-_point.x-frameWidth;
				}
				
				if ( isTileSprite )
				{
					_point.x += xOff;
					_point.y += yOff;
				}
				
				var mat:Matrix = new Matrix;
				mat.scale( -1, 1);
				mat.translate( _point.x + frameWidth, _point.y );
				
				
				// clear the area we're replacing on, so we don't draw over and double the image.
				rect = new Rectangle(_point.x, _point.y, _framePixels.width, _framePixels.height);
				spriteEntry.bitmap.bitmapData.fillRect(rect, 0);
				
				spriteEntry.bitmap.bitmapData.draw(_framePixels, mat);
			}
			else
			{
				var wid:Number = _framePixels.width;
				var ht:Number = _framePixels.height;
				if ( isTileSprite )
				{
					pt.x += xOff;
					pt.y += yOff;
				}
				rect = new Rectangle(pt.x, pt.y, wid, ht);
				spriteEntry.bitmap.bitmapData.fillRect(rect, 0);
				spriteEntry.bitmap.bitmapData.copyPixels(_framePixels, new Rectangle(0, 0, wid, ht), pt);
			}
		}
		
		override protected function calcFrame():void
		{
			if ( isTileSprite )
			{
				var setTile:Boolean = false;
				if ( lastAlpha != _alpha )
				{
					SetAsTile();
					setTile = true;
				}
				if ( recalcFlipFrame )
				{
					if ( !setTile )
					{
						SetAsTile();
					}
					if ( _facing == FlxSprite.LEFT )
					{
						var newPixels:BitmapData = new BitmapData(_framePixels.width, _framePixels.height,true,0x00000000);
						var mtx:Matrix = new Matrix();
						mtx.scale(-1,1);
						mtx.translate(newPixels.width,0);
						newPixels.draw(_framePixels, mtx);
						_framePixels = newPixels;
					}
					recalcFlipFrame = false;
				}
				if ( lastAlpha != _alpha )
				{
					if (_ct != null)
						_framePixels.colorTransform(_flashRect, _ct);
					lastAlpha = _alpha;
				}
				return;
			}
			super.calcFrame();
		}
		
		override public function render():void
		{
			if ( !alwaysDraw && !IsWithinScreenArea() )
			{
				wasDrawn = false;
				return;
			}
			wasDrawn = true;
			super.render();
		}
		
		protected function renderHeightLine():void
		{
			if ( z != 0 && layer == App.getApp().CurrentLayer )
			{
				var masterLayer:LayerMap = layer.parent.FindMasterLayer();
				if ( masterLayer && masterLayer.map.tileOffsetX == 0 && masterLayer.map.tileOffsetY != 0 )
				{
					// Horizontal line
					var zDiff:int = masterLayer.map.tileOffsetY < 0 ? z : -z;
					var xpos:int = masterLayer.map.tileOffsetY < 0 ? x : right;
					var ypos:int = bottom - ( height * 0.5 );
					DebugDraw.DrawLine(xpos, ypos, xpos + zDiff, ypos, scrollFactor, false, selected ? 0xffffffff : 0x88bbbbbb, true, true, !selected);
				}
				else
				{
					// Vertical line.
					xpos = x + ( width * 0.5 );
					ypos = bottom;
					DebugDraw.DrawLine(xpos, ypos, xpos, ypos - z, scrollFactor, false, selected ? 0xffffffff : 0x88bbbbbb, true, true, !selected);
				}
			}
		}
		
		override protected function renderSprite():void
		{
			getScreenXY(_point);
			_flashPoint.x = _point.x;
			_flashPoint.y = _point.y;
			
			renderHeightLine();
			
			selected = false;
			
			if ( recalcFlipFrame )
			{
				calcFrame();
			}
			
			var drawBmp:BitmapData = getDrawBitmap( _framePixels );
			
			var showOnion:Boolean = false;
			if ( (showPreviousFrameOnionSkin||showNextFrameOnionSkin) && hasAnimOverride && savedAnim && savedAnim.frames.length > 1 && paused )
			{
				var prevFrame:int = _curFrame - 1;
				var nextFrame:int = _curFrame + 1;
				var showPrev:Boolean = showPreviousFrameOnionSkin;
				var showNext:Boolean = showNextFrameOnionSkin;
				if ( prevFrame < 0 )
				{
					prevFrame = savedAnim.frames.length - 1;
					if ( !animOverrideLooped )
						showPrev = false;
				}
				if ( nextFrame >= savedAnim.frames.length )
				{
					nextFrame = savedAnim.frames.length - 1;
					if ( !animOverrideLooped )
						showNext = false;
				}
				showOnion = showPrev || showNext;
				if ( ( showPrev && currentOnionPrevFrame != prevFrame ) 
					|| ( showNext && currentOnionNextFrame != nextFrame ) )
				{
					var savedFrame:uint = _curFrame;
					currentOnionPrevFrame = prevFrame;
					currentOnionNextFrame = nextFrame;
					var ct:ColorTransform = new ColorTransform(1, 1, 1, onionSkinAlpha);
					if ( onionSkinFramePixels == null || onionSkinFramePixels.width != _framePixels.width || onionSkinFramePixels.height != _framePixels.height )
					{
						onionSkinFramePixels = new BitmapData(_framePixels.width, _framePixels.height, true, 0x00000000);
					}
					
					if ( showPrev )
					{
						SetCurrentAnimFrameIndex(currentOnionPrevFrame);
						onionSkinFramePixels.copyPixels(_framePixels, onionSkinFramePixels.rect, new Point);
					}
					if ( showNext )
					{
						SetCurrentAnimFrameIndex(currentOnionNextFrame);
						onionSkinFramePixels.copyPixels(_framePixels, onionSkinFramePixels.rect, new Point, null, null, true);
					}
					onionSkinFramePixels.colorTransform(onionSkinFramePixels.rect, ct);
					SetCurrentAnimFrameIndex(savedFrame);
				}
				
			}
			
			//Simple render
			if(((angle == 0) || (_bakedRotation > 0)) && (scale.x == 1) && (scale.y == 1) && (blend == null))
			{
				if ( showOnion )
				{
					if ( !drawOnionSkinAbove )
					{
						FlxG.buffer.copyPixels(onionSkinFramePixels, _flashRect, _flashPoint, null, null, true);
						FlxG.buffer.copyPixels(_framePixels, _flashRect, _flashPoint, null, null, true);
					}
					else
					{
						FlxG.buffer.copyPixels(_framePixels, _flashRect, _flashPoint, null, null, true);
						FlxG.buffer.copyPixels(onionSkinFramePixels, _flashRect, _flashPoint, null, null, true);
					}
				}
				else
				{
					FlxG.buffer.copyPixels(drawBmp, _flashRect, _flashPoint, null, null, true);
				}
				return;
			}
			
			var topLeft:FlxPoint;					
			var bottomRight:FlxPoint;
			
			var topLeftOuterCorner:FlxPoint;
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
				topLeftOuterCorner = topLeft = avatarTopLeft;
				bottomRight = avatarBottomRight;
			}
				
			if ( bakedBitmap == null || lastBakedBitmapAngle != angle || !lastBakedBitmapScale.equals(scale) || lastBakedAlpha != alpha || lastBakedFacing != _facing )
			{
				//Advanced render
				_mtx.identity();
				
				_mtx.scale(scale.x,scale.y);
				if (angle != 0)
					_mtx.rotate(Math.PI * 2 * (angle / 360));
				_mtx.translate( -(topLeft.x - topLeftOuterCorner.x)*FlxG.invExtraZoom, -(topLeft.y - topLeftOuterCorner.y)*FlxG.invExtraZoom );
				bakedBitmap = new BitmapData((bottomRight.x - topLeft.x)*FlxG.invExtraZoom, (bottomRight.y - topLeft.y)*FlxG.invExtraZoom, true, 0x00000000);
				if ( showOnion )
				{
					if ( !drawOnionSkinAbove )
					{
						bakedBitmap.draw(onionSkinFramePixels, _mtx, null, blend, null, antialiasing);
						bakedBitmap.draw(_framePixels, _mtx, null, blend, null, antialiasing);
					}
					else
					{
						bakedBitmap.draw(_framePixels, _mtx, null, blend, null, antialiasing);
						bakedBitmap.draw(onionSkinFramePixels, _mtx, null, blend, null, antialiasing);
					}
				}
				else
					bakedBitmap.draw(_framePixels, _mtx, null, blend, null, antialiasing);
				
				lastBakedBitmapScale.copyFrom( scale );
				lastBakedBitmapAngle = angle;
				lastBakedAlpha = _alpha;
				lastBakedFrameNum = EditorState.FrameNum;
				lastBakedFacing = _facing;
				
				redrawScaledBitmaps(bakedBitmap);
			}
			
			bakedBitmapPt = new Point(topLeft.x, topLeft.y);
			drawBmp = getDrawBitmap( bakedBitmap );
			FlxG.buffer.copyPixels(drawBmp, drawBmp.rect, bakedBitmapPt, null, null, true);
		}
		
		public function updateAlphaPulse():void
		{
			var currentLayer:LayerEntry = App.getApp().CurrentLayer;
			if ( layer && Global.OnionSkinEnabled && currentLayer &&
				layer != App.getApp().CurrentLayer && layer.parent !=  currentLayer)
			{
				alpha = (layer.parent == currentLayer.parent ? Global.SameGroupOnionSkinAlpha : Global.OnionSkinAlpha) * overrideAlpha;
			}
			else
			{
				if ( _alphaPulseEnabled && (!layer || layer == App.getApp().CurrentLayer ) )
				{
					alpha = alpha + alphaPulseDirection * FlxG.elapsed * 2;
					if ( alpha >= 1 )
					{
						alpha = 1;
						alphaPulseDirection = -1;
					}
					else if ( alpha <= 0 )
					{
						alpha = 0;
						alphaPulseDirection = 1;
					}
				}
				else
				{
					alpha = overrideAlpha;
				}
			}
		}
		
		override public function update():void
		{
			super.update();
			
			if ( _pixels == null )
			{
				DrawBoundingBox( 0xffffffff, false );
			}
			
			updateAlphaPulse();
			
		}
		
		public function IsOverWorldPos( testPoint:FlxPoint, testPixels:Boolean = false, boundsExtend:int = 0 ): Boolean
		{
			var avatarTopLeft:FlxPoint = new FlxPoint( left, top );
			var avatarBottomRight:FlxPoint = new FlxPoint( right, bottom );
			
			avatarBottomRight.x += boundsExtend;
			avatarBottomRight.y += boundsExtend;
			
			if ( angle == 0 )
			{
				avatarTopLeft.x -= boundsExtend;
				avatarTopLeft.y -= boundsExtend;
				if( testPoint.x >= avatarTopLeft.x &&
					testPoint.x <= avatarBottomRight.x &&
					testPoint.y >= avatarTopLeft.y &&
					testPoint.y <= avatarBottomRight.y )
				{
					if ( testPixels )
					{
						var pixel:uint = _pixels.getPixel32( testPoint.x - avatarTopLeft.x, testPoint.y - avatarTopLeft.y );
						return ( pixel > 0 );
					}
					return true;
				}
			}
			else
			{
				var matrix:Matrix = GetTransformMatrixForRealPosToDrawnPos(avatarTopLeft, angle);
				avatarTopLeft.x -= boundsExtend;
				avatarTopLeft.y -= boundsExtend;
				var A:FlxPoint = new FlxPoint(0,matrix.transformPoint(new Point(avatarTopLeft.x,avatarBottomRight.y)));
				var B:FlxPoint = new FlxPoint(0,matrix.transformPoint(avatarTopLeft.toPoint()));
				var C:FlxPoint = new FlxPoint(0, matrix.transformPoint(avatarBottomRight.toPoint()));
				
				if ( Hits.PointInRectangle(testPoint, A, B, C) )
				{
					//TODO implement the testPixels version of this.
					return true;
				}
				
			}
			return false;
		}
		
		/**
		* Instantiate a new point object.
		*
		* @param   testScreenPoint      The screen based position to test
		* @param   testPixels      		Should this use pixel perfect selection?
		* @param   boundsExtend			An amount to extend the region to test by.
		* @param   posOUT				Optional - stores the fractional position of the point relative to the sprite.
		*/
		public function IsOverScreenPos( testScreenPoint:FlxPoint, testPixels:Boolean = false, boundsExtend:int = 0, posOUT:FlxPoint = null, testNeighbouringPixels:Boolean = false ): Boolean
		{
			var avatarTopLeft:FlxPoint = EditorState.getScreenXYFromMapXY( left, top, scrollFactor.x, scrollFactor.y );
			var avatarBottomRight:FlxPoint = EditorState.getScreenXYFromMapXY( right, bottom, scrollFactor.x, scrollFactor.y );
			
			avatarBottomRight.x += boundsExtend;
			avatarBottomRight.y += boundsExtend;
			
			if ( angle == 0 )
			{
				avatarTopLeft.x -= boundsExtend;
				avatarTopLeft.y -= boundsExtend;
				if ( posOUT )
				{
					posOUT.x = Misc.getFrac(testScreenPoint.x, avatarTopLeft.x, avatarBottomRight.x);
					posOUT.y = Misc.getFrac(testScreenPoint.y, avatarTopLeft.y, avatarBottomRight.y);
				}
				if( testScreenPoint.x >= avatarTopLeft.x &&
					testScreenPoint.x <= avatarBottomRight.x &&
					testScreenPoint.y >= avatarTopLeft.y &&
					testScreenPoint.y <= avatarBottomRight.y )
				{
					if ( testPixels )
					{
						var xPos:int = testScreenPoint.x - avatarTopLeft.x;
						var yPos:int = testScreenPoint.y - avatarTopLeft.y;
						var pixel:uint = _pixels.getPixel32( xPos, yPos );
						if ( pixel == 0 && testNeighbouringPixels )
						{
							if ( _pixels.getPixel32( xPos - 1, yPos - 1 ) > 0 )
								return true;
							if ( _pixels.getPixel32( xPos - 1, yPos ) > 0 )
								return true;
							if ( _pixels.getPixel32( xPos - 1, yPos + 1 ) > 0 )
								return true;
							if ( _pixels.getPixel32( xPos, yPos - 1 ) > 0 )
								return true;
							if ( _pixels.getPixel32( xPos, yPos + 1 ) > 0 )
								return true; 
							if ( _pixels.getPixel32( xPos + 1, yPos - 1 ) > 0 )
								return true;
							if ( _pixels.getPixel32( xPos + 1, yPos ) > 0 )
								return true;
							if ( _pixels.getPixel32( xPos + 1, yPos + 1) > 0 )
								return true;
						}
						return ( pixel > 0 );
					}
					return true;
				}
			}
			else
			{
				var matrix:Matrix = GetTransformMatrixForRealPosToDrawnPos(avatarTopLeft, angle);
				avatarTopLeft.x -= boundsExtend;
				avatarTopLeft.y -= boundsExtend;
				var A:FlxPoint = new FlxPoint(0,matrix.transformPoint(new Point(avatarTopLeft.x,avatarBottomRight.y)));
				var B:FlxPoint = new FlxPoint(0,matrix.transformPoint(avatarTopLeft.toPoint()));
				var C:FlxPoint = new FlxPoint(0, matrix.transformPoint(avatarBottomRight.toPoint()));
				
				if ( Hits.PointInRectangle(testScreenPoint, A, B, C, posOUT) )
				{
					//TODO implement the testPixels version of this.
					return true;
				}
				
			}
			return false;
		}
		
		// Returns a matrix that will transform a point relative to how it is internally represented into
		// a point that represents what the user sees on the screen. All points are in map space.
		public function GetTransformMatrixForRealPosToDrawnPos( avatarPos:FlxPoint, avatarAngle:Number ):Matrix
		{
			var matrix:Matrix = new Matrix;
			var xOffset:Number = avatarPos.x + ((width * 0.5)>>FlxG.zoomBitShifter);
			var yOffset:Number = avatarPos.y + ((height * 0.5)>>FlxG.zoomBitShifter);
			matrix.translate( -xOffset, -yOffset );
			matrix.rotate(avatarAngle * Math.PI / 180 );
			matrix.translate( xOffset, yOffset );
			return matrix;
		}
		
		public function GetRotatedPosWithOffset( sourcePos:FlxPoint, offset:FlxPoint ):FlxPoint
		{
			var matrix:Matrix = new Matrix;
			var xOffset:Number = sourcePos.x + ((width * 0.5)>>FlxG.zoomBitShifter);
			var yOffset:Number = sourcePos.y + ((height * 0.5)>>FlxG.zoomBitShifter);
			
			matrix.translate( xOffset, yOffset );
			matrix.translate( -offset.x, -offset.y );
			matrix.rotate(angle * Math.PI / 180);
			matrix.translate( -xOffset, -yOffset);
			
			var pt:Point = matrix.transformPoint( new Point( 0, 0 ) );
			var res:FlxPoint = new FlxPoint(sourcePos.x + pt.x, sourcePos.y + pt.y );
			return res;
		}
		
		public function GetSnappedPos( sourcePos:FlxPoint, destPos:FlxPoint, centerOnCursor:Boolean ):void
		{
			if ( GuideLayer.SnappingEnabled )
			{
				var anchorPos:FlxPoint = GetAnchor();
				switch( GuideLayer.SnapPosType )
				{
					case GuideLayer.SnapPosType_TopLeft:
						anchorPos.x = 0;
						anchorPos.y = 0;
						break;
					case GuideLayer.SnapPosType_BoundsTopLeft:
						anchorPos.x = spriteEntry ? spriteEntry.Bounds.x * scale.x : 0;
						anchorPos.y = spriteEntry ? spriteEntry.Bounds.y * scale.y : 0;
						break;
					case GuideLayer.SnapPosType_BottomLeft:
						anchorPos.x = 0;
						anchorPos.y = height;
						break;
					case GuideLayer.SnapPosType_BoundsBottomLeft:
						anchorPos.x = spriteEntry ? spriteEntry.Bounds.x * scale.x : 0;
						anchorPos.y = height;
						break;
					case GuideLayer.SnapPosType_Center:
						anchorPos.x = width / 2;
						anchorPos.y = height / 2;
						break;
					
					// default is Anchor, which is what it was initialised to.
				}
				if ( spriteEntry && spriteEntry.IsSurfaceObject )
				{
					var noLayer:Boolean = layer == null;
					if ( noLayer )
					{
						layer = App.getApp().CurrentLayer as LayerAvatarBase;
					}
					GetIsoBasePos(anchorPos, true);
					anchorPos.x -= x;
					anchorPos.y -= y;
					if ( noLayer )
					{
						layer = null;
					}
				}
				destPos.x = sourcePos.x + anchorPos.x;
				destPos.y = sourcePos.y + anchorPos.y;
				if ( centerOnCursor )
				{
					destPos.x -= (width * 0.5);
					destPos.y -= (height * 0.5);
				}
				// This actually seems counter-intuitive. Just snap to closest anchor to where you
				// would have been.
				/*if ( angle != 0 )
				{
					var mat:Matrix = GetTransformMatrixForRealPosToDrawnPos( destPos, angle );
					var pt:Point = new Point(destPos.x, destPos.y);
					pt = mat.transformPoint(pt);
					
					destPos.x = GuideLayer.GetSnappedX(null, pt.x);
					destPos.y = GuideLayer.GetSnappedY(null, pt.y);
					
					destPos = GetRotatedPosWithOffset(destPos, anchorPos);
				}
				else*/
				{
					//destPos.x = GuideLayer.GetSnappedX(null, destPos.x) - anchorPos.x;
					//destPos.y = GuideLayer.GetSnappedY(null, destPos.y) - anchorPos.y;
					GuideLayer.GetSnappedPos(App.getApp().CurrentLayer, destPos.x, destPos.y, destPos);
					destPos.subFrom( anchorPos );
				}
			}
			else if ( centerOnCursor )
			{
				destPos.x -= (width * 0.5);
				destPos.y -= (height * 0.5);
			}
		}
		
		// This returns true if the avatar is within or under the box
		public function IsUnderScreenBox( boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean
		{
			if ( !visible )
			{
				return false;
			}
			var avatarTopLeft:FlxPoint = EditorState.getScreenXYFromMapXY( left, top, scrollFactor.x, scrollFactor.y );
			var avatarBottomRight:FlxPoint = EditorState.getScreenXYFromMapXY( right, bottom, scrollFactor.x, scrollFactor.y );
			
			var name:String = spriteEntry.name;
			
			if ( angle != 0 )
			{
				var matrix:Matrix = GetTransformMatrixForRealPosToDrawnPos(avatarTopLeft,angle);
				var topLeft:Point = matrix.transformPoint(avatarTopLeft.toPoint());
				var topRight:Point = matrix.transformPoint(new Point(avatarBottomRight.x,avatarTopLeft.y));
				var bottomRight:Point = matrix.transformPoint(avatarBottomRight.toPoint());
				var bottomLeft:Point = matrix.transformPoint(new Point(avatarTopLeft.x, avatarBottomRight.y));
				// At this point topLeft has been rotated and so is not necessarily at the top or left anymore!!
				
				// Extrapolate this from the rotated box to the largest normal box containing this.
				avatarTopLeft.x = Math.min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x);
				avatarTopLeft.y = Math.min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y);
				avatarBottomRight.x = Math.max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x);
				avatarBottomRight.y = Math.max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y);
			}
			var res:Boolean = (avatarTopLeft.x <= boxBottomRight.x &&
				avatarTopLeft.y <= boxBottomRight.y &&
				avatarBottomRight.x >= boxTopLeft.x &&
				avatarBottomRight.y >= boxTopLeft.y);
			if ( res )
				return true;
			return res;
		}
		
		// This returns true if the avatar is fully within the box.
		public function IsWithinScreenBox( boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean
		{
			if ( !visible )
			{
				return false;
			}
			var avatarTopLeft:FlxPoint = EditorState.getScreenXYFromMapXY( left, top, scrollFactor.x, scrollFactor.y );
			var avatarBottomRight:FlxPoint = EditorState.getScreenXYFromMapXY( right, bottom, scrollFactor.x, scrollFactor.y );
			
			if ( angle == 0 )
			{
				return (avatarTopLeft.x >= boxTopLeft.x && 
						avatarTopLeft.x <= boxBottomRight.x &&
						avatarTopLeft.y >= boxTopLeft.y && 
						avatarTopLeft.y <= boxBottomRight.y &&
						avatarBottomRight.x >= boxTopLeft.x &&
						avatarBottomRight.x <= boxBottomRight.x &&
						avatarBottomRight.y >= boxTopLeft.y &&
						avatarBottomRight.y <= boxBottomRight.y );
			}
			else
			{
				var matrix:Matrix = GetTransformMatrixForRealPosToDrawnPos(avatarTopLeft,angle);
				var topLeft:Point = matrix.transformPoint(avatarTopLeft.toPoint());
				var topRight:Point = matrix.transformPoint(new Point(avatarBottomRight.x,avatarTopLeft.y));
				var bottomRight:Point = matrix.transformPoint(avatarBottomRight.toPoint());
				var bottomLeft:Point = matrix.transformPoint(new Point(avatarTopLeft.x, avatarBottomRight.y));
				// At this point topLeft has been rotated and so is not necessarily at the top or left anymore!!
				return (topLeft.x >= boxTopLeft.x && 
						topLeft.x <= boxBottomRight.x &&
						topLeft.y >= boxTopLeft.y && 
						topLeft.y <= boxBottomRight.y &&
						topRight.x >= boxTopLeft.x &&
						topRight.x <= boxBottomRight.x &&
						topRight.y >= boxTopLeft.y &&
						topRight.y <= boxBottomRight.y &&
						bottomLeft.x >= boxTopLeft.x && 
						bottomLeft.x <= boxBottomRight.x &&
						bottomLeft.y >= boxTopLeft.y && 
						bottomLeft.y <= boxBottomRight.y &&
						bottomRight.x >= boxTopLeft.x &&
						bottomRight.x <= boxBottomRight.x &&
						bottomRight.y >= boxTopLeft.y &&
						bottomRight.y <= boxBottomRight.y);
			}
		}
		
		public function set Flipped( flip:Boolean ):void
		{
			var newFacing:uint = flip ? FlxSprite.LEFT : FlxSprite.RIGHT;
			recalcFlipFrame = _facing != newFacing;
			facing = newFacing;
		}
		
		public function get Flipped():Boolean
		{
			return (_facing == FlxSprite.LEFT);
		}
		
		public function CreateGUID():void
		{
			guid = GUID.create();
		}
		
		public function GetGUID():String
		{
			return guid;
		}
		
		public function SetGUID( newGUID:String ):void
		{
			guid = newGUID;
		}
		
		public function GetAnchor():FlxPoint
		{
			var anchor:FlxPoint = new FlxPoint();
			if ( spriteEntry )
			{
				anchor.copyFrom(spriteEntry.Anchor);
			}
			return anchor;
		}
		
		public function CopyData( destAvatar:EditorAvatar ):void
		{
			// Can copy everything except the attachment data.
			for ( var i:uint = 0; i < properties.length; i++ )
			{
				destAvatar.properties.addItem(properties[i].Clone());
			}
			if ( spriteEntry )
			{
				destAvatar.animIndex = animIndex;
				destAvatar.SetFromSpriteEntry( spriteEntry, true, true );
			}
			destAvatar.Flipped = Flipped;
			
			destAvatar.angle = angle;
			destAvatar.width = width;
			destAvatar.height = height;
			destAvatar.scale = FlxPoint.CreateObject(scale);
			destAvatar.offset = FlxPoint.CreateObject(offset);
			destAvatar.z = z;
			if ( spriteEntry && spriteEntry.IsTileSprite )
			{
				destAvatar.TileDims = TileDims.copy();
				destAvatar.TileOrigin = TileOrigin.copy();
				destAvatar.SetAsTile();
			}
		}
		
		// Must be overriden completely for any derived classes.
		public function CreateClipboardCopy():EditorAvatar
		{
			var newAvatar:EditorAvatar = new EditorAvatar(x, y, layer);
			newAvatar.CreateGUID();
			CopyData(newAvatar);
			
			
			return newAvatar;
		}
		
		
		
		// Not the rotated bounding box but a fast estimate 'horiz' bounding box
		protected function GetScreenRectEstimate( rect:Rectangle = null ):Rectangle
		{
			if ( rect == null )
			{
				rect = ScreenRectValue;
			}
			if ( angle == 0 )
			{
				rect.x = left;
				rect.y = top;
				rect.width = width;
				rect.height = height;
			}
			else
			{
				// This is a very rough estimate as not using trig. Likely to be much larger
				// than the real space it uses. It doesn't account for the angle, but rather
				// all possible angles, using magic numbers gathered from trial and eror.
				// As long as it's bigger than the shape that should do for culling tests.
				var maximum:int = Math.max(width, height);
				var diff:Number = Math.abs(width - height);
				rect.width = rect.height = ( maximum * 1.75 ) - ( diff * 0.6 );
				rect.x = left - height * 0.5;
				rect.y = top - width * 0.5;
			}
			if (FlxG.extraZoom < 1 )
			{
				rect.width *= FlxG.extraZoom;
				rect.height *= FlxG.extraZoom;
			}
			//DebugDraw.DrawBox(rect.x, rect.y, rect.right, rect.bottom, 0, scrollFactor,0xfffff000);
			return rect;
		}
		
		protected function IsWithinScreenArea( dumpOldBakedBitmaps:Boolean = false ):Boolean
		{
			var rect:Rectangle = GetScreenRectEstimate();
			var pt:FlxPoint = getScreenXY();// EditorState.getScreenXYFromMapXY(0, 0, scrollFactor.x, scrollFactor.y);
			rect.x = pt.x;
			rect.y = pt.y;
			
			if ( rect.right < 0 || rect.bottom < 0 || rect.left > FlxG.width || rect.top > FlxG.height )
			{
				if ( bakedBitmap && dumpOldBakedBitmaps && EditorState.FrameNum - lastBakedFrameNum > 10 )
				{
					bakedBitmap.dispose();
					bakedBitmap = null;
				}
				return false;
			}
			return true;
		}
		
		public function Exports():Boolean
		{
			return( !spriteEntry || spriteEntry.Exports );
		}
		
		public function CanScale():Boolean
		{
			return( !spriteEntry || spriteEntry.CanScale );
		}
		
		public function CanRotate():Boolean
		{
			return( !spriteEntry || spriteEntry.CanRotate );
		}
		
		public function CanSelect():Boolean
		{
			return spriteTrailOwner == null;
		}
		
		public function CanSave():Boolean
		{
			return spriteTrailOwner == null;
		}
		
		public function CanMove():Boolean
		{
			return true;
		}
		
		public function SkewAlignment():Boolean
		{
			return false;
		}
		
		public function AlwaysScaleUniformly():Boolean { return false; }
		
		public function GetIsoCorners( masterLayerMap:FlxTilemapExt, shrink:Boolean = false ):void
		{
			GetIsoCornersForPos( masterLayerMap, x, y, z, isoTopLeft, isoBottomRight, shrink );
		}
		
		// Doesn't return exact position - just a position in world space that is consistent, ie for collision detection and z sorting.
		public function GetIsoCornersForPos( masterLayerMap:FlxTilemapExt, _x:Number, _y:Number, _z:Number, topLeft:FlxPoint, botRight:FlxPoint, shrink:Boolean = false ):void
		{
			var ht:int = shrink ? Math.max(0, height - 1 ) : height;
			var wid:int = shrink ? Math.max(0, width - 1) : width;
			var bot:int = _y + ht;
			var lft:int = _x;
			
			if ( masterLayerMap.tileOffsetX )
			{
				bot -= _z;
			}
			else if ( masterLayerMap.tileOffsetY < 0 )
			{
				lft += _z;
			}
			else if ( masterLayerMap.tileOffsetY > 0 )
			{
				lft -= _z;// This case might really need to be handled from the right edge instead of the left.
			}
			
			var ratio:Number = masterLayerMap.tileOffsetY ? ht / masterLayerMap.tileHeight : wid / masterLayerMap.tileWidth;
			var tileSpacingY:Number = masterLayerMap.tileSpacingY * ratio;
			var tileSpacingX:Number = masterLayerMap.tileSpacingX * ratio;
			var tileOffsetX:Number = masterLayerMap.tileOffsetX * ratio;
			var tileOffsetY:Number = masterLayerMap.tileOffsetY * ratio;

			/*if ( masterLayerMap.tileOffsetY )
			{
				ratio = ht / masterLayerMap.tileHeight;
				var gradient:Number = masterLayerMap.tileOffsetY / masterLayerMap.tileWidth;
			}
			else
			{
				ratio = wid / masterLayerMap.tileWidth;
				gradient = masterLayerMap.tileHeight / masterLayerMap.tileOffsetX;
				tileSpacingY = tileSpacingX * gradient;
				tileOffsetY = tileOffsetX * gradient;
			}*/
			
			var topLeftX:int = lft;
			var topLeftY:int = bot - tileSpacingY;
			//var topRightX:int = 0 + masterLayerMap.tileSpacingX;
			//var topRightY:int = bot - masterLayerMap.tileSpacingY;
			//var botLeftX:int = 0;
			//var botLeftY:int = bot;
			var botRightX:int = lft + tileSpacingX;
			var botRightY:int = bot;
			
			if ( tileOffsetX < 0 ) // Slant to the up and right.
			{
				topLeftX -= tileOffsetX;
				//topRightX -= tileOffsetX;
			}
			else if ( tileOffsetX > 0 ) // Slant to the up and left.
			{
				//botLeftX += tileOffsetX;
				botRightX += tileOffsetX;
			}
			
			if ( tileOffsetY < 0 )	// Tile going up and to the right.
			{
				//topRightY += tileOffsetY;
				botRightY += tileOffsetY;
			}
			else if ( tileOffsetY > 0 ) // Tile going down and to the right.
			{
				topLeftY -= tileOffsetY;
				//botLeftY -= tileOffsetY;
			}
			
			masterLayerMap.GetPseudoWorldFromScreenPos(botRightX, botRightY, botRight );
			if ( spriteEntry && spriteEntry.IsSurfaceObject )
			{
				masterLayerMap.GetPseudoWorldFromScreenPos(topLeftX, topLeftY, topLeft );
			}
			else
			{
				isoTopLeft.copyFrom( botRight );
			}
		}
		
		// Returns the base pos of the tile that will be aligned to any isometric tiles.
		public function GetIsoBasePos( basePos:FlxPoint, getTop:Boolean = false ):void
		{
			var masterLayer:LayerMap = layer.parent.FindMasterLayer();
			if ( masterLayer && ( spriteEntry && spriteEntry.IsSurfaceObject ) )
			{
				// Get the centre of the sprite's base (as though it was a tile). Ie ignoring the "height".
				var widthRatio:Number = getTop ? 1 - ( masterLayer.map.tileSpacingX / masterLayer.map.tileWidth ) : 0.5;
				var heightRatio:Number = getTop ? 1 : 0.5;
				basePos.x = x + ( width * widthRatio );
				basePos.y = bottom - z;
				var ratio:Number;
				// Check standard or skewed isometric tilemaps.
				if ( masterLayer.map.tileOffsetX || masterLayer.map.tileOffsetY )
				{
					if ( masterLayer.map.tileOffsetX == 0 && masterLayer.map.tileOffsetY != 0 )
					{
						var zDiff:int = masterLayer.map.tileOffsetY < 0 ? z : -z;
						var xpos:int = masterLayer.map.tileOffsetY < 0 ? x : right;
						var ypos:int = bottom - ( height * 0.5 );
						basePos.y = bottom;
						basePos.x = xpos + zDiff;
					}
					else
					{
						ratio = width / masterLayer.map.tileWidth;
						basePos.y -= (masterLayer.map.tileSpacingY + Math.abs(masterLayer.map.tileOffsetY) ) * ratio * heightRatio;
					}
				}
				else if ( masterLayer.map.xStagger )
				{
					ratio = width / masterLayer.map.tileSpacingX;
					basePos.y -= masterLayer.map.tileSpacingY * ratio;
				}
				else
				{
					ratio = width / masterLayer.map.tileSpacingX;
					basePos.y -= ( masterLayer.map.tileSpacingY * heightRatio * ratio);
				}
			}
			else
			{
				// The middle bottom of the sprite
				basePos.x = x + ( width * 0.5 );
				if ( masterLayer && ( masterLayer.map.tileOffsetX == 0 && masterLayer.map.tileOffsetY != 0 ))
				{
					zDiff = masterLayer.map.tileOffsetY < 0 ? z : -z;
					xpos = masterLayer.map.tileOffsetY < 0 ? x : right;
					ypos = bottom - ( height * 0.5 );
					basePos.y = bottom;
					basePos.x = xpos + zDiff;
				}
				else
				{
					basePos.y = bottom - z;
				}
			}
		}
		
		public function SendToLayerFront():Boolean
		{
			//if ( !layer.AutoDepthSort )
			{
				var index:int = layer.sprites.members.indexOf( this );
				if ( index != -1 )
				{
					layer.sprites.members.splice(index, 1);
					layer.sprites.members.push( this );
					return true;
				}
			}
			return false;
		}
		
		public function SendToLayerBack():Boolean
		{
			//if ( !layer.AutoDepthSort )
			{
				var index:int = layer.sprites.members.indexOf( this );
				if ( index != -1 )
				{
					layer.sprites.members.splice(index, 1);
					layer.sprites.members.splice(0, 0, this);
					return true;
				}
			}
			return false;
		}
		
		public function Delete():void
		{
			var avatarIndex:uint = layer.sprites.members.indexOf(this);
			markForDeletion = true;
			if ( attachment )
			{
				if ( attachment.Parent )
				{
					attachment.Parent.attachment = null;
				}
				else if (attachment.Child )
				{
					attachment.Child.attachment = null;
				}
				attachment = null;
			}
			var i:uint = linksFrom.length;
			while(i--)
			{
				var link:AvatarLink = linksFrom[i];
				AvatarLink.RemoveLink(link);
			}
			i = linksTo.length;
			while(i--)
			{
				link = linksTo[i];
				AvatarLink.RemoveLink(link);
			}
			layer.sprites.members.splice(avatarIndex, 1);
			/*if ( SpriteDeletedCallback != null )
			{
				SpriteDeletedCallback( avatar );
			}*/
		}
		
		public function GetBitmap():BitmapData
		{
			return _framePixels;
		}
		
	}

}