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
	public class OperationDeleteSpriteEntry extends IOperation
	{
		private var avatars:Vector.<AvatarInfo>;
		private var index:uint;
		private var spriteEntry:SpriteEntry;
		private var parentGroup:SpriteEntry;
		
		public function OperationDeleteSpriteEntry( _spriteEntry:SpriteEntry, _parentGroup:SpriteEntry ) 
		{
			spriteEntry = _spriteEntry;
			parentGroup = _parentGroup;
			index = parentGroup.children.getItemIndex( spriteEntry );
			// This will add another ref to the image before it's removed by the calling code.
			ImageBank.LoadImage( spriteEntry.imageFile );
			avatars = new Vector.<AvatarInfo>;
			
			var currentState:EditorState = FlxG.state as EditorState;
			var app:App = App.getApp();
			if ( app.layerGroups.length )
			{
				currentState.CallFunctionOnGroupForSprite( app.layerGroups[0], spriteEntry, addSpriteToList );
			}
		}
		
		private function addSpriteToList( testAvatar:EditorAvatar, layer:LayerAvatarBase, index:uint, ... arguments ):int
		{
			avatars.push( new AvatarInfo( testAvatar, layer ) );
			return index;
		}
		
		override public function Undo():void
		{
			// Calling load a second time will negate the remove call from Removed() below.
			ImageBank.LoadImage( spriteEntry.imageFile );
			
			parentGroup.children.addItemAt( spriteEntry, index );
			
			for ( var i:uint = 0; i < avatars.length; i++ )
			{
				avatars[i].avatar.markForDeletion = false;
				avatars[i].layer.sprites.members.splice(avatars[i].layer.sprites.members.length, 0, avatars[i].avatar);
			}
			
			var currentState:EditorState = FlxG.state as EditorState;
			currentState.UpdateMapList();
			App.getApp().spriteData.itemUpdated(parentGroup);
		}
		
		override public function Removed():void
		{
			ImageBank.RemoveImageRef( spriteEntry.imageFile );
		}
		
	}

}
import com.Game.EditorAvatar;
import com.Layers.LayerAvatarBase;
internal class AvatarInfo
{
	public var avatar:EditorAvatar;
	public var layer:LayerAvatarBase;
	
	public function AvatarInfo( _avatar:EditorAvatar, _layer:LayerAvatarBase ):void
	{
		avatar = _avatar;
		layer = _layer;
		// Not going to store index as tricky to reinsert multiple avatars in one layer 
		// at the same time and maintain the same order.
	}
	
}