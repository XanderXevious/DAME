package com.UI 
{
	import com.UI.Docking.DockablePage;
	import com.UI.Docking.DockableTabNav;
	import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.geom.Matrix;
    import mx.containers.DividedBox;
    import mx.containers.dividedBoxClasses.BoxDivider;
    import mx.core.UIComponent;
	import flash.display.SpreadMethod;
	import flash.display.GradientType;

        
    /**
     *  The alpha value for the background behind the dividers.
     *  A value of <code>0.0</code> means completely transparent
     *  and a value of <code>1.0</code> means completely opaque.
     *  @default 1
     */
    [Style(name="dividerBackgroundAlpha", type="Number", inherit="no")]
    
    /**
     *  Background color of behind the dividers
     *  @default 0x000000
     */
    [Style(name = "dividerBackgroundColor", type = "uint", format = "Color", inherit = "no")]
	
	[Style(name="barFillColors",type="Array",format="Color",inherit="no")]
    [Style(name="barBorderColor",type="uint",format="Color",inherit="no")]

    
    //[IconFile("DividedBox.png")]

    /**
     * Extends the mx.containers.DividedBox class to add the dividerBackgroundAlpha and
     * dividerBackgroundColor styles.  These styles fill in the background behind each divider.
     * 
     * @author Chris Callendar
     * @date April 20th, 2010
     */ 
    public class ExtendedDividedBox extends mx.containers.DividedBox
    {
        private var spreadMethod:String = SpreadMethod.PAD;
		private var _barFillColors:Array;
		private var _barBorderColor:uint;
		private var fillType:String = GradientType.LINEAR;
		private var alphas:Array = [1,1];
        private var ratios:Array = [0, 255];
		private var storedGraphics:Graphics = null;
		
		[Embed(source='../../../assets/NavGrip.png')] private var DividerSkinImage:Class;
		
        public function ExtendedDividedBox()
		{
            super();
			styleName = "com.UI.DividerSkin";
			setStyle("dividerSkin", DividerSkinImage);
        }
		
		override public function styleChanged(styleProp:String):void 
		{

            super.styleChanged(styleProp);

            // Check to see if style changed.
			// For some reason styleProp is always null ????
            //if (styleProp=="barFillColors" || styleProp=="barBorderColor") 
            {
                _barBorderColor=0;
                _barFillColors=null;
                invalidateDisplayList();
                return;
            }
        }
		
		public function PreDelete():void
		{
			var i:int = numChildren;
			while ( i-- )
			{
				var child:DisplayObject = getChildAt(i);
				removeChild( child );
				var tabs:DockableTabNav = child as DockableTabNav;
				if ( tabs )
				{
					tabs.PreDelete();
					continue;
				}
				var dock:DockablePage = child as DockablePage;
				if( dock )
				{
					dock.PreDelete();
					continue;
				}
				var divider:ExtendedDividedBox = child as ExtendedDividedBox;
				if ( divider )
				{
					divider.PreDelete();
					continue;
				}
			}
		}
        
        override protected function updateDisplayList(w:Number, h:Number):void
		{
            super.updateDisplayList(w, h);

            // fill in behind each divider
            var dividerCount:int = numDividers;
            if (dividerCount > 0)
			{
                var bgColor:uint = getStyle("dividerBackgroundColor");
                var bgAlpha:Number = getStyle("dividerBackgroundAlpha");
                if (isNaN(bgAlpha) || (bgAlpha < 0) && (bgAlpha > 1))
				{ 
                    bgAlpha = 1;
                }
                // use the divider's parent (dividerLayer) to paint the background
                var g:Graphics = (getDividerAt(0).parent as UIComponent).graphics;
                g.clear();
				storedGraphics = g;
				
				if (!_barFillColors)
				{
                    _barFillColors = getStyle("barFillColors");
                    if (!_barFillColors)
					{
                        _barFillColors =[0xFAE38F,0xEE9819]; // if no style default to orange
                    }
                }
                
                if (!_barBorderColor)
				{
                    _barBorderColor = getStyle("barBorderColor");
                    if (!_barBorderColor)
					{
                        _barBorderColor =0xEE9819; // if no style default to orange
                    }
                }
                
                g.lineStyle(1, _barBorderColor);
				
                for (var i:int = 0; i < dividerCount; i++)
				{
                    var divider:BoxDivider = getDividerAt(i);
					var mat:Matrix = new Matrix;
					if (direction == "vertical")
					{
						mat.createGradientBox(divider.width,divider.height,Math.PI/2, divider.x, divider.y);
					}
					else
					{
						mat.createGradientBox( divider.width, divider.height, 0, divider.x, divider.x + 10 );
					}

                    g.beginGradientFill(fillType, _barFillColors, alphas, ratios, mat, spreadMethod);
                    //g.beginFill(bgColor, bgAlpha);
                    g.drawRect(divider.x, divider.y, divider.width, divider.height);
                    //g.endFill();
                }
            }
			else
			{
				if ( storedGraphics )
				{
					storedGraphics.clear();
				}
			}
            
        }
        
    }


}

import flash.events.Event;


internal class ButtonClickEvent extends Event
{

		public function ButtonClickEvent(type:String,buttonObject:Object,selected:Boolean){
			super(type);
			
			this.buttonObject=buttonObject;
			this.selected=selected;
			
		}

		public var buttonObject:Object;
		public var selected:Boolean;

		override public function clone():Event {
			return new ButtonClickEvent(type, buttonObject,selected);
		}

	
}
