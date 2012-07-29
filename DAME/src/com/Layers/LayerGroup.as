package com.Layers 
{
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Utils.WeakReference;
	import mx.collections.ArrayCollection;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerGroup extends LayerEntry
	{
		private var masterLayerCached:LayerMap = null;
		private var lastFrameCachedMasterLayer:uint = 0;
		public var exportId:uint; // only used to identify a group with the copy used for exporting.
		
		public function LayerGroup( _name:String ) : void
		{
			super( null, _name, null, new ArrayCollection() );
			properties = new ArrayCollection();
		}
		
		public override function IsGroup():Boolean
		{
			return true;
		}
		
		override public function UpdateVisibility( ):void
		{
			super.UpdateVisibility( );
			
			if ( children )
			{
				for each( var child:LayerEntry in children )
				{
					child.UpdateVisibility();
				}
			}
		}
		
		override public function SetScrollFactors( newXScroll:Number, newYScroll:Number ) :void
		{
			super.SetScrollFactors(newXScroll, newYScroll);
			
			var i:uint = children.length;
			while (i--)
			{
				children[i].SetScrollFactors(newXScroll, newYScroll);
			}
		}
		
		override public function Clone( _parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry
		{
			return new LayerGroup( _name).CopyData(this, copyContents);
		}
		
		override protected function CopyData(sourceLayer:LayerEntry, copyContents:Boolean ):LayerEntry
		{
			super.CopyData(sourceLayer, copyContents);
			
			var sourceGroupLayer:LayerGroup = sourceLayer as LayerGroup;
			if ( sourceGroupLayer )
			{
				for ( var i:uint = 0; i < sourceGroupLayer.children.length; i++ )
				{
					var oldLayer:LayerEntry = sourceGroupLayer.children[i];
					var newLayer:LayerEntry = oldLayer.Clone(this, oldLayer.name, copyContents);
					children.addItem(newLayer);
				}
			}
			
			return this;
		}
		
		public function FindMasterLayer():LayerMap
		{
			if ( masterLayerCached != null && EditorState.FrameNum > lastFrameCachedMasterLayer )
			{
				return masterLayerCached;
			}
			
			lastFrameCachedMasterLayer = EditorState.FrameNum;
			
			var i:int = children.length;
			while(i--)
			{
				var mapLayer:LayerMap = children[i] as LayerMap;
				if ( mapLayer && mapLayer.IsMasterLayer() )
				{
					return mapLayer;
				}
			}
			return null;
		}
		
	}

}