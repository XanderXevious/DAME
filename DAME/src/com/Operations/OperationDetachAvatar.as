package com.Operations 
{
	import com.Game.AvatarAttachment;
	import com.Game.EditorAvatar;
	import com.Operations.IOperation;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationDetachAvatar extends IOperation
	{
		private var childAvatar:EditorAvatar;
		private var childAvatarAttachment:AvatarAttachment;
		private var parentAvatarAttachment:AvatarAttachment;
		
		public function OperationDetachAvatar( _childAvatar:EditorAvatar ) 
		{
			childAvatar = _childAvatar;
			childAvatarAttachment = childAvatar.attachment;
			parentAvatarAttachment = childAvatarAttachment.Parent.attachment;
		}
		
		override public function Undo():void
		{
			childAvatar.attachment = childAvatarAttachment;
			childAvatar.attachment.Parent.attachment = parentAvatarAttachment;
		}
		
	}

}