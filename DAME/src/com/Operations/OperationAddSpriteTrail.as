package com.Operations 
{
	import com.Editor.EditorTypeAvatarsBase;
	import com.Game.EditorAvatar;
	import com.Game.SpriteTrailObject;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationAddSpriteTrail extends IOperation
	{
		private var trail:SpriteTrailObject;
		private var addOperation:IOperation;
		private var attachOperation:IOperation;
		
		public function OperationAddSpriteTrail( editor:EditorTypeAvatarsBase, avatar:SpriteTrailObject ) 
		{
			addOperation = new OperationAddAvatar( editor, avatar.layer, avatar );
			attachOperation = new OperationAttachAvatar( avatar );
			trail = avatar;
		}
		
		override public function Undo():void
		{
			for each( var child:EditorAvatar in trail.children )
			{
				child.Delete();
				/*if ( SpriteDeletedCallback != null )
				{
					SpriteDeletedCallback( avatar );
				}*/
			}
			attachOperation.Undo();
			addOperation.Undo();
		}
		
	}

}