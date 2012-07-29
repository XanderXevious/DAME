package com.Operations 
{
	import com.Game.AvatarAttachment;
	import com.Game.EditorAvatar;
	import com.Operations.IOperation;
	import org.flixel.FlxPoint;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationAttachAvatar extends IOperation
	{
		private var childAvatar:EditorAvatar;
		private var pos:FlxPoint;
		private var attachment:AvatarAttachment;
		
		public function OperationAttachAvatar( _childAvatar:EditorAvatar ) 
		{
			childAvatar = _childAvatar;
			pos = FlxPoint.CreateObject( childAvatar );
			if( childAvatar.attachment )
				attachment = childAvatar.attachment.Clone();
		}
		
		override public function Undo():void
		{
			childAvatar.attachment = attachment;
			childAvatar.attachment.Parent.attachment = null;
			childAvatar.attachment = null;
			childAvatar.copyFrom(pos);
			if ( childAvatar.layer.AutoDepthSort )
			{
				childAvatar.layer.SortAvatar(childAvatar);
			}
		}
		
	}

}