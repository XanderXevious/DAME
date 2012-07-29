package com.Operations 
{
	import com.Game.EditorAvatar;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationMoveAvatar extends IOperation
	{
		private var avatars:Vector.<AvatarPosition>;
		
		public function OperationMoveAvatar( _avatars:Vector.<EditorAvatar> ) 
		{
			avatars = new Vector.<AvatarPosition>;
			var i:uint = _avatars.length;
			while ( i-- )
			{
				avatars.push( new AvatarPosition( _avatars[i] ) );
			}
		}
		
		override public function Undo():void
		{
			var i:uint = avatars.length;
			while ( i-- )
			{
				avatars[i].Restore();
			}
		}
		
	}

}
import com.Game.EditorAvatar;
import org.flixel.FlxPoint;

internal class AvatarPosition
{
	public var avatar:EditorAvatar;
	public var pos:FlxPoint;
	public var z:Number;
	
	public function AvatarPosition( _avatar:EditorAvatar ):void
	{
		avatar = _avatar;
		pos = FlxPoint.CreateObject(avatar);
		z = avatar.z;
	}
	
	public function Restore():void
	{
		avatar.copyFrom(pos);
		if ( avatar.attachment && avatar.attachment.Parent )
		{
			avatar.attachment.Parent.RefreshAttachmentValues();
		}
		
		avatar.z = z;
		if ( avatar.layer.AutoDepthSort )
			avatar.layer.SortAvatar(avatar);
		avatar.UpdateAttachment();
		if ( avatar.attachment && avatar.attachment.Child )
		{
			avatar.attachment.Child.UpdateAttachment();
		}
	}
}