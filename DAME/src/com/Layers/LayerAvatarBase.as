package com.Layers 
{
	import com.Editor.EditorTypeAvatarsBase;
	import com.EditorState;
	import com.Game.Avatar;
	import com.Game.EditorAvatar;
	import org.flixel.FlxG;
	import org.flixel.FlxGroup;
	import org.flixel.FlxPoint;
	import mx.collections.ArrayCollection;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerAvatarBase extends LayerEntry
	{
		public var sprites:FlxGroup = new FlxGroup();
		
		// The min/max values can only extend - never shrink.
		public var minx:int = -1000;
		public var maxx:int = 1000;
		public var miny:int = -1000;
		public var maxy:int = 1000;
		
		// Is this layer aligned with the master layer
		public var AlignedWithMasterLayer:Boolean = false;
		public var AutoDepthSort:Boolean = false;
		
		public function LayerAvatarBase( _parent:LayerGroup, _name:String ):void
		{
			super( _parent, _name, null, null);
			properties = new ArrayCollection();
		}
		
		public function UpdateMinMax(avatar:EditorAvatar):void
		{
			minx = Math.min(avatar.x - 500, minx );
			miny = Math.min(avatar.y - 500, miny );
			maxx = Math.max(avatar.right + 500, maxx );
			maxy = Math.max(avatar.bottom + 500, maxy );
		}
		override public function SetScrollFactors( newXScroll:Number, newYScroll:Number ) :void
		{
			super.SetScrollFactors( newXScroll, newYScroll );
			
			sprites.scrollFactor.x = newXScroll;
			sprites.scrollFactor.y = newYScroll;
		}
		
		override public function UpdateVisibility( ):void
		{
			super.UpdateVisibility( );
			
			sprites.visible = visible && parent.visible;
		}
		
		// These are needed for the exporter
		// Override in the Path layer
		public function IsPathLayer():Boolean
		{
			return false;
		}
		
		public function IsShapeLayer():Boolean
		{
			return false;
		}
		
		public function IsSpriteLayer():Boolean
		{
			return false;
		}
		
		public function IsImageLayer():Boolean
		{
			return false;
		}
		
		override public function GetLayerCenter( ):FlxPoint
		{
			if ( sprites.members.length == 0 )
			{
				return null;
			}
			
			var topLeft:FlxPoint = new FlxPoint(Number.MAX_VALUE,Number.MAX_VALUE);
			var bottomRight:FlxPoint = new FlxPoint(-Number.MAX_VALUE,-Number.MAX_VALUE)
			var i:uint = sprites.members.length;
			while (i--)
			{
				var sprite:EditorAvatar = sprites.members[i];
				topLeft.x = Math.min(topLeft.x, sprite.x);
				topLeft.y = Math.min(topLeft.y, sprite.y);
				bottomRight.x = Math.max(bottomRight.x, sprite.right );
				bottomRight.y = Math.max(bottomRight.y, sprite.bottom );
			}
			return new FlxPoint( topLeft.x + ((bottomRight.x - topLeft.x) / 2 ), topLeft.y + ((bottomRight.y - topLeft.y) / 2 ) );;
		}
		
		// finds the next item to the left or above the current map pos.
		override public function GetPreviousItemPos( currentX:Number, currentY:Number, forceSelect:Boolean ):FlxPoint
		{
			if ( sprites.members.length == 0 )
			{
				return null;
			}
			
			var centreX:int = int((FlxG.width / 2) - currentX);
			var centreY:int = int((FlxG.height / 2) - currentY);
			
			var bestX:int = int.MIN_VALUE;
			var bestY:int = int.MIN_VALUE;
			var bestAvatar:EditorAvatar = null;
			var found:Boolean = false;
			
			for ( var i:uint = 0; i < sprites.members.length; i++ )
			{
				var avatar:EditorAvatar = sprites.members[i];
				if ( !avatar.CanSelect() )
					continue;
				var x:int = int(avatar.x + ( avatar.width * 0.5 ));
				var y:int = int(avatar.y + ( avatar.height * 0.5 ));
				var foundThisIter:Boolean = false;
				
				if ( x <= centreX )
				{
					if ( x == centreX )
					{
						if ( y < centreY && ( y > bestY || x > bestX ) )
						{
							foundThisIter = true;
						}
					}
					else if ( x > bestX )
					{
						foundThisIter = true;
					}
					else if ( x == bestX )
					{
						if ( y > bestY )
						{
							foundThisIter = true;
						}
					}
					
					if ( foundThisIter && (x!=currentX || y!=currentY) )
					{
						found = true;
						bestX = x;
						bestY = y;
						bestAvatar = avatar;
					}
				}
			}
			if ( !found )
			{
				return null;
			}
			if ( forceSelect && bestAvatar )
			{
				var editorState:EditorState = FlxG.state as EditorState;
				var avatarEditor:EditorTypeAvatarsBase = editorState.getCurrentEditor(App.getApp()) as EditorTypeAvatarsBase;
				if ( avatarEditor )
				{
					avatarEditor.ForceSelection(bestAvatar);
				}
			}
			return new FlxPoint(bestX, bestY);
		}
		
		// finds the next item to the right or below the current map pos.
		override public function GetNextItemPos( currentX:Number, currentY:Number, forceSelect:Boolean ):FlxPoint
		{
			if ( sprites.members.length == 0 )
			{
				return null;
			}
			
			var centreX:int = int((FlxG.width / 2) - currentX);
			var centreY:int = int((FlxG.height / 2) - currentY);
			
			var bestX:int = int.MAX_VALUE;
			var bestY:int = int.MAX_VALUE;
			var found:Boolean = false;
			var bestAvatar:EditorAvatar = null;
			
			for ( var i:uint = 0; i < sprites.members.length; i++ )
			{
				var avatar:EditorAvatar = sprites.members[i];
				if ( !avatar.CanSelect() )
					continue;
				var x:int = int(avatar.x + ( avatar.width * 0.5 ));
				var y:int = int(avatar.y + ( avatar.height * 0.5 ));
				var foundThisIter:Boolean = false;
				if ( x >= centreX )
				{
					if ( x == centreX )
					{
						if ( y > centreY && ( y < bestY || x < bestX ) )
						{
							foundThisIter = true;
						}
					}
					else if ( x < bestX )
					{
						foundThisIter = true;
					}
					else if ( x == bestX )
					{
						if ( y < bestY )
						{
							foundThisIter = true;
						}
					}
					
					if ( foundThisIter && (x!=currentX || y!=currentY) )
					{
						found = true;
						bestX = x;
						bestY = y;
						bestAvatar = avatar;
					}
				}
			}
			if ( !found )
			{
				return null;
			}
			if ( forceSelect && bestAvatar )
			{
				var editorState:EditorState = FlxG.state as EditorState;
				var avatarEditor:EditorTypeAvatarsBase = editorState.getCurrentEditor(App.getApp()) as EditorTypeAvatarsBase;
				if ( avatarEditor )
				{
					avatarEditor.ForceSelection(bestAvatar);
				}
			}
			return new FlxPoint(bestX, bestY);
		}
		
		override protected function CopyData(sourceLayer:LayerEntry, copyContents:Boolean):LayerEntry
		{
			var sourceAvatarLayer:LayerAvatarBase = sourceLayer as LayerAvatarBase;
			if ( sourceAvatarLayer && copyContents )
			{
				for ( var i:uint = 0; i < sourceAvatarLayer.sprites.members.length; i++ )
				{
					var avatar:EditorAvatar = sourceAvatarLayer.sprites.members[i];
					var newAvatar:EditorAvatar = avatar.CreateClipboardCopy();
					newAvatar.x = avatar.x;
					newAvatar.y = avatar.y;
					newAvatar.scrollFactor.x = avatar.scrollFactor.x;
					newAvatar.scrollFactor.y = avatar.scrollFactor.y;
					newAvatar.layer = this;
					sprites.add(newAvatar,true);
				}
				minx = sourceAvatarLayer.minx;
				miny = sourceAvatarLayer.miny;
				maxx = sourceAvatarLayer.maxx;
				maxy = sourceAvatarLayer.maxy;
			}
			super.CopyData(sourceLayer, copyContents);
			return this;
		}
		
		public function MakeAutoDepthSort( isAuto:Boolean):void
		{
			AutoDepthSort = isAuto;
			if ( isAuto )
			{
				var masterLayer:LayerMap = null;
				if ( AlignedWithMasterLayer && ( masterLayer = parent.FindMasterLayer() ) && masterLayer.map.IsIso() )
				{
					var list:Array = sprites.members;
					var j:int = list.length;
					while (j--)
					{
						var testAvatar:EditorAvatar = list[j] as EditorAvatar;
						
						if ( testAvatar )
						{
							testAvatar.isoTopLeft = new FlxPoint;
							testAvatar.isoBottomRight = new FlxPoint;
							testAvatar.GetIsoCorners(masterLayer.map);
						}
					}
					sprites.members.sort(isoSortHandler);
				}
				else
				{
					sprites.members.sort(simpleSortHandler);
				}
				
				function isoSortHandler(avatar:Avatar, testAvatar:Avatar ):int
				{
					if ( avatarInFrontOf(masterLayer, avatar, testAvatar ) )
						return -1;
					else
						return 1;
				}
				
				function simpleSortHandler(avatar:Avatar,testAvatar:Avatar):int
				{
					var realY1:Number = avatar.bottom - avatar.z;
					var realY2:Number = testAvatar.bottom - testAvatar.z;
					if(realY1 < realY2) // avatar is in front of testAvatar.
						return -1;
					else if(realY1 > realY2)
						return 1;
					return 0;
				}
			}
		}
		
		// Is avatar in front of testAvatar - still not perfect for all cases.
		protected function avatarInFrontOf(masterLayer:LayerMap, avatar:Avatar, testAvatar:Avatar ):Boolean
		{
			if ( avatar.z == testAvatar.z )
			{
				if ( masterLayer.map.tileOffsetX < 0 )
				{
					if ( ( avatar.isoBottomRight.y > testAvatar.isoBottomRight.y && avatar.isoBottomRight.x > testAvatar.isoTopLeft.x ) ||
					( avatar.isoBottomRight.x > testAvatar.isoBottomRight.x && avatar.isoBottomRight.y > testAvatar.isoTopLeft.y ) )
					{
						// Standard diamond iso or skewed to up right.
						// higher y and x = in front.
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetX > 0 )
				{
					if ( ( avatar.isoBottomRight.y > testAvatar.isoBottomRight.y && avatar.isoTopLeft.x < testAvatar.isoBottomRight.x ) ||
					( avatar.isoTopLeft.x < testAvatar.isoTopLeft.x && avatar.isoBottomRight.y > testAvatar.isoTopLeft.y ) )
					{
						// skewed to up left. higher y, lower x = in front.
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetY < 0 )
				{
					if ( ( avatar.isoTopLeft.y < testAvatar.isoTopLeft.y && avatar.isoTopLeft.x < testAvatar.isoBottomRight.x ) ||
					( avatar.isoTopLeft.x < testAvatar.isoTopLeft.x && avatar.isoTopLeft.y < testAvatar.isoBottomRight.y ) )
					{
						// skewed down and to the up-right, lower y and x = in front
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetY > 0 )
				{
					if ( ( avatar.isoTopLeft.y < testAvatar.isoTopLeft.y && avatar.isoBottomRight.x > testAvatar.isoTopLeft.x ) ||
					( avatar.isoBottomRight.x > testAvatar.isoBottomRight.x && avatar.isoTopLeft.y < testAvatar.isoBottomRight.y ) )
					{
						// skewed down and to the up-left, lower y, higher x = in front.
						return true;
					}
				}
				else
				{
					if ( avatar.isoBottomRight.y > testAvatar.isoBottomRight.y )
					{
						// 2d with height.
						// higher y = in front.
						return true;
					}
				}
			}
			else if ( avatar.z < testAvatar.z )
			{
				if ( masterLayer.map.tileOffsetX < 0 )
				{
					if ( avatar.isoBottomRight.y > testAvatar.isoTopLeft.y && avatar.isoBottomRight.x > testAvatar.isoTopLeft.x )
					{
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetX > 0 )
				{
					if ( avatar.isoBottomRight.y > testAvatar.isoTopLeft.y && avatar.isoTopLeft.x < testAvatar.isoBottomRight.x )
					{
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetY < 0 )
				{
					if ( avatar.isoTopLeft.y < testAvatar.isoBottomRight.y && avatar.isoTopLeft.x < testAvatar.isoBottomRight.x )
					{
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetY > 0 )
				{
					if ( avatar.isoTopLeft.y < testAvatar.isoBottomRight.y && avatar.isoBottomRight.x > testAvatar.isoTopLeft.x )
					{
						return true;
					}
				}
				else
				{
					// 2d with height.
					if ( avatar.isoBottomRight.y > testAvatar.isoTopLeft.y )
					{
						return true;
					}
				}
			}
			else if ( avatar.z > testAvatar.z )
			{
				if ( masterLayer.map.tileOffsetX < 0 )
				{
					if ( avatar.isoTopLeft.y >= testAvatar.isoBottomRight.y || avatar.isoTopLeft.x >= testAvatar.isoBottomRight.x )
					{
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetX > 0 )
				{
					if ( avatar.isoTopLeft.y >= testAvatar.isoBottomRight.y || avatar.isoBottomRight.x <= testAvatar.isoTopLeft.x )
					{
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetY < 0 )
				{
					if ( avatar.isoBottomRight.y <= testAvatar.isoTopLeft.y && avatar.isoBottomRight.x <= testAvatar.isoTopLeft.x )
					{
						return true;
					}
				}
				else if ( masterLayer.map.tileOffsetY > 0 )
				{
					if ( avatar.isoBottomRight.y <= testAvatar.isoTopLeft.y && avatar.isoTopLeft.x >= testAvatar.isoBottomRight.x )
					{
						return true;
					}
				}
				else
				{
					// 2d with height.
					if ( avatar.isoTopLeft.y >= testAvatar.isoBottomRight.y )
					{
						return true;
					}
				}
			}
			return false;
		}
		
		public function SortAvatar(avatar:Avatar):void
		{
			var list:Array = sprites.members;
			var currentIndex:int = list.indexOf(avatar);
			if ( currentIndex != -1 )
			{
				var j:int = list.length;
				var inserted:Boolean = false;
				var masterLayer:LayerMap = null;
				if ( AlignedWithMasterLayer && ( masterLayer = parent.FindMasterLayer() ) && masterLayer.map.IsIso() )
				{
					while (j--)
					{
						var testAvatar:EditorAvatar = list[j] as EditorAvatar;
						
						if ( testAvatar )
						{
							testAvatar.isoTopLeft = new FlxPoint;
							testAvatar.isoBottomRight = new FlxPoint;
							testAvatar.GetIsoCorners(masterLayer.map);
						}
					}
					list.splice(currentIndex, 1);
					j = list.length;

					while (j--)
					{
						testAvatar = list[j] as EditorAvatar;
						var insertNow:Boolean = avatarInFrontOf(masterLayer, avatar, testAvatar);
						
						if( insertNow )
						{
							list.splice(j + 1, 0, avatar);
							inserted = true;
							break;
						}
					}
					
					if ( j )
					{
						var i:int = j;
						j++;
						var startIdx:int = i;
						// Now go through all the avatars behind it and see if they should actually be in front.
						// The reason is that these avatars might have not been occluding anything before so their order was unimportant.
						// But now they may be occluded by this even though they're really in front of it.
						while ( (i--) > 0 )
						{
							testAvatar = list[i] as EditorAvatar;
							insertNow = avatarInFrontOf(masterLayer, testAvatar, avatar );
							
							if ( insertNow )
							{
								// Not there yet. Sometimes there can be cases where it can be infront BUT there is already an avatar in front of that.
								// That avatar should be the next one up, so just check this avatar against that.
								if ( i + 1 < j )
								{
									if ( avatarInFrontOf(masterLayer, list[ i + 1 ], testAvatar ) )
										continue;
								}
								list.splice( i, 1 );
								list.splice( j, 0, testAvatar );
							}
						}
					}
				}
				else
				{
					list.splice(currentIndex, 1);
					var realY:Number = avatar.bottom - avatar.z;
					while (j--)
					{
						testAvatar = list[j] as EditorAvatar;
						if ( testAvatar && testAvatar.bottom - testAvatar.z < realY )
						{
							list.splice(j + 1, 0, avatar);
							inserted = true;
							break;
						}
					}
				}
				
				if ( !inserted )
				{
					list.splice(0, 0, avatar);
				}
			}
		}
		
		
	}

}