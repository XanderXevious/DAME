package com.Editor 
{
	import com.EditorState;
	import com.Game.AvatarLink;
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Operations.HistoryStack;
	import com.Operations.OperationAddLink;
	import com.Operations.OperationDeleteAvatar;
	import com.Operations.OperationDeleteLink;
	import com.Operations.OperationMoveAvatar;
	import com.Properties.PropertyBase;
	import com.Properties.PropertyData;
	import com.Utils.DebugDraw;
	import com.Utils.Global;
	import com.Utils.Hits;
	import com.Utils.Misc;
	import flash.display.NativeMenu;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.system.System;
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.managers.CursorManager;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import org.flixel.FlxU;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeAvatarsBase extends EditorType
	{
		protected var selectedAvatarLink:AvatarLink = null;
		protected var selectedSprites:Vector.<EditorAvatar> = new Vector.<EditorAvatar>();
		protected var layerClassType:Class;
		protected var SpriteDeletedCallback:Function = null;
		protected var usePixelPerfectSelection:Boolean = false;
		
		protected var clickedSprite:EditorAvatar = null;
		protected var lastSpriteClickedOn:EditorAvatar = null;
		protected var originalAngleFromSelectedSprite:Number = 0;
		
		protected var drawMarquees:Boolean = true;
		
		public static const maxAvatarWidth:Number = 5000;
		public static const maxAvatarHeight:Number = 5000;
		
		[Embed(source="../../../assets/scaleCursor.png")]
        private static var scaleCursor:Class;
		
		[Embed(source="../../../assets/scaleHorizCursor.png")]
        private static var scaleHorizCursor:Class;
		
		[Embed(source="../../../assets/scaleVertCursor.png")]
        private static var scaleVertCursor:Class;
		
		[Embed(source="../../../assets/rotateCursor.png")]
        private static var rotateCursor:Class;
		
		
		protected var mouseOverHorizHandle:Boolean = false;
		protected var mouseOverVertHandle:Boolean = false;
		protected var mouseOverDiagHandle:Boolean = false;
		protected var mouseOverRotateHandle:Boolean = false;
		protected var handleDraggedFrac:FlxPoint = new FlxPoint;
		private var currentAvatarUnderCursor:EditorAvatar = null;
		
		protected var selectionChanged:Boolean = false;
		protected var multiSelectDataProvider:ArrayCollection = new ArrayCollection();
		private var usingMultiSelectProps:Boolean = false;
		private var multiSelectCurrentPropId:int = 1;
		
		public override function EditorTypeAvatarsBase(editor:EditorState) 
		{
			super( editor );
			
			contextMenu = new NativeMenu();
			addNewContextMenuItem(contextMenu, "Copy GUID", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Link To Another Object", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Delete", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Send To Front", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Send To Back", contextMenuHandler );
			
			selectionEnabled = true;
			
			allowRotation = true;
			
			multiSelectDataProvider.addEventListener( CollectionEvent.COLLECTION_CHANGE, propertyDataChanged );
		}
		
		override public function Update( isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			if ( !isActive )
			{
				return;
			}
			
			var moveToFront:Boolean = FlxG.keys.pressed( "PLUS" );
			var moveToBack:Boolean = FlxG.keys.pressed( "MINUS" );
			
			if ( moveToFront || moveToBack )
			{
				var app:App = App.getApp();
				var layer:* = app.CurrentLayer as layerClassType;
				if ( layer )
				{
					for ( var i:uint = 0; i < selectedSprites.length; i++ )
					{
						var avatar:EditorAvatar = selectedSprites[i];

						if ( moveToFront && avatar.SendToLayerFront() )
						{
							selectionChanged = true;
						}
						else if (moveToBack && avatar.SendToLayerBack() )
						{
							selectionChanged = true;
						}
					}
				}
			}
			else if ( !FlxG.keys.pressed("CONTROL") && !FlxG.keys.pressed("SHIFT") && !Global.windowedApp.IsEditingProperty )
			{
				var moveDirX:int = 0;
				var moveDirY:int = 0;
				if ( FlxG.keys.justPressed("LEFT") )
					moveDirX = -1;
				else if ( FlxG.keys.justPressed("RIGHT") )
					moveDirX = 1;
				if ( FlxG.keys.justPressed("UP") )
					moveDirY = -1;
				else if ( FlxG.keys.justPressed("DOWN") )
					moveDirY = 1;
				if ( moveDirX || moveDirY )
				{
					i = selectedSprites.length;
					if ( i )
					{
						HistoryStack.BeginOperation(new OperationMoveAvatar( selectedSprites ) );
						while(i--)
						{
							avatar = selectedSprites[i];
							if ( avatar.CanMove() )
							{
								avatar.x += moveDirX;
								avatar.y += moveDirY;

								if ( avatar.layer.AutoDepthSort )
								{
									avatar.layer.SortAvatar(avatar);
								}
								if ( avatar.attachment )
								{
									if( avatar.attachment.Parent )
									{
										avatar.attachment.Parent.RefreshAttachmentValues();
									}
									else if ( avatar.attachment.Child )
									{
										avatar.attachment.Child.UpdateAttachment();
									}
								}
							}
						}
					}
				}
			}
		}
		
		private function AdjustSnappedScreenPos( avatar:EditorAvatar, x:Number, y:Number ):void
		{
			if ( GuideLayer.SnappingEnabled )
			{
				mouseScreenPos = EditorState.getScreenXYFromMapXYPrecise(x, y, avatar.scrollFactor.x, avatar.scrollFactor.y);
			}
		}
		
		override protected function UpdateDisplay( layer:LayerEntry ):void
		{
			var assignedCursor:Boolean = false;
			
			// Don't take mouseScreenPos as that gets modified if constraining axes.
			var unscaledScreenPos:FlxPoint = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
			var mouseMapPos:FlxPoint = EditorState.getMapXYFromScreenXY(unscaledScreenPos.x, unscaledScreenPos.y, layer.xScroll, layer.yScroll);
			mouseMapPos.multiplyBy(FlxG.extraZoom);
			var screenPos:FlxPoint = new FlxPoint(unscaledScreenPos.x * FlxG.extraZoom, unscaledScreenPos.y * FlxG.extraZoom);
					
			currentAvatarUnderCursor = null;
			if ( !isRotating && !isScaling )
			{
				mouseOverDiagHandle = false;
				mouseOverHorizHandle = false;
				mouseOverVertHandle = false;
				mouseOverRotateHandle = false;
			}
			
			if ( AvatarToLinkFrom && !AvatarToLinkFrom.markForDeletion )
			{
				// Because the from Avatar may be on a different layer its coords must be mapped to the screen and onto this layer.
				var fromPos:FlxPoint = EditorState.getScreenXYFromMapXY(AvatarToLinkFrom.x + AvatarToLinkFrom.width/2, AvatarToLinkFrom.y + AvatarToLinkFrom.height/2, AvatarToLinkFrom.layer.xScroll, AvatarToLinkFrom.layer.yScroll,false);
				fromPos = EditorState.getMapXYFromScreenXY(fromPos.x, fromPos.y, layer.xScroll, layer.yScroll);
				fromPos.multiplyBy(FlxG.extraZoom);
				var scrollFactors:FlxPoint = new FlxPoint(layer.xScroll, layer.yScroll);
				DebugDraw.DrawLine(fromPos.x, fromPos.y, mouseMapPos.x, mouseMapPos.y, scrollFactors, false, 0xffffffff, true, true);
			}
			
			AvatarLink.DrawLinksForLayer(layer, selectedAvatarLink);
			
			var i:uint;
			
			i = selectedSprites.length;
			while(i--)
			{
				var overScaleHandle:Boolean = false;
				
				var avatar:EditorAvatar = selectedSprites[i];
				avatar.selected = true;
				// Extend the area to show handles and allow rotations a little bit. 8 pixels should do.
				var showHandles:Boolean = Global.MarqueesVisible && drawMarquees && avatar.IsOverScreenPos( screenPos, false, 8 );
				avatar.DrawBoundingBox( layer == avatar.layer ? Global.SelectionColour : Global.SelectionColourOtherLayer, true, showHandles && (avatar.CanRotate() || avatar.CanScale()) );
				if ( showHandles == true && !assignedCursor && !isScaling && !isRotating && !isMovingItems && (avatar.CanRotate() || avatar.CanScale() ) )
				{
					mouseMapPos = EditorState.getMapXYFromScreenXY(unscaledScreenPos.x, unscaledScreenPos.y, avatar.scrollFactor.x, avatar.scrollFactor.y);
					//mouseMapPos.multiplyBy(FlxG.extraZoom);
					var x1:Number = avatar.left;// >> FlxG.zoomBitShifter;
					var y1:Number = avatar.top;// >> FlxG.zoomBitShifter;
					var x2:Number = avatar.right;// >> FlxG.zoomBitShifter;
					var y2:Number = avatar.bottom;// >> FlxG.zoomBitShifter;
					
					var masterLayer:LayerMap;
			
					if ( avatar.SkewAlignment() )
					{
						masterLayer = avatar.layer.parent.FindMasterLayer();
					}
					if ( avatar.angle == 0 && !masterLayer )
					{
						// Unrotated sprites...
						if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x1, y1, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, x1, y1);
							handleDraggedFrac.create_from_points(0, 0);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x2, y1, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, x2, y1);
							handleDraggedFrac.create_from_points(1, 0);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x1, y2, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, x1, y2);
							handleDraggedFrac.create_from_points(0, 1);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else if( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x2, y2, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, x2, y2);
							handleDraggedFrac.create_from_points(1, 1);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else
						{
							var x1x2:Number = x1 + 0.5 * (x2 - x1);
							var y1y2:Number = y1 + 0.5 * (y2 - y1);
							if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x1x2, y1, 3 ) )
							{
								AdjustSnappedScreenPos(avatar, x1x2, y1);
								handleDraggedFrac.create_from_points(0.5, 0);
								overScaleHandle = mouseOverVertHandle = true;
							}
							else if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x1x2, y2, 3 ) )
							{
								AdjustSnappedScreenPos(avatar, x1x2, y2);
								handleDraggedFrac.create_from_points(0.5, 1);
								overScaleHandle = mouseOverVertHandle = true;
							}
							else if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x1, y1y2, 3 ) )
							{
								AdjustSnappedScreenPos(avatar, x1, y1y2);
								handleDraggedFrac.create_from_points(0, 0.5);
								overScaleHandle = mouseOverHorizHandle = true;
							}
							else if ( Hits.PointIsInUnrotatedRectangleRange( mouseMapPos, x2, y1y2, 3 ) )
							{
								AdjustSnappedScreenPos(avatar, x2, y1y2);
								handleDraggedFrac.create_from_points(1, 0.5);
								overScaleHandle = mouseOverHorizHandle = true;
							}
						}
					}
					else
					{
						// Rotated sprites...
						
						var avatarTopLeft:FlxPoint = EditorState.getScreenXYFromMapXY( avatar.left, avatar.top, avatar.scrollFactor.x, avatar.scrollFactor.y );
						var avatarBottomRight:FlxPoint = EditorState.getScreenXYFromMapXY( avatar.right, avatar.bottom, avatar.scrollFactor.x, avatar.scrollFactor.y );
						if ( !masterLayer )
						{
							var matrix:Matrix = avatar.GetTransformMatrixForRealPosToDrawnPos(avatarTopLeft, avatar.angle);
							
							/*var pt1:Point = new Point(x1, y1);
							var pt2:Point = new Point(x2, y1);
							var pt3:Point = new Point(x1, y2);
							var pt4:Point = new Point(x2, y2);
							
							pt1 = matrix.transformPoint(pt1);
							pt2 = matrix.transformPoint(pt2);
							pt3 = matrix.transformPoint(pt3);
							pt4 = matrix.transformPoint(pt4);*/
							var pt1:FlxPoint = new FlxPoint(0, matrix.transformPoint(avatarTopLeft.toPoint()));
							var pt2:FlxPoint = new FlxPoint(0, matrix.transformPoint(new Point(avatarBottomRight.x,avatarTopLeft.y)));
							var pt3:FlxPoint = new FlxPoint(0, matrix.transformPoint(new Point(avatarTopLeft.x,avatarBottomRight.y)));
							var pt4:FlxPoint = new FlxPoint(0, matrix.transformPoint(avatarBottomRight.toPoint()));
							
							
						}
						else
						{
							pt1 = new FlxPoint(avatar.x + ( ( masterLayer.map.tileOffsetX < 0 ) ? - masterLayer.map.tileOffsetX * avatar.scale.y : 0 ),avatar.y + ( ( masterLayer.map.tileOffsetY < 0 ) ? - masterLayer.map.tileOffsetY * avatar.scale.x : 0 ));
							pt2 = new FlxPoint(pt1.x + ( masterLayer.map.tileSpacingX * avatar.scale.x ), pt1.y + ( masterLayer.map.tileOffsetY * avatar.scale.x ));
							pt4 = new FlxPoint(pt2.x + ( masterLayer.map.tileOffsetX * avatar.scale.y ), pt2.y + ( masterLayer.map.tileSpacingY * avatar.scale.y ));
							pt3 = new FlxPoint(pt1.x + ( masterLayer.map.tileOffsetX * avatar.scale.y ), pt1.y + ( masterLayer.map.tileSpacingY * avatar.scale.y ));
						}
						
						if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt1.x, pt1.y, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, pt1.x, pt1.y);
							handleDraggedFrac.create_from_points(0, 0);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt2.x, pt2.y, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, pt2.x, pt2.y);
							handleDraggedFrac.create_from_points(1, 0);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt3.x, pt3.y, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, pt3.x, pt3.y);
							handleDraggedFrac.create_from_points(0, 1);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt4.x, pt4.y, 3 ) )
						{
							AdjustSnappedScreenPos(avatar, pt4.x, pt4.y);
							handleDraggedFrac.create_from_points(1, 1);
							overScaleHandle = mouseOverDiagHandle = true;
						}
						else
						{
							if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt1.x + 0.5 * (pt2.x - pt1.x), pt1.y + 0.5 * (pt2.y - pt1.y), 3 ) )
							{
								AdjustSnappedScreenPos(avatar, pt1.x + 0.5 * (pt2.x - pt1.x), pt1.y + 0.5 * (pt2.y - pt1.y));
								handleDraggedFrac.create_from_points(0.5, 0);
								overScaleHandle = mouseOverVertHandle = true;
							}
							else if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt3.x + 0.5 * (pt4.x - pt3.x), pt3.y + 0.5 * (pt4.y - pt3.y), 3 ) )
							{
								AdjustSnappedScreenPos(avatar, pt3.x + 0.5 * (pt4.x - pt3.x), pt3.y + 0.5 * (pt4.y - pt3.y));
								handleDraggedFrac.create_from_points(0.5, 1);
								overScaleHandle = mouseOverVertHandle = true;
							}
							else if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt1.x + 0.5 * (pt3.x - pt1.x), pt1.y + 0.5 * (pt3.y - pt1.y), 3 ) )
							{
								AdjustSnappedScreenPos(avatar, pt1.x + 0.5 * (pt3.x - pt1.x), pt1.y + 0.5 * (pt3.y - pt1.y));
								handleDraggedFrac.create_from_points(0, 0.5);
								overScaleHandle = mouseOverHorizHandle = true;
							}
							else if ( Hits.PointIsInUnrotatedRectangleRange( screenPos, pt2.x + 0.5 * (pt4.x - pt2.x), pt2.y + 0.5 * (pt4.y - pt2.y), 3 ) )
							{
								AdjustSnappedScreenPos(avatar, pt2.x + 0.5 * (pt4.x - pt2.x), pt2.y + 0.5 * (pt4.y - pt2.y));
								handleDraggedFrac.create_from_points(1, 0.5);
								overScaleHandle = mouseOverHorizHandle = true;
							}
							
						}
					}
					if ( !overScaleHandle )
					{
						// Check if you're in the area between the outer area and the actual bounds.
						if ( allowRotation && avatar.CanRotate() && !avatar.IsOverScreenPos( screenPos, false, 0 ) )
						{
							assignedCursor = true;
							mouseOverRotateHandle = true;
						}
					}
					else
					{
						if ( avatar.CanScale() )
						{
							assignedCursor = true;
						}
						else
						{
							mouseOverHorizHandle = mouseOverDiagHandle = mouseOverVertHandle = false;
						}
					}
					
					if ( assignedCursor )
					{
						currentAvatarUnderCursor = avatar;
					}
					// Work out if we should show a transformation cursor.
					if ( mouseOverDiagHandle && currentCursorClass!=scaleCursor )
					{
						if ( cursorId != -1)
						{
							CursorManager.removeCursor(cursorId);
						}
						currentCursorClass = scaleCursor;
						cursorId = CursorManager.setCursor(currentCursorClass, 2, -10, -10);
					}
					else if ( mouseOverHorizHandle && currentCursorClass!=scaleHorizCursor )
					{
						if ( cursorId != -1)
						{
							CursorManager.removeCursor(cursorId);
						}
						currentCursorClass = scaleHorizCursor;
						cursorId = CursorManager.setCursor(currentCursorClass, 2, -10, -10);
					}
					else if ( mouseOverVertHandle && currentCursorClass!=scaleVertCursor )
					{
						if ( cursorId != -1)
						{
							CursorManager.removeCursor(cursorId);
						}
						currentCursorClass = scaleVertCursor;
						cursorId = CursorManager.setCursor(currentCursorClass, 2, -10, -10);
					}
					else if ( mouseOverRotateHandle && currentCursorClass!= rotateCursor )
					{
						if ( cursorId != -1)
						{
							CursorManager.removeCursor(cursorId);
						}
						currentCursorClass = rotateCursor;
						cursorId = CursorManager.setCursor(currentCursorClass, 2, -10, -10);
					}
				}
			}
			
			if ( !assignedCursor && currentCursorClass!=null && !isScaling && !isRotating )
			{
				currentCursorClass = null;
				if ( cursorId != -1 )
				{
					CursorManager.removeCursor(cursorId);
					cursorId = -1;
				}
			}
		}
		
		private function propertyDataChanged(event:CollectionEvent):void
		{
			if ( usingMultiSelectProps && selectedSprites.length > 1 )
			{
				var j:uint = selectedSprites.length;
				var k:uint;
				var changedProp:PropertyBase;
				var prop:PropertyBase;
				var props:ArrayCollection;
				
				if ( event.kind == CollectionEventKind.UPDATE )
				{
					changedProp = event.items[0].source as PropertyBase;
					// The contents of the data have changed so update all objects to contain this new value.
					while ( j-- )
					{
						props = selectedSprites[j].properties;
						k = props.length;
						while ( k-- )
						{
							prop = props[k] as PropertyBase;
							if ( prop.sharedId == changedProp.sharedId )
							{
								prop.Name = changedProp.Name;
								prop.Value = changedProp.Value;
							}
						}
					}
				}
				else if ( event.kind == CollectionEventKind.ADD )
				{
					changedProp = event.items[0] as PropertyBase;
					changedProp.sharedId = multiSelectCurrentPropId;
					while ( j-- )
					{
						props = selectedSprites[j].properties;
						prop = changedProp.Clone();
						prop.sharedId = changedProp.sharedId;
						props.addItem( prop )
					}
					multiSelectCurrentPropId++;
				}
				else if ( event.kind == CollectionEventKind.REMOVE )
				{
					changedProp = event.items[0] as PropertyBase;
					while ( j-- )
					{
						props = selectedSprites[j].properties;
						k = props.length;
						while ( k-- )
						{
							prop = props[k] as PropertyBase;
							if ( prop.sharedId == changedProp.sharedId )
							{
								props.removeItemAt( k );
							}
						}
					}
				}
			}
		}
		
		override public function GetCurrentObjectProperties():ArrayCollection
		{
			usingMultiSelectProps = false;
			var selectionHadChanged:Boolean = selectionChanged;
			selectionChanged = false;
			
			if ( selectedSprites.length )
			{
				if ( selectedSprites.length > 1 )
				{
					if ( selectionHadChanged )
					{
						multiSelectDataProvider.removeAll();
						var props:ArrayCollection;
						// We only display properties shared by all selected sprites,
						// so first populate with the props of the 1st sprite.
						props = selectedSprites[0].properties;
						for ( var i:uint = 0; i < props.length; i++ )
						{
							var propShared:Boolean = true;
							var prop:PropertyBase = props[i] as PropertyBase;
							var isData:Boolean = prop is PropertyData;
							for ( var j:uint = 1; j < selectedSprites.length && propShared; j++ )
							{
								var propSharedInSprite:Boolean = false;
								var props2:ArrayCollection = selectedSprites[j].properties;
								var k:uint = props2.length;
								// Find the property in the other sprite.
								while (k-- && !propSharedInSprite)
								{
									var prop2:PropertyBase = props2[k] as PropertyBase;
									// Must be exactly the same type of property.
									if ( prop2.Name == prop.Name && prop2.Type == prop.Type)
									{
										if ( (prop2 is PropertyData) == isData )
										{
											prop2.sharedId = i;
											propSharedInSprite = true;
										}
									}
								}
								if ( !propSharedInSprite )
								{
									propShared = false;
								}
							}
							if ( propShared )
							{
								prop.sharedId = i;
								prop = prop.Clone();
								prop.sharedId = i;
								multiSelectDataProvider.addItem( prop );
								multiSelectCurrentPropId = i + 1;
							}
						}
					}
					usingMultiSelectProps = true;
					return multiSelectDataProvider;
				}
				usingMultiSelectProps = false;
				return selectedSprites[0].properties;
			}
			else if ( selectedAvatarLink )
			{
				usingMultiSelectProps = false;
				return selectedAvatarLink.properties;
			}
			return null;
		}
		
		protected function RecalcSelectionBox( boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):void
		{
			// Resolve the cases where we sized the box backwards in 1 or 2 directions.
			if ( selectionBoxStart.x > selectionBoxEnd.x )
			{
				var temp:int = selectionBoxStart.x;
				selectionBoxStart.x = selectionBoxEnd.x;
				selectionBoxEnd.x = temp;
			}
			if ( selectionBoxStart.y > selectionBoxEnd.y )
			{
				temp = selectionBoxStart.y;
				selectionBoxStart.y = selectionBoxEnd.y;
				selectionBoxEnd.y = temp;
			}
			
			var app:App = App.getApp();
			// Need to remap the box into screen space so that everything can be dealt with in screen space.
			boxTopLeft.copyFrom( EditorState.getScreenXYFromMapXY( selectionBoxStart.x/FlxG.extraZoom, selectionBoxStart.y/FlxG.extraZoom, app.CurrentLayer.xScroll, app.CurrentLayer.yScroll ) );
			boxBottomRight.copyFrom( EditorState.getScreenXYFromMapXY( selectionBoxEnd.x/FlxG.extraZoom, selectionBoxEnd.y/FlxG.extraZoom, app.CurrentLayer.xScroll, app.CurrentLayer.yScroll ) );
		}
		
		override protected function SelectInsideBox( layer:LayerEntry, boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean
		{
			boxTopLeft = new FlxPoint;
			boxBottomRight = new FlxPoint;
			RecalcSelectionBox( boxTopLeft, boxBottomRight );
			
			var avatarTopLeft:FlxPoint;
			var avatarBottomRight:FlxPoint;
			var app:App = App.getApp();
				
			var i:uint = app.layerGroups.length;
			while( i-- )
			{
				var group:LayerGroup = app.layerGroups[i];
				var j:uint = group.children.length;
				while( j-- )
				{
					var layerEntry:LayerEntry = group.children[j];
					if ( Global.SelectFromCurrentLayerOnly && layerEntry != layer )
					{
						continue;
					}
					if ( layerEntry is layerClassType && layerEntry.IsVisible() )
					{
						var spriteLayer:* = layerEntry as layerClassType;
						var k:uint = spriteLayer.sprites.members.length;
						while( k-- )
						{
							var avatar:EditorAvatar = spriteLayer.sprites.members[k];
							if( avatar.CanSelect() && avatar.IsWithinScreenBox( boxTopLeft, boxBottomRight ) )
							{
								var removedItem:Boolean = false;
								if ( FlxG.keys.pressed( "CONTROL" ) )
								{
									var index:int = selectedSprites.indexOf( avatar );
									if ( index != -1 )
									{
										selectedSprites.splice(index, 1);
										selectionChanged = true;
										removedItem = true;
									}
								}
								
								if( !removedItem )
								{
									selectedSprites.push( avatar );
									selectionChanged = true;
									if ( AvatarToLinkFrom && AvatarToLinkFrom != avatar && !AvatarToLinkFrom.markForDeletion )
									{
										var newLink:AvatarLink = AvatarLink.GenerateLink(AvatarToLinkFrom, avatar);
										HistoryStack.BeginOperation(new OperationAddLink(newLink));
										AvatarToLinkFrom = null;
									}
								}
							}
						}
					}
				}
			}
			return selectedSprites.length != 0;
		}
		
		override protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint
		{
			var index:uint = 0;
			var isOnItem:uint = SELECTED_NONE;
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			clickedSprite = null;
			lastSpriteClickedOn = null;
			if ( currentAvatarUnderCursor != null )
			{
				if ( mouseOverRotateHandle && allowRotation )
				{
					clickedSprite = currentAvatarUnderCursor;
					isOnItem = SELECTED_ITEM_AND_SET_STATE;
					isRotating = true;
					originalAngleFromSelectedSprite = GetAngleOfPointFromAvatar(modifiedMousePos, clickedSprite, clickedSprite, clickedSprite.angle);
				}
				else if ( allowScaling )
				{
					if ( mouseOverDiagHandle || mouseOverHorizHandle || mouseOverVertHandle )
					{
						clickedSprite = currentAvatarUnderCursor;
						isOnItem = SELECTED_ITEM_AND_SET_STATE;
						isScaling = true;
					}
				}
			}
			if ( isOnItem == SELECTED_NONE )
			{
				// If we click down on an already selected sprite then we initiate move mode.
				for each( var avatar:EditorAvatar in selectedSprites )
				{
					if ( avatar.IsOverScreenPos( mouseScreenPos ) )
					{
						lastSpriteClickedOn = avatar;
						// HOLD CTRL to remove items from the selection.
						if ( FlxG.keys.pressed( "CONTROL" ) )
						{
							//selectedSprites.splice(index, 1);
							//index--;
							isOnItem = SELECTED_AND_REMOVED;
							break;
						}
						else
						{
							clickedSprite = avatar;
							if ( allowRotation )
							{
								originalAngleFromSelectedSprite = GetAngleOfPointFromAvatar(modifiedMousePos, avatar, avatar, avatar.angle);
							}
							isOnItem = SELECTED_ITEM;
							if ( AvatarToLinkFrom && AvatarToLinkFrom != avatar && !AvatarToLinkFrom.markForDeletion )
							{
								var newLink:AvatarLink = AvatarLink.GenerateLink(AvatarToLinkFrom, avatar);
								HistoryStack.BeginOperation(new OperationAddLink(newLink));
								AvatarToLinkFrom = null;
							}
							
							break;
						}
					}
					index++;
				}
			}
			
			if ( isOnItem )
			{
				for each( avatar in selectedSprites )
				{
					avatar.storedAvatarPos.copyFrom(avatar);
					avatar.storedAvatarAngle = avatar.angle;
					avatar.storedAvatarScale.copyFrom(avatar.scale);
					avatar.storedWidth = avatar.width;
					avatar.storedHeight = avatar.height;
				}
			}
			
			// Hold SHIFT to add new items to the selection.
			if ( clearIfNoSelection && !isOnItem && !FlxG.keys.pressed( "SHIFT" ) && !FlxG.keys.pressed( "CONTROL" ))
			{
				if ( selectedSprites.length )
				{
					selectionChanged = true;
					selectedSprites.length = 0;
				}
			}
			return isOnItem;
		}
		
		protected function GetAngleOfPointFromAvatar( worldPos:FlxPoint, avatar:EditorAvatar, avatarPos:FlxPoint, avatarAngle:Number ):Number
		{
			var anchorPos:FlxPoint;
			
			if ( clickedSprite.attachment && clickedSprite.attachment.Parent )
			{
				anchorPos = avatar.GetAnchor();
				anchorPos.x *= avatar.scale.x;
				anchorPos.y *= avatar.scale.y;

				var mat:Matrix = avatar.GetTransformMatrixForRealPosToDrawnPos( avatarPos, avatarAngle );
				var pt:Point = new Point(anchorPos.x + avatarPos.x, anchorPos.y + avatarPos.y);
				pt = mat.transformPoint(pt);
				anchorPos.create_from_flashPoint(pt);
			}
			else
			{
				anchorPos = new FlxPoint( avatar.width * 0.5, avatar.height * 0.5 );
				anchorPos.addTo( avatarPos );
			}
			
			var offset:FlxPoint = new FlxPoint( worldPos.x - anchorPos.x, worldPos.y - anchorPos.y );

			return Math.atan2( offset.y, offset.x ) * 180 / Math.PI;
		}
		
		override protected function SelectUnderCursor( layer:LayerEntry ):Boolean
		{
			if ( !FlxG.keys.pressed( "CONTROL" ) && !FlxG.keys.pressed( "SHIFT" ) && selectedSprites.length )
			{
				selectionChanged = true;
				selectedSprites.length = 0;
			}
			
			selectedAvatarLink = null;
			
			//var screenPos:FlxPoint = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
			// If we click down on an already selected sprite then we initiate move mode.
			var app:App = App.getApp();
			var i:uint = app.layerGroups.length;
			while( i-- )
			{
				var group:LayerGroup = app.layerGroups[i];
				var j:uint = group.children.length;
				while( j-- )
				{
					var layerEntry:LayerEntry = group.children[j];
					if ( Global.SelectFromCurrentLayerOnly && layerEntry != layer )
					{
						continue;
					}
					if ( layerEntry is layerClassType && layerEntry.IsVisible() )
					{
						var spriteLayer:* = layerEntry as layerClassType;
						var k:uint = spriteLayer.sprites.members.length;
						while( k-- )
						{
							var avatar:EditorAvatar = spriteLayer.sprites.members[k];
							if ( avatar.CanSelect() && avatar.IsOverScreenPos( mouseScreenPos, usePixelPerfectSelection, 0, null, true ) )
							{
								var index:int = selectedSprites.indexOf( avatar );
								selectionChanged = true;
								if ( index != -1 )
								{
									selectedSprites.splice(index, 1);
									return false;
								}
								selectedSprites.push( avatar );
								// Only select the first one.
								if ( AvatarToLinkFrom && AvatarToLinkFrom != avatar && !AvatarToLinkFrom.markForDeletion)
								{
									var newLink:AvatarLink = AvatarLink.GenerateLink(AvatarToLinkFrom, avatar);
									HistoryStack.BeginOperation(new OperationAddLink(newLink));
									AvatarToLinkFrom = null;
								}
								return true;
							}
						}
					}
				}
			}
			
			// If an avatar wasn't selected then look for avatar links to select, but only from the current layer	
			if ( layer && layer.IsVisible() )
			{
				spriteLayer = layer as layerClassType;
				k = spriteLayer.sprites.members.length;
				while( k-- )
				{
					avatar = spriteLayer.sprites.members[k];
					var m:uint = avatar.linksFrom.length;
					while ( m-- )
					{
						if ( avatar.linksFrom[m].DistanceFrom(mouseScreenPos) < 4 )
						{
							selectedAvatarLink = avatar.linksFrom[m];
							return true;
						}
					}
					m = avatar.linksTo.length;
					while ( m-- )
					{
						if ( avatar.linksTo[m].DistanceFrom(mouseScreenPos) < 4 )
						{
							selectedAvatarLink = avatar.linksTo[m];
							return true;
						}
					}
				}
			}
			return false;
		}
		
		override public function SelectNone():void
		{
			if ( selectedSprites.length )
			{
				selectionChanged = true;
			}
			selectedSprites.length = 0;
		}
		
		override public function DeselectInvisible(): void
		{
			var i:uint = selectedSprites.length;
			while (i--)
			{
				if ( !selectedSprites[i].layer.visible )
				{
					selectedSprites.splice(i, 1);
				}
			}
		}
		
		override public function SelectAll( ):void
		{
			var avatarTopLeft:FlxPoint;
			var avatarBottomRight:FlxPoint;
			var app:App = App.getApp();
				
			selectionChanged = true;
			selectedSprites.length = 0;
			var i:uint = app.layerGroups.length;
			while( i-- )
			{
				var group:LayerGroup = app.layerGroups[i];
				var j:uint = group.children.length;
				while( j-- )
				{
					var layerEntry:LayerEntry = group.children[j];
					if ( Global.SelectFromCurrentLayerOnly && layerEntry != app.CurrentLayer )
					{
						continue;
					}
					if ( layerEntry is layerClassType && layerEntry.IsVisible() && !layerEntry.Locked() )
					{
						var spriteLayer:* = layerEntry as layerClassType;
						var k:uint = spriteLayer.sprites.members.length;
						while( k-- )
						{
							var avatar:EditorAvatar = spriteLayer.sprites.members[k];
							if( avatar.CanSelect() )
								selectedSprites.push( avatar );
						}
					}
				}
			}
		}
		
		override protected function BeginTransformation():void
		{
			if ( isMovingItems )
			{
				HistoryStack.BeginOperation(new OperationMoveAvatar( selectedSprites ) );
			}
			else if ( isScaling && cursorId == -1 )
			{
				currentCursorClass = scaleCursor;
				cursorId = CursorManager.setCursor(scaleCursor,2,-10,-10);
			}
			else if (isRotating && cursorId == -1 )
			{
				currentCursorClass = rotateCursor;
				cursorId = CursorManager.setCursor(rotateCursor,2,-11,-10);
			}
		}
		
		override protected function EndTransformation():void
		{
		}
		
		private var prevPos:FlxPoint;
		private function overlapCb(Object1:EditorAvatar, Object2:EditorAvatar):Boolean
		{
			if ( Object1.layer != Object2.layer )
				return false;
			
			var masterLayer:LayerMap = null;
			if ( Object1.layer.AlignedWithMasterLayer && ( masterLayer = Object1.layer.parent.FindMasterLayer() ) && masterLayer.map.IsIso() )
			{
				Object1.isoTopLeft = new FlxPoint;
				Object1.isoBottomRight = new FlxPoint;
				Object1.GetIsoCorners(masterLayer.map, true);
				Object2.isoTopLeft = new FlxPoint;
				Object2.isoBottomRight = new FlxPoint;
				Object2.GetIsoCorners(masterLayer.map, true);
				
				
				
				/*
				if (Object1.isoBottomRight.y < Object2.isoTopLeft.y)
					return false;
				if (Object1.isoTopLeft.y > Object2.isoBottomRight.y)
					return false;

				if (Object1.isoBottomRight.x < Object2.isoTopLeft.x)
					return false;
				if (Object1.isoTopLeft.x > Object2.isoBottomRight.x)
					return false;*/
					
				var oldTopLeft1:FlxPoint = new FlxPoint;
				var oldBottomRight1:FlxPoint = new FlxPoint;

				Object1.GetIsoCornersForPos(masterLayer.map, prevPos.x, prevPos.y, Object1.z, oldTopLeft1, oldBottomRight1, true ); 
					
				var intersectData:Object = new Object;
				if( Hits.IntersectBox3d(Object1.isoTopLeft, Object1.isoBottomRight, 0, Object2.isoTopLeft, Object2.isoBottomRight, 0, Object1.isoTopLeft.x - oldTopLeft1.x, Object1.isoTopLeft.y - oldTopLeft1.y, 0, intersectData ) )
				{
					//trace ( intersectData.tLeave + " = " + intersectData.tEnter );
					
					var xDiff:Number = Object1.x - prevPos.x;
					var yDiff:Number = Object1.y - prevPos.y;
					var newX:Number = prevPos.x + ( xDiff * ( 1 - intersectData.tLeave ) );
					var newY:Number = prevPos.y + ( yDiff * ( 1 - intersectData.tLeave ) );
					var xSgn:int = xDiff ? Misc.sign( xDiff ) : 0;
					var ySgn:int = yDiff ? Misc.sign( yDiff ) : 0;
					var desiredX:Number = Object1.x;
					var desiredY:Number = Object1.y;
					Object1.x = newX - xSgn;
					Object1.y = newY - ySgn;
					if ( intersectData.tLeave == 1 )
					{
						//Object1.copyFrom(prevPos);
						prevPos.x = Object1.x = newX - xSgn;
						prevPos.y = Object1.y = newY - ySgn;
					}
					if ( ( Object1.x - prevPos.x ) * xSgn < 0 || ( Object1.y - prevPos.y ) * ySgn < 0 )
					{
						Object1.x = prevPos.x;
						Object1.y = prevPos.y;
					}
					
					if ( yDiff && xDiff)
					{
						var topLeft:Number = Object1.isoTopLeft.x;
						var bottomRight:Number = Object1.isoBottomRight.x;
						Object1.isoTopLeft.x = oldTopLeft1.x;
						Object1.isoBottomRight.x = oldBottomRight1.x;
						// Check against each axis in case we can partially move.
						if ( !Hits.IntersectBox3d(Object1.isoTopLeft, Object1.isoBottomRight, 0, Object2.isoTopLeft, Object2.isoBottomRight, 0, 0, Object1.isoTopLeft.y - oldTopLeft1.y, 0, intersectData ) )
						{
							// Need to work out the 2d pos from the real pos shifted along this axis.
							var realPos:FlxPoint = new FlxPoint;
							masterLayer.map.GetTileInfo(Object1.x - masterLayer.map.x, Object1.y - masterLayer.map.y, realPos, null, true);
							realPos.y += ( Object1.isoTopLeft.y - oldTopLeft1.y );
							masterLayer.map.GetTileWorldFromUnitPos(realPos.x, realPos.y, Object1, true );
						}
						else 
						{
							Object1.isoTopLeft.x = topLeft;
							Object1.isoBottomRight.x = bottomRight;
							topLeft = Object1.isoTopLeft.y;
							bottomRight = Object1.isoBottomRight.y;
							Object1.isoTopLeft.y = oldTopLeft1.y;
							Object1.isoBottomRight.y = oldBottomRight1.y;
							if ( !Hits.IntersectBox3d(Object1.isoTopLeft, Object1.isoBottomRight, 0, Object2.isoTopLeft, Object2.isoBottomRight, 0, Object1.isoTopLeft.x - oldTopLeft1.x, 0, 0, intersectData ) )
							{
								// Need to work out the 2d pos from the real pos shifted along this axis.
								realPos = new FlxPoint;
								masterLayer.map.GetTileInfo(Object1.x - masterLayer.map.x, Object1.y - masterLayer.map.y, realPos, null, true);
								realPos.x += ( Object1.isoTopLeft.x - oldTopLeft1.x );
								masterLayer.map.GetTileWorldFromUnitPos(realPos.x, realPos.y, Object1, true );
							}
							else
							{
								Object1.isoTopLeft.y = topLeft;
								Object1.isoBottomRight.y = bottomRight;
							}
						}
					}
					return true;
				}

			}
			return false;
		}
		
		override protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			var i:uint = selectedSprites.length;
			
			var doCollide:Boolean = (i == 1);
			
			while(i--)
			{
				var avatar:EditorAvatar = selectedSprites[i];
				if ( avatar.CanMove() )
				{
					var avatarScreenPos:FlxPoint = EditorState.getScreenXYFromMapXY( avatar.storedAvatarPos.x, avatar.storedAvatarPos.y, avatar.scrollFactor.x, avatar.scrollFactor.y, false );
					
					var newPos:FlxPoint = EditorState.getMapXYFromScreenXY(avatarScreenPos.x + screenOffsetFromOriginalPos.x, avatarScreenPos.y + screenOffsetFromOriginalPos.y, avatar.scrollFactor.x, avatar.scrollFactor.y );			
					avatar.GetSnappedPos(newPos, newPos, false);
					
					var yDiff:Number = newPos.y - avatar.y;
					
					prevPos = avatar.copy();
					
					if ( FlxG.keys.pressed( "Z" ))
					{
						var masterLayer:LayerMap = avatar.layer.parent.FindMasterLayer();
						if ( masterLayer && masterLayer.map.tileOffsetX == 0 && masterLayer.map.tileOffsetY != 0 )
						{
							var zDiff:int = (newPos.x - avatar.x);
							if ( masterLayer.map.tileOffsetY < 0 )
								zDiff = -zDiff;
							avatar.z += zDiff;
						}
						else
							avatar.z += yDiff;
					}
					
					
					avatar.copyFrom( newPos );
					
					/*if ( doCollide )
					{
						
						FlxU.setWorldBounds(avatar.layer.minx, avatar.layer.miny,
							avatar.layer.maxx - avatar.layer.minx, avatar.layer.maxy - avatar.layer.miny);
						if ( FlxU.overlap(avatar, avatar.layer.sprites, overlapCb) )
						{
							//avatar.copyFrom( prevPos );
							return;
						}
					}*/
					
					if ( avatar.layer.AutoDepthSort )
					{
						avatar.layer.SortAvatar(avatar);
					}
					
					avatar.layer.UpdateMinMax( avatar );
					if ( avatar.attachment )
					{
						if( avatar.attachment.Parent )
						{
							avatar.attachment.Parent.RefreshAttachmentValues();
						}
						else if ( avatar.attachment.Child )
						{
							avatar.attachment.Child.UpdateAttachment();
						}
					}
				}
			}
		}
		
		override protected function DeleteSelection( ):void
		{
			if ( selectedSprites.length > 0 )
			{
				// Now add the history operation. Must be done after the avatars have been marked for deletion.
				HistoryStack.BeginOperation( new OperationDeleteAvatar( selectedSprites ) );
				
				for each ( var avatar:EditorAvatar in selectedSprites )
				{
					/*var avatarIndex:uint = avatar.layer.sprites.members.indexOf(avatar);
					avatar.markForDeletion = true;
					if ( avatar.attachment )
					{
						if ( avatar.attachment.Parent )
						{
							avatar.attachment.Parent.attachment = null;
						}
						else if ( avatar.attachment.Child )
						{
							avatar.attachment.Child.attachment = null;
						}
						avatar.attachment = null;
					}
					var i:uint = avatar.linksFrom.length;
					while(i--)
					{
						var link:AvatarLink = avatar.linksFrom[i];
						AvatarLink.RemoveLink(link);
					}
					i = avatar.linksTo.length;
					while(i--)
					{
						link = avatar.linksTo[i];
						AvatarLink.RemoveLink(link);
					}
					avatar.layer.sprites.members.splice(avatarIndex, 1);*/
					avatar.Delete();
					if ( SpriteDeletedCallback != null )
					{
						SpriteDeletedCallback( avatar );
					}
				}
				selectedSprites.length = 0;
				
				var currentState:EditorState = FlxG.state as EditorState;
				currentState.UpdateMapList();
			}
			else if ( selectedAvatarLink != null )
			{
				HistoryStack.BeginOperation(new OperationDeleteLink( selectedAvatarLink ) );
				AvatarLink.RemoveLink( selectedAvatarLink );
			}
			selectionChanged = true;
		}
		
		public function RemoveAvatarFromSelection( avatar:EditorAvatar ):void
		{
			if ( SpriteDeletedCallback != null )
			{
				SpriteDeletedCallback( avatar );
			}
			
			var i:uint = selectedSprites.length;
			while ( i-- )
			{
				if ( selectedSprites[i] == avatar )
				{
					selectedSprites.splice(i, 1);
					selectionChanged = true;
					return;
				}
			}
			
		}
		
		protected function contextMenuHandler(event:Event):void
		{			
			switch( event.target.label )
			{
				case "Delete":
				DeleteSelection();
				break;
				
				case "Copy GUID":
				if ( selectedSprites.length )
				{
					System.setClipboard(selectedSprites[0].GetGUID());
				}
				break;
				
				case "Link To Another Object":
				if ( selectedSprites.length )
				{
					AvatarToLinkFrom = selectedSprites[0];
				}
				break;
				
				case "Send To Front":
				if ( selectedSprites.length )
				{
					selectedSprites[0].SendToLayerFront();
				}
				break;
				
				case "Send To Back":
				if ( selectedSprites.length )
				{
					selectedSprites[0].SendToLayerBack();
				}
				break;
			}
		}
		
		public function ForceSelection(avatar:EditorAvatar):void
		{
			selectedSprites.length = 0;
			selectedSprites.push( avatar );
			selectionChanged = true;
		}
		
		public function GetSelection():Vector.<EditorAvatar>
		{
			return selectedSprites;
		}
		
		
		
	}

}