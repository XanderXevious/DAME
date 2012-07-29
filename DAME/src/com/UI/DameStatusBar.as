package com.UI 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.core.UIComponent;
	
	[Style(name = "fontColor", type = "uint", format = "Color", inherit = "no")]
	
	public class DameStatusBar extends HBox
	{
		private var statusLabel:Label;
		private var minimizedTools:Vector.<Button> = new Vector.<Button>;
		private var buttonBox:HBox;
		
		private var _status:String;
		public function get status():String
		{
			return statusLabel.text;
		}
		public function set status( text:String ):void
		{
			statusLabel.text = text;
		}
		
		public function DameStatusBar() 
		{
			
		}
		
		override public function styleChanged(styleProp:String):void 
		{

            super.styleChanged(styleProp);

			var color:uint = getStyle("fontColor");
            setStyle("color", color );
			var children:Array = getChildren();
			for each( var child:UIComponent in children )
			{
				child.setStyle("color", color );
			}
        }
		
		override protected function createChildren() :void
		{
			super.createChildren();
			
			statusLabel = new Label;
			addChild(statusLabel);
			
			buttonBox = new HBox;
			buttonBox.percentWidth = 100;
			buttonBox.setStyle("horizontalAlign", "right");
			buttonBox.setStyle("horizontalGap", 2);
			addChild(buttonBox);
		}
		
		public function AddMinimizedWindow( title:String, callback:Function ):void
		{
			var newButton:Button = new Button();
			newButton.label = title;
			newButton.toolTip = "Press to restore the " + title + " window.";
			newButton.addEventListener( 'click', callback );
			newButton.height = 18;
			newButton.setStyle("cornerRadius", 0);
			minimizedTools.push( newButton );
			buttonBox.addChild(newButton);
			
		}
		
		public function RemoveMinimizedWindow( title:String ):void
		{
			for ( var i:uint = 0; i < minimizedTools.length; i++ )
			{
				if ( minimizedTools[i].label == title )
				{
					buttonBox.removeChild(minimizedTools[i]);
					minimizedTools.splice(i, 1);
				}
			}
		}
		
		public function HasMinimizedWindow():Boolean
		{
			return minimizedTools.length > 0;
		}
		
	}

}