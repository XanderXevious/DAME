package com.Editor 
{
	import com.Editor.EditorType;
	import com.Game.EditorAvatar;
	import com.Game.PathEvent;
	import com.Game.PathNode;
	import com.Game.PathObject;
	import com.Game.SpriteTrailObject;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerPaths;
	import com.Layers.LayerSprites;
	import com.Operations.HistoryStack;
	import com.Operations.OperationAddAvatar;
	import com.Operations.OperationAddSpriteTrail;
	import com.Operations.OperationPasteAvatars;
	import com.Operations.OperationShapeAddNode;
	import com.Operations.OperationShapeDeleteNode;
	import com.Operations.OperationShapeMoveNode;
	import com.Operations.OperationTransformShape;
	import com.Tiles.SpriteEntry;
	import com.Utils.Misc;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import mx.collections.ArrayCollection;
	import mx.events.CloseEvent;
	import org.flixel.FlxPoint;
	import org.flixel.FlxG;
	import com.EditorState;
	import mx.controls.Alert;
	import com.Utils.Global;
	import com.UI.AlertBox;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypePaths extends EditorTypeAvatarsBase
	{
		// This is the shape that is currently being edited.
		private var currentPath:PathObject;
		private var movingNodes:Boolean = false;
		private var movingEvents:Boolean = false;
		private var selectedNodeIndex:int;
		private var selectingTangent1:Boolean = false;
		private var selectingTangent2:Boolean = false;
		
		public static var StopEditingShape:Boolean = false;
		public static var ClosedPoly:Boolean = false;
		public static var CurveMode:Boolean = false;
		public static var EventsMode:Boolean = false;
		
		protected static var _isActive:Boolean = false;
		public static function IsActiveEditor():Boolean { return _isActive; };
		
		private var closeOpenShapeMenuItem:NativeMenuItem;
		private var spriteTrailMenuItem:NativeMenuItem;
		
		private var currentPathEvent:PathEvent = null;
		
		private var pathEventCursor:PathEvent = new PathEvent(0, 0, null, null);
		
		public function EditorTypePaths( editor:EditorState ) 
		{
			super( editor );
			layerClassType = LayerPaths;
			SpriteDeletedCallback = ShapeRemoved;
			usePixelPerfectSelection = true;
			
			editor.add(pathEventCursor);
			pathEventCursor.visible = false;
			pathEventCursor.alphaPulseEnabled = true;
			
			// So that we can paint and drag without releasing the mouse.
			allowContinuousPainting = true;
			
			allowScaling = true;
			
			addNewContextMenuItem(contextMenu, "Spawn Instance", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Spawn Instance On Other layer", contextMenuHandler );
			spriteTrailMenuItem = addNewContextMenuItem(contextMenu, "Attach Sprite Trail", contextMenuHandler );
			closeOpenShapeMenuItem = addNewContextMenuItem(contextMenu, "Close shape", contextMenuHandler );
			
		}
		
		override public function Update(isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			_isActive = isActive;
			
			/*if ( currentPath != null )
			{
				if ( ClosedPoly != currentPath.IsClosedPoly )
				{
					currentPath.IsClosedPoly = ClosedPoly;
					currentPath.Invalidate();
				}
			}*/
			
			if ( _isActive && !isRotating && !isMovingItems && !isScaling )
			{
				if ( FlxG.keys.justPressed( "DELETE" ) )
				{
					if ( !ErasePathEvent() )
					{
						if ( !inSelectionMode )
						{
							EraseNode();
						}
					}
				}
			}
			
			if ( StopEditingShape )
			{
				if ( currentPath != null )
				{
					currentPath.alphaPulseEnabled = false;
					currentPath.IsSelected = false;
				}
				currentPath = null;
				StopEditingShape = false;
			}
			
			if ( _isActive && EventsMode && currentPathEvent && currentPathEvent.visible )
			{
				currentPathEvent.flashThisFrame = true;
			}
			
			if ( _isActive && EventsMode && !movingEvents && !inSelectionMode )
			{
				pathEventCursor.visible = false;
				var pathLayer:LayerPaths = App.getApp().CurrentLayer as LayerPaths;
				if( pathLayer )
				{
					var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
					modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			
					var radius:Number = 20 * 20;
					var j:uint = pathLayer.sprites.members.length;
					var pathEventRadiusSquared:Number = PathEvent.GetSize() * PathEvent.GetSize();
					var overEvent:Boolean = false;
					while( j-- && !overEvent )
					{
						var path:PathObject = pathLayer.sprites.members[j];
						if ( path == currentPath ||
							( modifiedMousePos.x >= path.x-4 && modifiedMousePos.x <= path.x + path.width + 4 &&
							modifiedMousePos.y >= path.y-4 && modifiedMousePos.y <= path.y + path.height + 4 ) )
						{
							var i:int = path.pathEvents.length;
							while ( i-- )
							{
								if (mousePos.squareDistance(path.pathEvents[i]) < pathEventRadiusSquared )
								{
									overEvent = true;
									pathEventCursor.visible = false;
									path.pathEvents[i].highlighted = true;
									break;
								}
							}
							if ( !overEvent )
							{
								var closestPt:FlxPoint = path.GetClosestPoint( modifiedMousePos, null, null, null );
								if ( closestPt.squareDistance(modifiedMousePos) < radius )
								{
									pathEventCursor.visible = true;
									pathEventCursor.pathObj = path;
									pathEventCursor.x = closestPt.x;
									pathEventCursor.y = closestPt.y;
								}
							}
						}
					}
				}
			}
			else
			{
				pathEventCursor.pathObj = null;
				pathEventCursor.visible = false;
			}
		}
		
		override protected function HideDisplay():void
		{
			pathEventCursor.visible = false;
		}
		
		override public function GetCurrentObjectProperties():ArrayCollection
		{
			if ( EventsMode && currentPathEvent )
			{
				return currentPathEvent.properties;
			}
			
			var props:ArrayCollection = super.GetCurrentObjectProperties();

			if ( !props && currentPath )
			{
				return currentPath.properties;
			}
			return props;
		}
		
		override protected function Paint( layer:LayerEntry ):void
		{
			var pathLayer:LayerPaths = App.getApp().CurrentLayer as LayerPaths;
			
			if ( pathLayer == null )
			{
				return;
			}
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			var snappedMousePos:FlxPoint = FlxPoint.CreateObject(modifiedMousePos);
			
			// Handle snap to grid
			if ( !layer.map && GuideLayer.SnappingEnabled )
			{
				GuideLayer.GetSnappedPos(layer, modifiedMousePos.x, modifiedMousePos.y, snappedMousePos);
			}
			
			if ( EventsMode )
			{
				if ( !movingEvents && pathEventCursor.visible && pathEventCursor.pathObj)
				{
					currentPathEvent = new PathEvent( pathEventCursor.x, pathEventCursor.y, pathEventCursor.pathObj.layer, pathEventCursor.pathObj);
					currentPathEvent.pathObj.AddPathEvent( currentPathEvent );
					currentPathEvent.UpdateAttachment();
					movingEvents = true;
				}
				else if ( currentPathEvent )
				{
					if ( !currentPathEvent.equals(snappedMousePos) )
					{
						currentPathEvent.x = snappedMousePos.x;
						currentPathEvent.y = snappedMousePos.y;
						currentPathEvent.UpdateAttachment();
					}
				}
				if ( currentPathEvent )
				{
					currentPathEvent.highlighted = true;
				}
			}
			else if ( currentPath == null )
			{
				currentPath = new PathObject( snappedMousePos.x, snappedMousePos.y, CurveMode, pathLayer );
				currentPath.CreateGUID();
				currentPath.alphaPulseEnabled = true;
				currentPath.IsSelected = true;
				pathLayer.sprites.add( currentPath, true );
				currentPath.IsClosedPoly = ClosedPoly;
				currentPath.SelectedNodeIndex = selectedNodeIndex = 0;
				movingNodes = true;
				selectionChanged = true;
				selectedSprites.length = 0;
				selectedSprites.push(currentPath);
				
				HistoryStack.BeginOperation( new OperationAddAvatar( this, pathLayer, currentPath ) );
			}
			else if ( movingNodes )
			{
				selectedNodeIndex = Math.max(0, Math.min( selectedNodeIndex, currentPath.nodes.length - 1 ) );
				if ( selectingTangent1 || selectingTangent2 )
				{
					// Tangents don't get snapped to grids so use original mousePos.
					var tangentPos:FlxPoint = modifiedMousePos.v_sub(currentPath);
					tangentPos.x -= currentPath.nodes[selectedNodeIndex].x;
					tangentPos.y -= currentPath.nodes[selectedNodeIndex].y;
					var thisTangent:FlxPoint = selectingTangent1 ? currentPath.nodes[selectedNodeIndex].tangent1 : currentPath.nodes[selectedNodeIndex].tangent2;
					var otherTangent:FlxPoint = selectingTangent1 ? currentPath.nodes[selectedNodeIndex].tangent2 : currentPath.nodes[selectedNodeIndex].tangent1;
					
					thisTangent.create_from_points(tangentPos.x, tangentPos.y);
					// Other tangent has its own magnitude but must be the same direction as this tangent.
					var mag:Number = otherTangent.magnitude();
					var norm:FlxPoint = thisTangent.normalized();
					otherTangent.x = norm.x * -mag;
					otherTangent.y = norm.y * -mag;
					currentPath.Invalidate();
				}
				else
				{
					var currentPos:FlxPoint = FlxPoint.CreateObject(currentPath);
					currentPath.nodes[selectedNodeIndex].copyFrom( snappedMousePos.v_sub(currentPath) );
					currentPath.Invalidate();
					AdjustInstancedNodes(currentPath,currentPos,false);
				}
			}
			else
			{
				HistoryStack.BeginOperation( new OperationShapeAddNode( currentPath, selectedNodeIndex + 1 ) );
				currentPos = FlxPoint.CreateObject(currentPath);
				currentPath.AddNode(selectedNodeIndex + 1, snappedMousePos.v_sub(currentPath ) );
				currentPath.Invalidate();
				selectedNodeIndex++;
				currentPath.SelectedNodeIndex = selectedNodeIndex;
				AdjustInstancedNodes(currentPath,currentPos,false);
				movingNodes = true;
			}
		}
		
		override protected function UpdateDisplay( layer:LayerEntry ):void
		{
			drawMarquees = ( currentPath == null || inSelectionMode );
			super.UpdateDisplay( layer );
		}
		
		private function AdjustInstancedNodes( shape:PathObject, currentPos:FlxPoint, testSelection:Boolean ):void
		{
			currentPos.subFrom(shape);
			if ( shape.IsInstanced && ( currentPos.x != 0 || currentPos.y != 0 ) )
			{
				var i:uint = shape.instancedShapes.length;
				while (i--)
				{
					var testShape:PathObject = shape.instancedShapes[i];
					if ( testShape != shape )
					{
						if ( !testSelection || selectedSprites.indexOf(testShape) == -1 )
						{
							testShape.x -= currentPos.x;
							testShape.y -= currentPos.y;
						}
					}
				}
			}
		}
		
		/*override protected function BeginPainting( layer:LayerEntry, leftMouse:Boolean ):void
		{
			var pathLayer:LayerPaths = App.getApp().CurrentLayer as LayerPaths;
			
			if ( !leftMouse )
			{
				return;
			}
			
			if ( pathLayer == null )
			{
				return;
			}
		}*/
		
		private function TrySelectingNodes( pathLayer:LayerPaths ):Boolean
		{
			var tempPos:FlxPoint = new FlxPoint;
			var tangentPos:FlxPoint = new FlxPoint;
			selectingTangent1 = false;
			selectingTangent2 = false;
			var i:uint;
			if ( EventsMode )
			{
				var pathEventRadiusSquared:Number = PathEvent.GetSize() * PathEvent.GetSize();
			}
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			
			var selectDistance:Number = FlxG.extraZoom < 1 ? 4 * FlxG.invExtraZoom : 4;
			var tangentSelectDistance:Number = FlxG.extraZoom < 1 ? 6 * FlxG.invExtraZoom : 6;
			
			var j:uint = pathLayer.sprites.members.length;
			while( j-- )
			{
				var shape:PathObject = pathLayer.sprites.members[j];
				if ( shape == currentPath ||
					( modifiedMousePos.x >= shape.x-selectDistance && modifiedMousePos.x <= shape.x + shape.width + selectDistance &&
					modifiedMousePos.y >= shape.y-selectDistance && modifiedMousePos.y <= shape.y + shape.height + selectDistance ) )
				{
					if ( EventsMode )
					{
						i = shape.pathEvents.length;
						//currentPath = shape;
						//currentPath.IsSelected = true;
						while ( i-- )
						{
							if (mousePos.squareDistance(shape.pathEvents[i]) < pathEventRadiusSquared )
							{
								currentPathEvent = shape.pathEvents[i];
								movingEvents = true;
								//HistoryStack.BeginOperation( new OperationShapeMovePathEvent( shape, i, shape.nodes[i] ) );
								return true;
							}
						}
					}
					else
					{
						i = shape.nodes.length;
						while(i--)
						{
							var node:PathNode = shape.nodes[i];
							tempPos.create_from_points(shape.x + node.x, shape.y + node.y);
							if ( shape.IsCurved && (shape==currentPath))
							{
								tangentPos.create_from_points(tempPos.x + node.tangent1.x, tempPos.y + node.tangent1.y );
								if ( tangentPos.distance_to(modifiedMousePos) < tangentSelectDistance )
								{
									selectingTangent1 = true;
								}
								else
								{
									tangentPos.create_from_points(tempPos.x + node.tangent2.x, tempPos.y + node.tangent2.y );
									if ( tangentPos.distance_to(modifiedMousePos) < tangentSelectDistance )
									{
										selectingTangent2 = true;
									}
								}
							}
							if ( selectingTangent1 || selectingTangent2 || tempPos.distance_to(modifiedMousePos) < tangentSelectDistance )
							{
								HistoryStack.BeginOperation( new OperationShapeMoveNode( shape, i, shape.nodes[i] ) );
								selectedNodeIndex = i;
								movingNodes = true;
								if ( currentPath != null )
								{
									currentPath.IsSelected = false;
									currentPath.alphaPulseEnabled = false;
								}
								currentPath = shape;
								currentPath.SelectedNodeIndex = selectedNodeIndex;
								currentPath.alphaPulseEnabled = true;
								currentPath.IsSelected = true;
								
								return true;
							}
						}
					}
				}
			}
			
			return false;
		}
		
		override protected function EndPainting( layer:LayerEntry ):void
		{
			movingNodes = false;
			movingEvents = false;
		}
		
		override protected function BeginTransformation():void
		{
			super.BeginTransformation();
			
			if ( !isRotating && !isScaling )
			{
				return;
			}
			
			HistoryStack.BeginOperation( new OperationTransformShape( selectedSprites ) );
			
			for each( var shape:PathObject in selectedSprites )
			{
				shape.storedNodes.length = 0;
				for each( var node:PathNode in shape.nodes )
				{
					shape.storedNodes.push( node.CopyNode() );
				}
				
				shape.storedAvatarPos.copyFrom(shape);
				shape.storedAvatarAngle = shape.angle;
				shape.storedAvatarScale.copyFrom(shape.scale);
				shape.storedWidth = shape.width;
				shape.storedHeight = shape.height;
			}
		}
		
		override protected function EndTransformation():void
		{
			super.EndTransformation();
			
			for each( var shape:PathObject in selectedSprites )
			{
				shape.storedNodes.length = 0;
			}
		}
		
		override protected function DeleteSelection():void
		{
			if (!inSelectionMode && !InAttachMode && !IsSpawningInstance)
			{
				return;	// In this mode DELETE key actually means delete node.
			}
			super.DeleteSelection();
		}
		
		override protected function RotateSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{			
			if ( clickedSprite == null )
			{
				return;
			}
			
			// Always rotate around the centre.
			var centrePos:FlxPoint = EditorState.getScreenXYFromMapXY(
														clickedSprite.storedAvatarPos.x + (clickedSprite.storedWidth / 2),
														clickedSprite.storedAvatarPos.y + (clickedSprite.storedHeight / 2),
														clickedSprite.scrollFactor.x,
														clickedSprite.scrollFactor.y );
			screenOffsetFromOriginalPos = new FlxPoint( mouseScreenPos.x - centrePos.x, mouseScreenPos.y - centrePos.y );

			var angleDiff:Number = originalAngleFromSelectedSprite - Math.atan2( screenOffsetFromOriginalPos.y, screenOffsetFromOriginalPos.x ) * 180 / Math.PI;
			var middle:Point = new Point();
			var mat:Matrix = new Matrix;
			var pt:Point = new Point();
			var currentPos:FlxPoint = new FlxPoint();
			
			var j:uint = selectedSprites.length;
			while ( j-- )
			{
				var shape:PathObject = selectedSprites[j] as PathObject;
				var angle:Number = shape.storedAvatarAngle - angleDiff;
				if ( angle < 0 )
				{
					angle += 360;
				}
				
				if ( FlxG.keys.pressed("A") )
				{
					angle = Math.round(angle/45) * 45;
				}
				
				currentPos.copyFrom(shape);

				centrePos.create_from_points(shape.storedWidth* 0.5, shape.storedHeight * 0.5);
				mat.identity();
				mat.rotate(angle * Math.PI / 180);
				var storedNode:PathNode;
				var i:uint;
				for ( i = 0; i < shape.storedNodes.length; i++ )
				{
					storedNode = shape.storedNodes[i];
					pt.x = storedNode.x - centrePos.x;
					pt.y = storedNode.y - centrePos.y;
					pt = mat.transformPoint(pt);
					shape.nodes[i].x = ( shape.storedAvatarPos.x + pt.x + centrePos.x ) - shape.x;
					shape.nodes[i].y = ( shape.storedAvatarPos.y + pt.y + centrePos.y ) - shape.y;
					
					if ( shape._isCurved )
					{
						// Rotate the tangents next.
						pt.x = shape.storedNodes[i].tangent1.x;
						pt.y = shape.storedNodes[i].tangent1.y;
						pt = mat.transformPoint(pt);
						shape.nodes[i].tangent1.create_from_points(pt.x, pt.y);
						
						pt.x = shape.storedNodes[i].tangent2.x;
						pt.y = shape.storedNodes[i].tangent2.y;
						pt = mat.transformPoint(pt);
						shape.nodes[i].tangent2.create_from_points(pt.x, pt.y);
					}
				}
				
				shape.Invalidate();
				
				AdjustInstancedNodes(shape, currentPos, true);
			}
		}
		
		override protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			var storedPos:Vector.<FlxPoint> = new Vector.<FlxPoint>( selectedSprites.length );
			
			var j:uint = selectedSprites.length;
			while ( j-- )
			{
				var path:PathObject = selectedSprites[j] as PathObject;
				storedPos[j] = new FlxPoint(path.x, path.y);
			}
				
			super.MoveSelection( screenOffsetFromOriginalPos );
			
			j = selectedSprites.length;
			while ( j-- )
			{
				path = selectedSprites[j] as PathObject;
				var i:int = path.pathEvents.length;
				if ( i )
				{
					var diff:FlxPoint = path.v_sub(storedPos[j]);
					while ( i-- )
					{
						path.pathEvents[i].x += diff.x;
						path.pathEvents[i].y += diff.y;
						
					}
				}
			}
		}
		
		override protected function ScaleSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			if ( clickedSprite == null )
			{
				return;
			}
			
			var newMousePosX:Number = mousePos.x;
			var newMousePosY:Number = mousePos.y;
			var newOffsetX:Number = screenOffsetFromOriginalPos.x;
			var newOffsetY:Number = screenOffsetFromOriginalPos.y;
			
			var anchorFrac:FlxPoint = new FlxPoint(0.5, 0.5);
			var anchorPos:FlxPoint = new FlxPoint(clickedSprite.storedAvatarPos.x + (clickedSprite.storedWidth / 2),
												clickedSprite.storedAvatarPos.y + (clickedSprite.storedHeight / 2) );
			if ( mouseOverDiagHandle || mouseOverHorizHandle || mouseOverVertHandle )
			{
				anchorFrac.create_from_points(1 - handleDraggedFrac.x, 1 - handleDraggedFrac.y);
				anchorPos = new FlxPoint(Math.abs(clickedSprite.storedAvatarPos.x + clickedSprite.storedWidth * anchorFrac.x), clickedSprite.storedAvatarPos.y + Math.abs(clickedSprite.storedHeight * anchorFrac.y) );
				//anchorPos = new FlxPoint(Math.abs(clickedSprite.width * anchorFrac.x), Math.abs(clickedSprite.height * anchorFrac.y) );
				
				// Try to snap the handle to the grid.
			// TODO - Doesn't quite snap perfectly.
				//newMousePosX = GuideLayer.GetSnappedX(clickedSprite.layer, mousePos.x);
				//newMousePosY = GuideLayer.GetSnappedY(clickedSprite.layer, mousePos.y);
				//newOffsetX = screenOffsetFromOriginalPos.x - (mousePos.x - newMousePosX);
				//newOffsetY = screenOffsetFromOriginalPos.y - (mousePos.y - newMousePosY);
			}
			var scaleDiffX:Number = newOffsetX;
			var scaleDiffY:Number = newOffsetY;
			var originalOffsetX:Number;
			var originalOffsetY:Number;
			var currentOffsetX:Number;
			var currentOffsetY:Number;

			originalOffsetX = (newMousePosX-newOffsetX) - anchorPos.x;
			originalOffsetY = (newMousePosY-newOffsetY) - anchorPos.y;
			currentOffsetX = newMousePosX - anchorPos.x;
			currentOffsetY = newMousePosY - anchorPos.y;
			
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
			
			// Try to scale it so the same point on the sprite always stay under the cursor.
			var originalPercentX:Number = originalOffsetX / ( clickedSprite.storedWidth * 0.5 );
			var originalPercentY:Number = originalOffsetY / ( clickedSprite.storedHeight * 0.5 );
			if ( originalPercentX > 0.001 && originalPercentX < 0.001 )
			{
				originalPercentX = 0.001;
			}
			if ( originalPercentY > 0.001 && originalPercentY < 0.001 )
			{
				originalPercentY = 0.001;
			}
			var width:Number = 2 * currentOffsetX / originalPercentX;
			var height:Number = 2 * currentOffsetY / originalPercentY;
			var maxWidth:Number = Math.max(maxAvatarWidth, clickedSprite.storedWidth);
			var maxHeight:Number = Math.max(maxAvatarHeight, clickedSprite.storedHeight );
			width = Math.min( width, maxWidth );
			height = Math.min( height, maxHeight );
			scaleDiffX = width / clickedSprite.storedWidth;
			scaleDiffY = height / clickedSprite.storedHeight;
			
			if ( FlxG.keys.pressed("S") || mouseOverDiagHandle )
			{
				if ( Math.abs( scaleDiffX ) > Math.abs( scaleDiffY ) )
				{
					scaleDiffY = scaleDiffX;
				}
				else
				{
					scaleDiffX = scaleDiffY;
				}
			}
			else if ( mouseOverHorizHandle )
			{
				scaleDiffY = 1;
			}
			else if ( mouseOverVertHandle )
			{
				scaleDiffX = 1;
			}
			
			var scaleX:Number;
			var scaleY:Number;
			
			
			var pt:FlxPoint = new FlxPoint();
			
			var currentPos:FlxPoint = new FlxPoint();
			
			// Only allow scaling of one object at a time to avoid confusion and accidentally stalling the editor.
			var shape:PathObject = clickedSprite as PathObject;
			{
				scaleX = Math.min(shape.storedAvatarScale.x * scaleDiffX, 50 );
				scaleY = Math.min(shape.storedAvatarScale.y * scaleDiffY, 50 );
				if ( scaleX < 0.05 && scaleX >= -0.05 )
				{
					scaleX = 0.05;
				}
				if ( scaleY < 0.05 && scaleY >= -0.05 )
				{
					scaleY = 0.05;
				}
				
				currentPos.copyFrom(shape);
				
				var centrePos:FlxPoint = new FlxPoint(Math.abs(clickedSprite.storedWidth * anchorFrac.x), Math.abs(clickedSprite.storedHeight * anchorFrac.y) );
				
				//var centrePos:FlxPoint =  shape.storedWidth * 0.5, shape.storedHeight * 0.5);
				
				maxWidth = Math.max(maxAvatarWidth, shape.storedWidth);
				maxHeight = Math.max(maxAvatarHeight, shape.storedHeight );
				width = shape.storedWidth * scaleX;
				height = shape.storedHeight * scaleY;
				if ( width > maxWidth )
				{
					scaleX = maxWidth / shape.storedWidth;
				}
				else if ( width < -maxWidth )
				{
					scaleX = -maxWidth / shape.storedWidth;
				}
				if ( height > maxHeight )
				{
					scaleY = maxHeight / shape.storedHeight;
				}
				else if ( height < -maxHeight )
				{
					scaleY = -maxHeight / shape.storedHeight;
				}
				
				var i:uint;
				for ( i = 0; i < shape.storedNodes.length; i++ )
				{
					pt.x = shape.storedNodes[i].x;
					pt.y = shape.storedNodes[i].y;
					pt.x = ( pt.x - centrePos.x ) * scaleX;
					pt.y = ( pt.y - centrePos.y ) * scaleY;
					pt.x = ( shape.storedAvatarPos.x + pt.x + centrePos.x ) - shape.x;
					pt.y = ( shape.storedAvatarPos.y + pt.y + centrePos.y ) - shape.y;
					shape.nodes[i].x = pt.x;
					shape.nodes[i].y = pt.y;
					
					if ( shape._isCurved )
					{
						shape.nodes[i].tangent1.x = shape.storedNodes[i].tangent1.x * scaleX;
						shape.nodes[i].tangent1.y = shape.storedNodes[i].tangent1.y * scaleY;
						
						shape.nodes[i].tangent2.x = shape.storedNodes[i].tangent2.x * scaleX;
						shape.nodes[i].tangent2.y = shape.storedNodes[i].tangent2.y * scaleY;
					}
				}
				
				shape.Invalidate();
				
				AdjustInstancedNodes(shape, currentPos, true);
			}
		}
		
		private function ErasePathEvent( ):Boolean
		{
			if ( EventsMode && currentPathEvent && currentPathEvent.visible )
			{
				var i:int = currentPathEvent.pathObj.pathEvents.indexOf( currentPathEvent );
				if ( i != -1 )
				{
					currentPathEvent.pathObj.pathEvents.splice( i, 1 );
				}
				currentPathEvent = null;
				return true;
			}
			return false;
		}
		
		private function EraseNode( ):void
		{
			if ( currentPath == null )
			{
				return;
			}
			
			if ( currentPath.nodes.length > 1 && selectedNodeIndex < currentPath.nodes.length )
			{
				var currentPos:FlxPoint = FlxPoint.CreateObject(currentPath);
				HistoryStack.BeginOperation( new OperationShapeDeleteNode( currentPath, selectedNodeIndex, currentPath.nodes[selectedNodeIndex] ) );
				currentPath.nodes.splice(selectedNodeIndex, 1);
				currentPath.SelectedNodeIndex = selectedNodeIndex = currentPath.nodes.length - 1;
				currentPath.Invalidate();
				
				AdjustInstancedNodes(currentPath, currentPos, false);
			}
			else
			{
				if ( currentPath.IsInstanced )
				{
					AlertBox.Show("Deleting an instanced shape will delete all shared instances too. Continue?", "Warning", AlertBox.OK | AlertBox.CANCEL, null, deleteSharedInstancesListener, AlertBox.CANCEL);
				}
				else
				{
					// Only 1 node so just remove the shape entirely.
					selectedSprites.length = 0;
					selectionChanged = true;
					selectedSprites.push(currentPath);
					// Call the base delete selection so we bypass any extra checks due to current selection mode.
					super.DeleteSelection();
					currentPath = null;
				}
			}
		}
		
		private function deleteSharedInstancesListener(eventObj:CloseEvent):void
		{
			if (eventObj.detail == AlertBox.OK)
			{
				selectionChanged = true;
				selectedSprites.length = 0;
				var i:uint = currentPath.instancedShapes.length;
				while (i--)
				{
					var testShape:PathObject = currentPath.instancedShapes[i];
					if ( !testShape.markForDeletion )
					{
						selectedSprites.push( testShape );
					}
				}
				
				DeleteSelection();
				currentPath = null;
			}
		}
		
		private function ShapeRemoved( avatar:EditorAvatar ):void
		{
			if ( avatar == currentPath )
			{
				currentPath = null;
			}
		}
		
		override protected function SelectInsideBox( layer:LayerEntry, boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean
		{
			var res:Boolean = super.SelectInsideBox( layer, boxTopLeft, boxBottomRight );
			
			AttachAvatar();
			
			return res;
		}
		
		override protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint
		{			
			if ( !EventsMode && TrySpawnInstance( layer as LayerPaths ) )
			{
				return SELECTED_ITEM;
			}
			
			if ( !InAttachMode && !inSelectionMode && !mouseOverHorizHandle && !mouseOverDiagHandle && !mouseOverRotateHandle && !mouseOverVertHandle)
			{
				TrySelectingNodes( layer as LayerPaths );
				return SELECTED_NONE;
			}
			
			var res:uint = super.SelectWithinSelection( layer, clearIfNoSelection );
			
			if ( res == SELECTED_NONE )
			{
				if ( !InAttachMode && !inSelectionMode )
				{
					TrySelectingNodes( layer as LayerPaths );
					return SELECTED_NONE;
				}
			}
			
			AttachAvatar();
			
			return res;
		}
		
		override protected function SelectUnderCursor( layer:LayerEntry ):Boolean
		{
			var res:Boolean = super.SelectUnderCursor( layer );
			
			AttachAvatar( );
			
			return res;
		}
		
		public function AttachAvatar( ):Boolean
		{
			if ( (InAttachMode || InSpriteTrailMode ) && AvatarToAttach && selectedSprites.length == 1 )
			{
				if ( AvatarToAttach.attachment || selectedSprites[0].attachment )
					return false;
					
				selectedSprites[0].AttachAvatar(AvatarToAttach);
				if ( AvatarToAttach is SpriteTrailObject )
				{
					AvatarToAttach.layer.sprites.add(AvatarToAttach, true);
					if ( AvatarToAttach.layer.AutoDepthSort )
					{
						AvatarToAttach.layer.SortAvatar(AvatarToAttach);
					}
					var state:EditorState = FlxG.state as EditorState;
					HistoryStack.BeginOperation( new OperationAddSpriteTrail( this, AvatarToAttach as SpriteTrailObject ) );
					state.spriteEditor.ForceSelection( AvatarToAttach );
					App.getApp().CreateSpriteTrailWindow();
				}
				return true;
			}
			return false;
		}
		
		// Try to spawn a new path instance.
		private function TrySpawnInstance(layer:LayerPaths ):Boolean
		{
			if ( !layer )
			{
				return false;
			}
			
			var res:Boolean = false;
			
			if ( IsSpawningInstance )
			{
				if ( selectedSprites.length == 1 )
				{
					if ( layer && layer.IsVisible() )
					{
						var baseShape:PathObject = selectedSprites[0] as PathObject;
						
						if ( currentPath )
						{
							currentPath.IsSelected = false;
							currentPath.alphaPulseEnabled = false;
						}
						selectionChanged = true;
						selectedSprites.length = 0;
						
						currentPath = baseShape.CreateInstancedCopy(mousePos.x,mousePos.y);
						layer.sprites.add(currentPath, true);
						selectedSprites.push(currentPath);
						
						HistoryStack.BeginOperation( new OperationAddAvatar( this, layer, currentPath ) );
						res = true;
					}
				}
				IsSpawningInstance = false;
			}
			return res;
		}
		
		public function SetSelectedNodeIndex( shape:PathObject, index:uint ):void
		{
			if ( currentPath == shape )
			{
				shape.SelectedNodeIndex = index;
				selectedNodeIndex = index;
			}
		}
		
		override public function CopyData():void
		{
			if ( selectedSprites.length == 0 )
			{
				return;
			}
			
			var data:ShapeClipboardData = new ShapeClipboardData();
			var i:uint = selectedSprites.length;
			while ( i-- )
			{
				data.avatars.push( selectedSprites[i].CreateClipboardCopy() );
			}
			Clipboard.SetData( data );
		}
		
		override public function PasteData():void
		{
			var data:ShapeClipboardData = Clipboard.GetData( ) as ShapeClipboardData;
			
			if ( data == null )
			{
				return;
			}
			
			var pathLayer:LayerPaths = App.getApp().CurrentLayer as LayerPaths;
			
			if ( pathLayer == null || !pathLayer.IsVisible() || pathLayer.Locked())
			{
				return;
			}
			
			centerMousePosToScreen( pathLayer );
			
			if ( currentPath )
			{
				currentPath.alphaPulseEnabled = false;
				currentPath.IsSelected = false;
				currentPath = null;
			}
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			
			// Handle snap to grid
			if ( GuideLayer.SnappingEnabled )
			{
				//modifiedMousePos.x = GuideLayer.GetSnappedX(pathLayer, mousePos.x);
				//modifiedMousePos.y = GuideLayer.GetSnappedY(pathLayer, mousePos.y);
				GuideLayer.GetSnappedPos(pathLayer, mousePos.x, mousePos.y, modifiedMousePos);
			}
			selectionChanged = true;
			selectedSprites.length = 0;
			
			var newAvatars:Vector.<EditorAvatar> = new Vector.<EditorAvatar>;
			var i:uint = data.avatars.length;
			var xOffset:Number = data.avatars[0].x - modifiedMousePos.x;
			var yOffset:Number = data.avatars[0].y - modifiedMousePos.y;
			while ( i-- )
			{
				var newSprite:PathObject = data.avatars[i].CreateClipboardCopy() as PathObject;
				newSprite.x -= xOffset;
				newSprite.y -= yOffset;
				newSprite.layer = pathLayer;
				newSprite.Invalidate();
				pathLayer.sprites.add(newSprite, true);
				pathLayer.UpdateMinMax( newSprite );
				selectedSprites.push(newSprite);
				newAvatars.push(newSprite);
			}
			
			HistoryStack.BeginOperation( new OperationPasteAvatars(this, pathLayer, newAvatars) );
		}
		
		override protected function DecideContextMenuActivation( ):void
		{
			var oldSelection:EditorAvatar = selectedSprites.length ? selectedSprites[0] : null;
			selectedSprites.length = 0;
			// If we click down on an already selected sprite then we initiate move mode.

			var layer:LayerPaths = App.getApp().CurrentLayer as LayerPaths;
			if ( layer && layer.IsVisible() )
			{
				var selectedObj:PathObject = null;
				for each( var avatar:EditorAvatar in layer.sprites.members )
				{
					if ( avatar.IsOverScreenPos( mouseScreenPos, true, 0, null, true ) )
					{
						selectedObj = avatar as PathObject;
						
						// Only select the first one.
						break;
					}
				}

				if ( selectedObj == null )
				{
					selectedObj = oldSelection as PathObject;
				}
				if ( selectedObj == null )
				{
					// Try again but do a box selection.
					for each( avatar in layer.sprites.members )
					{
						if ( avatar.IsOverScreenPos( mouseScreenPos, false ) )
						{
							selectedObj = avatar as PathObject;
							break;
						}
					}
				}
				spriteTrailMenuItem.enabled = selectedObj != null && !selectedObj.attachment;
				
				if ( selectedObj != null )
				{
					closeOpenShapeMenuItem.label = selectedObj.IsClosedPoly ? "Open Shape" : "Close Shape";
					selectedSprites.push( selectedObj );
					selectionChanged = true;
					contextMenu.display( FlxG.stage, FlxG.stage.mouseX, FlxG.stage.mouseY );
					return;
				}
				
			}
			
			
		}
		
		override protected function contextMenuHandler(event:Event):void
		{			
			switch( event.target.label )
			{
				case "Spawn Instance":
				if ( selectedSprites.length )
				{
					var layer:LayerPaths = App.getApp().CurrentLayer as LayerPaths;
					if ( layer && layer.IsVisible() )
					{
						var baseShape:PathObject = selectedSprites[0] as PathObject;
						
						if ( currentPath )
						{
							currentPath.IsSelected = false;
							currentPath.alphaPulseEnabled = false;
						}
						
						selectionChanged = true;
						selectedSprites.length = 0;
						
						currentPath = baseShape.CreateInstancedCopy(baseShape.x+50,baseShape.y);
						layer.sprites.add(currentPath, true);
						selectedSprites.push(currentPath);
						
						HistoryStack.BeginOperation( new OperationAddAvatar( this, layer, currentPath ) );
					}
				}
				break;
				
				case "Spawn Instance On Other layer":
				if ( selectedSprites.length )
				{
					IsSpawningInstance = true;
				}
				break;
				
				case "Open Shape":
				if ( selectedSprites.length )
				{
					baseShape = selectedSprites[0] as PathObject;
					baseShape.IsClosedPoly = false;
					baseShape.Invalidate();
				}
				break;
				
				case "Close Shape":
				if ( selectedSprites.length )
				{
					baseShape = selectedSprites[0] as PathObject;
					baseShape.IsClosedPoly = true;
					baseShape.Invalidate();
				}
				break;
				
				case "Attach Sprite Trail":
				if ( selectedSprites.length && !selectedSprites[0].attachment )
				{
					selectionChanged = true;
					selectedSprites.length = 1;
					InSpriteTrailMode = true;
				}
				break;
				
				default:
				super.contextMenuHandler(event);
				break;
			}
		}
		
		
	}

}

import com.Game.EditorAvatar;

internal class ShapeClipboardData
{
	public var avatars:Vector.<EditorAvatar> = new Vector.<EditorAvatar>();
}