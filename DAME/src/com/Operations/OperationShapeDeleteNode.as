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
	public class OperationShapeDeleteNode extends IOperation
	{
		private var shape:PathObject;
		private var node:PathNode;
		private var index:uint;
		
		public function OperationShapeDeleteNode( _shape:PathObject, _index:uint, _node:PathNode ) 
		{
			shape = _shape;
			index = _index;
			node = _node.CopyNode();
		}
		
		override public function Undo():void
		{
			shape.nodes.splice(index, 0, node);
			shape.Invalidate();
			var state:EditorState = FlxG.state as EditorState;
			state.pathEditor.SetSelectedNodeIndex(shape, index);
		}
		
	}

}