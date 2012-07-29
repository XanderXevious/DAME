package com.Editor 
{
	import flash.events.Event;
	import mx.containers.Box;
	import mx.controls.Label;
	import mx.controls.Text;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PromptManager
	{
		static public var manager:PromptManager = new PromptManager;
		
		private var panelAlignY:uint = ALIGN_CENTER;
		private var panelAlignX:uint = ALIGN_CENTER;
		private var panelDodges:Boolean = false;
		private var panel:Box = new Box;
		private var label:Text;
		private var id:String = null;
		private var visible:Boolean = false;
		private var alpha:Number = 1;
		
		public static const ALIGN_CENTER:uint = 0;
		public static const ALIGN_LEFT:uint = 1;
		public static const ALIGN_RIGHT:uint = 2;
		public static const ALIGN_TOP:uint = 3;
		public static const ALIGN_BOTTOM:uint = 4;
		
		public function PromptManager() 
		{
			label = new Text;
			label.text = "";
			label.setStyle( "fontSize", 12 );
			label.setStyle( "fontFamily", "Arial" );
			label.setStyle( "textAlign", "center" );
			label.setStyle( "fontWeight", "bold" );
			label.maxWidth = 150;
			panel.addChild(label);
			panel.alpha = 1;
			panel.setStyle("backgroundColor", 0xffffff );
			//panel.setStyle("backgroundAlpha", 0.7 );
			panel.setStyle("borderThickness", 2 );
			panel.setStyle("borderColor", 0 );
			panel.setStyle("borderStyle", "solid" );
			panel.visible = false;
			App.getApp().gamePanel.addChild(panel);
			panel.addEventListener(Event.ENTER_FRAME, update );
			label.mouseFocusEnabled = panel.mouseFocusEnabled = false;
			label.mouseEnabled = panel.mouseEnabled = false;
			panel.focusEnabled = label.focusEnabled = false;
		}
		
		public function ShowPrompt(text:String, dodgeMouseMode:Boolean = true, Id:String = null ):void
		{
			label.text = text;
			visible = panel.visible = true;
			panel.validateDisplayList();
			panel.validateNow();
			alpha = panel.alpha = 1;
			
			panelDodges = dodgeMouseMode;
			if ( panelDodges )
			{
				panelAlignX = ALIGN_RIGHT;
				panelAlignY = ALIGN_BOTTOM;
			}
			else
			{
				panelAlignX = ALIGN_CENTER;
				panelAlignY = ALIGN_CENTER;
			}
			id = Id;
			
			PositionPanel();
		}
		
		private function PositionPanel():void
		{
			var maxWidth:uint = App.getApp().gamePanel.width - 20;
			var maxHeight:uint = App.getApp().gamePanel.height - 20;
			
			if( panelAlignX == ALIGN_CENTER )
				panel.x = Math.max( 0, ( maxWidth / 2 ) - ( panel.width / 2 ) );
			else if ( panelAlignX == ALIGN_LEFT )
				panel.x = 0;
			else if ( panelAlignX == ALIGN_RIGHT )
				panel.x = maxWidth - panel.width;
				
			if ( panelAlignY == ALIGN_CENTER )
				panel.y = Math.max( 0, ( maxHeight / 2 ) - ( panel.height / 2 ) );
			else if ( panelAlignY == ALIGN_TOP )
				panel.y = 0;
			else if ( panelAlignY == ALIGN_BOTTOM )
				panel.y = maxHeight - panel.height;
		}
		
		public function HidePrompt(text:String = null ):void
		{
			if ( !text || text == label.text )
			{
				visible = panel.visible = false;
				alpha = panel.alpha = 1;
			}
		}
		
		public function HidePromptById(Id:String = null ):void
		{
			if ( !Id || (id && id == Id) )
			{
				id = null;
				visible = panel.visible = false;
				alpha = panel.alpha = 1;
			}
		}
		
		private function update(event:Event):void
		{
			if ( panel.visible )
			{
				var time:Number = FlxG.elapsed;
				alpha = Math.max( 0.8, alpha - ( time * 0.08 ) );
				panel.alpha = alpha;
				PositionPanel();
			}
			if ( visible && alpha < 0.82 )
			{
				var insideX:Boolean = panel.mouseX > 0 && panel.mouseX < panel.width;
				var insideY:Boolean = panel.mouseY > 0 && panel.mouseY < panel.height;
				if ( insideX && insideY )
				{
					if ( panelDodges )
					{
						panelAlignX = ( panelAlignX == ALIGN_RIGHT ) ? ALIGN_LEFT : ALIGN_RIGHT;
						//panelAlignY = ( panelAlignY == ALIGN_CENTER ) ? ALIGN_BOTTOM : ALIGN_TOP;
							
					}
					else
					{
						panel.visible = false;
					}
				}
				else if( !panelDodges )
				{
					// Fade off as the mouse gets closer to the panel.
					var xDist:int = !insideX ? Math.min( Math.abs( panel.mouseX ), Math.abs( panel.mouseX - panel.width ) ) : 0;
					var yDist:int = !insideY ? Math.min( Math.abs( panel.mouseY ), Math.abs( panel.mouseY - panel.height ) ) : 0;
					var minDist:Number = Math.max( xDist, yDist );
					if ( minDist < 50 )
					{
						panel.alpha = Math.min( alpha, ( minDist / 50 ) * 0.8 );
					}
					panel.visible = true;
				}
			}
		}
		
	}

}