package com.Layers 
{
	import com.Layers.LayerAvatarBase;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerShapes extends LayerAvatarBase
	{
		public function LayerShapes( _parent:LayerGroup, _name:String ):void
		{
			super( _parent, _name);
		}
		
		// This is needed for the exporter
		override public function IsShapeLayer():Boolean
		{
			return true;
		}
		
		override public function Clone( _parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry
		{
			return new LayerShapes( _parent, _name).CopyData(this, copyContents);
		}
		
	}

}