package com.Operations 
{
	import com.Tiles.SpriteEntry;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationAddSpriteEntry extends IOperation
	{
		private var entry:SpriteEntry;
		private var parent:SpriteEntry;
		
		public function OperationAddSpriteEntry( _entry:SpriteEntry, _parent:SpriteEntry ) 
		{
			entry = _entry;
			parent = _parent;
		}
		
		override public function Undo():void
		{
			parent.children.removeItemAt( parent.children.getItemIndex( entry ) );
			App.getApp().spriteData.itemUpdated(parent);
		}
		
	}

}