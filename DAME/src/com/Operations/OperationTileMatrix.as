package com.Operations 
{
	import com.EditorState;
	import com.Layers.LayerMap;
	import com.Operations.IOperation;
	import org.flixel.FlxG;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationTileMatrix extends IOperation
	{
		private var layer:LayerMap;
		private var boxes:Object;
		
		public function OperationTileMatrix( _layer:LayerMap, _boxes:Object ) 
		{
			layer = _layer;
			boxes = _boxes;
		}
		
		override public function Undo():void
		{
			var state:EditorState = FlxG.state as EditorState;
			state.tileMatrixEditor.RestoreTileMatrix( layer, boxes );
		}
		
	}

}