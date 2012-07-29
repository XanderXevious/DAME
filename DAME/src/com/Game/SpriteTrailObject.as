package com.Game 
{
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Tiles.SpriteEntry;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import org.flixel.FlxU;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpriteTrailObject extends EditorAvatar
	{
		public var children:Vector.<EditorAvatar> = new Vector.<EditorAvatar>;
		
		public var trailData:SpriteTrailData = new SpriteTrailData;
		
		public function SpriteTrailObject(_layer:LayerAvatarBase)
		{
			super(0, 0, null);
			layer = _layer;	// Don't pass in the layer as we may not have actually added it yet.
			visible = false;
		}
		
		override public function CanRotate():Boolean
		{
			return false;
		}
		
		override public function CanScale():Boolean
		{
			return false;
		}
		
		override public function CanMove():Boolean
		{
			return false;
		}
		
		override protected function renderSprite():void
		{
			// Nothing to render!
		}
		
		override public function DetachAvatar( ):void
		{
			var i:int = children.length;
			while ( i-- )
			{
				var child:EditorAvatar = children[i];
				child.spriteTrailOwner = null;
			}
			children.length = 0;
			super.DetachAvatar();
		}
		
		override public function Delete():void
		{
			var i:int = children.length;
			while ( i-- )
			{
				var child:EditorAvatar = children[i];
				child.Delete();
			}
			children.length = 0;
			super.Delete();
		}
		
		private function CreateChildAtPosition( index:int, pos:FlxPoint, angle:Number, trail:SpriteTrailEntry ):EditorAvatar
		{
			var spriteEntry:SpriteEntry = trail ? trail.sprite : null;
			var child:EditorAvatar;
			if ( index >= children.length )
			{
				child = new EditorAvatar(pos.x, pos.y, layer );
				children.push(child);
				child.scrollFactor = layer.sprites.scrollFactor;
				layer.sprites.members.splice(layer.sprites.members.indexOf(this) + 1, 0, child);
				child.CreateGUID();
			}
			else
			{
				child = children[index];
				child.layer = layer;
			}
			child.copyFrom(pos);
			var reset:Boolean = false;
			if ( spriteEntry )
			{
				if ( !spriteEntry.IsTileSprite )
				{
					if ( child.animIndex != trail.frame )
					{
						reset = true;
						child.animIndex = trail.frame;
					}
				}
				else
				{
					if ( trail.dims && ( !child.TileDims || trail.dims.x != child.TileDims.x || trail.dims.y != child.TileDims.y ) )
					{
						reset = true;
						child.TileDims = trail.dims;
					}
					if ( child.TileDims && !trail.dims && (child.TileDims.x != spriteEntry.previewBitmap.width || child.TileDims.y != spriteEntry.previewBitmap.height) )
					{
						reset = true;
						child.TileDims = trail.dims;
					}
					if ( trail.offset && ( !child.TileOrigin || trail.offset.x != child.TileOrigin.x || trail.offset.y != child.TileOrigin.y ) )
					{
						reset = true;
						child.TileOrigin = trail.offset;
					}
					if ( child.TileOrigin && !trail.offset)
					{
						var x:int = spriteEntry.TileOrigin.x;
						var y:int = spriteEntry.TileOrigin.y;
						if ( child.TileOrigin.x != x || child.TileOrigin.y != y )
						{
							reset = true;
							child.TileOrigin = null;
						}
					}
				}
			}
			if( reset || child.spriteEntry != spriteEntry )
				child.SetFromSpriteEntry( spriteEntry, true, true );
			var anchor:FlxPoint = trail && trail.anchor ? trail.anchor.copy() : child.GetAnchor();
			if ( angle != 0 )
			{
				var matrix:Matrix = new Matrix;
				var w:int = child.width / 2;
				var h:int = child.height / 2;
				matrix.translate( -w, -h );
				matrix.rotate(angle * Math.PI / 180 );
				matrix.translate( w, h );
				// Get the real pos of the anchor after rotations.
				var pt:Point = new Point(anchor.x, anchor.y);
				pt = matrix.transformPoint(pt);
				anchor.create_from_flashPoint(pt);
			}
			child.subFrom(anchor);
			child.spriteTrailOwner = this;
			child.angle = angle;
			
			return child;
		}
		
		// Update the position of all child sprites here.
		override public function UpdateAttachment():void
		{
			super.UpdateAttachment();
			
			if ( attachment && attachment.Parent )
			{
				attachment.Offset.x = 0;
				attachment.Offset.y = 0;
			
				var pathAvatar:PathObject = attachment.Parent as PathObject;
				x = pathAvatar.x;
				y = pathAvatar.y;
				width = pathAvatar.width;
				height = pathAvatar.height;
				attachment.Parent.GetAttachmentPosition(this);
				
				var numSprites:int = trailData.sprites.length;
				var spriteIdx:int = 0;
				
				var lengths:Vector.<Number> = new Vector.<Number>;
				var points:Vector.<FlxPoint> = new Vector.<FlxPoint>;
				var totalLength:Number = pathAvatar.GetLinearPointsAndLength(lengths, points);
				var gap:Number = trailData.SpriteSeparation;
				var numChildren:int;
				if ( trailData.CleverSpread )
				{
					numChildren = Math.floor( totalLength / gap );
					gap = totalLength / numChildren;
				}
				else
				{
					numChildren = Math.ceil( totalLength / gap );
				}
				
				var lastNode:FlxPoint = null;
				var len:Number = 0;
				var lastLen:Number = 0;
				var segLen:Number;
				var childCount:int = 0;
				var childPos:FlxPoint = new FlxPoint;
				var lastPos:FlxPoint = new FlxPoint;
				var dir:FlxPoint;
				
				var angle:Number = trailData.RotationOffset;
				
				var maxPoints:int = points.length;
				var data:SpriteTrailEntry = null;
				var entry:SpriteEntry = null;
				
				var currentSeed:Number = trailData.RandomSeed;
				
				if ( maxPoints )
				{
					if ( trailData.RotateFollows && maxPoints > 1 )
					{
						dir = points[1].v_sub(points[0]);
						angle = trailData.RotationOffset + ( dir.radians() * Misc.RAD_TO_DEG );
					}
					
					childPos.copyFrom(points[0]);
					childPos.addTo(this);
					lastPos.copyFrom(childPos);
					
					if ( trailData.EdgeSprites && !pathAvatar.IsClosedPoly )
					{
						spriteIdx = 0;
					}
					else if ( trailData.RandomSprites )
					{
						currentSeed = FlxU.random( currentSeed );
						spriteIdx = currentSeed * numSprites;
					}
					else
					{
						spriteIdx = 0;
					}
					data = ( spriteIdx < numSprites ) ? trailData.sprites[spriteIdx] : null;
					CreateChildAtPosition(childCount, childPos, angle, data);
					childCount++;
				}
				
				for ( var i:uint = 0; i < maxPoints; i++ )
				{
					var pathNode:FlxPoint = points[i];
					if ( lastNode != null )
					{
						var startLen:Number = len;
						segLen = lengths[i - 1];
						len += segLen;
						while ( lastLen + gap < len && childCount < numChildren )
						{
							lastLen += gap;
							var ptLen:Number = lastLen - startLen;
							var t:Number = ptLen / segLen;
							childPos.x = Misc.lerp( t, lastNode.x, pathNode.x );
							childPos.y = Misc.lerp( t, lastNode.y, pathNode.y );
							
							childPos.addTo(this);
							
							if ( trailData.RotateFollows )
							{
								dir = childPos.v_sub(lastPos);
								angle = trailData.RotationOffset + ( dir.radians() * Misc.RAD_TO_DEG );
								lastPos.copyFrom(childPos);
							}
							
							if ( trailData.EdgeSprites && childCount == numChildren-1 && !trailData.CleverSpread && !pathAvatar.IsClosedPoly )
							{
								spriteIdx = Math.max( 0, numSprites-1 );
							}
							else if ( trailData.RandomSprites )
							{
								currentSeed = FlxU.random( currentSeed );
								spriteIdx = currentSeed * numSprites;
							}
							else
							{
								spriteIdx++;
								if ( spriteIdx == numSprites )
									spriteIdx = 0;
							}
							data = ( spriteIdx < numSprites ) ? trailData.sprites[spriteIdx] : null;
							
							CreateChildAtPosition(childCount, childPos, angle, data);
							childCount++;
						}
					}
					lastNode = pathNode;
				}
				
				if ( trailData.CleverSpread && !pathAvatar.IsClosedPoly && maxPoints > 1 )
				{
					// Add one last sprite to the end.
					childPos.copyFrom(points[maxPoints-1]);
					childPos.addTo(this);
					
					if ( trailData.RotateFollows )
					{
						dir = childPos.v_sub(lastPos);
						angle = trailData.RotationOffset + ( dir.radians() * Misc.RAD_TO_DEG );
					}
					if ( trailData.EdgeSprites )
					{
						spriteIdx = Math.max( 0, numSprites - 1 );
					}
					else if ( trailData.RandomSprites )
					{
						currentSeed = FlxU.random( currentSeed );
						spriteIdx = currentSeed * numSprites;
					}
					else
					{
						spriteIdx++;
						if ( spriteIdx == numSprites )
							spriteIdx = 0;
					}
					data = ( spriteIdx < numSprites ) ? trailData.sprites[spriteIdx] : null;
					
					CreateChildAtPosition(childCount, childPos, angle, data);
					childCount++;
				}
				
				// Remove any unnecessary children.
				while ( childCount < children.length )
				{
					var child:EditorAvatar = children[children.length - 1];
					var avatarIndex:uint = child.layer.sprites.members.indexOf(child);
					child.layer.sprites.members.splice(avatarIndex, 1);
					children.length--;
				}
			}
			layer.UpdateMinMax(this);
		}
		
		override public function SendToLayerFront():Boolean
		{
			var changed:Boolean = false;
			for each( var child:EditorAvatar in children )
			{
				changed = child.SendToLayerFront() || changed;
			}
			return changed;
		}
		
		override public function SendToLayerBack():Boolean
		{
			var changed:Boolean = false;
			for each( var child:EditorAvatar in children )
			{
				changed = child.SendToLayerBack() || changed;
			}
			return changed;
		}
		
	}

}