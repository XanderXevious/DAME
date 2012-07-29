package com.UI
{
    import mx.controls.treeClasses.TreeItemRenderer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import mx.controls.treeClasses.*;
	import flash.display.Bitmap;
	import mx.core.UIComponent;
	
	/*
	 * Adds a checkbox to the item in the tree
	 */

    public class SpriteTreeItemRenderer extends TreeItemRenderer
	{
		public var bmp:Bitmap = null;
		private var uiRef:UIComponent = null;
		private var dirtyResize:Boolean = false;
		
        public function SpriteTreeItemRenderer()
		{
            super();
            mouseEnabled = false;
			
        }
		
        override public function set data(value:Object):void
		{
            if (value != null)
			{
                super.data = value;
				
				if ( uiRef && bmp)
				{
					uiRef.removeChild( bmp );
					bmp = null;
				}
				
				if ( uiRef && value != null && value.previewBitmap != null)
				{
					bmp = new Bitmap(value.previewBitmap.bitmapData);
					uiRef.addChild( bmp );// adding sprite to UIcompoent
					// Ensure the tile is scaled to fit the row.
					var scale:Number = height / bmp.height;
					if( scale != 0)
					{
						bmp.height = height;
						bmp.width *= scale;
					}
					else
					{
						// Sometimes bizarrely the height is 0 so we need to ensure that we can update
						// this when we render and have a valid height
						dirtyResize = true;
					}
				}
				
            }
        }
        override protected function createChildren():void
		{
            super.createChildren();
            
			uiRef = new UIComponent(); // creating a UI component Object
			addChild( uiRef ); // add UI component to mxml base container
        }
		
        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
            super.updateDisplayList(unscaledWidth,unscaledHeight);
            if (super.data)
			{
                var tld:TreeListData = TreeListData(listData);
                //In some cases you only want a checkbox to appear if an item is a leaf.
                //if so, then keep the following block uncommented,
                //otherwise you can comment it out to display the checkbox

				if ( bmp == null )
				{
					dirtyResize = false;
					return;
				}
				
				
				if ( dirtyResize ) 
				{
					var scale:Number = height / bmp.height;
					bmp.height = height;
					bmp.width *= scale;
					//width = bmp.width;
					dirtyResize = false;
				}
				
				//reposition the controls to make room for checkbox
				bmp.x = label.x
				label.x = bmp.x + bmp.width;
            }
        }
               
    }

}