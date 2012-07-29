package com.Operations 
{
	import com.EditorState;
	import com.Game.PathObject;
	import com.Operations.IOperation;
	import org.flixel.FlxG;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationShapeAddNode extends OperationTransformShape
	{
		private var shape:PathObject;
		private var index:uint;
		
		public function OperationShapeAddNode( _shape:PathObject, _index:uint ) 
		{
			super(null);
			shape = _shape;
			index = _index;
			super.ContructFromSingleAvatar( shape );
		}
		
		override public function Undo():void
		{
			super.Undo();
			var state:EditorState = FlxG.state as EditorState;
			state.pathEditor.SetSelectedNodeIndex(shape, index-1);
		}
		
	}

}