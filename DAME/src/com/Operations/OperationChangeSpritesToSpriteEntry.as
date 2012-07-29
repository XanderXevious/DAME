package com.Operations 
{
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationChangeSpritesToSpriteEntry extends IOperation
	{
		private var avatars:Vector.<AvatarInfo>;
		
		public function OperationChangeSpritesToSpriteEntry( _avatars:Vector.<EditorAvatar> ) 
		{
			avatars = new Vector.<AvatarInfo>;
			
			for ( var i:uint = 0; i < _avatars.length; i++ )
			{
				var avatar:EditorAvatar = _avatars[i];
				avatars.push( new AvatarInfo( avatar ) );
			}
		}
		
		override public function Undo():void
		{
			for ( var i:uint = 0; i < avatars.length; i++ )
			{
				avatars[i].avatar.SetFromSpriteEntry(avatars[i].sprite);
			}
		}
		
	}

}
import com.Game.EditorAvatar;
import com.Tiles.SpriteEntry;
internal class AvatarInfo
{
	public var avatar:EditorAvatar;
	public var sprite:SpriteEntry;
	
	public function AvatarInfo( _avatar:EditorAvatar):void
	{
		avatar = _avatar;
		sprite = avatar.spriteEntry;
		// Not going to store index as tricky to reinsert multiple avatars in one layer 
		// at the same time and maintain the same order.
	}
	
}