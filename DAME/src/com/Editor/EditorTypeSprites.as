package com.Editor 
{
	import com.Editor.EditorType;
	import com.Game.EditorAvatar;
	import com.Game.SpriteTrailObject;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Layers.LayerSprites;
	import com.Operations.HistoryStack;
	import com.Operations.OperationAddAvatar;
	import com.Operations.OperationAddSpriteTrail;
	import com.Operations.OperationAttachAvatar;
	import com.Operations.OperationChangeSpritesToSpriteEntry;
	import com.Operations.OperationDetachAvatar;
	import com.Operations.OperationDetachSpriteTrail;
	import com.Operations.OperationPasteAvatars;
	import com.Operations.OperationTransformSprite;
	import com.Tiles.SpriteEntry;
	import com.UI.SetObjectCoordsPopup;
	import com.UI.SpriteDataPopup;
	import com.UI.SpriteTileDataPopup;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxPoint;
	import org.flixel.FlxG;
	import com.EditorState;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeSprites extends EditorTypeAvatarsBase
	{
		private var spriteCursor:EditorAvatar;
		protected static const MAX_SCALE_PER_FRAME:Number = 1.1;
		
		protected var detachMenuItem:NativeMenuItem = null;
		protected var attachMenuItem:NativeMenuItem = null;
		protected var setSpritePreviewMenuItem:NativeMenuItem = null;
		protected var resetSpriteMenuItem:NativeMenuItem = null
		
		protected var dontDrawSprites:Boolean = false;
		
		static public var UpdateSpriteTrails:Boolean = false;
		
		static public var ModifySpriteImage:Boolean = false;
		private var lastScreenOffset:FlxPoint = new FlxPoint();
		
		private var currentTileListSpriteEntry:SpriteEntry = null;
		public function get CurrentTileListSpriteEntry():SpriteEntry { return currentTileListSpriteEntry; }
		
		public function EditorTypeSprites( editor:EditorState ) 
		{
			super( editor );
			layerClassType = LayerSprites;
			
			// Add the sprite placement cursor last so it always appears above everything else.
			spriteCursor = new EditorAvatar(0, 0, null);
			spriteCursor.visible = false;
			spriteCursor.alphaPulseEnabled = true;
			editor.add(spriteCursor);
			
			allowScaling = true;
			
			attachMenuItem = addNewContextMenuItem(contextMenu, "Attach to path", contextMenuHandler );
			detachMenuItem = addNewContextMenuItem(contextMenu, "Detach from path", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Attach sprite trail", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Set Position...", contextMenuHandler );
			setSpritePreviewMenuItem = addNewContextMenuItem(contextMenu, "Set image from tile list", contextMenuHandler );
			resetSpriteMenuItem = addNewContextMenuItem(contextMenu, "Reset Sprite Image", contextMenuHandler );
			addNewContextMenuItem( contextMenu, "Edit Sprite Entry...", contextMenuHandler );
		}
		
		override protected function HideDisplay():void
		{
			spriteCursor.visible = false;
		}
		
		override public function Update( isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			if ( UpdateSpriteTrails )
			{
				UpdateSpriteTrails = false;
				var foundSpriteTrail:Boolean = false;
				
				if ( isActive )
				{
					var i:int = selectedSprites.length;
					
					while (i--)
					{
						var spriteTrail:SpriteTrailObject = selectedSprites[i] as SpriteTrailObject;
						if ( spriteTrail )
						{
							spriteTrail.trailData = Global.spriteTrailData.Clone();
							spriteTrail.UpdateAttachment( );
							foundSpriteTrail = true;
						}
					}
				}
				if ( !foundSpriteTrail )
				{
					// Next try any paths that are selected.
					var editor:EditorState = FlxG.state as EditorState;
					var pathSelection:Vector.<EditorAvatar> = editor.pathEditor.GetSelection();
					if ( EditorTypePaths.IsActiveEditor() )
					{
						i = pathSelection.length;
						while ( i-- )
						{
							if ( pathSelection[i].attachment )
							{
								spriteTrail = pathSelection[i].attachment.Child as SpriteTrailObject;
								if ( spriteTrail )
								{
									spriteTrail.trailData = Global.spriteTrailData.Clone();
									spriteTrail.UpdateAttachment( );
									foundSpriteTrail = true;
								}
							}
						}
					}
				}
			}
			
			if ( !isActive )
			{
				return;
			}
		}
		
		public function FlipSprites():void
		{
			spriteCursor.Flipped = !spriteCursor.Flipped;
			
			var spriteLayer:LayerSprites = App.getApp().CurrentLayer as LayerSprites;
			
			if ( spriteLayer == null || !spriteLayer.IsVisible() || spriteLayer.Locked())
			{
				return;
			}
			
			for each( var avatar:EditorAvatar in selectedSprites )
			{
				avatar.Flipped = !avatar.Flipped;
			}
		}
		
		public function RestoreSpritesToDefault( ):void
		{
			for each( var avatar:EditorAvatar in selectedSprites )
			{
				avatar.x = avatar.x - ( avatar.frameWidth - avatar.width ) / 2;
				avatar.y = avatar.y - ( avatar.frameHeight - avatar.height ) / 2;
				avatar.width = avatar.frameWidth;
				avatar.height = avatar.frameHeight;
				avatar.scale.x = avatar.scale.y = 1;
				avatar.offset.x = - ( avatar.width - avatar.frameWidth ) / 2;
				avatar.offset.y = - ( avatar.height - avatar.frameHeight ) / 2;
				avatar.Flipped = false;
				
				avatar.angle = 0;
				avatar.OnResize();
			}
		}
		
		override protected function UpdateDisplay( layer:LayerEntry ):void
		{
			super.UpdateDisplay( layer );
			
			if ( dontDrawSprites )
			{
				return;
			}
			spriteCursor.visible = false;
			
			if ( !isMovingItems && !isRotating && !isScaling )
			{
				var state:EditorState = FlxG.state as EditorState;
				var sprite:SpriteEntry = App.getApp().CurrentEditSprite as SpriteEntry;
				if ( inSelectionMode )
				{
					if ( App.getApp().myTileList.CustomData != currentTileListSpriteEntry || !App.getApp().myTileList.HasEmptyFirstTile )
					{
						updateTileListForSprite( currentTileListSpriteEntry, true, SpriteIndexChanged, ModifySprites);
					}
					if ( sprite != null && sprite.bitmap != null && spriteCursor.spriteEntry != sprite )
					{
						Global.windowedApp.changeEditMode(0);
					}
				}
				else
				{
					// Display the current sprite over the cursor.
					if ( sprite != null && sprite.bitmap != null )
					{
						var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
						
						// Handle snap to grid
						modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
						
						spriteCursor.visible = true;
						spriteCursor.GetSnappedPos(modifiedMousePos, modifiedMousePos, true);
						spriteCursor.x = modifiedMousePos.x;
						spriteCursor.y = modifiedMousePos.y;
						spriteCursor.scrollFactor.x = layer.xScroll;
						spriteCursor.scrollFactor.y = layer.yScroll;
						
						var spriteChanged:Boolean = false;
						if ( spriteCursor.spriteEntry != sprite )
						{
							spriteChanged = true;
							if ( !sprite.IsTileSprite )
								spriteCursor.animIndex = sprite.tilePreviewIndex;
							spriteCursor.SetFromSpriteEntry( sprite, true, true );
						}
						
						if ( !state.tileListIsSprite || spriteChanged || App.getApp().myTileList.CustomData != sprite || !App.getApp().myTileList.HasEmptyFirstTile )
						{
							if ( updateTileListForSprite( sprite, true, SpriteIndexChanged, ModifySprites) )
							{
								currentTileListSpriteEntry = sprite;
							}
						}
					}
				}
			}
		}
		
		private function SpriteIndexChanged():void
		{
			var state:EditorState = FlxG.state as EditorState;
			if ( spriteCursor.spriteEntry && !spriteCursor.spriteEntry.IsTileSprite )
			{
				spriteCursor.spriteEntry.tilePreviewIndex = App.getApp().myTileList.selectedIndex - 1;
				spriteCursor.SetAnimIndex( spriteCursor.spriteEntry.tilePreviewIndex);
			}
		}
		
		private var lastSnappedPos:FlxPoint = new FlxPoint;
		private var doneFirstSprite:Boolean = false;
		
		override protected function BeginPainting(layer:LayerEntry, leftMouse:Boolean):void
		{
			super.BeginPainting(layer, leftMouse);
			doneFirstSprite = false;
		}
		
		override protected function Paint( layer:LayerEntry ):void
		{
			var spriteLayer:LayerSprites = App.getApp().CurrentLayer as LayerSprites;
			
			if ( spriteLayer == null )
			{
				return;
			}
			
			allowContinuousPainting = GuideLayer.PaintContinuouslyWhenSnapped && GuideLayer.SnappingEnabled;
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			
			// Handle snap to grid
			/*if ( !layer.map && GuideLayer.SnappingEnabled )
			{
				modifiedMousePos.x = GuideLayer.GetSnappedX(layer, mousePos.x);
				modifiedMousePos.y = GuideLayer.GetSnappedY(layer, mousePos.y);
			}*/
			
			var sprite:SpriteEntry = App.getApp().CurrentEditSprite as SpriteEntry;
			if ( sprite != null && sprite.bitmap != null )
			{
				if ( allowContinuousPainting )//&& doneFirstSprite)
				{
					/* No longer do a continuous unbroken line - the conversion from realpos to unit pos and back with snapping causes
					 * complicated errors.
					selectedSprites[0].GetSnappedPos( modifiedMousePos, modifiedMousePos, true, sharedPos);
					modifiedMousePos.copyFrom(sharedPos);
					paintSpritesInLine( spriteLayer, lastSnappedPos.x, lastSnappedPos.y, modifiedMousePos.x, modifiedMousePos.y, sprite );
					lastSnappedPos.copyFrom(sharedPos);
					return;*/
					var drawData:Object = new Object();
					drawData.sprite = sprite;
					drawData.layer = layer;
					drawCallback(spriteCursor.x + spriteCursor.width/2, spriteCursor.y + spriteCursor.height/2, drawData );// modifiedMousePos.x, modifiedMousePos.y, drawData);
					return;
				}
				var newSprite:EditorAvatar = new EditorAvatar( modifiedMousePos.x - sprite.Anchor.x, modifiedMousePos.y - sprite.Anchor.y, spriteLayer );
				if ( !sprite.IsTileSprite )
					newSprite.animIndex = sprite.tilePreviewIndex;
				newSprite.SetFromSpriteEntry( sprite, true, true );
				if ( spriteCursor.Flipped )
				{
					newSprite.Flipped = true;
				}
				
				newSprite.GetSnappedPos( modifiedMousePos, modifiedMousePos, true);
				newSprite.x = modifiedMousePos.x;
				newSprite.y = modifiedMousePos.y;
				
				lastSnappedPos.copyFrom(modifiedMousePos);
				doneFirstSprite = true;
				
				newSprite.CreateGUID();
				
				HistoryStack.BeginOperation( new OperationAddAvatar( this, spriteLayer, newSprite ) );
					
				spriteLayer.sprites.add(newSprite, true);
				if ( newSprite.layer.AutoDepthSort )
				{
					newSprite.layer.SortAvatar(newSprite);
				}
				selectionChanged = true;
				selectedSprites.length = 0;
				selectedSprites.push(newSprite);
			}
		}
		
		private function drawCallback( x:int, y:int, drawData:Object ):void
		{
			// As the coords are in units they need to be transformed back relative to the start pos and the grid.
			
			// Add the 2 pixels so that we're inside the grid box and not on the edge - can get grey areas 
			// in the edge where it doesn't quite detect that the avatar is underneath.
			//x = GuideLayer.XStart + ( x * GuideLayer.XSpacing ) + 2;
			//y = GuideLayer.YStart + ( y * GuideLayer.YSpacing ) + 2;
			//GuideLayer.GetWorldPosFromUnitPos( drawData.layer, x, y, sharedPos);
			//x = sharedPos.x;
			//y = sharedPos.y;
			
			var spriteLayer:LayerSprites = drawData.layer;
			var sprite:SpriteEntry = drawData.sprite;
			var k:uint = spriteLayer.sprites.members.length;

			var tempPos:FlxPoint = new FlxPoint(x, y);// EditorState.getScreenXYFromMapXY( x, y, spriteLayer.xScroll, spriteLayer.yScroll );
			while( k-- )
			{
				var avatar:EditorAvatar = spriteLayer.sprites.members[k];
				if ( avatar.IsOverWorldPos( tempPos, usePixelPerfectSelection ) )
				{
					return;
				}
			}
			tempPos.create_from_points(x, y);
			var newSprite:EditorAvatar = new EditorAvatar( tempPos.x - sprite.Anchor.x, tempPos.y - sprite.Anchor.y, spriteLayer );
			if ( !sprite.IsTileSprite )
				newSprite.animIndex = sprite.tilePreviewIndex;
			newSprite.SetFromSpriteEntry( sprite, true, true );
			if ( spriteCursor.Flipped )
			{
				newSprite.Flipped = true;
			}
			
			newSprite.GetSnappedPos( tempPos, tempPos, true);
			newSprite.x = tempPos.x;
			newSprite.y = tempPos.y;
			
			doneFirstSprite = true;
			
			newSprite.CreateGUID();
			
			HistoryStack.BeginOperation( new OperationAddAvatar( this, spriteLayer, newSprite ) );
				
			spriteLayer.sprites.add(newSprite, true);
			if ( newSprite.layer.AutoDepthSort )
			{
				newSprite.layer.SortAvatar(newSprite);
			}
			selectionChanged = true;
			selectedSprites.length = 0;
			selectedSprites.push(newSprite);
		}
		
		private function paintSpritesInLine( layer:LayerSprites, x1:int, y1:int, x2:int, y2:int, sprite:SpriteEntry ):void
		{
			var drawData:Object = new Object();
			drawData.sprite = sprite;
			drawData.layer = layer;
			//drawData.startX = x1;
			//drawData.startY = y1;
			
			var pos1:FlxPoint = new FlxPoint;
			var pos2:FlxPoint = new FlxPoint;
			GuideLayer.GetSnappedPos(layer, x1, y1, sharedPos, pos1);
			GuideLayer.GetSnappedPos(layer, x2, y2, sharedPos, pos2);
			
			/*x1 = ( x1 - GuideLayer.XStart ) / GuideLayer.XSpacing;
			x2 = ( x2 - GuideLayer.XStart ) / GuideLayer.XSpacing;
			y1 = ( y1 - GuideLayer.YStart ) / GuideLayer.YSpacing;
			y2 = ( y2 - GuideLayer.YStart ) / GuideLayer.YSpacing;*/
			
			Misc.DrawCustomLine( pos1.x, pos1.y, pos2.x, pos2.y, drawCallback, drawData );
		}
		
		public function RefreshSpriteGraphics( sprite:SpriteEntry ):void
		{
			if ( sprite == spriteCursor.spriteEntry )
			{
				spriteCursor.SetFromSpriteEntry( sprite, true, true );
			}
		}
		
		override protected function SelectUnderCursor( layer:LayerEntry ):Boolean
		{
			var res:Boolean = super.SelectUnderCursor( layer );
			
			if ( res && !FlxG.keys.pressed( "CONTROL" ) && !FlxG.keys.pressed( "SHIFT" ) && selectedSprites.length )
			{
				var obj:EditorAvatar = selectedSprites[ selectedSprites.length - 1 ];
				if ( obj )
				{
					if ( updateTileListForSprite( obj.spriteEntry, true, SpriteIndexChanged, ModifySprites ) )
					{
						currentTileListSpriteEntry = obj.spriteEntry;
					}
				}
			}
			return res;
		}
		
		override protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint
		{
			if ( InSpriteTrailMode )
			{
				var editor:EditorState = FlxG.state as EditorState;
				var spriteLayer:LayerAvatarBase = App.getApp().CurrentLayer as LayerAvatarBase;
				var spriteTrail:SpriteTrailObject = new SpriteTrailObject(spriteLayer);
				spriteTrail.trailData = Global.spriteTrailData.Clone();
				AvatarToAttach = spriteTrail;
				AvatarToAttach.CreateGUID();
				if ( editor.pathEditor.AttachAvatar() )
				{
					HistoryStack.BeginOperation( new OperationAddSpriteTrail( this, AvatarToAttach as SpriteTrailObject ) );
					ForceSelection( AvatarToAttach );
					App.getApp().CreateSpriteTrailWindow();
					isDoingSomething = true;
					return SELECTED_ITEM_AND_SET_STATE;
				}
					
			}
			return super.SelectWithinSelection( layer, clearIfNoSelection );
		}
		
		override protected function BeginTransformation():void
		{
			ModifySpriteImage = false;
			if ( FlxG.keys.pressed("T") )
			{
				for each( var avatar:EditorAvatar in selectedSprites )
				{
					if ( avatar.spriteEntry && avatar.spriteEntry.IsTileSprite )
					{
						ModifySpriteImage = true;
						break;
					}
				}
			}
			
			if ( !ModifySpriteImage )
			{
				super.BeginTransformation();
			}
			
			lastScreenOffset.create_from_points(0, 0);
			if ( isRotating || isScaling || ModifySpriteImage)
			{
				HistoryStack.BeginOperation( new OperationTransformSprite( selectedSprites ) );
			}
			
			
		}
		
		override protected function RotateSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{			
			if ( clickedSprite == null )
			{
				return;
			}
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			// Always rotate around the anchor.
			var angleDiff:Number = originalAngleFromSelectedSprite - GetAngleOfPointFromAvatar( modifiedMousePos, clickedSprite, clickedSprite.storedAvatarPos,clickedSprite.storedAvatarAngle );

			
			for each( var avatar:EditorAvatar in selectedSprites )
			{
				if ( avatar.CanRotate() )
				{
					avatar.angle = avatar.storedAvatarAngle - angleDiff;
					if ( avatar.angle < 0 )
					{
						avatar.angle += 360;
					}
					if ( FlxG.keys.pressed("A") )
					{
						avatar.angle = Math.round(avatar.angle/45) * 45;
					}
					avatar.OnRotate();
				}
			}
		}
		
		override protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			if ( !ModifySpriteImage )
			{
				super.MoveSelection( screenOffsetFromOriginalPos );
				return;
			}
			
			// Handle transforming the sprite image directly.
			var i:uint = selectedSprites.length;
			
			while(i--)
			{
				var avatar:EditorAvatar = selectedSprites[i];
				if ( avatar.spriteEntry && avatar.spriteEntry.IsTileSprite )
				{
					if ( !avatar.TileOrigin )
					{
						avatar.TileOrigin = avatar.spriteEntry.TileOrigin.copy();
					}
					var mat:Matrix = new Matrix;
					mat.rotate( -avatar.angle * Math.PI / 180);
					if ( avatar.Flipped )
					{
						mat.scale( -1, 1);
					}
					var pt:Point = new Point(lastScreenOffset.x, lastScreenOffset.y);
					pt = mat.transformPoint(pt);
					avatar.TileOrigin.x += pt.x / avatar.scale.x;
					avatar.TileOrigin.y += pt.y / avatar.scale.y;
					pt.x = screenOffsetFromOriginalPos.x;
					pt.y = screenOffsetFromOriginalPos.y;
					pt = mat.transformPoint(pt);
					
					avatar.TileOrigin.x -= pt.x / avatar.scale.x;
					avatar.TileOrigin.y -= pt.y / avatar.scale.y;
					avatar.SetAsTile();
				}
			}
			lastScreenOffset.copyFrom(screenOffsetFromOriginalPos);
		}
		
		override protected function ScaleSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			if ( clickedSprite == null || !clickedSprite.CanScale() )
			{
				return;
			}
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);

			var storedAnchorPos:FlxPoint;
			var anchorPos:FlxPoint;
			var unscaledAnchor:FlxPoint;
			var anchorFrac:FlxPoint;
			var newMousePosX:Number = modifiedMousePos.x;
			var newMousePosY:Number = modifiedMousePos.y;
			var newOffsetX:Number = screenOffsetFromOriginalPos.x;
			var newOffsetY:Number = screenOffsetFromOriginalPos.y;
			
			var clickedHandle:Boolean = ( mouseOverDiagHandle || mouseOverHorizHandle || mouseOverVertHandle );
			
			var masterLayer:LayerMap = null;
			if ( clickedSprite.SkewAlignment() )
				masterLayer = clickedSprite.layer.parent.FindMasterLayer();
			
			if ( clickedSprite.attachment )
			{
				storedAnchorPos = clickedSprite.GetAnchor();
				anchorPos = storedAnchorPos.copy();
				storedAnchorPos.x *= clickedSprite.storedAvatarScale.x;
				storedAnchorPos.y *= clickedSprite.storedAvatarScale.y;
				anchorPos.x *= clickedSprite.scale.x;
				anchorPos.y *= clickedSprite.scale.y;
			}
			else if ( clickedHandle )
			{
				anchorFrac = new FlxPoint(1 - handleDraggedFrac.x, 1 - handleDraggedFrac.y);
				storedAnchorPos = new FlxPoint(Math.abs(clickedSprite.storedWidth * anchorFrac.x), Math.abs(clickedSprite.storedHeight * anchorFrac.y) );
				anchorPos = new FlxPoint(Math.abs(clickedSprite.width * anchorFrac.x), Math.abs(clickedSprite.height * anchorFrac.y) );
				
				// Try to snap the handle to the grid.
				//newMousePosX = GuideLayer.GetSnappedX(clickedSprite.layer, mousePos.x);
				//newMousePosY = GuideLayer.GetSnappedY(clickedSprite.layer, mousePos.y);
				GuideLayer.GetSnappedPos(clickedSprite.layer, modifiedMousePos.x, modifiedMousePos.y, sharedPos);
				newMousePosX = sharedPos.x;
				newMousePosY = sharedPos.y;
				newOffsetX = screenOffsetFromOriginalPos.x - (modifiedMousePos.x - newMousePosX);
				newOffsetY = screenOffsetFromOriginalPos.y - (modifiedMousePos.y - newMousePosY);
			}
			else
			{
				anchorFrac = new FlxPoint(0.5, 0.5);
				storedAnchorPos = new FlxPoint(clickedSprite.storedWidth * 0.5, clickedSprite.storedHeight * 0.5 );
				anchorPos = new FlxPoint(clickedSprite.width * 0.5, clickedSprite.height * 0.5 );
			}
			
			if ( masterLayer )
			{
				var newFracX:Number = masterLayer.map.tileOffsetY < 0 ? handleDraggedFrac.x : anchorFrac.x;
				var newFracY:Number = masterLayer.map.tileOffsetX < 0 ? handleDraggedFrac.y : anchorFrac.y;
				var xRatio:Number = masterLayer.map.tileOffsetX / masterLayer.map.tileSpacingY;
				var yRatio:Number = masterLayer.map.tileOffsetY / masterLayer.map.tileSpacingX;
				// TODO: The values here only work correctly when scaling from diagonal handles.
				var xOff:int = (xRatio * storedAnchorPos.y);
				var yOff:int = (yRatio * storedAnchorPos.x);
				storedAnchorPos.x += (xOff * newFracX);
				storedAnchorPos.y += (yOff * newFracY);
				xOff = (xRatio * anchorPos.y);
				yOff = (yRatio * anchorPos.x);
				anchorPos.x += (xOff * newFracX);
				anchorPos.y += (yOff * newFracY);
			}
			
			// Find the original and current offsets from the anchor.
			var originalOffsetX:Number;
			var originalOffsetY:Number;
			var currentOffsetX:Number;
			var currentOffsetY:Number;
			
			if ( clickedSprite.angle != 0 )
			{
				// Transform from the rotation to the original orientation to get each axes' offset.
				var mat:Matrix = new Matrix;
				var xOffset:Number = clickedSprite.storedAvatarPos.x + (clickedSprite.storedWidth * 0.5);
				var yOffset:Number = clickedSprite.storedAvatarPos.y + (clickedSprite.storedHeight * 0.5);
				mat.translate( -xOffset, -yOffset );
				mat.rotate( -clickedSprite.angle * Math.PI / 180 );
				mat.translate( xOffset, yOffset );
				mat.translate( -(clickedSprite.storedAvatarPos.x + storedAnchorPos.x), -(clickedSprite.storedAvatarPos.y + storedAnchorPos.y)); 
				var pt:Point = new Point;
				pt.x = newMousePosX-newOffsetX;
				pt.y = newMousePosY-newOffsetY;
				pt = mat.transformPoint( pt );
				originalOffsetX = pt.x;
				originalOffsetY = pt.y;
				
				pt.x = newMousePosX;
				pt.y = newMousePosY;
				pt = mat.transformPoint( pt );
				currentOffsetX = pt.x;
				currentOffsetY = pt.y;
			}
			else
			{
				anchorPos.x = storedAnchorPos.x + clickedSprite.storedAvatarPos.x;
				anchorPos.y = storedAnchorPos.y + clickedSprite.storedAvatarPos.y;
				originalOffsetX = (newMousePosX-newOffsetX) - anchorPos.x;
				originalOffsetY = (newMousePosY-newOffsetY) - anchorPos.y;
				currentOffsetX = newMousePosX - anchorPos.x;
				currentOffsetY = newMousePosY - anchorPos.y;
			}
			
			//trace( originalOffsetX + " => " + currentOffsetX );
			
			var frameWidth:Number = clickedSprite.width;
			var frameHeight:Number = clickedSprite.height;
			
			// If we start scaling too close to the centre then do nothing until the mouse has moved far enough from the centre.
			// This prevents it from scaling up too quickly.
			if ( Math.abs( originalOffsetX / clickedSprite.storedWidth ) < 0.2  )
			{
				var newOriginalOffsetX:Number = clickedSprite.storedWidth * 0.2;
				currentOffsetX = Math.max( newOriginalOffsetX, Math.abs(currentOffsetX) ) * Misc.sign(currentOffsetX);
				originalOffsetX = newOriginalOffsetX * Misc.sign(originalOffsetX);
			}
			if ( Math.abs( originalOffsetY / clickedSprite.storedHeight ) < 0.2  )
			{
				var newOriginalOffsetY:Number = clickedSprite.storedHeight * 0.2;
				currentOffsetY = Math.max( newOriginalOffsetY, Math.abs(currentOffsetY) ) * Misc.sign(currentOffsetY);
				originalOffsetY = newOriginalOffsetY * Misc.sign(originalOffsetY);
			}
			
			var scaleDiffX:Number = originalOffsetX ? Math.abs( currentOffsetX / originalOffsetX ): 1;
			var scaleDiffY:Number = originalOffsetY ? Math.abs( currentOffsetY / originalOffsetY ): 1;
			
			if ( FlxG.keys.pressed("S") || mouseOverDiagHandle )
			{
				// Handle uniform scaling.
				scaleDiffX = scaleDiffY = Math.max(scaleDiffX, scaleDiffY);
			}
			else if ( mouseOverHorizHandle )
			{
				scaleDiffY = 1;
			}
			else if ( mouseOverVertHandle )
			{
				scaleDiffX = 1;
			}
			
			// Now apply the changes to the sprite.
			var avatar:EditorAvatar = clickedSprite;
			{
				var newScaleDiffX:Number;
				var newScaleDiffY:Number;
				if ( avatar.AlwaysScaleUniformly() )
				{
					newScaleDiffX = newScaleDiffY = Math.max(scaleDiffX, scaleDiffY);
				}
				else
				{
					newScaleDiffX = scaleDiffX;
					newScaleDiffY = scaleDiffY;
				}
				avatar.scale.x = Math.min(avatar.storedAvatarScale.x * newScaleDiffX, 50 );
				avatar.scale.y = Math.min(avatar.storedAvatarScale.y * newScaleDiffY, 50 );
				if ( avatar.scale.x < 0.1 )
				{
					avatar.scale.x = 0.1;
				}
				if ( avatar.scale.y < 0.1 )
				{
					avatar.scale.y = 0.1;
				}
							

				avatar.width = avatar.storedWidth * ( avatar.scale.x / avatar.storedAvatarScale.x );
				avatar.height = avatar.storedHeight * ( avatar.scale.y / avatar.storedAvatarScale.y );
				
				var maxWidth:Number = Math.max(maxAvatarWidth, avatar.storedWidth);
				var maxHeight:Number = Math.max(maxAvatarHeight, avatar.storedHeight );
				
				if ( avatar.width > maxWidth )
				{
					avatar.width = maxWidth;
					avatar.scale.x = maxWidth / avatar.storedWidth;
				}
				if ( avatar.height > maxHeight )
				{
					avatar.height = maxHeight
					avatar.scale.y = maxHeight / avatar.storedHeight;
				}
				
				
				// Simulate scaling on the centre axis by moving it so the centre stays in the same place.
				avatar.x = avatar.storedAvatarPos.x - ( avatar.width - avatar.storedWidth ) * 0.5;
				avatar.y = avatar.storedAvatarPos.y - ( avatar.height - avatar.storedHeight ) * 0.5;
				
				if ( ModifySpriteImage && avatar.spriteEntry && avatar.spriteEntry.IsTileSprite )
				{
					if ( !avatar.TileDims )
					{
						avatar.TileDims = new FlxPoint(avatar.spriteEntry.previewBitmap.width, avatar.spriteEntry.previewBitmap.height);
					}
					avatar.scale.x = avatar.storedAvatarScale.x;
					avatar.scale.y = avatar.storedAvatarScale.y;
					avatar.TileDims.x = avatar.width / avatar.scale.x;
					avatar.TileDims.y = avatar.height / avatar.scale.y;
					avatar.SetAsTile();
				}
				// Both scaling and rotating can behave differently depending on how the user intends to implement them.
				// This solution works for the editor, leaving the user the freedom to handle the implementation hisself.
				avatar.offset.x = - ( avatar.width - avatar.frameWidth ) * 0.5;
				avatar.offset.y = - ( avatar.height - avatar.frameHeight ) * 0.5;
				
				if ( masterLayer && clickedHandle )
				{
					var ax:Number = avatar.storedAvatarPos.x;
					var ay:Number = avatar.storedAvatarPos.y;
					
					if ( masterLayer.map.tileOffsetX < 0 && handleDraggedFrac.y == 1 )
					{
						ax += ( masterLayer.map.tileOffsetX * (avatar.scale.y - avatar.storedAvatarScale.y) );
					}
					else if ( handleDraggedFrac.y == 0 )
					{
						if( masterLayer.map.tileOffsetX > 0 )
							ax -= ( masterLayer.map.tileOffsetX * (avatar.scale.y - avatar.storedAvatarScale.y) );
						ay -= ( masterLayer.map.tileSpacingY * (avatar.scale.y - avatar.storedAvatarScale.y) );
					}
					if ( masterLayer.map.tileOffsetY < 0 && handleDraggedFrac.x == 1 )
					{
						ay += (masterLayer.map.tileOffsetY * (avatar.scale.x - avatar.storedAvatarScale.x) );
					}
					else if ( handleDraggedFrac.x == 0 )
					{
						ax -= ( masterLayer.map.tileSpacingX * (avatar.scale.x - avatar.storedAvatarScale.x) );
						if( masterLayer.map.tileOffsetY > 0 )
							ay -= (masterLayer.map.tileOffsetY * (avatar.scale.x - avatar.storedAvatarScale.x) );
					}
					avatar.x = ax;
					avatar.y = ay;
					avatar.width = (masterLayer.map.tileSpacingX * avatar.scale.x) + Math.abs(masterLayer.map.tileOffsetX * avatar.scale.y);
					avatar.height = (masterLayer.map.tileSpacingY * avatar.scale.y) + Math.abs(masterLayer.map.tileOffsetY * avatar.scale.x);
				}
				else if ( !clickedSprite.attachment && clickedHandle )
				{
					var matrix:Matrix = new Matrix;
					xOffset = ( avatar.width * 0.5 );
					yOffset = ( avatar.height * 0.5 );
					
					matrix.translate( xOffset, yOffset );
					matrix.translate( -avatar.width * anchorFrac.x, -avatar.height * anchorFrac.y );
					matrix.rotate(avatar.angle * Math.PI / 180);
					matrix.translate( -xOffset, -yOffset);
					
					
					pt = matrix.transformPoint( new Point( 0, 0 ) );
					
					// Find out the location of the anchor before we began this scaling operation.
					if ( avatar.angle != 0 )
					{
						xOffset = avatar.storedAvatarPos.x + (avatar.storedWidth * 0.5);
						yOffset = avatar.storedAvatarPos.y + (avatar.storedHeight * 0.5);
						matrix.identity();
						matrix.translate( -xOffset, -yOffset );
						matrix.rotate(avatar.angle * Math.PI / 180 );
						matrix.translate( xOffset, yOffset );
			
						var pt2:Point = new Point( avatar.storedAvatarPos.x +storedAnchorPos.x, avatar.storedAvatarPos.y +storedAnchorPos.y);
						pt2 = matrix.transformPoint( pt2 );
						avatar.x = pt2.x;
						avatar.y = pt2.y;
					}
					else
					{
						avatar.x = avatar.storedAvatarPos.x + storedAnchorPos.x;
						avatar.y = avatar.storedAvatarPos.y + storedAnchorPos.y;
					}
					// Add to the original location of the anchor.
					avatar.x += pt.x;
					avatar.y += pt.y;
					
				}
				
				avatar.OnResize( );
			}
		}
		
		override public function CopyData():void
		{
			if ( selectedSprites.length == 0 )
			{
				return;
			}
			
			var data:SpriteClipboardData = new SpriteClipboardData();
			var i:uint = selectedSprites.length;
			while ( i-- )
			{
				// No copying of sprite trails as they always have to be attached to work properly.
				if ( !(selectedSprites[i] is SpriteTrailObject ) )
				{
					data.avatars.push( selectedSprites[i].CreateClipboardCopy() );
				}
			}
			if ( data.avatars.length )
			{
				Clipboard.SetData( data );
			}
		}
		
		override public function PasteData():void
		{
			var data:SpriteClipboardData = Clipboard.GetData( ) as SpriteClipboardData;
			
			if ( data == null )
			{
				return;
			}
			
			var spriteLayer:LayerSprites = App.getApp().CurrentLayer as LayerSprites;
			
			if ( spriteLayer == null || !spriteLayer.IsVisible() || spriteLayer.Locked())
			{
				return;
			}

			centerMousePosToScreen( spriteLayer );
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			
			selectionChanged = true;
			selectedSprites.length = 0;
			
			var i:uint = data.avatars.length;
			
			data.avatars[0].GetSnappedPos(mousePos, modifiedMousePos, true);
			var xOffset:Number = data.avatars[0].x - modifiedMousePos.x;
			var yOffset:Number = data.avatars[0].y - modifiedMousePos.y;
			
			var newAvatars:Vector.<EditorAvatar> = new Vector.<EditorAvatar>;
			while ( i-- )
			{
				var newSprite:EditorAvatar = data.avatars[i].CreateClipboardCopy();
				newSprite.x -= xOffset;
				newSprite.y -= yOffset;
				newSprite.layer = spriteLayer;
				spriteLayer.sprites.add(newSprite, true);
				spriteLayer.UpdateMinMax( newSprite );
				selectedSprites.push(newSprite);
				newAvatars.push(newSprite);
				
				if ( newSprite.layer.AutoDepthSort )
				{
					newSprite.layer.SortAvatar(newSprite);
				}
			}
			
			HistoryStack.BeginOperation( new OperationPasteAvatars(this, spriteLayer, newAvatars) );
		}
		
		override protected function DecideContextMenuActivation( ):void
		{
			var oldSelection:EditorAvatar = selectedSprites.length ? selectedSprites[0] : null;
			selectionChanged = true;
			selectedSprites.length = 0;
			// If we click down on an already selected sprite then we initiate move mode.

			var spriteLayer:LayerSprites = App.getApp().CurrentLayer as LayerSprites;
			if ( spriteLayer && spriteLayer.IsVisible() )
			{
				var bestAvatar:EditorAvatar = null;
				if ( oldSelection && oldSelection.IsOverScreenPos( mouseScreenPos, usePixelPerfectSelection ) )
				{
					bestAvatar = oldSelection;
				}
				else
				{
					for each( var avatar:EditorAvatar in spriteLayer.sprites.members )
					{
						if ( avatar.CanSelect() && avatar.IsOverScreenPos( mouseScreenPos, usePixelPerfectSelection ) )
						{
							bestAvatar = avatar;
							break;
						}
					}
				}
				if ( bestAvatar )
				{
					if ( updateTileListForSprite( bestAvatar.spriteEntry, true, SpriteIndexChanged, ModifySprites) )
					{
						currentTileListSpriteEntry = bestAvatar.spriteEntry;
					}
					selectedSprites.push( bestAvatar );
					if ( bestAvatar.attachment )
					{
						attachMenuItem.enabled = false;
						detachMenuItem.enabled = true;
					}
					else
					{
						attachMenuItem.enabled = true;
						detachMenuItem.enabled = false;
					}
					
					setSpritePreviewMenuItem.enabled = !bestAvatar.isTileSprite;
					resetSpriteMenuItem.enabled = ( bestAvatar.isTileSprite && ( bestAvatar.TileDims || bestAvatar.TileOrigin) ) || ( !bestAvatar.isTileSprite && bestAvatar.animIndex != -1 )
					
					contextMenu.display( FlxG.stage, FlxG.stage.mouseX, FlxG.stage.mouseY );
					// Only select the first one.
					return;
				}
			}
			// Fallback case. Just show menu options that don't require a selected sprite.
			var tempMenu:NativeMenu = new NativeMenu;
			addNewContextMenuItem(tempMenu, "Attach sprite trail", contextMenuHandler );
			tempMenu.display( FlxG.stage, FlxG.stage.mouseX, FlxG.stage.mouseY );
		}
		
		override protected function contextMenuHandler(event:Event):void
		{			
			switch( event.target.label )
			{
			case "Attach to path":
				if ( selectedSprites.length )
				{
					AvatarToAttach = selectedSprites[0];
					HistoryStack.BeginOperation( new OperationAttachAvatar( AvatarToAttach ) );
					InAttachMode = true;
				}
				break;
				
			case "Detach from path":
				if ( selectedSprites.length )
				{
					selectedSprites.length = 1;
					var avatar:EditorAvatar = selectedSprites[0];
					
					if ( avatar is SpriteTrailObject )
					{
						HistoryStack.BeginOperation( new OperationDetachSpriteTrail( avatar as SpriteTrailObject) );
						avatar.DetachAvatar();
						DeleteSelection();
						HistoryStack.CancelLastOperation( HistoryStack.GetLastOperation() );
					}
					else
					{
						HistoryStack.BeginOperation( new OperationDetachAvatar( avatar ) );
						avatar.DetachAvatar();
					}
					InAttachMode = false;
				}
				break;
				
			case "Attach sprite trail":
				var spriteLayer:LayerAvatarBase = App.getApp().CurrentLayer as LayerAvatarBase;
				var spriteTrail:SpriteTrailObject = new SpriteTrailObject(spriteLayer);
				spriteTrail.trailData = Global.spriteTrailData.Clone();
				AvatarToAttach = spriteTrail;
				AvatarToAttach.CreateGUID();
				// Not added until the path is selected, otherwise it cancels it by simply forgetting about it...
				InAttachMode = true;
				break;
				
			case "Set Position...":
				if ( selectedSprites.length )
				{
					App.CreatePopupWindow( SetObjectCoordsPopup, true );
				}
				break;
				
			case "Edit Sprite Entry...":
				if ( selectedSprites.length )
				{
					var entry:SpriteEntry = selectedSprites[0].spriteEntry;
					if ( entry.IsTileSprite )
					{
						var popup:SpriteTileDataPopup = App.CreatePopupWindow(SpriteTileDataPopup,true) as SpriteTileDataPopup;
						if ( popup )
						{
							popup.opener = this;
							popup.Entry = entry;
						}
					}
					else
					{
						var spriteAnimPopup:SpriteDataPopup = App.CreatePopupWindow(SpriteDataPopup,true) as SpriteDataPopup;
						if ( spriteAnimPopup )
						{
							spriteAnimPopup.opener = this;
							spriteAnimPopup.Entry = entry;
						}
					}
				}
				break;
				
			case resetSpriteMenuItem.label:
				if ( selectedSprites.length && selectedSprites[0].spriteEntry )
				{
					avatar = selectedSprites[0];
					avatar.TileDims = null;
					avatar.TileOrigin = null;
					avatar.animIndex = -1;
					if ( avatar.isTileSprite )
					{
						avatar.frameWidth = avatar.spriteEntry.previewBitmap.width;
						avatar.frameHeight = avatar.spriteEntry.previewBitmap.height;
						avatar.offset.x = - ( avatar.width - avatar.frameWidth ) * 0.5;
						avatar.offset.y = - ( avatar.height - avatar.frameHeight ) * 0.5;
						avatar.scale.x = avatar.width / avatar.frameWidth;
						avatar.scale.y = avatar.height / avatar.frameHeight;
						avatar.SetAsTile();
					}
					else
					{
						avatar.SetAnimIndex( -1);
					}
				}
				break;
				
			case setSpritePreviewMenuItem.label:
				if ( selectedSprites.length && selectedSprites[0].spriteEntry && !selectedSprites[0].isTileSprite )
				{
					selectedSprites[0].SetAnimIndex( App.getApp().myTileList.selectedIndex - 1);
				}
				break;
				
			default:
				super.contextMenuHandler(event);
				break;
			}
		}
		
		public function ChangeSelectionToSprite(sprite:SpriteEntry):void
		{
			var i:uint = selectedSprites.length;
			if ( i )
			{
				HistoryStack.BeginOperation(new OperationChangeSpritesToSpriteEntry(selectedSprites));
				while ( i-- )
				{
					if ( !sprite.IsTileSprite )
						selectedSprites[i].animIndex = sprite.tilePreviewIndex;
					selectedSprites[i].SetFromSpriteEntry(sprite);
				}
			}
		}
		
		override public function GetSelectedSpriteEntry():SpriteEntry
		{
			return currentTileListSpriteEntry;
		}
		
	}

}
import com.Game.EditorAvatar;

internal class SpriteClipboardData
{
	public var avatars:Vector.<EditorAvatar> = new Vector.<EditorAvatar>();
}