package com.Game 
{
	import com.EditorState;
	import com.Layers.LayerAvatarBase;
	import com.Utils.BezierUtils;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import org.flixel.FlxPoint;
	import org.flixel.FlxG;
	import com.Utils.DebugDraw;
	import org.flixel.FlxU;
	import com.Utils.Global;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PathObject extends EditorAvatar
	{
		public var nodes:Vector.<PathNode> = new Vector.<PathNode>();
		
		private var shape:Shape;
		private var debugShape:Shape;	// Used to render the node handles when selected.
		public var IsClosedPoly:Boolean = false;
		public var _isCurved:Boolean = false;
		public function get IsCurved():Boolean { return _isCurved; }
		public var IsSelected:Boolean = false;
		public var SelectedNodeIndex:uint = 0;
		
		// Values used for editing to handle rotating/scaling.
		public var storedNodes:Vector.<PathNode> = new Vector.<PathNode>();
		
		private var _isInstanced:Boolean = false;
		public function get IsInstanced():Boolean { return _isInstanced; }
		
		public var instancedShapes:Vector.<PathObject> = null;
		
		// These values will only be set if there is a sprite trail object attached.
		private var cachedLengths:Vector.<Number> = null;
		private var cachedPoints:Vector.<FlxPoint> = null;
		private var cachedTotalLength:Number = 0;
		
		public var pathEvents:Vector.<PathEvent> = new Vector.<PathEvent>;
		
		public var redrawPathEvents:Boolean = false;
		
		private var oldLineThickness:int = 0;
		
		private var cachedMinExtent:FlxPoint = new FlxPoint();
		
		public var ShapeFillAlpha:Number = 0.0;
		public var ShapeFillColor:uint = 0;
		
		public override function set markForDeletion( mark:Boolean ):void
		{
			super.markForDeletion = mark;
			if ( mark )
			{
				IsSelected = false;
			}
			else
			{
				Invalidate();
			}
		}
		
		public function PathObject(X:Number,Y:Number,Curved:Boolean, layer:LayerAvatarBase) 
		{
			super(X, Y, layer );
			
			_isCurved = Curved;
			
			nodes.push( new PathNode(0, 0, _isCurved) );

			debugShape = new Shape();
			shape = new Shape();
			SetFromBitmap(new Bitmap(new BitmapData(1, 1)),1,1);
			Invalidate();
			
			canCreateBmp = false;
		}
	
		
		override public function render():void
		{
			super.render();
			
			if ( wasDrawn )
			{
				var matrix:Matrix = new Matrix;
				var pos:FlxPoint = this.copy();
				getScreenXY(pos);
				if ( FlxG.zoomScale < 0.5 )
				{
					matrix.scale( FlxG.zoomScale, FlxG.zoomScale);
				}
				matrix.translate( -cachedMinExtent.x + pos.x, -cachedMinExtent.y + pos.y);
				FlxG.buffer.draw(shape, matrix, new ColorTransform(1,1,1,alpha));
			}
			
			if (!wasDrawn )
			{
				return;
			}
			
			if ( App.getApp().CurrentLayer == layer )
			{
				if (  IsSelected )
				{
					var node:PathNode;
					var tangent:FlxPoint;
					var tempPos:FlxPoint = new FlxPoint();
					var color:uint;
					
					if ( Global.UseFlashShapeRenderer )
					{
						debugShape.graphics.clear();
					}
					
					var screenPos:FlxPoint = new FlxPoint();
					getScreenXY(screenPos);
					
					for (var i:uint = 0; i < nodes.length; i++ )
					{
						node = nodes[i];
						
						var nodex:Number = node.x >> FlxG.zoomBitShifter;
						var nodey:Number = node.y >> FlxG.zoomBitShifter;
						
						// Draw a box around the selected node.
						if ( i == SelectedNodeIndex )
						{
							color = Misc.blendARGB( (_isInstanced ? Global.PathNodeColourInstancedSelected1 : Global.PathNodeColourSelected1 ), Global.PathColour, alpha);
						}
						else
						{
							color = Misc.blendARGB( (_isInstanced ? Global.PathColour : Global.PathColour ), Global.PathColour, alpha * 0.8);
						}
						if ( Global.UseFlashShapeRenderer )
						{
							debugShape.graphics.lineStyle(0, color, 1,true);
							debugShape.graphics.moveTo(screenPos.x + nodex, screenPos.y + nodey);
							debugShape.graphics.drawRect(screenPos.x + (nodex - 2), screenPos.y + (nodey - 2), 4, 4);
						}
						else
						{
							var nx:uint = screenPos.x + nodex;
							var ny:uint = screenPos.y + nodey;
							Misc.DrawCustomRect(nx - 2, ny - 2, nx + 2, ny + 2, EditorState.DrawOnBufferCallback, color );
						}
						
						if ( _isCurved )
						{
							// Draw the tangent.
							color = Global.PathTangentColour;
							if ( i == SelectedNodeIndex )
							{
								color = Misc.blendARGB(Global.PathTangentColourSelected1, Global.PathTangentColour, alpha);
							}
							
							var tan1x:Number = node.tangent1.x >> FlxG.zoomBitShifter;
							var tan1y:Number = node.tangent1.y >> FlxG.zoomBitShifter;
							var tan2x:Number = node.tangent2.x >> FlxG.zoomBitShifter;
							var tan2y:Number = node.tangent2.y >> FlxG.zoomBitShifter;
							if ( Global.UseFlashShapeRenderer )
							{
								debugShape.graphics.lineStyle(0, color, 1, true);
								tempPos.create_from_points(screenPos.x + nodex + tan1x, screenPos.y + nodey + tan1y );
								
								debugShape.graphics.moveTo(tempPos.x, tempPos.y );
								debugShape.graphics.drawRect(tempPos.x - 2, tempPos.y - 2, 4, 4);
								
								debugShape.graphics.moveTo(tempPos.x, tempPos.y );
								debugShape.graphics.lineTo(screenPos.x + nodex, screenPos.y + nodey);
								tempPos.create_from_points(screenPos.x + nodex + tan2x, screenPos.y + nodey + tan2y );
								debugShape.graphics.lineTo(tempPos.x, tempPos.y );
								debugShape.graphics.moveTo(tempPos.x, tempPos.y );
								debugShape.graphics.drawRect(tempPos.x - 2, tempPos.y - 2, 4, 4);
							}
							else
							{
								tempPos.create_from_points(screenPos.x + nodex + tan1x, screenPos.y + nodey + tan1y );
								Misc.DrawCustomRect(tempPos.x - 2, tempPos.y - 2, tempPos.x + 2, tempPos.y + 2, EditorState.DrawOnBufferCallback, color );
								Misc.DrawCustomLine( tempPos.x, tempPos.y, screenPos.x + nodex, screenPos.y + nodey, EditorState.DrawOnBufferCallback, color );
								
								tempPos.create_from_points(screenPos.x + nodex + tan2x, screenPos.y + nodey + tan2y );
								
								Misc.DrawCustomLine( tempPos.x, tempPos.y, screenPos.x + nodex, screenPos.y + nodey, EditorState.DrawOnBufferCallback, color );
								Misc.DrawCustomRect( tempPos.x - 2, tempPos.y - 2, tempPos.x + 2, tempPos.y + 2, EditorState.DrawOnBufferCallback, color );

							}
						}
						if ( Global.UseFlashShapeRenderer )
						{
							FlxG.buffer.draw(debugShape);
						}
					}
				}
				
				//if ( redrawPathEvents || IsSelected )
				{
					redrawPathEvents = false;
					renderPathEvents();
				}
				//DrawBoundingBox();
			}
		}
		
		private function renderPathEvents():void
		{
			var i:uint = pathEvents.length;
			while ( i-- )
			{
				pathEvents[i].render();
			}
		}
		
		override public function update():void
		{
			super.update();
			var lineThickness:int = FlxG.extraZoom < 1 ? FlxG.invExtraZoom : 0;
			if ( lineThickness != oldLineThickness )
			{
				Invalidate(false);
			}
		}
		
		public function AddNode(index:uint, position:FlxPoint):void
		{
			var node:PathNode = new PathNode(position.x, position.y, _isCurved);
			if ( index > nodes.length )
			{
				index = nodes.length;
			}
			else if ( index == 0 )
			{
				index = 1;
			}
			nodes.splice( index, 0, node );
			if ( IsCurved )
			{
				if ( nodes.length > 1 )
				{
					var oldTangentPosX:Number = nodes[index - 1].x + nodes[index - 1].tangent1.x;
					var oldTangentPosY:Number = nodes[index - 1].y + nodes[index - 1].tangent1.y;
					node.tangent1.create_from_points(position.x - oldTangentPosX, position.y - oldTangentPosY);
					node.tangent1.normalize();
					node.tangent1.multiplyBy(30);
					node.tangent2.create_from_points(node.tangent1.x * -1, node.tangent1.y * -1);
				}
			}
		}
		
		private function ChangeExtentsAgainstPoints(testPoint:FlxPoint, minExtent:FlxPoint, maxExtent:FlxPoint):void
		{
			if ( testPoint.x > maxExtent.x )
			{
				maxExtent.x = testPoint.x;
			}
			if ( testPoint.x < minExtent.x )
			{
				minExtent.x = testPoint.x;
			}
			
			if ( testPoint.y > maxExtent.y )
			{
				maxExtent.y = testPoint.y;
			}
			if ( testPoint.y < minExtent.y )
			{
				minExtent.y = testPoint.y;
			}
		}
		
		private function DrawBezierSegment(Anchor1:FlxPoint, Tangent1:FlxPoint, Tangent2:FlxPoint, Anchor2:FlxPoint, minExtent:FlxPoint, maxExtent:FlxPoint):void
		{
			var control2:FlxPoint = Anchor2.v_add(Tangent2);
			var control1:FlxPoint = Anchor1.v_add(Tangent1);
			var curvePos:FlxPoint;
			for ( var t:Number = 0.1; t < 1; t+=0.05 )
			{
				curvePos = Misc.GetPositionOnBezierSegment( t, Anchor1, control1, control2, Anchor2, null );
				ChangeExtentsAgainstPoints(curvePos, minExtent, maxExtent);
				shape.graphics.lineTo(curvePos.x, curvePos.y);
			}
			// Draw the last part of the curve
			shape.graphics.lineTo(Anchor2.x, Anchor2.y);
		}
		
		public function Invalidate( sourceInstance:Boolean = true ):void
		{
			if ( markForDeletion )
			{
				return;
			}
			
			var maxExtent:FlxPoint = new FlxPoint(-999999,-999999);
			var minExtent:FlxPoint = new FlxPoint(999999,999999);
			var node:PathNode;
			var tangent:FlxPoint;
			var tempPos:FlxPoint = new FlxPoint();
			
			var nodeIndex:uint = nodes.length;
			while( nodeIndex-- )
			{
				node = nodes[nodeIndex];
				ChangeExtentsAgainstPoints(node, minExtent, maxExtent);
			}
			
			shape.graphics.clear();
			var pathColour:uint = ( _isInstanced ? Global.PathColourInstanced : Global.PathColour);
			var lineThickness:int = FlxG.extraZoom < 1 ? FlxG.invExtraZoom : 2;
			shape.graphics.lineStyle(lineThickness, pathColour, 1,true);
			
			var lastPoint:FlxPoint = null;
			
			var curvePos:FlxPoint = new FlxPoint();
			var lastNode:PathNode = null;
			
			if( IsClosedPoly && ShapeFillAlpha > 0 )
				shape.graphics.beginFill( ShapeFillColor, ShapeFillAlpha);
			
			for ( nodeIndex = 0; nodeIndex < nodes.length; nodeIndex++ )
			{			
				node = nodes[nodeIndex];
				if ( lastNode == null )
					shape.graphics.moveTo(node.x, node.y);
				if ( lastNode != null )
				{
					//shape.graphics.moveTo(lastNode.x, lastNode.y);
					if ( _isCurved )
					{
						DrawBezierSegment( lastNode, lastNode.tangent1, node.tangent2, node, minExtent, maxExtent );
					}
					else
					{
						shape.graphics.lineTo(node.x, node.y);
					}
				}
				//shape.graphics.moveTo(node.x, node.y);
				lastNode = node;
			}
			
			// Close the gap between the last and first nodes if this is a closed shape.
			if ( IsClosedPoly && nodes.length > 1 )
			{
				shape.graphics.moveTo(lastNode.x, lastNode.y);
				if ( IsCurved )
				{
					DrawBezierSegment( lastNode, lastNode.tangent1, nodes[0].tangent2, nodes[0], minExtent, maxExtent );
				}
				else
				{
					shape.graphics.lineTo(nodes[0].x, nodes[0].y);
				}
			}
			
			if( IsClosedPoly && ShapeFillAlpha > 0 )
				shape.graphics.endFill();
			
			for ( nodeIndex = 0; nodeIndex < nodes.length; nodeIndex++ )
			{			
				node = nodes[nodeIndex];
				shape.graphics.lineStyle(lineThickness, 0xff444444, 1, true);
				shape.graphics.beginFill(0xffffff, 1);
				shape.graphics.drawRect(node.x - 2, node.y - 2, 4, 4);
				shape.graphics.endFill();
				shape.graphics.lineStyle(lineThickness, pathColour, 1,true);
			}
			
			nodeIndex = nodes.length;
			while( nodeIndex-- )
			{			
				node = nodes[nodeIndex];
				node.x -= minExtent.x;
				node.y -= minExtent.y;
			}
			
			// Ensure the origin of the shape is always at the top left corner of the node extents
			x += minExtent.x;
			y += minExtent.y;
			
			// Ensure that the bitmap is a bit larger to allow for drawing the node tangents.
			width = frameWidth = (maxExtent.x - minExtent.x) + 4;
			height = frameHeight = (maxExtent.y - minExtent.y) + 4;
			
			
			//_pixels = new BitmapData( width, height, true, 0x00000000);
			var matrix:Matrix = new Matrix;
			matrix.translate( -minExtent.x, -minExtent.y);
			cachedMinExtent = minExtent;
			//_pixels.draw(shape,matrix);
			resetHelpers();
			
			if ( cachedLengths )
			{
				cachedLengths.length = 0;
				cachedPoints.length = 0;
				cachedTotalLength = GetLinearPointsAndLength(null, null);
			}
			
			if ( attachment && attachment.Child )
			{
				RefreshAttachmentValues();
			}
			
			if ( sourceInstance && _isInstanced )
			{
				var instanceIndex:uint = instancedShapes.length;
				while ( instanceIndex-- )
				{
					if ( instancedShapes[instanceIndex] != this )
					{
						instancedShapes[instanceIndex].Invalidate( false );
					}
				}
			}
			
			oldLineThickness = lineThickness;
			
		}
		
		public function GetLinearPointsAndLength( lengths:Vector.<Number>, points:Vector.<FlxPoint> ):Number
		{
			var lastNode:PathNode = null;
			var len:Number = 0;
			var segLen:Number = 0;
			var control1:FlxPoint = new FlxPoint;
			var control2:FlxPoint = new FlxPoint;
			var i:uint;
			if ( lengths == null )
			{
				lengths = cachedLengths = new Vector.<Number>;
				points = cachedPoints = new Vector.<FlxPoint>;
			}
			else if( cachedLengths != null )
			{
				for ( i = 0; i < cachedLengths.length; i++ )
				{
					lengths.push(cachedLengths[i]);
				}
				for ( i = 0; i < cachedPoints.length; i++ )
				{
					points.push(cachedPoints[i]);
				}
				return cachedTotalLength;
			}
			else
			{
				// Naughty - it assumes that the lengths and points passed in won't be modified.
				cachedLengths = lengths;
				cachedPoints = points;
			}
			
			if ( nodes.length )
			{
				points.push( nodes[0].copy() );
			}
			for ( i = 0; i < nodes.length; i++ )
			{
				var pathNode:PathNode = nodes[i] as PathNode;
				if ( lastNode != null )
				{
					if ( IsCurved )
					{
						control2.copyFrom(pathNode);
						control2.addTo(pathNode.tangent2);
						segLen = Misc.GetLengthOfBezierSegment(lastNode, control1, control2, pathNode, lengths, points, false, 7 );
					}
					else
					{
						segLen = pathNode.distance_to(lastNode);
						lengths.push( segLen );
						points.push( pathNode.copy() );
					}
					len += segLen;
				}
				lastNode = pathNode;
				if ( IsCurved )
				{
					control1.copyFrom(pathNode);
					control1.addTo(pathNode.tangent1);
				}
			}
			if ( IsClosedPoly && nodes.length > 1 )
			{
				if ( IsCurved )
				{
					pathNode = nodes[0];
					control2.copyFrom(pathNode);
					control2.addTo(pathNode.tangent2);
					segLen = Misc.GetLengthOfBezierSegment(lastNode, control1, control2, pathNode, lengths, points, false, 7 );
				}
				else
				{
					segLen = lastNode.distance_to(nodes[0]);

					lengths.push( segLen );
					points.push( nodes[0].copy() );
				}
				len += segLen;
			}
			cachedTotalLength = len;
			return len;
		}
		
		public function refreshPathEventAttachments():void
		{
			var i:int = pathEvents.length;
			while ( i-- )
			{
				pathEvents[i].UpdateAttachment();
			}
		}
		
		override public function RefreshAttachmentValues( ):void
		{
			if ( !attachment || !attachment.Child )
			{
				return;
			}
			var childPos:FlxPoint = FlxPoint.CreateObject(attachment.Child);
			
			// When we have an anchor we basically fake the position. Moving the pos (usually top left ) to where
			// the closest pt on the path is. Then GetAttachmentPosition will correct this so the anchor is at that location.
			var editorAvatar:EditorAvatar = attachment.Child as EditorAvatar;
			var anchor:FlxPoint = editorAvatar.GetAnchor();
			anchor.x *= editorAvatar.scale.x;
			anchor.y *= editorAvatar.scale.y;
			childPos.addTo(anchor);
			
			if ( editorAvatar.angle != 0 )
			{
				// Get the real pos of the anchor after rotations.
				var matrix:Matrix = editorAvatar.GetTransformMatrixForRealPosToDrawnPos(editorAvatar,editorAvatar.angle);
				var pt:Point = new Point(childPos.x, childPos.y);
				pt = matrix.transformPoint(pt);
				childPos.create_from_flashPoint(pt);
			}
			
			if ( !scrollFactor.equals(editorAvatar.scrollFactor ) )
			{
				// Position needs to be in my world space to compare points.
				// getScreenXY()
				var screenPos:FlxPoint = new FlxPoint();
				screenPos.x = FlxU.floor(childPos.x + roundingError)+FlxU.floor(FlxG.scroll.x*editorAvatar.scrollFactor.x);
				screenPos.y = FlxU.floor(childPos.y + roundingError)+FlxU.floor(FlxG.scroll.y*editorAvatar.scrollFactor.y);
				
				//getMapXYFromScreenXY (inverse of getScreenXY):
				childPos.x = FlxU.floor( screenPos.x + roundingError) - FlxU.floor(FlxG.scroll.x*scrollFactor.x);
				childPos.y = FlxU.floor( screenPos.y + roundingError) - FlxU.floor(FlxG.scroll.y*scrollFactor.y);
			}
			
			// Needs to be at least a line to do the big calculations.
			if ( nodes.length < 2 )
			{
				attachment.Child.attachment.Offset.create_from_points(0, 0);
				attachment.segmentNumber = 0;
				attachment.percentInSegment = 0;
				return;
			}
			
			var closestPt:FlxPoint = GetClosestPoint( childPos, attachment, "percentInSegment", "segmentNumber" );
			
			attachment.Child.attachment.Offset.x = closestPt.x - x;
			attachment.Child.attachment.Offset.y = closestPt.y - y;
			attachment.Child.attachment.percentInSegment = attachment.percentInSegment;
			attachment.Child.attachment.segmentNumber = attachment.segmentNumber;
			GetAttachmentPosition(attachment.Child);
			attachment.Child.UpdateAttachment();
			
			refreshPathEventAttachments();
		}
		
		public function GetClosestPoint( testPos:FlxPoint, resObj:Object, bestTName:String, bestSegmentName:String):FlxPoint
		{
			if ( nodes.length < 2 )
			{
				return null;
			}
			var closestPt:FlxPoint = new FlxPoint;
			var i:int = nodes.length - 1;
			var lastPos:FlxPoint = new FlxPoint(x + nodes[i].x, y + nodes[i].y);
			var lastTangent:FlxPoint;
			var testClosestPt:FlxPoint = new FlxPoint();
			var control1:FlxPoint = new FlxPoint();
			var control2:FlxPoint = new FlxPoint();
			var t:Number;
			var bestT:Number = 0;
			var bestSegmentIndex:uint = 0;
			var dist:Number;
			var bestDist:Number = 999999;
			var pos:FlxPoint = new FlxPoint;
			
			if ( _isCurved )
			{
				lastTangent = nodes[i].tangent2;
			}
				
			while ( i-- )
			{
				pos.create_from_points(x + nodes[i].x, y + nodes[i].y);
				if ( _isCurved )
				{
					control1.create_from_points(lastPos.x + lastTangent.x, lastPos.y + lastTangent.y);
					control2.create_from_points(pos.x + nodes[i].tangent1.x, pos.y + nodes[i].tangent1.y);
					t = BezierUtils.closestPointToBezier(pos, control2, control1, lastPos, testPos, testClosestPt );
					lastTangent = nodes[i].tangent2;
				}
				else
				{
					t = Misc.ClosestPointOnSegment(pos, lastPos, testPos, testClosestPt);
				}
				dist = Misc.squareDistance(testPos, testClosestPt);
				if ( dist < bestDist )
				{
					closestPt.copyFrom(testClosestPt);
					bestDist = dist;
					bestT = t;
					bestSegmentIndex = i;
				}
				
				lastPos.create_from_points(pos.x, pos.y);
			}

			// For cloest paths test the line from the last node to the first node.
			if ( IsClosedPoly )
			{
				i = nodes.length - 1;
				pos.create_from_points(x+nodes[i].x, y+nodes[i].y);
				if ( _isCurved )
				{
					control1.create_from_points(lastPos.x + lastTangent.x, lastPos.y + lastTangent.y);
					control2.create_from_points(pos.x + nodes[i].tangent1.x, pos.y + nodes[i].tangent1.y);
					t = BezierUtils.closestPointToBezier(pos, control2, control1, lastPos, testPos, testClosestPt );
				}
				else
				{
					t = Misc.ClosestPointOnSegment(pos, lastPos, testPos, testClosestPt);
				}
				dist = Misc.squareDistance(testPos, testClosestPt);
				if ( dist < bestDist )
				{
					closestPt.copyFrom(testClosestPt);
					bestDist = dist;
					bestT = t;
					bestSegmentIndex = i;
				}
			}
			
			if ( resObj )
			{
				if ( bestSegmentName )
				{
					resObj[bestSegmentName] = bestSegmentIndex;
				}
				if ( bestTName )
				{
					resObj[ bestTName ] = bestT;
				}
			}
			
			return closestPt;
		}
		
		override public function GetAttachmentPosition( attachedAvatar:Avatar ):void
		{
			if ( attachment == null || attachment.Child != attachedAvatar )
			{
				return;
			}
			
			// Ensure different scroll factors are handled first.
			super.GetAttachmentPosition( attachedAvatar );
			
			// We take the position of the avatar and move it so the anchor is where the position was.
			
			var editorAvatar:EditorAvatar = attachedAvatar as EditorAvatar;
			var anchor:FlxPoint = editorAvatar.GetAnchor();
			var matrix:Matrix = new Matrix;
			var xOffset:Number = (attachedAvatar.width / 2);
			var yOffset:Number = (attachedAvatar.height / 2);
			
			matrix.translate( xOffset, yOffset );
			matrix.translate( -anchor.x * attachedAvatar.scale.x, -anchor.y * attachedAvatar.scale.y );
			matrix.rotate(attachedAvatar.angle * Math.PI / 180);
			matrix.translate( -xOffset, -yOffset);
			
			
			var pt:Point = matrix.transformPoint( new Point( 0,0 ) );
			attachedAvatar.x += pt.x;
			attachedAvatar.y += pt.y;
		}
		
		override public function CreateClipboardCopy():EditorAvatar
		{
			var newAvatar:PathObject = new PathObject(x, y, _isCurved, layer );
			for ( var i:uint = 0; i < properties.length; i++ )
			{
				newAvatar.properties.addItem(properties[i].Clone());
			}
			newAvatar.Flipped = Flipped;
			newAvatar.CreateGUID();
			newAvatar.angle = angle;
			newAvatar.width = width;
			newAvatar.height = height;
			newAvatar.scale = FlxPoint.CreateObject(scale);
			newAvatar.offset = FlxPoint.CreateObject(offset);
			newAvatar.IsClosedPoly = IsClosedPoly;
			newAvatar.ShapeFillAlpha = ShapeFillAlpha;
			newAvatar.ShapeFillColor = ShapeFillColor;
			newAvatar.nodes = new Vector.<PathNode>;
			for each( var node:PathNode in nodes )
			{
				newAvatar.nodes.push( node.CopyNode() );
			}
			// Can copy everything except the attachment data.
			return newAvatar;
		}
		
		public function CreateInstancedCopy( _x:Number, _y:Number ):PathObject
		{
			var newAvatar:PathObject = new PathObject(_x, _y, _isCurved, layer );
			newAvatar.nodes = nodes;
			newAvatar.storedNodes = storedNodes;
			newAvatar.width = width;
			newAvatar.height = height;
			newAvatar.scale = scale;
			newAvatar.offset = offset;
			newAvatar.angle = angle;
			newAvatar.CreateGUID();
			newAvatar._isInstanced = true;
			_isInstanced = true;
			
			if ( instancedShapes == null )
			{
				instancedShapes = new Vector.<PathObject>();
				instancedShapes.push( this );
			}
			newAvatar.instancedShapes = instancedShapes;
			instancedShapes.push( newAvatar );
			newAvatar.Invalidate(false);
			return newAvatar;
		}
		
		// This is used specifically when being loaded, so skips a few steps.
		public function SetInstanced( sourceAvatar:PathObject ):void
		{
			_isInstanced = true;
			if ( sourceAvatar )
			{
				instancedShapes = sourceAvatar.instancedShapes;
				width = sourceAvatar.width;
				height = sourceAvatar.height;
				nodes = sourceAvatar.nodes;
				storedNodes = sourceAvatar.storedNodes;
				scale = sourceAvatar.scale;
				offset = sourceAvatar.offset;
				angle = sourceAvatar.angle;
			}
			
		}
		
		public function AddPathEvent( pathEvent:PathEvent ):void
		{
			pathEvents.push( pathEvent );
			redrawPathEvents = true;
		}
		
	}

}