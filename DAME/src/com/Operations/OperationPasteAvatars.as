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
	public class OperationPasteAvatars extends IOperation
	{
		private var editor:EditorTypeAvatarsBase;
		private var avatars:Vector.<EditorAvatar>;
		private var layer:LayerAvatarBase;
		
		public function OperationPasteAvatars( _editor:EditorTypeAvatarsBase, _layer:LayerAvatarBase, _avatars:Vector.<EditorAvatar> ) 
		{
			editor = _editor;
			layer = _layer;
			avatars = _avatars;
		}
		
		override public function Undo():void
		{
			for each ( var avatar:EditorAvatar in avatars )
			{
				var shape:PathObject = avatar as PathObject;
				if ( shape && shape.IsInstanced )
				{
					var index:uint = shape.instancedShapes.indexOf( shape );
					if ( index >= 0 )
					{
						shape.instancedShapes.splice(index, 1);
					}
				}
				editor.RemoveAvatarFromSelection(avatar );
				layer.sprites.remove(avatar, true);
			}
		}
		
	}

}