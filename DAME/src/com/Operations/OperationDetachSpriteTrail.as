package com.Operations 
{
	import com.Game.EditorAvatar;
	import com.Game.SpriteTrailObject;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationDetachSpriteTrail extends IOperation
	{
		private var trail:SpriteTrailObject;
		private var children:Vector.<EditorAvatar> = new Vector.<EditorAvatar>;
		private var deleteOperation:IOperation;
		private var detachOperation:IOperation;
		
		public function OperationDetachSpriteTrail( avatar:SpriteTrailObject ) 
		{
			var selection:Vector.<EditorAvatar> = new Vector.<EditorAvatar>;
			selection.push( avatar );
			detachOperation = new OperationDetachAvatar( avatar );
			deleteOperation = new OperationDeleteAvatar( selection );
			for each( var child:EditorAvatar in avatar.children )
			{
				children.push( child );
			}
			trail = avatar;
		}
		
		override public function Undo():void
		{
			deleteOperation.Undo();
			detachOperation.Undo();
			// It may have rendered some new children. Just go with the old children.
			for each( var child:EditorAvatar in trail.children )
			{
				if( children.indexOf( child ) == -1 )
					child.Delete();
			}
			trail.children = children;
		}
		
	}

}