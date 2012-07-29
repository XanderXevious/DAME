package com.Operations 
{
	import com.EditorState;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationPasteTiles extends IOperation
	{
		private var oldSelection:Object;
		
		public function OperationPasteTiles( _oldSelection:Object  )
		{
			oldSelection = _oldSelection;
		}
		
		override public function Undo():void
		{
			var state:EditorState = FlxG.state as EditorState;
			
			state.tileEditor.RestoreSelection( oldSelection, true );
		}
		
	}

}