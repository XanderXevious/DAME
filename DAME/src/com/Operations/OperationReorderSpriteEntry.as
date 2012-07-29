package com.Operations 
{
	import com.EditorState;
	import com.Operations.IOperation;
	import com.Tiles.SpriteEntry;
	import org.flixel.FlxG;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationReorderSpriteEntry extends IOperation
	{
		private var entry:SpriteEntry;
		private var parent:SpriteEntry;
		private var index:uint;
		
		public function OperationReorderSpriteEntry( _entry:SpriteEntry ) 
		{
			entry = _entry;
			
			var currentState:EditorState = FlxG.state as EditorState;
			parent = currentState.FindParentSpriteEntry( App.getApp().spriteData[0], entry );
			if ( parent )
			{
				index = parent.children.getItemIndex( entry );
			}
		}
		
		override public function Undo():void
		{
			var currentState:EditorState = FlxG.state as EditorState;
			var currentParent:SpriteEntry = currentState.FindParentSpriteEntry( App.getApp().spriteData[0], entry );
			if ( currentParent )
			{
				currentParent.children.removeItemAt( currentParent.children.getItemIndex( entry ) );
			}
			
			parent.children.addItemAt( entry, index );
			App.getApp().spriteData.itemUpdated(parent);
		}
		
	}

}