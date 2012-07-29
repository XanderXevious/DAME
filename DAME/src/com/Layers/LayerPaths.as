package com.Layers 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerPaths extends LayerAvatarBase
	{
		public function LayerPaths( _parent:LayerGroup, _name:String ):void
		{
			super( _parent, _name);
		}
		
		// This is needed for the exporter
		override public function IsPathLayer():Boolean
		{
			return true;
		}
		
		override public function Clone( _parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry
		{
			return new LayerPaths( _parent, _name).CopyData(this, copyContents);
		}
		
	}

}