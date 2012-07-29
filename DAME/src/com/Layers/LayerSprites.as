package com.Layers 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerSprites extends LayerAvatarBase
	{
		public function LayerSprites( _parent:LayerGroup, _name:String ):void
		{
			super( _parent, _name);
		}
		
		// This is needed for the exporter
		override public function IsSpriteLayer():Boolean
		{
			return true;
		}

		override public function Clone( _parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry
		{
			return new LayerSprites( _parent, _name).CopyData(this, copyContents);
		}
		
	}

}