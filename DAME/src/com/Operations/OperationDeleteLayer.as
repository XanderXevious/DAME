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
	public class OperationDeleteLayer extends IOperation
	{
		private var layer:LayerEntry;
		private var group:LayerEntry;
		private var index:uint;
		
		public function OperationDeleteLayer( _layer:LayerEntry ) 
		{
			layer = _layer;
			group = layer.parent;
			if ( group )
			{
				var i:uint = group.children.length;
				while ( i-- )
				{
					if ( group.children[i] == layer )
					{
						index = i;
						return;
					}
				}
			}
			else
			{
				var groups:ArrayCollection = App.getApp().layerGroups;
				i = groups.length;
				while ( i-- )
				{
					if ( groups[i] == layer )
					{
						index = i;
						return;
					}
				}
			}
		}
		
		override public function Undo():void
		{
			if ( group )
			{
				group.children.addItemAt(layer, index);
			}
			else
			{
				var groups:ArrayCollection = App.getApp().layerGroups;
				groups.addItemAt( layer, index );
			}
			var currentState:EditorState = FlxG.state as EditorState;
			if ( currentState )
			{
				currentState.UpdateMapList();
			}
		}
		
	}

}