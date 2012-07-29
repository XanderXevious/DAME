package com 
{
	import com.Editor.*;
	import com.Editor.EditorType;
	import com.Game.Avatar;
	import com.Game.EditorAvatar;
	import com.Game.PathObject;
	import com.Layers.*;
	import com.Operations.HistoryStack;
	import com.Operations.OperationModifyTiles;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import com.UI.TileConnectionGrid;
	import com.Utils.DebugDraw;
	import com.Utils.Global;
	import com.Utils.ImageSaver;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import mx.managers.CursorManager;
	import org.flixel.*;
	import flash.utils.getTimer;
	import flash.ui.Mouse;
	import com.Utils.MouseHandler;
	import mx.utils.ObjectProxy;
	import flash.system.System;

	public class EditorState extends FlxState
	{		
		private var _currentMap:FlxTilemapExt = null;
		private var _currentLayer:LayerEntry = null;
		public static var lyrStage:FlxGroup;
		
		public static var debugDraw:FlxObject;
		
		public static var fps: Number = 0;
		private static var _fpsText:String = "0";
		private static var timeSinceStatusBarUpdate: Number = 0;	// How long since the last statusbar update;
		private static var totalFrameCountTimer: Number = 0;	// current time in miliseconds.
		private static var frameCount: uint = 0;		// Number of frames the editor has been running for.
		private static var frameCountInSeconds: uint = 0;		// Number of frames over the last second.
		public static function get FrameNum():uint { return frameCount; }
		
		private static var alwaysShowSavePrompt:Boolean = false;
		private static var lastSaveTime:Number = 0;
		public static function recordSave():void { lastSaveTime = totalFrameCountTimer; }//alwaysShowSavePrompt = false; }
		
		private var leftMouse:MouseHandler = null;
		private var middleMouse:MouseHandler = null;
		private var rightMouse:MouseHandler = null;
		
		private var mapFocus:FlxSprite;
		private var storedMapFocusPos:FlxPoint = new FlxPoint(0, 0);
		
		private var editMode:String = "EditModePaint";
		public static var InSelectMode:Boolean = false;
		public function get EditMode():String { return editMode; }
		
		private var isDrawingOnTiles:Boolean = false;
		private var statusBarUpdateCounter:uint = 0;
		private var storedMemString:String = "";
		private var baseMemory:Number = 0;
		
		private var cameraMovePercentRemaining:Number = 0;
		private var cameraMoveStartPos:FlxPoint = new FlxPoint();
		private var cameraMoveEndPos:FlxPoint = new FlxPoint();
		
		private var lastTimePerformedSearch:Number = 0;
		
		private var mouseIsOver:Boolean = true;
		private var safeMouseX:Number = -1;
		private var safeMouseY:Number = -1;
		private var wasDragging:Boolean = false;
		private var lastTimeDidZoomIn:Number = 0;
		private var lastTimeDidZoomOut:Number = 0;
		
		public var tileListIsSprite:Boolean = false;
		
		private static var dancingStepCount:Number = 0;
		
		private static var CurrentMapSelectedTileIdx:uint = 1;
		
		public function ChangeEditMode( newMode:String ):void
		{
			isDrawingOnTiles = ( newMode == "EditModeDraw" );
			if ( isDrawingOnTiles )
			{
				isDrawingOnTiles = true;
				editMode = "EditModePaint";
			}
			else
			{
				editMode = newMode;
			}
		}
		
		private static const roundingError:Number = 0.0000001;
		
		public var tileEditor:EditorTypeTiles;
		public var spriteEditor:EditorTypeSprites;
		public var drawEditor:EditorTypeDraw;
		public var tileMatrixEditor:EditorTypeTileMatrix;
		public var pathEditor:EditorTypePaths;
		public var shapeEditor:EditorTypeShapes;
		public var groupsEditor:EditorTypeGroups;
		
		//public static var _zoom:Number;
		//private static var _fxZoom:FlxSprite;
		

		public function EditorState():void
		{
			super();
		}
		
		override public function create():void
		{
			//_zoom = 1;
			//_fxZoom = new FlxSprite();// create de zoom;
			//_fxZoom.createGraphic(FlxG.width, FlxG.height, 0, true);// create the sprite same size that FlxG buffer
				
			//FlxG.maxElapsed = 1 / 15;
			lyrStage = new FlxGroup;
			
			FlxTilemap.disableWhenInactive = false;
			FlxTilemapExt.handleScreenResize = true;

			this.add(lyrStage);

			// Initialise the camera.
			mapFocus = new FlxSprite(0, 0);
			
			debugDraw = new DebugDraw();
			this.add(debugDraw);
			
			ImageBank.Initialize();
			new ImageSaver("");
			
			stage.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
			stage.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			
			leftMouse = new MouseHandler(MouseHandler.LEFT, leftMouseDown, leftMouseUp );
			middleMouse = new MouseHandler(MouseHandler.MIDDLE, middleMouseDown, middleMouseUp );
			rightMouse = new MouseHandler(MouseHandler.RIGHT, rightMouseDown, rightMouseUp );
			MainGame.flxGame.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved );
			
			if ( DebugDraw.singleton == null )
			{
				new DebugDraw();
			}
			
			UpdateMapList();
			
			
			tileEditor = new EditorTypeTiles( this );
			spriteEditor = new EditorTypeSprites( this );
			shapeEditor = new EditorTypeShapes( this );
			drawEditor = new EditorTypeDraw( this );
			tileMatrixEditor = new EditorTypeTileMatrix( this );
			pathEditor = new EditorTypePaths( this );
			groupsEditor = new EditorTypeGroups( this );
			
			//FlxU.setWorldBounds(0, 0, FlxG.width * 2, FlxG.height * 2);
		}
		
		private function handleMouseOver(event:MouseEvent):void
		{
			mouseIsOver = true;		
			// Hack to prevent flixel from staying paused when I open a popup window, lose focus and return.
			if ( FlxG.pause )
			{
				FlxG.pause = false;
			}
		}
		
		private function handleMouseOut(event:MouseEvent):void
		{
			mouseIsOver = false;
		}
		
		override public function render():void
		{
			super.render();
		}
		
		override public function update():void
		{
			super.update();

			dancingStepCount+= 7 * FlxG.elapsed;
			if ( dancingStepCount >= 4 )
				dancingStepCount -= 4;
			
			// Handle weirdness when you have multiple nativewindows and move the mouse over them 
			// - it updates mouse pos relative to them by default.
			if ( mouseIsOver )
			{
				safeMouseX = FlxG.mouse.screenX;
				safeMouseY = FlxG.mouse.screenY;
			}
			else
			{
				FlxG.mouse.screenX = safeMouseX;
				FlxG.mouse.screenY = safeMouseY;
			}
			
			// Something seems to override the frameRate that isn't my code or flixel
			if ( stage.frameRate > 30 )
			{
				stage.frameRate = 30;
			}
			
			var app:App = App.getApp();
			
			var currentEditor:EditorType = getCurrentEditor(app);
			
			if ( currentEditor != spriteEditor && app.myTileList )
			{
				app.myTileList.SelectionChanged = TileSelectionChanged;
			}
			
			
			var mainwid:int = Global.windowedApp.MainCanvas.width;
			
			// Resize the screen area to draw.
			FlxG.width = (Global.windowedApp.MainCanvas.width ) / MainGame.flxGame.scaleX;
			FlxG.height = app.StageHeight / MainGame.flxGame.scaleY;

			// Can't use FlxG.elapsed as that modifies the real elapsed time 
			frameCount++;
			frameCountInSeconds++;
			var time:uint = getTimer();
			var elapsed:Number = (time - totalFrameCountTimer) / 1000;
			timeSinceStatusBarUpdate += elapsed;
			totalFrameCountTimer = time;
			if ( timeSinceStatusBarUpdate > 1 )
			{
				fps = frameCountInSeconds;
				frameCountInSeconds = 0;
				_fpsText = fps + " fps";
				timeSinceStatusBarUpdate -= 1;
			}
			
			if ( !middleMouse.mouseDown )
			{
				MainGame.flxGame.useHandCursor = false;
				MainGame.flxGame.buttonMode = false;
			}
			
			
			// Move the camera if one was requested.
			if ( cameraMovePercentRemaining > 0 )
			{
				cameraMovePercentRemaining -= FlxG.elapsed * 2;
				if ( cameraMovePercentRemaining < 0 )
				{
					cameraMovePercentRemaining = 0;
				}
				FlxG.scroll.x = mapFocus.x = Misc.lerp(cameraMovePercentRemaining, cameraMoveEndPos.x, cameraMoveStartPos.x);
				FlxG.scroll.y = mapFocus.y = Misc.lerp(cameraMovePercentRemaining, cameraMoveEndPos.y, cameraMoveStartPos.y);
			}
			
			if ( FlxG.keys.justPressed("F11") )
			{
				if ( stage.displayState != StageDisplayState.NORMAL )
				{
					stage.displayState = StageDisplayState.NORMAL;
				}
				else
				{
					stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				}
			}
			
			if ( FlxG.keys.CONTROL )
			{
				if ( FlxG.keys.justPressed("PLUS"))
				{
					lastTimeDidZoomIn = time;
					zoomView( true );
				}
				else if ( FlxG.keys.PLUS )
				{
					if ( time - lastTimeDidZoomIn > 300 )
					{
						zoomView( true );
					}
				}
				else if (FlxG.keys.justPressed("MINUS") )
				{
					lastTimeDidZoomOut = time;
					zoomView( false );
				}
				else if ( FlxG.keys.MINUS )
				{
					if ( time - lastTimeDidZoomOut > 300 )
					{
						zoomView( false );
					}
				}
			}
			
			// Bookmarks
			if ( FlxG.keys.CONTROL )
			{
				// For some reason the "ZERO" keydown even never fired if ctrl + SHIFT pressed,
				// so for consistency we just do 1-9 keys.
				if ( FlxG.keys.justPressed("ONE"))
					app.bookmarks[0].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("TWO"))
					app.bookmarks[1].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("THREE"))
					app.bookmarks[2].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("FOUR"))
					app.bookmarks[3].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("FIVE"))
					app.bookmarks[4].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("SIX"))
					app.bookmarks[5].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("SEVEN"))
					app.bookmarks[6].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("EIGHT"))
					app.bookmarks[7].handleMenuShortcut(FlxG.keys.SHIFT );
				else if ( FlxG.keys.justPressed("NINE"))
					app.bookmarks[8].handleMenuShortcut(FlxG.keys.SHIFT );
			}
			
			// Move the map with arrow keys.
			if ( !FlxG.keys.SHIFT && FlxG.keys.pressed("CONTROL") )
			{
				var accel:uint = 300;
				var maxSpeed:uint = 400;
				// When Shift is pressed then arrow keys are handled by MyTree.
				if ( FlxG.keys.pressed("LEFT") && mapFocus.velocity.x >= 0 )
				{
					mapFocus.velocity.x = Math.min( maxSpeed, mapFocus.velocity.x + FlxG.elapsed * accel );
				}
				else if ( FlxG.keys.pressed("RIGHT") && mapFocus.velocity.x <= 0 )
				{
					mapFocus.velocity.x = Math.max( -maxSpeed, mapFocus.velocity.x - FlxG.elapsed * accel );
				}
				else
				{
					if ( mapFocus.velocity.x > 0 )
					{
						mapFocus.velocity.x = Math.max( 0, mapFocus.velocity.x - FlxG.elapsed * accel * 2 );
					}
					else if ( mapFocus.velocity.x < 0 )
					{
						mapFocus.velocity.x = Math.min( 0, mapFocus.velocity.x + FlxG.elapsed * accel * 2 );
					}
				}
				if ( FlxG.keys.pressed("UP") && mapFocus.velocity.y >= 0 )
				{
					mapFocus.velocity.y = Math.min( maxSpeed, mapFocus.velocity.y + FlxG.elapsed * accel );
				}
				else if ( FlxG.keys.pressed("DOWN") && mapFocus.velocity.y <= 0 )
				{
					mapFocus.velocity.y = Math.max( -maxSpeed, mapFocus.velocity.y - FlxG.elapsed * accel );
				}
				else
				{
					if ( mapFocus.velocity.y > 0 )
					{
						mapFocus.velocity.y = Math.max( 0, mapFocus.velocity.y - FlxG.elapsed * accel * 2 );
					}
					else if ( mapFocus.velocity.y < 0 )
					{
						mapFocus.velocity.y = Math.min( 0, mapFocus.velocity.y + FlxG.elapsed * accel * 2 );
					}
				}
				var xScroll:Number = app.CurrentLayer ? app.CurrentLayer.xScroll : 1;
				var yScroll:Number = app.CurrentLayer ? app.CurrentLayer.yScroll : 1;
				mapFocus.x += mapFocus.velocity.x * FlxG.elapsed / xScroll;
				mapFocus.y += mapFocus.velocity.y * FlxG.elapsed / yScroll;
				FlxG.scroll.x = mapFocus.x;
				FlxG.scroll.y = mapFocus.y
			}

			if ( app.CurrentLayer == null )
			{
				SetStatusBarText(null, null);
				MouseScrollView(app.CurrentLayer, elapsed);
				return;
			}
			
			if ( FlxG.keys.pressed("F3") )
			{
				if ( time - lastTimePerformedSearch > 300 )
				{
					lastTimePerformedSearch = time;
					FindNextItem();
				}
			}
			else if ( FlxG.keys.pressed("F2") )
			{
				if ( time - lastTimePerformedSearch > 300 )
				{
					lastTimePerformedSearch = time;
					FindPreviousItem();
				}
			}
			
			GuideLayer.DrawGuidelines(app.CurrentLayer);
			
			if ( _currentMap != app.CurrentLayer.map )
			{
				UpdateCurrentTileList( app.CurrentLayer );
				
				if ( app.brushesWindow && app.brushesWindow.visible )
				{
					app.brushesWindow.recalcPreview();
				}
			}
			if ( _currentLayer != app.CurrentLayer )
			{
				_currentLayer = app.CurrentLayer;
				UpdateOnionSkin( _currentLayer );
			}
			
			// Scroll the view...
			MouseScrollView(app.CurrentLayer, elapsed);
			
			// Get again in case it's changed.
			currentEditor = getCurrentEditor(app);
			

			pathEditor.Update( currentEditor==pathEditor, InSelectMode, leftMouse.mouseDown, rightMouse.mouseDown );
			spriteEditor.Update( currentEditor == spriteEditor, InSelectMode, leftMouse.mouseDown, rightMouse.mouseDown );
			shapeEditor.Update( currentEditor==shapeEditor, InSelectMode, leftMouse.mouseDown, rightMouse.mouseDown );
			drawEditor.Update( currentEditor==drawEditor, InSelectMode, leftMouse.mouseDown, rightMouse.mouseDown );
			tileEditor.Update( currentEditor == tileEditor, InSelectMode, leftMouse.mouseDown, rightMouse.mouseDown );
			tileMatrixEditor.Update( currentEditor == tileMatrixEditor, false, leftMouse.mouseDown, rightMouse.mouseDown );
			groupsEditor.Update( currentEditor == groupsEditor, true, leftMouse.mouseDown, rightMouse.mouseDown );
			
			SetStatusBarText(app.CurrentLayer, currentEditor);
		}
		
		private function MouseScrollView( layer:LayerEntry, elapsed:Number ):void
		{
			//trace(middleMouse.mouseDown + " and d = " + FlxG.keys.pressed("D") );
			// Scroll the view...
			if ( middleMouse.mouseDown )
			{
				var scrollX:Number = FlxG.zoomScale * ( (layer == null || layer.xScroll == 0 ) ? 1 : layer.xScroll );
				var scrollY:Number = FlxG.zoomScale * ( (layer == null || layer.yScroll == 0 ) ? 1 : layer.yScroll );
				if ( FlxG.keys.pressed("D") )
				{
					if ( !wasDragging )
					{
						middleMouse.mousePressedPos.create_from_points(stage.mouseX, stage.mouseY);
						storedMapFocusPos.copyFrom(mapFocus);
						wasDragging = true;
					}
					mapFocus.x += (elapsed * 4 * ( stage.mouseX - middleMouse.mousePressedPos.x )) / scrollX;
					mapFocus.y += (elapsed * 4 * ( stage.mouseY - middleMouse.mousePressedPos.y )) / scrollY;
				}
				else
				{
					if ( wasDragging )
					{
						middleMouse.mousePressedPos.create_from_points(stage.mouseX, stage.mouseY);
						storedMapFocusPos.copyFrom(mapFocus);
						wasDragging = false;
					}
					mapFocus.x = storedMapFocusPos.x + ( stage.mouseX - middleMouse.mousePressedPos.x ) / scrollX;
					mapFocus.y = storedMapFocusPos.y + ( stage.mouseY - middleMouse.mousePressedPos.y ) / scrollY;
				}
				FlxG.scroll.x = mapFocus.x;
				FlxG.scroll.y = mapFocus.y;
				
				MainGame.flxGame.useHandCursor = true;
				MainGame.flxGame.buttonMode = true;
				
			}
		}
		
		private function SetStatusBarText( currentLayer:LayerEntry, currentEditor:EditorType ):void
		{
			if ( statusBarUpdateCounter <= 0)
			{
				statusBarUpdateCounter = 60;
				var currentMem:Number = Number( System.totalMemory / (1024 * 1024) );
				var newMem:Number;
				if ( baseMemory == 0 )
				{
					baseMemory = currentMem;
				}
				else if ( currentMem < baseMemory )
				{
					baseMemory = currentMem;
				}
				newMem = currentMem - baseMemory;
				storedMemString = currentMem.toFixed( 2 ) + "MB";
				
			}
			statusBarUpdateCounter--;
			
			
			var mem:String = storedMemString;
			
			var displayPos:String = "";
			
			if ( currentLayer )
			{
				var pos:FlxPoint = currentEditor ? currentEditor.MousePos : null;
				if ( pos )
				{
					pos = pos.copy();
					pos.multiplyBy(FlxG.invExtraZoom);
				}
				var layerName:String = "";
				if ( currentLayer is LayerSprites )
				{
					layerName += "Sprites: ";
				}
				else if ( currentLayer is LayerMap )
				{
					pos = getMapXYFromScreenXY(FlxG.mouse.screenX, FlxG.mouse.screenY, currentLayer.xScroll, currentLayer.yScroll);
					pos.subFrom(currentLayer.map);
					layerName += "Map: ";
				}
				else if ( currentLayer is LayerPaths )
				{
					layerName += "Paths: ";
				}
				else if ( currentLayer is LayerGroup )
				{
					layerName += "Group: ";
				}
				layerName += currentLayer.name;
				
				var zText:String = "";
				if ( currentEditor is EditorTypeTiles )
				{
					zText = currentEditor.GetZText();
				}
				
				displayPos = pos ? ("X: " + pos.x + ", Y: " + pos.y + zText + " | ") : "";
				
				if ( currentLayer is LayerMap && 
					( currentEditor is EditorTypeTiles || currentEditor is EditorTypeDraw || currentEditor is EditorTypeTileMatrix) )
				{
					if ( currentEditor.currentTile.x >= 0 && currentEditor.currentTile.y >= 0 &&
						currentEditor.currentTile.x < currentLayer.map.widthInTiles && 
						currentEditor.currentTile.y < currentLayer.map.heightInTiles )
					{
						layerName += " (" + currentEditor.currentTile.x + "," + currentEditor.currentTile.y + " id=" + currentLayer.map.getTile(currentEditor.currentTile.x, currentEditor.currentTile.y) + ")";
					}
				}
			}
			else
			{
				layerName = "";
			}
			
			// Text to indicate the current selected object
			var currentObjectText:String = "";
			if ( currentEditor is EditorTypeSprites )
			{
				var spriteEditor:EditorTypeSprites = currentEditor as EditorTypeSprites;
				var selectedSprites:Vector.<EditorAvatar> = spriteEditor.GetSelection();
				if ( selectedSprites && selectedSprites.length == 1 )
				{
					var sprite:SpriteEntry = selectedSprites[0].spriteEntry;
					if ( sprite )
					{
						currentObjectText = " | " + (sprite.name.length ? sprite.name : sprite.className );
					}
				}
			}
			var dropperText:String = "";
			if ( currentEditor is EditorTypeDraw )
			{
				var drawEditor:EditorTypeDraw = currentEditor as EditorTypeDraw;
				dropperText = drawEditor.getDropperText();
				if ( dropperText.length )
				{
					dropperText = " | " + dropperText;
				}
			}
			
			var lastSaveString:String = "";
			var minute:Number = 60 * 1000;
			if ( totalFrameCountTimer - lastSaveTime > minute )//&& (alwaysShowSavePrompt )|| HistoryStack.IsFull() ) )
			{
				alwaysShowSavePrompt = true;
				lastSaveString = "| " + (uint)(Math.floor((totalFrameCountTimer - lastSaveTime)/minute) ) + " minutes since last save.";
			}
			App.getApp().StatusBarText = displayPos 
						+ layerName 
						+ currentObjectText
						+ dropperText
						+ " | Zoom: " + (FlxG.zoomScale * 100) + "%" 
						+ " | Mem: " + mem 
						+ " | " + _fpsText
						+ lastSaveString;
		}
		
		// Does the inverse of getScreenXY
		public static function getMapXYFromScreenXY(xPos:Number, yPos:Number, _scrollX:Number, _scrollY:Number):FlxPoint
		{
			var pos:FlxPoint = new FlxPoint();
			pos.x = FlxU.floor(xPos + roundingError + FlxG.extraScroll.x) - FlxU.floor( FlxG.scroll.x * _scrollX );
			pos.y = FlxU.floor(yPos + roundingError + FlxG.extraScroll.y) - FlxU.floor( FlxG.scroll.y * _scrollY );
			return pos;
		}
		
		// Does what getScreenXY does 
		public static function getScreenXYFromMapXY( _x:Number, _y:Number, _scrollX:Number, _scrollY:Number, doScale:Boolean = true ):FlxPoint
		{
			var point:FlxPoint = new FlxPoint();
			point.x = FlxU.floor( _x + roundingError + FlxG.extraScroll.x) + FlxU.floor(FlxG.scroll.x * _scrollX);
			point.y = FlxU.floor( _y + roundingError + FlxG.extraScroll.y) + FlxU.floor(FlxG.scroll.y * _scrollY);
			//point.multiplyBy(FlxG.extraZoom);
			if ( doScale )
			{
				point.x = point.x >> FlxG.zoomBitShifter;
				point.y = point.y >> FlxG.zoomBitShifter;
			}
			return point;
		}
		
		// No rounding.
		public static function getScreenXYFromMapXYPrecise( _x:Number, _y:Number, _scrollX:Number, _scrollY:Number, doScale:Boolean = true):FlxPoint
		{
			var point:FlxPoint = new FlxPoint();
			point.x = ( _x + FlxG.extraScroll.x)+FlxU.floor(FlxG.scroll.x*_scrollX);
			point.y = ( _y + FlxG.extraScroll.y) + FlxU.floor(FlxG.scroll.y * _scrollY);
			//point.multiplyBy(FlxG.extraZoom);
			if ( doScale )
			{
				point.x = point.x >> FlxG.zoomBitShifter;
				point.y = point.y >> FlxG.zoomBitShifter;
			}
			return point;
		}
		
		public function zoomView(zoomIn:Boolean):void
		{
			var scale:Number = FlxG.zoomScale;// MainGame.flxGame.scaleX;
			var diff:Number = .50;
			var scales:Array = [.125, .25, .5, 1, 2, 4, 8, 15, 20, 40];
			var currentLevel:int = scales.indexOf(scale);
			currentLevel += ( zoomIn ? 1 : -1);
			currentLevel = Math.max( 0, Math.min( currentLevel, scales.length - 1 ) );
			scale = scales[currentLevel];
			
			var minScale:Number = Global.AllowZoomOut ? 0.125 : 1;
			scale = Math.min( 40, Math.max( minScale, scale ) );
			
			if ( scale != FlxG.zoomScale)
			{
				var oldWidth:Number = FlxG.zoomScale < 1 ? FlxG.width / FlxG.zoomScale : FlxG.width;
				var oldHeight:Number = FlxG.zoomScale < 1 ? FlxG.height / FlxG.zoomScale : FlxG.height;
				var percentX:Number = FlxG.zoomScale < 1 ? FlxG.mouse.screenX * FlxG.zoomScale / FlxG.width : FlxG.mouse.screenX / FlxG.width;
				var percentY:Number = FlxG.zoomScale < 1 ? FlxG.mouse.screenY * FlxG.zoomScale / FlxG.height : FlxG.mouse.screenY / FlxG.height;
				percentX = Math.min( Math.max( 0, percentX ), 1 );
				percentY = Math.min( Math.max( 0, percentY ), 1 );
				
				var newWidth:Number = App.getApp().StageWidth / scale;
				var newHeight:Number = App.getApp().StageHeight /scale;
				// Reposition the camera so the zoom is relative to where the mouse cursor is on the screen.
				if ( zoomIn )
				{
					// zoom in
					mapFocus.x -= (oldWidth - newWidth) * percentX;
					mapFocus.y -= (oldHeight - newHeight) * percentY;
				}
				else
				{
					mapFocus.x += (newWidth-oldWidth) * percentX;
					mapFocus.y += (newHeight-oldHeight) * percentY;
				}
				FlxG.scroll.x = mapFocus.x;
				FlxG.scroll.y = mapFocus.y;
				
				FlxG.zoomScale = scale;
				
				if ( FlxG.zoomScale >= 1 )
				{
					MainGame.flxGame.scaleX = scale;
					MainGame.flxGame.scaleY = scale;
					FlxG.width = newWidth;
					FlxG.height = newHeight;
				}
			}
		}
		
		private function mouseWheelMoved(event:MouseEvent):void
		{
			var delta:int = Misc.sign(event.delta);
			zoomView(delta > 0 );
		}
		
		public function getCurrentEditor(app:App ):EditorType
		{
			if ( app.CurrentLayer is LayerSprites )
			{
				if ( isDrawingOnTiles )
				{
					return drawEditor;
				}
				return spriteEditor;
			}
			else if ( app.CurrentLayer is LayerPaths )
			{
				return pathEditor;
			}
			else if ( app.CurrentLayer is LayerShapes )
			{
				return shapeEditor;
			}
			else if ( app.CurrentLayer is LayerMap )
			{
				if ( isDrawingOnTiles )
				{
					return drawEditor;
				}
				else if ( editMode == "EditModeMatrix" )
				{
					return tileMatrixEditor;
				}
				else
				{
					return tileEditor;
				}
			}
			else if ( app.CurrentLayer is LayerGroup )
			{
				return groupsEditor;
			}
			return null;
		}
		
		private function leftMouseDown():void
		{
			var editor:EditorType = getCurrentEditor( App.getApp() );
			if ( editor )
			{
				editor.OnLeftMouseDown();
			}
		}
		
		private function leftMouseUp():void
		{
			var editor:EditorType = getCurrentEditor( App.getApp() );
			if ( editor )
			{
				editor.OnLeftMouseUp();
			}
		}
		
		private function rightMouseDown():void
		{
			var editor:EditorType = getCurrentEditor( App.getApp() );
			if ( editor )
			{
				editor.OnRightMouseDown();
			}
		}
		
		private function rightMouseUp():void
		{
			var editor:EditorType = getCurrentEditor( App.getApp() );
			if ( editor )
			{
				editor.OnRightMouseUp();
			}
		}
		
		private function middleMouseDown():void
		{
			wasDragging = FlxG.keys.pressed("D");
			storedMapFocusPos = FlxPoint.CreateObject( mapFocus );
		}
		
		private function middleMouseUp():void
		{
			/*var app:App = App.getApp();
			if ( app.CurrentLayer != null )
			{
				mapFocus.x = storedMapFocusPos.x + ( stage.mouseX - middleMouse.mousePressedPos.x ) / ( MainGame.flxGame.scaleX * ( app.CurrentLayer.xScroll == 0 ? 1 : app.CurrentLayer.xScroll ) );
				mapFocus.y = storedMapFocusPos.y + ( stage.mouseY - middleMouse.mousePressedPos.y ) / ( MainGame.flxGame.scaleY * ( app.CurrentLayer.yScroll == 0 ? 1 : app.CurrentLayer.yScroll ) );
			}
			else
			{
				mapFocus.x = storedMapFocusPos.x + ( stage.mouseX - middleMouse.mousePressedPos.x );
				mapFocus.y = storedMapFocusPos.y + ( stage.mouseY - middleMouse.mousePressedPos.y );
			}*/
			storedMapFocusPos = FlxPoint.CreateObject( mapFocus );
			FlxG.scroll.x = mapFocus.x;
			FlxG.scroll.y = mapFocus.y;
		}
		
		public function FindParentSpriteEntry( group:SpriteEntry, sprite:SpriteEntry ): SpriteEntry
		{
			if ( group.children == null )
			{
				return null;
			}
			var i:uint = group.children.length;
			while(i--)
			{
				var entry:SpriteEntry = group.children[i];
				if ( entry == sprite )
				{
					return group;
				}
				else
				{
					var parent:SpriteEntry = FindParentSpriteEntry( entry, sprite );
					if ( parent != null )
					{
						return parent;
					}
				}
			}
			
			return null;
		}
		
		public static function CallFuncForAllSpriteEntries( sprite:SpriteEntry, func:Function, ... arguments ): void
		{
			if ( sprite.children == null )
			{
				func( sprite, arguments );
				return;
			}
			var i:uint = sprite.children.length;
			while(i--)
			{
				var entry:SpriteEntry = sprite.children[i];
				CallFuncForAllSpriteEntries( entry, func, arguments );
			}
		}
		
		public static function CallFunctionOnLayerOrGroupForAllAvatars( layer:LayerEntry, func:Function, ... arguments ):void
		{
			var group:LayerGroup = layer as LayerGroup;
				
			if ( group )
			{
				var i:uint = group.children.length;
				while(i--)
				{
					
					var entry:LayerEntry = group.children[i] as LayerEntry;
					
					CallFunctionOnLayerOrGroupForAllAvatars( entry, func, arguments );
				}
			}
			else
			{
				var spriteLayer:LayerAvatarBase = layer as LayerAvatarBase;
				if ( spriteLayer )
				{
					for ( var j:uint = 0; j < spriteLayer.sprites.members.length; j++ )
					{
						j = func( spriteLayer.sprites.members[j], spriteLayer, j, arguments );
					}
				}
			}
		}
		
		public function CallFunctionOnGroupForSprite( layerGroup:LayerGroup, sprite:SpriteEntry, func:Function, ... arguments ):void
		{
			var i:uint = layerGroup.children.length;
			while(i--)
			{
				var entry:LayerEntry = layerGroup.children[i];
				var group:LayerGroup = entry as LayerGroup;
				
				if ( group )
				{
					CallFunctionOnGroupForSprite( group, sprite, func, arguments );
				}
				else
				{
					var spriteLayer:LayerSprites = entry as LayerSprites;
					if ( spriteLayer )
					{
						for ( var j:uint = 0; j < spriteLayer.sprites.members.length; j++ )
						{
							if ( sprite==null || spriteLayer.sprites.members[j].spriteEntry == sprite )
							{
								j = func( spriteLayer.sprites.members[j], spriteLayer, j, arguments );
							}
						}
					}
				}
			}
		}
		
		private function refreshMatchingSprite( testAvatar:EditorAvatar, layer:LayerAvatarBase, index:uint, ... arguments ):int
		{
			testAvatar.SetFromSpriteEntry( testAvatar.spriteEntry, true, true );
			return index;
		}
		
		public function RefreshSpriteGraphicsAndProperties( sprite:SpriteEntry ): void
		{
			var layerGroups:ArrayCollection = App.getApp().layerGroups;
			for ( var i:uint = 0; i < layerGroups.length; i++ )
			{
				CallFunctionOnGroupForSprite( layerGroups[i], sprite, refreshMatchingSprite );
			}
			
			spriteEditor.RefreshSpriteGraphics( sprite );
		}
		
		public function RemoveSpriteRefs(  testAvatar:EditorAvatar, layer:LayerAvatarBase, index:uint, ... arguments ):int
		{
			spriteEditor.RemoveAvatarFromSelection(testAvatar);
			layer.sprites.members.splice(index, 1);
			index--;
			return index;
		}
		
		// Recursively remove all references to all sprites in all sprite entries that are children of the one passed in.
		public function RemoveSpriteGroupReferences( spriteGroup:SpriteEntry ):void
		{
			if ( spriteGroup.isSprite() )
			{
				if ( App.getApp().layerGroups.length )
				{
					CallFunctionOnGroupForSprite( App.getApp().layerGroups[0], spriteGroup, RemoveSpriteRefs );
				}
				return;
			}
			
			var i:uint = spriteGroup.children.length;
			while(i--)
			{
				var entry:SpriteEntry = spriteGroup.children[i];
				RemoveSpriteGroupReferences( entry );
				spriteGroup.children.removeItemAt( spriteGroup.children.getItemIndex( entry ) );
			}
		}
		
		/*static public function SetCurrentTileToTileUnderCursor( mapPos:FlxPoint):void
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if (mapLayer )
			{
				var unitMapPosX:int = mapPos.x / mapLayer.map.tileWidth;
				var unitMapPosY:int = mapPos.y / mapLayer.map.tileHeight;
				
				if ( unitMapPosX < 0  ||
					unitMapPosY < 0  ||
					unitMapPosX >= mapLayer.map.widthInTiles ||
					unitMapPosY >= mapLayer.map.heightInTiles )
				{
					return;
				}
				var tileId:int = mapLayer.map.getTile(unitMapPosX, unitMapPosY);
				App.getApp().myTileList.selectedIndex = tileId;
			}
		}*/
		
		static public function SetCurrentTileToTileAtLocation( x:int, y:int ):void
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if (mapLayer )
			{
				
				if ( x < 0  ||
					y < 0  ||
					x >= mapLayer.map.widthInTiles ||
					y >= mapLayer.map.heightInTiles )
				{
					return;
				}
				var tileId:int = mapLayer.map.getTile(x, y);
				App.getApp().myTileList.selectedIndex = tileId;
			}
		}
		
		public function UpdateSpriteEntryIds( spriteEntry:SpriteEntry ):void
		{
			spriteEntry.UpdateSpriteEntryId();
			
			for each( var entry:SpriteEntry in spriteEntry.children )
			{
				UpdateSpriteEntryIds( entry );
			}
		}
		
		public function UpdateLayerVisibility(layer:LayerEntry):void
		{
			if ( !layer.visible )
			{
				if ( layer is LayerMap || layer is LayerGroup )
				{
					tileEditor.DeselectInvisible();
				}
				if ( layer is LayerPaths || layer is LayerGroup )
				{
					pathEditor.DeselectInvisible();
				}
				if ( layer is LayerShapes || layer is LayerGroup )
				{
					shapeEditor.DeselectInvisible();
				}
				if ( layer is LayerSprites || layer is LayerGroup )
				{
					spriteEditor.DeselectInvisible();
				}
			}
		}
		
		public function UpdateMapList():void
		{
			var app:App = App.getApp();
			
			lyrStage.members.length = 0;
			
			if ( app.layerGroups.length == 0 && tileEditor)
			{
				tileEditor.SelectNone();
				pathEditor.SelectNone();
				shapeEditor.SelectNone();
				spriteEditor.SelectNone();
			}
			
			for each( var group:LayerGroup in app.layerGroups )
			{
				for each( var layer:LayerEntry in group.children )
				{
					if ( layer.map )
					{
						if ( Global.DisplayLayersFirstOnTop )
						{
							lyrStage.members.unshift(layer.map);
						}
						else
						{
							lyrStage.add( layer.map );
						}
						layer.map.visible = group.visible && layer.visible;
					}
					else if ( layer is LayerImage )
					{
						var imageLayer:LayerImage = layer as LayerImage;
						if ( Global.DisplayLayersFirstOnTop )
						{
							lyrStage.members.unshift(imageLayer.sprite);
						}
						else
						{
							lyrStage.add( imageLayer.sprite );
						}
						imageLayer.sprite.visible = group.visible && layer.visible;
					}
					else if ( layer is LayerAvatarBase )
					{
						var spriteLayer:LayerAvatarBase = layer as LayerAvatarBase;
						if ( Global.DisplayLayersFirstOnTop )
						{
							lyrStage.members.unshift(spriteLayer.sprites);
						}
						else
						{
							lyrStage.add( spriteLayer.sprites );
						}
						
						spriteLayer.sprites.visible = group.visible && layer.visible;
						if ( layer is LayerPaths )
						{
							for each( var shape:PathObject in spriteLayer.sprites.members )
							{
								shape.visible = spriteLayer.sprites.visible;
							}
						}
					}
				}
			}
		}
		
		public function UpdateOnionSkin( layer:LayerEntry ):void
		{
			var app:App = App.getApp();
			
			for each( var group:LayerGroup in app.layerGroups )
			{
				for each( var testLayer:LayerEntry in group.children )
				{
					var testMapLayer:LayerMap = testLayer as LayerMap;
					var imageLayer:LayerImage = testLayer as LayerImage;
					if ( testMapLayer != null )
					{
						if ( Global.OnionSkinEnabled && layer != testMapLayer && layer !=testMapLayer.parent && layer )
						{
							testMapLayer.map.setAlpha( layer.parent == testMapLayer.parent ? Global.SameGroupOnionSkinAlpha : Global.OnionSkinAlpha);
						}
						else
						{
							testMapLayer.map.setAlpha( 1 );
						}
					}
				}
			}
		}
		
		public function UpdateCurrentTileList( layer:LayerEntry ):void
		{			
			UpdateOnionSkin(layer);
			if ( layer == null )
			{
				_currentMap = null;
				return;
			}

			_currentMap = layer.map;
			
			var app:App = App.getApp();

			app.myTileList.clearTiles();
			
			app.myTileList.CustomData = layer;
			
			app.myTileList.SelectionChanged = null;
			var mapLayer:LayerMap = layer as LayerMap;
// I'm not really happy with the tilelist being handled in so many different parts of code
// It makes it confusing who owns it at any time.
			if ( _currentMap != null )
			{
				tileListIsSprite = false;
				app.myTileList.modifyTilesCallback = ModifyTiles;
				app.myTileList.TileWidth = _currentMap.tileWidth;
				app.myTileList.TileHeight = _currentMap.tileHeight;
				app.myTileList.ColumnCount = 9; //TODO HACK
				app.myTileList.SetEraseTileIdx(mapLayer.EraseTileIdx);
				app.myTileList.HasEmptyFirstTile = false;
				
				if ( app.tileMatrix )
				{
					app.tileMatrixWindow.RedrawForCurrentLayer(mapLayer);
				}
				
				var i:uint;
				for ( i = 0; i < _currentMap.tileCount; i++ )
				{
					app.myTileList.pushTile(_currentMap.GetTileBitmap(i), i);
				}
				
				app.myTileList.selectedIndex = Math.max(Math.min(CurrentMapSelectedTileIdx, _currentMap.tileCount - 1), 0);
			}
			else
			{
				if ( getCurrentEditor(app) == drawEditor && layer is LayerSprites )
				{
					app.myTileList.modifyTilesCallback = drawEditor.ModifySprites;
				}
				app.myTileList.modifyTilesCallback = null;
			}
		}
		
		// The callback from the tile list menu.
		public function ModifyTiles( addNew:Boolean, copy:Boolean, del:Boolean, before:Boolean, into:Boolean, swap:Boolean, sourceTileId:int = -1, highlightTile:int = -1, globalUpdate:Boolean = true ):void
		{
			var app:App = App.getApp();
			
			var tileId:int = sourceTileId != -1 ? sourceTileId : app.myTileList.GetMetaDataAtIndex(app.myTileList.clickIndex) as int;
			var mapLayer:LayerMap = app.myTileList.CustomData as LayerMap;
			var changeGraphic:Boolean = true;
			var highlightTileId:int = -1;
			
			if ( (swap || (copy && into ) ) && highlightTileId == tileId )
			{
				// Glitches out if we copy into the same tile.
				return;
			}
			
			var isLastTile:Boolean = ( highlightTile == mapLayer.map.tileCount - 1 );
				
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
			
			if ( globalUpdate )
			{
				HistoryStack.BeginOperation(new OperationModifyTiles( mapLayer ) );
			}
			
			var tileCounts:Dictionary = new Dictionary(true);
			
			var baseBmp:BitmapData = null;
			var storedBmp:BitmapData = null;

			for each( var group:LayerGroup in app.layerGroups )
			{
				for each( var layer:LayerEntry in group.children )
				{
					var testMapLayer:LayerMap = layer as LayerMap;
					
					if ( testMapLayer != null && Misc.FilesMatch(mapLayer.imageFileObj, testMapLayer.imageFileObj ) )
					{
						if ( swap )
						{
							if ( tileId != -1 && highlightIndex != -1 )
							{
								if ( !baseBmp )
								{
									baseBmp = testMapLayer.map.GetTileBitmap( tileId );
								}
								if ( !storedBmp )
								{
									storedBmp = testMapLayer.map.GetTileBitmap( highlightIndex );
								}
								testMapLayer.map.SetTileBitmap( highlightIndex, baseBmp);
								testMapLayer.map.SetTileBitmap( tileId, storedBmp);
							}
						}
						else if ( addNew || copy )
						{
							if ( into )
							{
								if ( tileId != -1 )
								{
									baseBmp = testMapLayer.map.GetTileBitmap( tileId );
									testMapLayer.map.SetTileBitmap( highlightIndex, baseBmp);
								}
							}
							else
							{
								testMapLayer.map.insertNewTile( ( copy ? tileId : -1 ), highlightIndex, changeGraphic, mapLayer.imageData );
							}
						}
						else if ( del )
						{
							testMapLayer.map.removeTileAndShuntDown( tileId, changeGraphic, mapLayer.imageData );
						}
						tileCounts[testMapLayer] = testMapLayer.map.tileCount;
						testMapLayer.EraseTileIdx = Math.min(Math.max(testMapLayer.EraseTileIdx, 0), testMapLayer.map.tileCount - 1);
						changeGraphic = false;
					}
				}
			}
			ImageBank.MarkImageAsChanged( mapLayer.imageFileObj, mapLayer.imageData );
			
			// As the image changed callback resets the tileCount based on the dimensions, ensure the tile count is kept up to date.
			for ( var key:Object in tileCounts )
			{
				testMapLayer = key as LayerMap;
				testMapLayer.map.tileCount = tileCounts[testMapLayer];
			}
			
			if ( globalUpdate || !addNew || !isLastTile )
			{
				if ( app.tileMatrix )
				{
					if ( addNew || copy )
					{
						Global.windowedApp.tileMatrix.ShiftTileIds( highlightTileId, true );
					}
					else if( del )
					{
						Global.windowedApp.tileMatrix.ShiftTileIds( highlightTileId, false );
					}
					if ( getCurrentEditor(app) == tileMatrixEditor )
					{
						tileMatrixEditor.RedrawTiles();
					}
				}
				if ( app.brushesWindow )
				{
					if ( addNew || copy )
					{
						app.brushesWindow.ShiftTileIds( highlightTileId, true );
					}
					else if( del )
					{
						app.brushesWindow.ShiftTileIds( highlightTileId, false );
					}
				}
				UpdateCurrentTileList( mapLayer );
			}
			
		}
		
		public function MoveCameraToLocation( centrePos:FlxPoint, scrollX:Number, scrollY:Number ):void
		{
			cameraMoveStartPos.create_from_points(mapFocus.x, mapFocus.y);
			cameraMoveEndPos.x = ((FlxG.width / 2) - centrePos.x)/scrollX;
			cameraMoveEndPos.y = ((FlxG.height / 2) - centrePos.y) / scrollY;
			cameraMovePercentRemaining = 1;
		}
		
		public function MoveCameraToLocationExact( pos:FlxPoint, scrollX:Number, scrollY:Number, instant:Boolean = false ):void
		{
			cameraMoveStartPos.create_from_points(mapFocus.x, mapFocus.y);
			cameraMoveEndPos.x = pos.x/scrollX;
			cameraMoveEndPos.y = pos.y/scrollY;
			cameraMovePercentRemaining = instant ? 0.01 : 1;
		}
		
		public function FindNextItem():void
		{
			var CurrentLayer:LayerEntry = App.getApp().CurrentLayer;
			if ( CurrentLayer )
			{
				var x:Number = cameraMovePercentRemaining > 0 ? cameraMoveEndPos.x : FlxG.scroll.x;
				var y:Number = cameraMovePercentRemaining > 0 ? cameraMoveEndPos.y : FlxG.scroll.y;
				
				var centre:FlxPoint = CurrentLayer.GetNextItemPos(x * CurrentLayer.xScroll,y * CurrentLayer.yScroll, true);
				if ( centre )
				{
					MoveCameraToLocation( centre, CurrentLayer.xScroll, CurrentLayer.yScroll );
				}
			}
		}
		
		public function FindPreviousItem():void
		{
			var CurrentLayer:LayerEntry = App.getApp().CurrentLayer;
			if ( CurrentLayer )
			{
				var x:Number = cameraMovePercentRemaining > 0 ? cameraMoveEndPos.x : FlxG.scroll.x;
				var y:Number = cameraMovePercentRemaining > 0 ? cameraMoveEndPos.y : FlxG.scroll.y;
				
				var centre:FlxPoint = CurrentLayer.GetPreviousItemPos(x * CurrentLayer.xScroll,y * CurrentLayer.yScroll, true);
				if ( centre )
				{
					MoveCameraToLocation( centre, CurrentLayer.xScroll, CurrentLayer.yScroll );
				}
			}
		}
		
		// Simple callback function for DrawCustomLine that will draw a pixel directly on the flixel frame buffer.
		static public function DrawSteppedPixelsOnBufferCallback( x:int, y:int, drawData:Object ):void
		{
			if ( x >= 0 && y >= 0 && x < FlxG.buffer.width && y < FlxG.buffer.height )
			{
				var horizLine:Boolean = drawData as Boolean;
							
				var newColor:uint = 0xff000000;
				if ( horizLine )
				{
					if ( Math.abs(x - FlxG.scroll.x - dancingStepCount) % 4 < 2 )
					{
						newColor = 0xffffffff;
					}
				}
				else if( Math.abs(y - FlxG.scroll.y - dancingStepCount) % 4 < 2)
				{
					newColor = 0xffffffff;
				}
				
				FlxG.buffer.setPixel32(x, y, newColor );
			}
		}
		
		// Simple callback function for DrawCustomLine that will draw a pixel directly on the flixel frame buffer.
		static public function DrawOnBufferCallback( x:int, y:int, drawColorData:Object ):void
		{
			var color:uint = drawColorData as uint;
			var alpha:Number = ((color >> 24) & 0xff ) / 255;
			if ( x >= 0 && y >= 0 && x < FlxG.buffer.width && y < FlxG.buffer.height )
			{
				if ( alpha < 1 )
				{
					var oldColor:uint = FlxG.buffer.getPixel32(x, y);
					var newColor:uint = Misc.blendRGB(oldColor, color, alpha);
					FlxG.buffer.setPixel32(x, y, newColor);
				}
				else
				{
					
					FlxG.buffer.setPixel32(x, y, color );
				}
			}
		}
		
		public function TileSelectionChanged():void
		{
			var layer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( layer )
			{
				CurrentMapSelectedTileIdx = Math.min(Math.max(App.getApp().myTileList.selectedIndex, 0), layer.map.tileCount - 1);
			}
		}
		
		static public function SetCurrentLayerEraseTileIdx(tileIdx:uint):void
		{
			var layer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( layer )
			{
				layer.EraseTileIdx = Math.min(Math.max(tileIdx, 0), layer.map.tileCount - 1);
				App.getApp().myTileList.SetEraseTileIdx(layer.EraseTileIdx);
			}
		}
		
		static public function ReloadCurrentTileset():void
		{
			var layer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( layer )
			{
				ImageBank.ReloadImageFile(layer.imageFileObj, tilesetReloaded);
			}
		}
		
		static private function tilesetReloaded(filename:String, image:Bitmap):void
		{
			var app:App = App.getApp();
			var editor:EditorState = FlxG.state as EditorState;
			editor.UpdateCurrentTileList(app.CurrentLayer as LayerMap);
			
			if ( app.brushesWindow && app.brushesWindow.visible )
			{
				app.brushesWindow.recalcPreview();
			}
		}
		
		public function scrollToPos(x:int, y:int):void
		{
			FlxG.scroll.x = mapFocus.x = x;
			FlxG.scroll.y = mapFocus.y = y;
		}

	}

}
