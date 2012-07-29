package com.Operations 
{
	import com.EditorState;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationMoveTiles extends IOperation
	{
		private var selection:Object;
		
		public function OperationMoveTiles( _selection:Object ) 
		{
			selection = _selection;
		}
		
		override public function Undo():void
		{
			var state:EditorState = FlxG.state as EditorState;
			
			state.tileEditor.RestoreSelection( selection, true );
		}
		
	}

}