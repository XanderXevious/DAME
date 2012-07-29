package com.Operations 
{
	import com.EditorState;
	import com.Game.AvatarAttachment;
	import com.Game.EditorAvatar;
	import com.Game.PathObject;
	import com.Game.SpriteTrailObject;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import org.flixel.FlxG;
	import com.Game.AvatarLink;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationDeleteAvatar extends IOperation
	{
		private var avatars:Vector.<AvatarInfo>;
		private var index:uint;
		
		public function OperationDeleteAvatar( _avatars:Vector.<EditorAvatar>) 
		{
			avatars = new Vector.<AvatarInfo>;
			
			for ( var i:uint = 0; i < _avatars.length; i++ )
			{
				var avatar:EditorAvatar = _avatars[i];
				avatars.push( new AvatarInfo( avatar, avatar.layer ) );
			}
		}
		
		override public function Undo():void
		{
			for ( var i:uint = 0; i < avatars.length; i++ )
			{
				var avatar:EditorAvatar = avatars[i].avatar;
				avatar.markForDeletion = false;
				avatars[i].layer.sprites.members.splice(avatars[i].layer.sprites.members.length, 0, avatar);
				if ( avatars[i].attachedParent )
				{
					avatars[i].attachedParent.AttachAvatar(avatar);
				}
				if ( avatars[i].attachedChild )
				{
					avatar.AttachAvatar( avatars[i].attachedChild );
				}
				if ( avatar.layer.AutoDepthSort )
				{
					avatar.layer.SortAvatar(avatar);
				}
				
				for each( var link:AvatarLink in avatars[i].links )
				{
					link.RegisterLink();
				}
				/*var spriteTrail:SpriteTrailObject = avatar as SpriteTrailObject;
				if ( spriteTrail )
				{
					spriteTrail.children.length = 0;
					spriteTrail.UpdateAttachment();
				}
				/*if ( avatars[i].trailChildren )
				{
					var spriteTrail:SpriteTrailObject = avatar as SpriteTrailObject;
					if ( spriteTrail )
					{
						spriteTrail.children = avatars[i].trailChildren;
						for each( var child:EditorAvatar in spriteTrail.children )
						{
							child.markForDeletion = false;
							if ( child.layer.sprites.members.indexOf(child) == -1 )
								child.layer.sprites.members.splice(avatarIndex, 1);
							child.spriteTrailOwner = spriteTrail;
						}
					}
				}*/
			}
			
			var currentState:EditorState = FlxG.state as EditorState;
			currentState.UpdateMapList();
			avatars.length = 0;
		}
		
		override public function Removed():void
		{
			for ( var i:uint = 0; i < avatars.length; i++ )
			{
				var shape:PathObject = avatars[i].avatar as PathObject;
				if ( shape && shape.IsInstanced )
				{
					var index:uint = shape.instancedShapes.indexOf( shape );
					if ( index >= 0 )
					{
						shape.instancedShapes.splice(index, 1);
					}
				}
			}
			
		}
		
	}
}
import com.Game.AvatarLink;
import com.Game.EditorAvatar;
import com.Game.SpriteTrailObject;
import com.Layers.LayerAvatarBase;

internal class AvatarInfo
{
	public var avatar:EditorAvatar;
	public var layer:LayerAvatarBase;
	public var attachedParent:EditorAvatar = null;
	public var attachedChild:EditorAvatar = null;
	public var links:Vector.<AvatarLink> = new Vector.<AvatarLink>;
	public var trailChildren:Vector.<EditorAvatar> = null;
	
	public function AvatarInfo( _avatar:EditorAvatar, _layer:LayerAvatarBase ):void
	{
		avatar = _avatar;
		layer = _layer;
		if ( avatar.attachment )
		{
			attachedParent = avatar.attachment.Parent as EditorAvatar;
			attachedChild = avatar.attachment.Child as EditorAvatar;
		}
		for each( var link:AvatarLink in avatar.linksFrom )
		{
			links.push(link);
		}
		for each( link in avatar.linksTo )
		{
			links.push(link);
		}
		var spriteTrail:SpriteTrailObject = _avatar as SpriteTrailObject;
		if ( spriteTrail )
		{
			/*trailChildren = new Vector.<EditorAvatar>;
			for each( var child:EditorAvatar in spriteTrail.children )
			{
				trailChildren.push( child );
			}*/
		}
		// Not going to store index as tricky to reinsert multiple avatars in one layer 
		// at the same time and maintain the same order.
	}
	
}