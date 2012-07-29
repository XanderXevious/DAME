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
	public class OperationReorderLayer extends IOperation
	{
		private var layer:LayerEntry;
		private var group:LayerGroup;
		private var index:uint;
		
		public function OperationReorderLayer( _layer:LayerEntry ) 
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
			// First remove it from whatever it's current parent is.
			var collection:ArrayCollection = ( layer.parent ? layer.parent.children : App.getApp().layerGroups );
			
			collection.removeItemAt( collection.getItemIndex( layer ) );
			
			// Now add it to the original group at the correct index.
			collection = group ? group.children : App.getApp().layerGroups;
			
			collection.addItemAt(layer, index);
			layer.parent = group;

			var currentState:EditorState = FlxG.state as EditorState;
			if ( currentState )
			{
				currentState.UpdateMapList();
			}
		}
		
	}

}