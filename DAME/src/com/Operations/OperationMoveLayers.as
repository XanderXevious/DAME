package com.Operations 
{
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Operations.IOperation;
	import org.flixel.FlxPoint;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationMoveLayers extends IOperation
	{
		private var _data:Vector.<LayerData> = new Vector.<LayerData>;
		
		public function OperationMoveLayers( layer:LayerEntry ) 
		{
			var group:LayerGroup = layer as LayerGroup;
			if ( group )
			{
				var i:int = group.children.length;
				while (i--)
				{
					_data.push(new LayerData(group.children[i]));
				}
			}
			else if ( layer )
			{
				_data.push( new LayerData( layer ) );
			}
		}
		
		override public function Undo():void
		{
			for each( var item:LayerData in _data )
			{
				item.Undo();
			}
		}
		
	}

}
import com.Game.EditorAvatar;
import com.Layers.LayerAvatarBase;
import com.Layers.LayerEntry;
import com.Layers.LayerMap;
import org.flixel.FlxPoint;

internal class LayerData
{
	public var _layer:LayerEntry;
	public var _pos:FlxPoint;
	public var _avatar:EditorAvatar = null;
	
	public function LayerData(layer:LayerEntry)
	{
		_layer = layer;
		var mapLayer:LayerMap = layer as LayerMap;
		if ( mapLayer )
		{
			_pos = mapLayer.map.copy();
		}
		else
		{
			var avatarLayer:LayerAvatarBase = layer as LayerAvatarBase;
			if ( avatarLayer && avatarLayer.sprites.members.length )
			{
				_avatar = avatarLayer.sprites.members[0];
				_pos = _avatar.copy();
			}
		}
	}
	
	public function Undo():void
	{
		var offset:FlxPoint;
		var mapLayer:LayerMap = _layer as LayerMap;
		if ( mapLayer )
		{
			mapLayer.map.copyFrom(_pos);
		}
		else if ( _avatar )
		{
			offset = _avatar.v_sub( _pos );
			var avatarLayer:LayerAvatarBase = _layer as LayerAvatarBase;
			if ( avatarLayer )
			{
				for each( var avatar:EditorAvatar in avatarLayer.sprites.members )
				{
					avatar.create_from_points(avatar.x - offset.x, avatar.y - offset.y );
				}
				avatarLayer.minx -= offset.x;
				avatarLayer.miny -= offset.y;
				avatarLayer.maxx -= offset.x;
				avatarLayer.maxy -= offset.y;
			}
		}
	}
}