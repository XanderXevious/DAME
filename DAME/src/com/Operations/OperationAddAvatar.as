package com.Operations 
{	
	import com.Editor.EditorTypeAvatarsBase;
	import com.Game.EditorAvatar;
	import com.Game.PathObject;
	import com.Layers.LayerAvatarBase;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationAddAvatar extends IOperation
	{
		private var editor:EditorTypeAvatarsBase;
		private var sprite:EditorAvatar;
		private var spriteLayer:LayerAvatarBase;
		
		public function OperationAddAvatar( _editor:EditorTypeAvatarsBase, layer:LayerAvatarBase, newSprite:EditorAvatar ) 
		{
			editor = _editor;
			spriteLayer = layer;
			sprite = newSprite;
		}
		
		override public function Undo():void
		{
			var shape:PathObject = sprite as PathObject;
			if ( shape && shape.IsInstanced )
			{
				var index:uint = shape.instancedShapes.indexOf( shape );
				if ( index >= 0 )
				{
					shape.instancedShapes.splice(index, 1);
				}
			}
			editor.RemoveAvatarFromSelection(sprite );
			spriteLayer.sprites.remove(sprite, true);
		}
		
	}

}