package com.Operations 
{
	import com.Game.EditorAvatar;
	import com.Game.PathObject;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationTransformShape extends IOperation
	{
		private var avatars:Vector.<AvatarInfo> = new Vector.<AvatarInfo>;
		
		public function OperationTransformShape( _avatars:Vector.<EditorAvatar> ) 
		{
			if ( _avatars )
			{
				var i:uint = _avatars.length;
				while ( i-- )
				{
					avatars.push( new AvatarInfo( _avatars[i] as PathObject ) );
				}
			}
		}
		
		protected function ContructFromSingleAvatar( avatar:PathObject ):void
		{
			avatars.push( new AvatarInfo( avatar ) );
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

import com.Game.PathNode;
import com.Game.PathObject;
import org.flixel.FlxPoint;

internal class AvatarInfo
{
	public var avatar:PathObject;
	public var pos:FlxPoint;
	public var scale:FlxPoint;
	public var angle:Number;
	public var width:Number;
	public var height:Number
	public var offset:FlxPoint;
	public var nodes:Vector.<PathNode> = new Vector.<PathNode>();
	
	public function AvatarInfo( _avatar:PathObject ):void
	{
		avatar = _avatar;
		pos = FlxPoint.CreateObject(avatar);
		scale = FlxPoint.CreateObject(avatar.scale);
		angle = avatar.angle;
		width = avatar.width;
		height = avatar.height;
		offset = FlxPoint.CreateObject(avatar.offset);
		for ( var i:uint = 0; i < avatar.nodes.length; i++ )
		{
			nodes.push( avatar.nodes[i].CopyNode() );
		}
	}
	
	public function Restore():void
	{
		var diff:FlxPoint = pos.v_sub(avatar);
		avatar.copyFrom(pos);
		avatar.scale.copyFrom(scale);
		avatar.offset.copyFrom(offset);
		avatar.angle = angle;
		avatar.width = width;
		avatar.height = height;
		avatar.nodes = nodes;
		avatar.Invalidate(false);
		if ( avatar.IsInstanced )
		{
			var i:uint = avatar.instancedShapes.length;
			while ( i-- )
			{
				var shape:PathObject = avatar.instancedShapes[i];
				if ( shape != avatar )
				{
					shape.nodes = avatar.nodes;
					shape.width = width;
					shape.height = height;
					// Invalidate might have moved the shapes so need to offset them back by the amount this shape moved.
					shape.x += diff.x;
					shape.y += diff.y;

					shape.Invalidate(false);
				}
			}
		}
		avatar.OnResize();
	}
}