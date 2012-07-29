package org.flixel
{
	import com.Editor.GuideLayer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import org.flixel.data.FlxConsole;
	import org.flixel.data.FlxPause;

	/**
	 * FlxGame is the heart of all flixel games, and contains a bunch of basic game loops and things.
	 * It is a long and sloppy file that you shouldn't have to worry about too much!
	 * It is basically only used to create your game object in the first place,
	 * after that FlxG and FlxState have all the useful stuff you actually need.
	 */
	public class FlxGame extends Sprite
	{
		// NOTE: Flex 4 introduces DefineFont4, which is used by default and does not work in native text fields.
		// Use the embedAsCFF="false" param to switch back to DefineFont4. In earlier Flex 4 SDKs this was cff="false".
		// So if you are using the Flex 3.x SDK compiler, switch the embed statment below to expose the correct version.
		
		//Flex v4.x SDK only (see note above):
		//[Embed(source="data/nokiafc22.ttf",fontFamily="system",embedAsCFF="false")] protected var junk:String;
		
		//Flex v3.x SDK only (see note above):
		[Embed(source = "data/nokiafc22.ttf", fontFamily = "system")] protected var junk:String;
		
		/**
		 * Sets 0, -, and + to control the global volume and P to pause.
		 * @default true
		 */
		public var useDefaultHotKeys:Boolean;
		/**
		 * Displayed whenever the game is paused.
		 * Override with your own <code>FlxLayer</code> for hot custom pause action!
		 * Defaults to <code>data.FlxPause</code>.
		 */
		public var pause:FlxGroup;
		
		//startup
		internal var _iState:Class;
		internal var _created:Boolean;
		
		//basic display stuff
		internal var _state:FlxState;
		internal var _screen:Sprite;
		internal var _buffer:Bitmap;
		internal var _zoom:uint;
		internal var _gameXOffset:int;
		internal var _gameYOffset:int;
		internal var _frame:Class;
		internal var _zeroPoint:Point;
		
		//basic update stuff
		internal var _elapsed:Number;
		internal var _total:uint;
		internal var _paused:Boolean;
		internal var _framerate:uint;
		internal var _frameratePaused:uint;
		
		//Pause screen, sound tray, support panel, dev console, and special effects objects
		internal var _console:FlxConsole;
		
		public var noConsole:Boolean = true;
		
		private var maskShape:Shape = new Shape;
		
		
		private var swap:Bitmap = null;
		private var bmp1:Bitmap = null;
		private var bmp0:Bitmap;
		private var quadrantId:uint = 0;
		
		/**
		 * Game object constructor - sets up the basic properties of your game.
		 * 
		 * @param	GameSizeX		The width of your game in pixels (e.g. 320).
		 * @param	GameSizeY		The height of your game in pixels (e.g. 240).
		 * @param	InitialState	The class name of the state you want to create and switch to first (e.g. MenuState).
		 * @param	Zoom			The level of zoom (e.g. 2 means all pixels are now rendered twice as big).
		 */
		public function FlxGame(GameSizeX:uint,GameSizeY:uint,InitialState:Class,Zoom:uint=2)
		{
			if( FlxG.canHideSystemCursor )
				flash.ui.Mouse.hide();
			
			_zoom = Zoom;
			FlxState.bgColor = 0xff000000;
			FlxG.setGameData(this,GameSizeX,GameSizeY,Zoom);
			_elapsed = 0;
			_total = 0;
			pause = new FlxPause();
			_state = null;
			_iState = InitialState;
			_zeroPoint = new Point();

			useDefaultHotKeys = true;
			
			_frame = null;
			_gameXOffset = 0;
			_gameYOffset = 0;
			
			_paused = false;
			_created = false;
			
			addEventListener(Event.ENTER_FRAME, create);
		}
		
		/**
		 * Adds a frame around your game for presentation purposes (see Canabalt, Gravity Hook).
		 * 
		 * @param	Frame			If you want you can add a little graphical frame to the outside edges of your game.
		 * @param	ScreenOffsetX	Width in pixels of left side of frame.
		 * @param	ScreenOffsetY	Height in pixels of top of frame.
		 * 
		 * @return	This <code>FlxGame</code> instance.
		 */
		protected function addFrame(Frame:Class,ScreenOffsetX:uint,ScreenOffsetY:uint):FlxGame
		{
			_frame = Frame;
			_gameXOffset = ScreenOffsetX;
			_gameYOffset = ScreenOffsetY;
			return this;
		}
		
		/**
		 * Makes the little volume tray slide out.
		 * 
		 * @param	Silent	Whether or not it should beep.
		 */
		public function showSoundTray(Silent:Boolean=false):void
		{
		}
		
		/**
		 * Switch from one <code>FlxState</code> to another.
		 * Usually called from <code>FlxG</code>.
		 * 
		 * @param	State		The class name of the state you want (e.g. PlayState)
		 */
		public function switchState(State:FlxState):void
		{ 
			//Basic reset stuff
			FlxG.unfollow();
			FlxG.resetInput();
			_screen.x = 0;
			_screen.y = 0;
			
			//Swap the new state for the old one and dispose of it
			_screen.addChild(State);
			if(_state != null)
			{
				_state.destroy(); //important that it is destroyed while still in the display list
				_screen.swapChildren(State,_state);
				_screen.removeChild(_state);
			}
			_state = State;
			_state.scaleX = _state.scaleY = _zoom;
			
			//Finally, create the new state
			_state.create();
		}

		/**
		 * Internal event handler for input and focus.
		 */
		public function onKeyUp(event:KeyboardEvent):void
		{
			if ( _console != null )
			{
				if((event.keyCode == 192) || (event.keyCode == 220)) //FOR ZE GERMANZ
				{
					_console.toggle();
					return;
				}
			}

			FlxG.keys.handleKeyUp(event);
			var i:uint = 0;
			var l:uint = FlxG.gamepads.length;
			while(i < l)
				FlxG.gamepads[i++].handleKeyUp(event);
		}
		
		/**
		 * Internal event handler for input and focus.
		 */
		protected function onKeyDown(event:KeyboardEvent):void
		{
			FlxG.keys.handleKeyDown(event);
			var i:uint = 0;
			var l:uint = FlxG.gamepads.length;
			while(i < l)
				FlxG.gamepads[i++].handleKeyDown(event);
		}
		
		/**
		 * Internal event handler for input and focus.
		 */
		protected function onFocus(event:Event=null):void
		{
			//if(FlxG.pause)
			//	FlxG.pause = false;
		}
		
		/**
		 * Internal event handler for input and focus.
		 */
		protected function onFocusLost(event:Event=null):void
		{
			// Ensure that because we won't get any key up events we forget about any pressed keys when losing focus.
			FlxG.keys.reset();
			//FlxG.pause = true;
		}
		
		protected function onMouseDown(event:Event=null):void {}
		
		/**
		 * Internal function to help with basic pause game functionality.
		 */
		internal function unpauseGame():void
		{
			FlxG.resetInput();
			_paused = false;
			stage.frameRate = _framerate;
		}
		
		/**
		 * Internal function to help with basic pause game functionality.
		 */
		internal function pauseGame():void
		{
			if((x != 0) || (y != 0))
			{
				x = 0;
				y = 0;
			}
			flash.ui.Mouse.show();
			_paused = true;
			stage.frameRate = _frameratePaused;
		}
		private var doneUpdate:Boolean = true;
		private var doneRender:Boolean = true;
		/**
		 * This is the main game loop.  It controls all the updating and rendering.
		 */
		protected function update(event:Event):void
		{
			if ( !doneUpdate || !doneRender || FlxG.disableUpdate )
			{
				return;
			}
			doneUpdate = false;
			doneRender = false;
			var mark:uint = getTimer();
			
			var i:uint;

			//Frame timing
			var ems:uint = mark-_total;
			_elapsed = ems / 1000;
			if( _console != null )
				_console.mtrTotal.add(ems);
			_total = mark;
			FlxG.elapsed = _elapsed;
			if(FlxG.elapsed > FlxG.maxElapsed)
				FlxG.elapsed = FlxG.maxElapsed;
			FlxG.elapsed *= FlxG.timeScale;
			

			//Animate flixel HUD elements
			if(_console!=null && _console.visible)
				_console.update();
			var requestedRefresh:Boolean = FlxG.requestRefresh;
			FlxG.forceRefresh = FlxG.requestRefresh;
			FlxG.requestRefresh = false;
			//State updating
			FlxG.updateInput();
			if(_paused)
				pause.update();
			else
			{
				//Update the camera and game state
				FlxG.doFollow();
				_state.update();
			}
			//Keep track of how long it took to update everything
			var updateMark:uint = getTimer();
			if( _console != null )
				_console.mtrUpdate.add(updateMark - mark);
				
			//FlxState.screen.unsafeBind(FlxG.buffer);
			//_state.preProcess();
			FlxG.extraScroll.x = FlxG.extraScroll.y = 0;
			
			if ( FlxG.zoomScale == 0.25 )
			{
				FlxG.extraZoom = FlxG.zoomScale;
				FlxG.invExtraZoom = 4;
				FlxG.zoomBitShifter = 2;
				FlxG.zoomScale = 1;
			}
			else if ( FlxG.zoomScale == 0.125 )
			{
				FlxG.extraZoom = FlxG.zoomScale;
				FlxG.invExtraZoom = 8;
				FlxG.zoomBitShifter = 3;
				FlxG.zoomScale = 1;
			}
			else
			{
				FlxG.zoomBitShifter = 0;
				FlxG.extraZoom = 1;
				FlxG.invExtraZoom = 1;
			}
			
			
			
			if ( bmp0.width != FlxG.width + 1 || bmp0.height != FlxG.height + 1 || requestedRefresh )
			{
				bmp0.bitmapData = new BitmapData(FlxG.width + 1, FlxG.height + 1, true, FlxState.bgColor);
				FlxState.screen.pixels = bmp0.bitmapData;	// will call resetHelpers and so ensure the screen is correctly sized.
				
				if ( GuideLayer.ShowGameRegion )
				{
					var rect:Rectangle = new Rectangle;
					maskShape.graphics.clear();
					maskShape.graphics.lineStyle(0,0,0);
					maskShape.graphics.beginFill(0xffffff, GuideLayer.RegionOpacity);
					var top:int = 0;
					var left:int = 0;
					var regionScale:Number = FlxG.extraZoom < 1 ? FlxG.extraZoom : FlxG.zoomScale;
					var regionWidth:uint = ( regionScale < 1 ) ? GuideLayer.RegionWidth * regionScale : GuideLayer.RegionWidth;
					var regionHeight:uint = ( regionScale < 1 ) ? GuideLayer.RegionHeight * regionScale : GuideLayer.RegionHeight;
					if ( GuideLayer.RegionCentered && regionWidth < FlxG.width )
					{
						// 2 bars on left and right that go from top to bottom of screen.
						// Note that the parallax scroll doesn't align correctly when the frame is centered at the moment.
						left = rect.width = (FlxG.width - regionWidth) / 2;
						rect.height = FlxG.height;
						maskShape.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
						rect.x = rect.width + regionWidth;
						maskShape.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
					}
					else
					{
						left = 0;
						maskShape.graphics.drawRect(regionWidth, 0, FlxG.width - regionWidth, regionHeight);
					}
					
					if ( GuideLayer.RegionCentered && regionHeight < FlxG.height )
					{
						// bars that are on top and bottom and fit between the vertical bars.
						left = rect.x = rect.width;
						rect.y = 0;
						rect.width = regionWidth;
						top = rect.height = (FlxG.height - regionHeight) / 2;
						maskShape.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
						rect.y = rect.height + regionHeight;
						maskShape.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
					}
					else
					{
						top = 0;
						maskShape.graphics.drawRect(0, regionHeight, FlxG.width, FlxG.height - regionHeight);
					}
					maskShape.graphics.endFill();
					maskShape.graphics.lineStyle(1);
					maskShape.graphics.drawRect( left - 1, top - 1, regionWidth + 1, regionHeight + 1);
					
						
					/*if ( FlxG.zoomScale >= 1 )
					{
						FlxG.extraScroll.x = -left;
						FlxG.extraScroll.y = -top;
					}*/
				}
			}
			
			var numIters:int = 0;
			if ( FlxG.extraZoom < 1 )
			{
				// When zoomed out we're drawing a lot of tiles so it slows down the render pipeline.
				// using 'threading' alleviates this a bit.
				// The slowdown is for some reason only an issue in Release, but it ok in debug.
				var intervalId:uint = setInterval(doRender, 5);
			}
			else
			{
				doRender();
			}
				
			function doRender( ):void
			{
				if ( numIters > 0 )
				{
					return;
				}
				numIters++;
				//Render game content, special fx, and overlays
				if ( FlxG.zoomScale == 0.5 )
				{
					if ( bmp1 == null )
					{
						bmp1 = new Bitmap(new BitmapData(bmp0.width, bmp0.height, true, FlxState.bgColor));
						swap = new Bitmap(new BitmapData(bmp0.width, bmp0.height, true, FlxState.bgColor));
						_screen.addChild(swap);
						swap.visible = false;
					}
					else if ( bmp1.width != bmp0.width || bmp1.height != bmp0.height )
					{
						_screen.removeChild(swap);
						bmp1 = new Bitmap(new BitmapData(bmp0.width, bmp0.height, true, FlxState.bgColor));
						swap = new Bitmap(new BitmapData(bmp0.width, bmp0.height, true, FlxState.bgColor));
						_screen.addChild(swap);
						swap.visible = false;
					}
					FlxG.buffer = bmp1.bitmapData;
					FlxState.screen.unsafeBind(FlxG.buffer);
				}
				else
				{
					bmp0.visible = true;
					if( swap )
						swap.visible = false;
					FlxG.buffer = bmp0.bitmapData;
					//FlxState.screen.unsafeBind(FlxG.buffer);
					FlxG.buffer.lock();
					_state.preProcess();
					_state.render();
					//_state.postProcess();
					if ( GuideLayer.ShowGameRegion )
					{
						FlxG.buffer.draw(maskShape);
					}
					FlxG.buffer.unlock();
					quadrantId = 0;
				}
				if ( FlxG.zoomScale == 0.5 )
				{
					var mat:Matrix = new Matrix;
					// Draw each quadrant at a different frame when zoomed out.
					// Unfortunately when drawing them at the same time Flash stalls so this is laggy.
					if ( quadrantId == 0 )
					{
						_state.preProcess();
						_state.render();
						_state.postProcess();
						FlxG.buffer.unlock();
						mat.scale(0.5, 0.5);
						if ( swap.visible )
						{
							bmp0.visible = true;
							swap.visible = false;
							_buffer = swap;
						}
						else
						{
							bmp0.visible = false;
							swap.visible = true;
							_buffer = bmp0;
						}
						_buffer.bitmapData.lock();
						_buffer.bitmapData.draw(bmp1, mat);
						_buffer.bitmapData.unlock();
						quadrantId++;
					}
					else if ( quadrantId == 1 )
					{
						// Force the tilemaps etc to redraw due to changing the scroll values here.
						FlxG.forceRefresh = true;
						// top right
						_state.preProcess();
						FlxG.extraScroll.x = -FlxG.width;
						_state.render();
						FlxG.buffer.unlock();
						mat.identity();
						
						mat.translate(FlxG.width, 0);
						mat.scale(0.5, 0.5);
						_buffer.bitmapData.lock();
						_buffer.bitmapData.draw(bmp1, mat);
						_buffer.bitmapData.unlock();
						quadrantId++;
					}
					else if ( quadrantId == 2 )
					{
						FlxG.forceRefresh = true;
						// bottom left
						_state.preProcess();
						FlxG.extraScroll.x = 0;
						FlxG.extraScroll.y = -FlxG.height;
						_state.render();
						FlxG.buffer.unlock();
						mat.identity();
						mat.translate(0, FlxG.height);
						mat.scale(0.5, 0.5);
						_buffer.bitmapData.lock();
						_buffer.bitmapData.draw(bmp1, mat);
						_buffer.bitmapData.unlock();
						quadrantId++;
					}
					else if ( quadrantId == 3 )
					{
						FlxG.forceRefresh = true;
						// bottom right
						_state.preProcess();
						FlxG.extraScroll.x = -FlxG.width;
						FlxG.extraScroll.y = -FlxG.height;
						_state.render();
						FlxG.buffer.unlock();
						mat.identity();
						mat.translate(FlxG.width, FlxG.height);
						mat.scale(0.5, 0.5);
						_buffer.bitmapData.lock();
						_buffer.bitmapData.draw(bmp1, mat);
						if ( GuideLayer.ShowGameRegion )
						{
							
							_buffer.bitmapData.draw(maskShape);
							
						}
						_buffer.bitmapData.unlock();
						quadrantId = 0;
					}
					
					
					FlxState.screen.unsafeBind(bmp0.bitmapData);
					FlxG.extraScroll.x = 0;
					FlxG.extraScroll.y = 0;
					
				}
				
				if ( FlxG.extraZoom < 1 )
				{
					clearInterval(intervalId);
				}
				doneRender = true;
			}

			//bmp0.bitmapData.unlock();
			
			//Keep track of how long it took to draw everything
			if( _console != null )
				_console.mtrRender.add(getTimer()-updateMark);
			//clear mouse wheel delta
			FlxG.mouse.wheel = 0;
			
			if ( FlxG.extraZoom < 0.5 )
			{
				FlxG.zoomScale = FlxG.extraZoom;
			}
			doneUpdate = true;
		}
		
		/**
		 * Used to instantiate the guts of flixel once we have a valid pointer to the root.
		 */
		internal function create(event:Event):void
		{
			if(root == null)
				return;

			var i:uint;
			var l:uint;
			
			//Set up the view window and double buffering
			stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.frameRate = _framerate;
            _screen = new Sprite();
            addChild(_screen);
			var tmp:Bitmap = bmp0 = new Bitmap(new BitmapData(FlxG.width,FlxG.height,true,FlxState.bgColor));
			tmp.x = _gameXOffset;
			tmp.y = _gameYOffset;
			tmp.scaleX = tmp.scaleY = _zoom;
			_screen.addChild(tmp);
			FlxG.buffer = tmp.bitmapData;
			
			//Initialize game console
			if ( !noConsole )
			{
				_console = new FlxConsole(_gameXOffset, _gameYOffset, _zoom);
				addChild(_console);
			}
			var vstring:String = FlxG.LIBRARY_NAME+" v"+FlxG.LIBRARY_MAJOR_VERSION+"."+FlxG.LIBRARY_MINOR_VERSION;
			if(FlxG.debug)
				vstring += " [debug]";
			else
				vstring += " [release]";
			var underline:String = "";
			i = 0;
			l = vstring.length+32;
			while(i < l)
			{
				underline += "-";
				i++;
			}
			FlxG.log(vstring);
			FlxG.log(underline);
			
			//Add basic input even listeners
			stage.addEventListener(MouseEvent.MOUSE_DOWN, FlxG.mouse.handleMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, FlxG.mouse.handleMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			// Need these to ensure that the keys consider themselves being unpressed when the window loses focus
			// otherwise depressing after will not receive a key_up event.
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);

			//Initialize the decorative frame (optional)
			if(_frame != null)
			{
				var bmp:Bitmap = new _frame();
				bmp.scaleX = _zoom;
				bmp.scaleY = _zoom;
				addChild(bmp);
			}
			
			//All set!
			switchState(new _iState());
			FlxState.screen.unsafeBind(FlxG.buffer);
			removeEventListener(Event.ENTER_FRAME, create);
			addEventListener(Event.ENTER_FRAME, update);
		}
	}
}