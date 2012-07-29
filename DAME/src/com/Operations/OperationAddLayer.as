package com.Operations 
{
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Operations.IOperation;
	import mx.collections.ArrayCollection;
	import org.flixel.FlxG;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationAddLayer extends IOperation
	{
		private var layer:LayerEntry;
		private var group:LayerEntry;
		
		public function OperationAddLayer( _layer:LayerEntry ) 
		{
			layer = _layer;
			group = layer.parent;
		}
		
		override public function Undo():void
		{
			if ( group )
			{
				group.children.removeItemAt(group.children.getItemIndex(layer));
			}
			else
			{
				var groups:ArrayCollection = App.getApp().layerGroups;
				groups.removeItemAt(groups.getItemIndex(layer));
			}
			var currentState:EditorState = FlxG.state as EditorState;
			if ( currentState )
			{
				currentState.UpdateMapList();
			}
		}
		
	}

}