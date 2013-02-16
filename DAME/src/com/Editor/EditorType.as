package com.Editor 
{
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Operations.HistoryStack;
	import com.Operations.OperationModifySpriteFrames;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import com.Tiles.TileAnim;
	import com.Utils.Global;
	import com.Utils.Hits;
	import com.Utils.Misc;
	import flash.display.BitmapData;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import mx.managers.CursorManager;
	import org.flixel.FlxPoint;
	import org.flixel.FlxG;
	import com.EditorState;
	import com.Utils.DebugDraw;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorType 
	{
		protected var sharedPos:FlxPoint = new FlxPoint;
		
		protected var mousePos:FlxPoint;
		public function get MousePos():FlxPoint { return mousePos; }
		protected var inSelectionMode:Boolean = false;
		protected var allowContinuousPainting:Boolean = false;
		protected var allowRotation:Boolean = false;
		protected var allowScaling:Boolean = false;
		protected var lastHeldMousePos:FlxPoint = new FlxPoint( -1, -1);
		// last tile idx when mouse was held down.
		protected var lastHeldTileIdx:FlxPoint = new FlxPoint( -1, -1 );
		// Selection and moving
		protected var selectionBoxStart:FlxPoint = new FlxPoint();
		protected var selectionBoxEnd:FlxPoint = new FlxPoint();
		protected var selectionBoxTopRight:FlxPoint = new FlxPoint();	// For isometric
		protected var isSizingSelectionBox:Boolean = false;
		protected var isMovingItems:Boolean = false;
		protected var storedMoveAnchorPos:FlxPoint = new FlxPoint( 0, 0 );
		protected var selectionEnabled:Boolean = false;
		protected var hasLeftMouseDown:Boolean = false;
		protected var hasRightMouseDown:Boolean = false;
		protected var isRotating:Boolean = false;
		protected var isScaling:Boolean = false;
		protected var isDoingSomething:Boolean = false; // yay! Just to prevent it reselecting after we get a selection.
		protected var constrainXAxis:Boolean = false;
		protected var constrainYAxis:Boolean = false;
		private var axisConstraints:FlxPoint = new FlxPoint(0, 0);
		protected var mouseScreenPos:FlxPoint = new FlxPoint(0, 0);
		private var screenAxisConstraints:FlxPoint = new FlxPoint(0, 0);
		
		protected var contextMenu:NativeMenu = null;
		
		protected var cursorId:int = -1;
		protected var currentCursorClass:Class = null;
		
		public static var HighlightCurrentTile:Boolean = false;
		private static var _inAttachMode:Boolean = false;
		public var TileListHasBlankFirstTile:Boolean = true;

		public static function set InAttachMode(value:Boolean):void
		{
			if ( !_inAttachMode && value )
			{
				InSpriteTrailMode = false;
				_avatarToLinkFrom = null;
				PromptManager.manager.ShowPrompt("Move to the path layer and select the path you want to attach this sprite to.");
			}
			else if( _inAttachMode && !value )
			{
				PromptManager.manager.HidePrompt();
			}
			_inAttachMode = value;
		}
		public static function get InAttachMode():Boolean { return _inAttachMode; }
		
		private static var _inSpriteTrailMode:Boolean = false;
		public static function set InSpriteTrailMode(value:Boolean):void
		{
			if ( !_inSpriteTrailMode && value )
			{
				InAttachMode = false;
				_avatarToLinkFrom = null;
				PromptManager.manager.ShowPrompt("Move to the sprite layer you want the sprite trail to be added to and click the left mouse down to confirm.");
			}
			else if( _inSpriteTrailMode && !value )
			{
				PromptManager.manager.HidePrompt();
			}
			_inSpriteTrailMode = value;
		}
		public static function get InSpriteTrailMode():Boolean { return _inSpriteTrailMode; }
		
		public static var IsSpawningInstance:Boolean = false;
		public static var AvatarToAttach:EditorAvatar = null;
		
		static protected var _avatarToLinkFrom:EditorAvatar = null;
		public static function set AvatarToLinkFrom(avatar:EditorAvatar):void
		{
			if ( !_avatarToLinkFrom && avatar )
			{
				InAttachMode = false;
				InSpriteTrailMode = false;
				PromptManager.manager.ShowPrompt("Select the target object and a link will be generated.\nThis can be any type of object.");
			}
			else if( _avatarToLinkFrom && !avatar )
			{
				PromptManager.manager.HidePrompt();
			}
			_avatarToLinkFrom = avatar;
		}
		public static function get AvatarToLinkFrom():EditorAvatar { return _avatarToLinkFrom; }
		
		protected static const SELECTED_NONE:uint = 0;
		protected static const SELECTED_ITEM:uint = 1;
		protected static const SELECTED_AND_REMOVED:uint = 2;
		protected static const SELECTED_ITEM_AND_SET_STATE:uint = 3;	// selected but chose to handle state setting.
		
		protected var selectionAlignedWithMap:Boolean = true;
		
		function EditorType( editor:EditorState ):void
		{
		}
			
		public function Update( isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			var app:App = App.getApp();
			var layer:LayerEntry = app.CurrentLayer;
			
			hasLeftMouseDown = leftMouseDown;
			hasRightMouseDown = rightMouseDown;
			
			if ( layer == null || !isActive)
			{
				HideDisplay();
				return;
			}
			
			var allowConstraints:Boolean = !isRotating && !isScaling;
			
			// Handle axis constraints...
			
			if ( constrainXAxis && allowConstraints)
			{
				mouseScreenPos.x = screenAxisConstraints.x;
			}
			else
			{
				mouseScreenPos.x = FlxG.mouse.screenX;
			}
			if ( constrainYAxis && allowConstraints )
			{
				mouseScreenPos.y = screenAxisConstraints.y;
			}
			else
			{
				mouseScreenPos.y = FlxG.mouse.screenY;
			}
			
			
			mousePos = EditorState.getMapXYFromScreenXY(mouseScreenPos.x, mouseScreenPos.y, layer.xScroll, layer.yScroll );
			mousePos.x *= FlxG.extraZoom;
			mousePos.y *= FlxG.extraZoom;
			mouseScreenPos.x *= FlxG.extraZoom;
			mouseScreenPos.y *= FlxG.extraZoom;
			
			//var scaledMousePos:FlxPoint = new FlxPoint(mousePos.x * FlxG.extraZoom, mousePos.y * FlxG.extraZoom);
			if ( layer.Locked() )
			{
				HideDisplay();
				return;
			}
			
			if ( allowConstraints )
			{
				// Allow use of z as it's closer to x on the keyboard!!!
				if ( FlxG.keys.pressed( "Y" ) )//|| FlxG.keys.pressed( "Z" ))
				{
					if ( !constrainXAxis )
					{
						constrainXAxis = true;
						axisConstraints.x = mousePos.x;
						screenAxisConstraints.x = FlxG.mouse.screenX;
					}
				}
				else
				{
					constrainXAxis = false;
				}
				if ( FlxG.keys.pressed( "X" ) )
				{
					if ( !constrainYAxis )
					{
						constrainYAxis = true;
						axisConstraints.y = mousePos.y;
						screenAxisConstraints.y = FlxG.mouse.screenY;
					}
				}
				else
				{
					constrainYAxis = false;
				}
				
				if ( constrainXAxis )
				{
					mousePos.x = axisConstraints.x;
				}
				else if ( constrainYAxis )
				{
					mousePos.y = axisConstraints.y;
				}
			}
			
			inSelectionMode = isSelecting;
			
			UpdateDisplay( layer );
			
			if( isMovingItems || isRotating || isScaling )
			{
				var screenOffset:FlxPoint = new FlxPoint( mouseScreenPos.x - storedMoveAnchorPos.x, mouseScreenPos.y - storedMoveAnchorPos.y );
				if ( screenOffset.x != 0 || screenOffset.y != 0 )
				{
					screenOffset.multiplyBy(1 / FlxG.extraZoom);
					if ( isMovingItems )
					{
						MoveSelection( screenOffset );
					}
					else if ( isRotating )
					{
						// Allow each editor to decide how to handle rotation and the angles to rotate by (may be per object or per group etc).
						RotateSelection( screenOffset );
					}
					else if ( isScaling )
					{
						ScaleSelection( screenOffset );
					}
				}
			}
			else if ( (inSelectionMode && selectionEnabled ) || InAttachMode || InSpriteTrailMode || IsSpawningInstance)
			{
				if ( FlxG.keys.justPressed( "DELETE" ) )
				{
					DeleteSelection( );
				}
				else if ( leftMouseDown )
				{
					UpdateSelectionBox( layer );
					
					// Sets this here rather than on button down so it knows that it constitues a drag
					if ( selectionBoxEnd.x - selectionBoxStart.x != 0 || selectionBoxEnd.y - selectionBoxStart.y!= 0 )
					{
						isSizingSelectionBox = true;
					}
				}
			}
			else if (!inSelectionMode && !InAttachMode && !InSpriteTrailMode && !IsSpawningInstance)
			{
				if ( FlxG.keys.justPressed( "DELETE" ) )
				{
					DeleteSelection( );
				}
				else if ( allowContinuousPainting )
				{
					if ( leftMouseDown )
					{
						Paint( layer );
					}
					else if ( rightMouseDown )
					{
						PaintSecondary( layer );
					}
				}
			}
			
			if ( leftMouseDown || rightMouseDown )
			{
				lastHeldMousePos.copyFrom( mousePos );
				lastHeldTileIdx.copyFrom( currentTile );
			}
			else
			{
				lastHeldMousePos.create_from_points( -1, -1);
				lastHeldTileIdx.create_from_points( -1, -1 );
			}
		}
		
		private function UpdateSelectionBox( layer:LayerEntry ):void
		{
			selectionBoxEnd.x = mousePos.x;
			selectionBoxEnd.y = mousePos.y;
			if ( layer.map )
			{
				if ( selectionAlignedWithMap && ( layer.map.xStagger || layer.map.tileOffsetX || layer.map.tileOffsetY ) )
				{
					var tileOffsetX:int = layer.map.xStagger ? -Math.abs(layer.map.xStagger) : layer.map.tileOffsetX;
					var tileOffsetY:int = layer.map.xStagger ? layer.map.tileSpacingY : layer.map.tileOffsetY;
					var tileSpacingX:int = layer.map.xStagger ? layer.map.tileSpacingX / 2 : layer.map.tileSpacingX;
					Hits.LineRayIntersection( selectionBoxStart.x, selectionBoxStart.y, selectionBoxStart.x + tileSpacingX, selectionBoxStart.y + tileOffsetY,
											selectionBoxEnd.x, selectionBoxEnd.y, selectionBoxEnd.x - tileOffsetX, selectionBoxEnd.y - layer.map.tileSpacingY,
											selectionBoxTopRight );

					var botLeftX:int = selectionBoxStart.x + ( selectionBoxEnd.x - selectionBoxTopRight.x );
					var botLeftY:int = selectionBoxStart.y + ( selectionBoxEnd.y - selectionBoxTopRight.y );
					
					DebugDraw.DrawQuad( selectionBoxStart.x, selectionBoxStart.y, selectionBoxTopRight.x, selectionBoxTopRight.y,
										selectionBoxEnd.x, selectionBoxEnd.y, botLeftX, botLeftY, layer.map.scrollFactor, 0xffffffff );
					return;
				}
			}
			DebugDraw.DrawBox( selectionBoxStart.x, selectionBoxStart.y, selectionBoxEnd.x, selectionBoxEnd.y, 0, new FlxPoint(layer.xScroll,layer.yScroll), true, 0xffffffff, false );
		}
		
		protected function ConvertIsoPosToStagger( map:FlxTilemapExt, pos:FlxPoint, result:FlxPoint ):void
		{
			var evenRow:int = map.xStagger > 0 ? 0 : 1;
			
			var numEvenRows:int = Math.floor( pos.x / 2);
			result.x = numEvenRows;
			result.y = pos.x;
			
			numEvenRows = ( result.y % 2 == evenRow ) ? Math.ceil( pos.y / 2 ) : Math.floor( pos.y / 2 ) ;
			result.x -= numEvenRows;
			result.y += pos.y;
		}
		
		protected function ConvertStaggerPosToIso( map:FlxTilemapExt, start:FlxPoint, end:FlxPoint, corner:FlxPoint, bottomRightUnits:FlxPoint, topLeftUnitsOut:FlxPoint, topLeftUnitsIso:FlxPoint, bottomRightUnitsIso:FlxPoint):void
		{
			//if ( layerEntry.map.xStagger )
			{
				
				// Convert from staggered units to iso-aligned units.
				// All translations of (1,0) equate to (1,-1) in iso alignment.
				var topLeftIso:FlxPoint = new FlxPoint( topLeftUnitsOut.x, -topLeftUnitsOut.x );
				var botRightIso:FlxPoint = new FlxPoint( bottomRightUnits.x, -bottomRightUnits.x );
				// Vertical (0,1) = (0,1) if moving from an even row, or (1,0) if moving from an odd row.
				// but swap even add with odd if xStagger < 0.
				// Round up for number of odd rows, round down for number of even rows.
				if ( map.xStagger > 0 )
				{
					topLeftIso.x += Math.ceil( topLeftUnitsOut.y / 2);
					topLeftIso.y += Math.floor( topLeftUnitsOut.y / 2 );
					botRightIso.x += Math.ceil( bottomRightUnits.y / 2);
					botRightIso.y += Math.floor( bottomRightUnits.y / 2 );
				}
				else if ( map.xStagger < 0 )
				{
					topLeftIso.x += Math.floor( topLeftUnitsOut.y / 2);
					topLeftIso.y += Math.ceil( topLeftUnitsOut.y / 2 );
					botRightIso.x += Math.floor( bottomRightUnits.y / 2);
					botRightIso.y += Math.ceil( bottomRightUnits.y / 2 );
				}
				
				if ( topLeftIso.x <= botRightIso.x )
				{
					topLeftUnitsIso.x = topLeftIso.x;
					bottomRightUnitsIso.x = botRightIso.x;
					if ( topLeftIso.y <= botRightIso.y )
					{
						topLeftUnitsIso.y = topLeftIso.y;
						bottomRightUnitsIso.y = botRightIso.y;
						// topLeftUnitsOut is the top top left already.
					}
					else
					{
						topLeftUnitsIso.y = botRightIso.y;
						bottomRightUnitsIso.y = topLeftIso.y;
						ConvertIsoPosToStagger( map, topLeftUnitsIso, topLeftUnitsOut );
					}
				}
				else
				{
					topLeftUnitsIso.x = botRightIso.x;
					bottomRightUnitsIso.x = topLeftIso.x;
					if ( topLeftIso.y < botRightIso.y )
					{
						topLeftUnitsIso.y = topLeftIso.y;
						bottomRightUnitsIso.y = botRightIso.y;
						ConvertIsoPosToStagger( map, topLeftUnitsIso, topLeftUnitsOut );
					}
					else
					{
						topLeftUnitsIso.y = botRightIso.y;
						bottomRightUnitsIso.y = topLeftIso.y;
						topLeftUnitsOut.copyFrom(bottomRightUnits);
					}
				}
			}
		}
		
		//{ region Virtuals
		
		public function CutData():void
		{
			CopyData();
			DeleteSelection();
		}
		
		public function CopyData():void { }
		
		public function PasteData():void { }
		
		public function SelectAll():void { }
		
		public function SelectNone(): void { }
		
		public function DeselectInvisible(): void { }
		
		public function GetCurrentObjectProperties():ArrayCollection { return null; }
		
		protected function HideDisplay():void {}
		
		protected function UpdateDisplay( layer:LayerEntry ):void {}
		
		protected function Paint( layer:LayerEntry ):void {}
		
		protected function PaintSecondary( layer:LayerEntry ):void { }
		
		// Called when the user begins to paint (or erase)
		protected function BeginPainting( layer:LayerEntry, leftMouse:Boolean ):void { }
		
		// Called when the user has released the mouse button while painting.
		protected function EndPainting( layer:LayerEntry ):void { }
		
		protected function SelectUnderCursor( layer:LayerEntry ):Boolean { return false; }
		
		protected function SelectInsideBox( layer:LayerEntry, boxTopLeft:FlxPoint, boxBottomRight:FlxPoint ):Boolean { return false; }
		
		protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint { return SELECTED_NONE; }
		
		// Called once before and calls made to Move/Rotate/Scale
		protected function BeginTransformation():void { }
		
		// Called once after all calls to Move/Rotate/Scale
		protected function EndTransformation():void { }
		
		protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void { }
		
		protected function RotateSelection( screenOffsetFromOriginalPos:FlxPoint ):void { }
		
		protected function ScaleSelection( screenOffsetFromOriginalPos:FlxPoint ):void { }
		
		protected function ConfirmMovement( ): void { }
		
		protected function DeleteSelection( ):void { }
		
		protected function DecideContextMenuActivation( ):void { }
		
		public function GetZText():String { return ""; }
		
		public var currentTile:FlxPoint = new FlxPoint( -1, -1);
		protected var currentTileWorldPos:FlxPoint = new FlxPoint;
		protected var currentTileValid:Boolean = false;
		
		protected function UpdateCurrentTile( map:FlxTilemapExt, worldx:Number, worldy:Number):void
		{
			currentTileValid = GetTileInfo(map, worldx, worldy, currentTile, currentTileWorldPos );
		}
		
		// Returns true if the coordinates are over a tile.
		protected function GetTileInfo( map:FlxTilemapExt, worldx:Number, worldy:Number, unitTilePos:FlxPoint, tilePos:FlxPoint):Boolean
		{
			if ( map == null )
			{
				return false;
			}
			return map.GetTileInfo( worldx, worldy, unitTilePos, tilePos );
		}
		
		protected function DrawBoxAroundTile( map:FlxTilemapExt, tileWorldX:int, tileWorldY:int, colour:uint, yOffset:int, useInvert:Boolean = false, heightColour:uint = 0x44ffffff ):void
		{
			if ( map == null )
			{
				return;
			}
			
			tileWorldX = tileWorldX >> FlxG.zoomBitShifter;
			tileWorldY = tileWorldY >> FlxG.zoomBitShifter;
			
			tileWorldY -= (yOffset >> FlxG.zoomBitShifter);
			
			var top:int;
			
			if ( useInvert )
			{
				var cObj:Object = Misc.HEXtoARGB(colour);
				cObj.red = 0xff - cObj.red;
				cObj.green = 0xff - cObj.green;
				cObj.blue = 0xff - cObj.blue;
				var invertColour:uint = Misc.ARGBtoHEX(cObj);
			}
			
			var tileHeight:int = map.tileHeight >> FlxG.zoomBitShifter;
			var tileSpacingX:int = map.tileSpacingX >> FlxG.zoomBitShifter;
			var tileSpacingY:int = map.tileSpacingY >> FlxG.zoomBitShifter;
			
			// Check standard or skewed isometric tilemaps.
			if ( map.tileOffsetX || map.tileOffsetY )
			{
				var tileOffsetX:int = map.tileOffsetX >> FlxG.zoomBitShifter;
				var tileOffsetY:int = map.tileOffsetY >> FlxG.zoomBitShifter;
				var bottom:int = ( tileWorldY + tileHeight );
				
				var topLeftX:int = tileWorldX;
				var topLeftY:int = bottom - tileSpacingY;
				var topRightX:int = tileWorldX + tileSpacingX;
				var topRightY:int = bottom - tileSpacingY;
				var botLeftX:int = tileWorldX;
				var botLeftY:int = bottom;
				var botRightX:int = tileWorldX + tileSpacingX;
				var botRightY:int = bottom;
				
				if ( tileOffsetX < 0 ) // Slant to the up and right.
				{
					topLeftX -= tileOffsetX;
					topRightX -= tileOffsetX;
				}
				else if ( tileOffsetX > 0 ) // Slant to the up and left.
				{
					botLeftX += tileOffsetX;
					botRightX += tileOffsetX;
				}
				
				if ( tileOffsetY < 0 )	// Tile going up and to the right.
				{
					topRightY += tileOffsetY;
					botRightY += tileOffsetY;
				}
				else if ( tileOffsetY > 0 ) // Tile going down and to the right.
				{
					topLeftY -= tileOffsetY;
					botLeftY -= tileOffsetY;
				}
				
				DebugDraw.DrawQuad( topLeftX, topLeftY, topRightX, topRightY, botRightX, botRightY, botLeftX, botLeftY, map.scrollFactor, colour, false, 0x00000000, false, false, false);
				if ( useInvert )
				{
					DebugDraw.DrawQuad( topLeftX-1, topLeftY-1, topRightX-1, topRightY-1, botRightX-1, botRightY-1, botLeftX-1, botLeftY-1, map.scrollFactor, invertColour, false, 0x00000000, false, false, false);
				}
				if ( Global.DrawCurrentTileWithHeight )
				{
					var topmost:int = Math.min(topLeftY, topRightY, botLeftY);
					if ( topmost > tileWorldY )
					{
						if ( topLeftX < botLeftX )
						{
							var leftX:int = topLeftX;
							var leftY:int = topLeftY;
						}
						else
						{
							leftX = botLeftX;
							leftY = botLeftY;
						}
						if ( topRightX > botRightX )
						{
							var rightX:int = topRightX;
							var rightY:int = topRightY;
						}
						else
						{
							rightX = botRightX;
							rightY = botRightY;
						}
							
						DebugDraw.DrawLine( leftX, leftY, tileWorldX, tileWorldY, map.scrollFactor, false, heightColour, true, false );
						DebugDraw.DrawLine( leftX, tileWorldY, rightX, tileWorldY, map.scrollFactor, false, heightColour, true, false );
						DebugDraw.DrawLine( rightX, rightY, rightX, tileWorldY, map.scrollFactor, false, heightColour, true, false );
					}
				}
			}
			else if ( map.xStagger )
			{
				var realHeight:int = tileSpacingY * 2;
				
				bottom = ( tileWorldY + tileHeight );
				
				var halfWidth:int = tileSpacingX * 0.5;
						
				topLeftX = tileWorldX + halfWidth;
				topLeftY = bottom - realHeight;
				topRightX = tileWorldX + tileSpacingX;
				topRightY = bottom - tileSpacingY;
				botLeftX = tileWorldX;
				botLeftY = bottom - tileSpacingY;
				botRightX = tileWorldX + halfWidth;
				botRightY = bottom;
				
				DebugDraw.DrawQuad( topLeftX, topLeftY - 1, topRightX + 1, topRightY, botRightX, botRightY + 1, botLeftX - 1, botLeftY, map.scrollFactor, colour, false, 0x00000000, false, false, false);
				if ( useInvert )
				{
					DebugDraw.DrawQuad( topLeftX-1, topLeftY - 2, topRightX, topRightY-1, botRightX-1, botRightY, botLeftX - 2, botLeftY-1, map.scrollFactor, invertColour, false, 0x00000000, false, false, false);
				
				}
				if ( Global.DrawCurrentTileWithHeight && realHeight < tileHeight )
				{
					top = bottom - tileHeight;
					DebugDraw.DrawLine( botLeftX - 1, botLeftY, tileWorldX, top, map.scrollFactor, false, heightColour, true, false );
					DebugDraw.DrawLine( botLeftX - 1, top, topRightX + 1, top, map.scrollFactor, false, heightColour, true, false );
					DebugDraw.DrawLine( topRightX + 1, topRightY, topRightX + 1, top, map.scrollFactor, false, heightColour, true, false );
				}
			}
			else
			{
				bottom = tileWorldY + tileHeight;
				top = bottom - tileSpacingY;
				var right:int = tileWorldX + (map.tileWidth >> FlxG.zoomBitShifter) + 1;
				DebugDraw.DrawBox( tileWorldX - 1, top - 1, right, bottom + 1, 0, map.scrollFactor, false, colour, true, false, false, false );
				if ( useInvert )
				{
					DebugDraw.DrawBox( tileWorldX - 2, top - 2, right + 1, bottom + 2, 0, map.scrollFactor, false, invertColour, true, false, false, false );
				}
				if ( Global.DrawCurrentTileWithHeight && tileSpacingY < tileHeight )
				{
					DebugDraw.DrawLine( tileWorldX - 1, top, tileWorldX - 1, tileWorldY, map.scrollFactor, false, heightColour, true, false );
					DebugDraw.DrawLine( tileWorldX - 1, tileWorldY, right, tileWorldY, map.scrollFactor, false, heightColour, true, false );
					DebugDraw.DrawLine( right, top, right, tileWorldY, map.scrollFactor, false, heightColour, true, false );
				}
			}
		}
		
		protected function addNewContextMenuItem( menu:NativeMenu, text:String, handler:Function ):NativeMenuItem
		{
			var item:NativeMenuItem = new NativeMenuItem(text);
			menu.addItem(item);
			item.addEventListener(Event.SELECT, handler);
			return item;
		}
		
		protected function centerMousePosToScreen( layer:LayerEntry ):void
		{
			var changedMouse:Boolean = true;
			// If we select paste from the menu instead of shortcut then need to ensure it is pasted in the center of the screen.
			if ( mouseScreenPos.x < 0 || mouseScreenPos.x > FlxG.width)
			{
				mouseScreenPos.x = FlxG.width / 2;
				changedMouse = true;
			}
			if ( mouseScreenPos.y < 0 || mouseScreenPos.y > FlxG.height)
			{
				mouseScreenPos.y = FlxG.height / 2;
				changedMouse = true;
			}
			
			if ( changedMouse )
			{
				mousePos = EditorState.getMapXYFromScreenXY(mouseScreenPos.x, mouseScreenPos.y, layer.xScroll, layer.yScroll );
			}
		}
		
		
		//} endregion
		
		//{ region Mouse Handlers
		
		public function OnLeftMouseDown():void
		{
			var app:App = App.getApp();
			var layer:LayerEntry = app.CurrentLayer;
			
			if ( !(this is EditorTypePaths ) )
			{
				InAttachMode = false;
				IsSpawningInstance = false;
			}
			if ( !(this is EditorTypeSprites ) )
			{
				InSpriteTrailMode = false;
			}
			if ( !(this is EditorTypeAvatarsBase) )
			{
				AvatarToLinkFrom = null;
			}
			
			if ( layer == null || layer.Locked() )
			{
				return;
			}
			
			var selectionResult:uint = SELECTED_NONE;			
			
			// Don't need to be inSelectionMode to move a selection.
			// Moving selections takes priority over painting.
			if ( selectionEnabled || InAttachMode || InSpriteTrailMode || IsSpawningInstance)
			{
				selectionResult = SelectWithinSelection( layer, true );
				if ( selectionResult == SELECTED_ITEM )
				{
					if ( allowScaling && FlxG.keys.pressed( "ALT" ) )
					{
						isScaling = true;
					}
					else if ( allowRotation && FlxG.keys.pressed( "R" ) )
					{
						isRotating = true;
					}
					else
					{
						isMovingItems = true;
					}
				}
				if ( isScaling || isRotating || isMovingItems )
				{
					BeginTransformation();
				}
				storedMoveAnchorPos.create_from_points(mouseScreenPos.x, mouseScreenPos.y);
				selectionBoxStart.x = selectionBoxEnd.x = mousePos.x;
				selectionBoxStart.y = selectionBoxEnd.y = mousePos.y;
			}
			
			// When removing items this disallows any other operations from occuring.
			if( !isMovingItems && !isRotating && !isScaling && !isDoingSomething && !inSelectionMode && !InAttachMode && !InSpriteTrailMode && !IsSpawningInstance && selectionResult == SELECTED_NONE)
			{
				BeginPainting( layer, true );
				if ( !allowContinuousPainting )
				{
					Paint( layer );
				}
			}
		}
		
		public function OnLeftMouseUp():void
		{
			if ( isMovingItems || isRotating || isScaling || isDoingSomething )
			{
				ConfirmMovement();
				EndTransformation();
				isRotating = false;
				isScaling = false;
				isDoingSomething = false;
				isMovingItems = false;
				InAttachMode = false;
				InSpriteTrailMode = false;
				IsSpawningInstance = false;
				AvatarToLinkFrom = null;
				return;
			}
			var app:App = App.getApp();
			if ( !app.CurrentLayer || app.CurrentLayer.Locked())
			{
				InAttachMode = false;
				InSpriteTrailMode = false;
				IsSpawningInstance = false;
				AvatarToLinkFrom = null;
				return;
			}
			
			if ( isSizingSelectionBox )
			{
				isSizingSelectionBox = false;
				
				
				SelectInsideBox( app.CurrentLayer, null, null );// boxTopLeft, boxBottomRight );
			}
			else if (inSelectionMode )
			{
				SelectUnderCursor( app.CurrentLayer );
			}
			else
			{
				EndPainting( app.CurrentLayer );
			}
			InAttachMode = false;
			InSpriteTrailMode = false;
			IsSpawningInstance = false;
			AvatarToLinkFrom = null;
		}
		
		public function OnRightMouseDown():void
		{
			var app:App = App.getApp();
			if ( !app.CurrentLayer || app.CurrentLayer.Locked() )
			{
				return;
			}
			if (!inSelectionMode )
			{
				BeginPainting( app.CurrentLayer, false );
			}
		}
		
		public function OnRightMouseUp():void
		{
			var layer:LayerEntry = App.getApp().CurrentLayer;
			if ( !layer || layer.Locked() )
			{
				return;
			}
			
			if ( contextMenu != null )
			{
				DecideContextMenuActivation();
			}
			
			if ( !inSelectionMode )
			{
				EndPainting( layer );
			}
		}
		
		//} endregion
		
		protected function RemoveCurrentCursor():void
		{
			if (cursorId != -1 )
			{
				currentCursorClass = null;
				CursorManager.removeCursor(cursorId);
				cursorId = -1;
			}
		}
		
		protected function SetCurrentCursor( newClass:Class, xpos:int, ypos:int ):void
		{
			if ( newClass != currentCursorClass )
			{
				currentCursorClass = newClass;
				cursorId = CursorManager.setCursor(currentCursorClass, 2, xpos, ypos);
			}
		}
		
		static public function updateTileListForSprite(sprite:SpriteEntry, insertBlankZero:Boolean, selectionChangedFunction:Function, modifyCallback:Function):Boolean
		{
			var app:App = App.getApp();
			app.myTileList.clearTiles();
			if ( sprite && !sprite.CanEditFrames )
			{
				sprite.tilePreviewIndex = -1;
				return false;
			}
			var updateSelectTile:Boolean = true;
			if ( sprite && app.myTileList.CustomData == sprite )
			{
				updateSelectTile = false;
			}
			if ( !sprite || !sprite.IsTileSprite )
			{
				app.myTileList.CustomData = sprite;
			}
			if ( sprite && !sprite.IsTileSprite )
			{
				var state:EditorState = FlxG.state as EditorState;
				state.tileListIsSprite = true;
				var wid:int = sprite.previewBitmap.width;
				var ht:int = sprite.previewBitmap.height;
				var numRows:uint = Math.floor( sprite.bitmap.height / ht );
				var numColumns:uint = Math.floor( sprite.bitmap.width / wid );
				numRows = Math.max(numRows, 1);
				numColumns = Math.max(numColumns, 1 );
				var maxIndex:uint = ( numColumns * numRows );
				maxIndex = Math.min(sprite.numFrames, maxIndex);
				
				var flashPoint:Point = new Point(0, 0);
				
				app.myTileList.TileWidth = wid;
				app.myTileList.TileHeight = ht;
				app.myTileList.modifyTilesCallback = modifyCallback;
				app.myTileList.SetEraseTileIdx( -1);
				app.myTileList.HasEmptyFirstTile = insertBlankZero;
				
				var tileOffset:int = insertBlankZero ? 1 : 0;
				if ( insertBlankZero )
				{
					app.myTileList.pushTile(new BitmapData(1, 1, true, 0x00000000), 0);	// blank tile - use default.
				}
				try
				{
				
					for ( var i:uint = 0; i < maxIndex; i++ )
					{
						var currentRow:uint = i / numColumns;
						var currentColumn:uint = i % numColumns;
						
						var sourceRect:Rectangle = new Rectangle( currentColumn * wid, currentRow * ht, wid, ht);
						var tile:BitmapData = new BitmapData(wid, ht, true, 0xffffff);
						
						tile.copyPixels( sprite.bitmap.bitmapData, sourceRect, flashPoint );
						app.myTileList.pushTile(tile, i + tileOffset);
						
					}
					app.myTileList.SelectionChanged = selectionChangedFunction;
				}
				catch (error:Error)
				{
					// Sometimes gets invalid bitmapdata error if we load a new project with the tile list selected for sprites.
				}
				if( updateSelectTile )
				{
					app.myTileList.selectedIndex = sprite.tilePreviewIndex + tileOffset;
				}
				return true;
			}
			return false;
		}
		
		// The callback from the tile list menu. Similar to ModifyTiles in EditorState.
		public function ModifySprites( addNew:Boolean, copy:Boolean, del:Boolean, before:Boolean, into:Boolean, swap:Boolean, sourceTileId:int = -1, highlightTile:int = -1 ):void
		{
			var spriteEntry:SpriteEntry = GetSelectedSpriteEntry();
			if ( !spriteEntry )
			{
				return;
			}
			var app:App = App.getApp();
			
			var tileId:int = sourceTileId != -1 ? sourceTileId : app.myTileList.GetMetaDataAtIndex(app.myTileList.clickIndex) as int;
			var changeGraphic:Boolean = true;
			var highlightTileId:int = -1;
			
			if ( (swap || (copy && into ) ) && highlightTileId == tileId )
			{
				// Glitches out if we copy into the same tile.
				return;
			}
				
			if ( addNew || copy || swap )
			{
				var highlightIndex:int = app.myTileList.selectedIndex;
				if ( before )
				{
					highlightIndex--;
				}
				highlightTileId = app.myTileList.GetMetaDataAtIndex( highlightIndex ) as int;
			}
			else
			{
				highlightTileId = tileId;
			}
			
			if ( highlightTile != -1 )
			{
				highlightTileId = highlightIndex = highlightTile;
			}
			
			if ( TileListHasBlankFirstTile )
			{
				if( tileId != -1 )
					tileId--;
				if( sourceTileId != -1 )
					sourceTileId--;
				if ( highlightIndex != -1 )
					highlightIndex--;
			}
			
			HistoryStack.BeginOperation(new OperationModifySpriteFrames( spriteEntry ) );
			
			
			var tileWidth:uint = spriteEntry.previewBitmap.bitmapData.width;
			var tileHeight:uint = spriteEntry.previewBitmap.bitmapData.height;
			var tileCount:uint = spriteEntry.numFrames;
		
			var addedTile:Boolean = false;
			var removedTile:Boolean = false;
			
			if ( swap )
			{
				if ( tileId != -1 && highlightIndex != -1 )
				{
					var bmp:BitmapData = Misc.GetTileBitmap( spriteEntry.bitmap.bitmapData, tileId, tileWidth, tileHeight );
					var otherBmp:BitmapData = Misc.GetTileBitmap( spriteEntry.bitmap.bitmapData, highlightIndex, tileWidth, tileHeight );
					Misc.SetTileBitmap( spriteEntry.bitmap.bitmapData, highlightIndex, tileWidth, tileHeight, bmp);
					Misc.SetTileBitmap( spriteEntry.bitmap.bitmapData, tileId, tileWidth, tileHeight, otherBmp);
				}
			}
			else if ( addNew || copy )
			{
				if ( into )
				{
					if ( tileId != -1 )
					{
						bmp = Misc.GetTileBitmap( spriteEntry.bitmap.bitmapData, tileId, tileWidth, tileHeight );
						Misc.SetTileBitmap( spriteEntry.bitmap.bitmapData, highlightIndex, tileWidth, tileHeight, bmp);
					}
				}
				else
				{
					addedTile = true;
					spriteEntry.bitmap.bitmapData = Misc.insertNewTile( spriteEntry.bitmap.bitmapData, ( copy ? tileId : -1 ), highlightIndex, tileWidth, tileHeight, tileCount );
					tileCount++;
				}
			}
			else if ( del )
			{
				removedTile = true;
				spriteEntry.bitmap.bitmapData = Misc.removeTileAndShuntDown( spriteEntry.bitmap.bitmapData, tileId, tileWidth, tileHeight, tileCount);
				tileCount = Math.max(tileCount - 1, 1);
			}
			
			if ( tileId != -1 && ( addedTile || removedTile ) )
			{
				EditorState.CallFuncForAllSpriteEntries(app.spriteData[0], updateSprites);
			}
			
			
			function updateSprites( testSpriteEntry:SpriteEntry, ... arguments ):void
			{
				// If it's the same image file but different sprite dims then it's unclear what to do.
				if ( Misc.FilesMatch(spriteEntry.imageFile,testSpriteEntry.imageFile) && 
					spriteEntry.previewBitmap.width == testSpriteEntry.previewBitmap.width &&
					spriteEntry.previewBitmap.height == testSpriteEntry.previewBitmap.height )
				{
					if ( addedTile )
					{
						for each( var anim:TileAnim in spriteEntry.anims )
						{
							var i:int = anim.tiles.length;
							while ( i-- )
							{
								if ( anim.tiles[i] > highlightIndex )
								{
									anim.tiles[i]++;
								}
							}
						}
						var newShapes:Dictionary = new Dictionary;
						for (var key:Object in spriteEntry.shapes.frames )
						{
							var frameNum:int = key as int;
							if ( frameNum > highlightIndex )
							{
								newShapes[ frameNum + 1 ] = spriteEntry.shapes.frames[key];
							}
							else
							{
								newShapes[ frameNum ] = spriteEntry.shapes.frames[key];
							}
						}
						spriteEntry.shapes.frames = newShapes;
					}
					else if ( removedTile )
					{
						for each( anim in spriteEntry.anims )
						{
							i = anim.tiles.length;
							while ( i-- )
							{
								if ( anim.tiles[i] > tileId )
								{
									anim.tiles[i]--;
								}
								else if ( anim.tiles[i] == tileId )
								{
									anim.tiles.splice(i, 1);
								}
							}
						}
						newShapes = new Dictionary;
						for (key in spriteEntry.shapes.frames )
						{
							frameNum = key as int;
							if ( frameNum > tileId )
							{
								newShapes[ frameNum - 1 ] = spriteEntry.shapes.frames[key];
							}
							else if( frameNum < tileId )
							{
								newShapes[ frameNum ] = spriteEntry.shapes.frames[key];
							}
						}
						spriteEntry.shapes.frames = newShapes;
					}
					testSpriteEntry.numFrames = tileCount;
				}
			}
			ImageBank.MarkImageAsChanged( spriteEntry.imageFile, spriteEntry.bitmap );
			
			var currentState:EditorState = FlxG.state as EditorState;
			if ( app.layerGroups.length )
			{
				currentState.CallFunctionOnGroupForSprite( app.layerGroups[0], spriteEntry, updateSpriteFrameIndices );
			}
			
			function updateSpriteFrameIndices( testAvatar:EditorAvatar, layer:LayerAvatarBase, index:uint, ... arguments ):int
			{
				testAvatar.SetFromSpriteEntry( testAvatar.spriteEntry, true, true );
				if ( testAvatar.animIndex != -1 )
				{
					if ( addedTile && testAvatar.animIndex > highlightIndex )
					{
						testAvatar.SetAnimIndex( testAvatar.animIndex + 1 );
					}
					else if ( removedTile )
					{
						if ( testAvatar.animIndex > tileId )
						{
							testAvatar.SetAnimIndex( testAvatar.animIndex - 1 );
						}
					}
				}
				return index;
			}
			
			updateTileListForSprite(spriteEntry, TileListHasBlankFirstTile, null, ModifySprites );
			
			if ( app.animEditor )
			{
				app.animEditor.UpdateData();
			}
		}
		
		
		
		public function GetSelectedSpriteEntry():SpriteEntry { return null; }
		
		
	}
	
}