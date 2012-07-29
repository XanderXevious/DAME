package com.Operations 
{
	import com.Game.EditorAvatar;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationTransformSprite extends IOperation
	{
		private var avatars:Vector.<AvatarInfo>;
		
		public function OperationTransformSprite( _avatars:Vector.<EditorAvatar> ) 
		{
			avatars = new Vector.<AvatarInfo>;
			var i:uint = _avatars.length;
			while ( i-- )
			{
				avatars.push( new AvatarInfo( _avatars[i] ) );
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

internal class AvatarInfo
{
	public var avatar:EditorAvatar;
	public var pos:FlxPoint;
	public var scale:FlxPoint;
	public var angle:Number;
	public var width:Number;
	public var height:Number
	public var offset:FlxPoint;
	public var z:Number;
	public var tileDims:FlxPoint = null;
	public var tileOrigin:FlxPoint = null;
	
	public function AvatarInfo( _avatar:EditorAvatar ):void
	{
		avatar = _avatar;
		pos = FlxPoint.CreateObject(avatar);
		scale = FlxPoint.CreateObject(avatar.scale);
		angle = avatar.angle;
		width = avatar.width;
		height = avatar.height;
		offset = FlxPoint.CreateObject(avatar.offset);
		z = avatar.z;
		if ( avatar.spriteEntry && avatar.spriteEntry.IsTileSprite )
		{
			if ( avatar.TileDims )
				tileDims = avatar.TileDims.copy();
			if ( avatar.TileOrigin )
				tileOrigin = avatar.TileOrigin.copy();
		}
	}
	
	public function Restore():void
	{
		avatar.copyFrom(pos);
		avatar.scale.copyFrom(scale);
		avatar.offset.copyFrom(offset);
		avatar.angle = angle;
		avatar.width = width;
		avatar.height = height;
		avatar.z = z;
		if ( avatar.spriteEntry && avatar.spriteEntry.IsTileSprite )
		{
			avatar.TileDims = tileDims;
			avatar.TileOrigin = tileOrigin;
			avatar.SetAsTile();
		}
		avatar.OnResize();
		
		if ( avatar.layer.AutoDepthSort )
			avatar.layer.SortAvatar(avatar);
	}
}