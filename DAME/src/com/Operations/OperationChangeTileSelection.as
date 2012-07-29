package com.Operations 
{
	import com.EditorState;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationChangeTileSelection extends IOperation
	{
		private var selection:Object;
		
		public function OperationChangeTileSelection(_selection:Object ) 
		{
			selection = _selection;
		}
		
		override public function Undo():void
		{
			var state:EditorState = FlxG.state as EditorState;
			
			state.tileEditor.RestoreSelection( selection, false );
		}
		
	}

}