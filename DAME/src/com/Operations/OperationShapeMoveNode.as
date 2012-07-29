package com.Operations 
{
	import com.EditorState;
	import com.Game.PathNode;
	import com.Game.PathObject;
	import com.Operations.IOperation;
	import org.flixel.FlxG;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationShapeMoveNode extends OperationTransformShape
	{
		private var index:uint;
		private var shape:PathObject;
		
		public function OperationShapeMoveNode( _shape:PathObject, _index:uint, _node:PathNode ) 
		{
			super(null);
			shape = _shape;
			super.ContructFromSingleAvatar( shape );
			index = _index;
		}
		
		override public function Undo():void
		{
			super.Undo();
			var state:EditorState = FlxG.state as EditorState;
			state.pathEditor.SetSelectedNodeIndex(shape, index-1);
		}
		
	}

}