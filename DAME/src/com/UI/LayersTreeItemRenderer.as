package com.UI
{
	import com.EditorState;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerMap;
	import com.Layers.LayerPaths;
	import com.Layers.LayerSprites;
	import flash.display.Bitmap;
    import mx.controls.treeClasses.TreeItemRenderer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import mx.controls.CheckBox;
    import mx.controls.treeClasses.*;
	import mx.core.UIComponent;
	import org.flixel.FlxG;
	
	/*
	 * Adds a checkbox to the item in the tree
	 */

    public class LayersTreeItemRenderer extends TreeItemRenderer
	{
		[Embed("../../../assets/lockedIcon.png")]
		private var layerLockedIcon:Class;
		
		[Embed("../../../assets/alignIcon.png")]
		private var alignedIcon:Class;
		
		[Embed("../../../assets/masterLayerIcon.png")]
		private var masterLayerIcon:Class;
		
		//[Embed("../../../assets/templateIcon.png")]
		//private var templateIcon:Class;
		
		public var lockBmp:Bitmap = null;
		public var alignBmp:Bitmap = null;
		//public var templateBmp:Bitmap = null;
		private var uiRef:UIComponent = null;
		private var dirtyResize:Boolean = false;
		
        public var chk:CheckBox;
        public var entry:LayerEntry;
		
        public function LayersTreeItemRenderer()
		{
            super();
            mouseEnabled = false;
			
        }
		
        override public function set data(value:Object):void
		{
            if (value != null)
			{
                super.data = value;
				
				entry = LayerEntry(value);
				
				/*if ( entry.templatedBy )
				{
					setStyle( "fontWeight", "italic" );
				}
				else
				{
					setStyle( "fontWeight", "bold" );
				}*/
				
				if( chk )
					chk.selected = entry.visible;
				
				// Handle the locked icon
				if ( uiRef )
				{
					if( lockBmp)
					{
						uiRef.removeChild( lockBmp );
						lockBmp = null;
					}
					if ( alignBmp )
					{
						uiRef.removeChild( alignBmp );
						alignBmp = null;
					}
					/*if ( templateBmp )
					{
						uiRef.removeChild( templateBmp );
						templateBmp = null;
					}*/
					
					var mapLayer:LayerMap = entry as LayerMap;
					var avatarLayer:LayerAvatarBase = entry as LayerAvatarBase;
					if ( avatarLayer && avatarLayer.AlignedWithMasterLayer )
					{
						alignBmp = new alignedIcon;
						uiRef.addChild( alignBmp );
					}
					else if ( mapLayer && mapLayer.IsMasterLayer() )
					{
						alignBmp = new masterLayerIcon;
						uiRef.addChild( alignBmp );
					}
					/*if ( entry.isTemplateSource )
					{
						templateBmp = new templateIcon;
						uiRef.addChild( templateBmp );
					}*/
					
					if( entry && entry.Locked(false) )
					{
						lockBmp = new layerLockedIcon;
						uiRef.addChild( lockBmp );// adding sprite to UIcompoent
						// Ensure the tile is scaled to fit the row.
						/*var scale:Number = height / bmp.height;
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
						}*/
					}
				}
            }
        }
        override protected function createChildren():void
		{
            super.createChildren();
            chk = new CheckBox();
            chk.addEventListener(MouseEvent.CLICK, handleChkClick);
			chk.toolTip = "Use checkbox to hide/show the layer";
            addChild(chk);
			
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

                //for branch nodes
                /*if (tld.hasChildren)
				{
                    chk.visible = false;
                }
				else*/
				{
                    //You MUST have the else case to set visible to true
                    //even though you'd think the default would be visible
                    //it's an issue with itemrenderers...
                    chk.visible = true;
                }
				
                if (chk.visible)
				{
                    //if the checkbox is visible then
                    //reposition the controls to make room for checkbox
                    chk.x = label.x
                    label.x = chk.x + chk.measuredWidth;
                    chk.y = label.y + ( label.height - label.baselinePosition ) + 2; // +8
					
					// Align the lock icon to the right of the tree.
					var pos:int = unscaledWidth;
					if ( lockBmp )
					{
						pos = lockBmp.x = pos - lockBmp.width;
					}
					
					if ( alignBmp )
					{
						pos = alignBmp.x = pos - alignBmp.width;
					}
					
					/*if ( templateBmp )
					{
						pos = templateBmp.x = pos - templateBmp.width;
					}*/
                }
            }
        }
               
        private function handleChkClick(evt:MouseEvent):void
		{
			entry.visible = chk.selected;
			entry.UpdateVisibility( );
			
			var state:EditorState = FlxG.state as EditorState;
			state.UpdateLayerVisibility(entry);
        }
    }

}