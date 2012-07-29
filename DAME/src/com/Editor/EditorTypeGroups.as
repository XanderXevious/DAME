package com.Editor 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Operations.HistoryStack;
	import com.Operations.OperationMoveLayers;
	import mx.managers.CursorManager;
	import org.flixel.FlxPoint;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeGroups extends EditorType
	{
		protected static var _isActive:Boolean = false;
		public static function IsActiveEditor():Boolean { return _isActive; };
		
		private var selectedTiles:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>();
		
		public static var MovingGroup:Boolean = false;
		
		private var lastScreenOffset:FlxPoint;
		
		public function EditorTypeGroups( editor:EditorState ) 
		{
			super( editor );
			
			selectionEnabled = true;
		}
		
		override public function Update(isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			_isActive = isActive;			
		}
		
		override protected function SelectUnderCursor( layer:LayerEntry ):Boolean
		{
			return false;
		}
		
		override protected function SelectWithinSelection( layer:LayerEntry, clearIfNoSelection:Boolean ):uint
		{
			if ( MovingGroup )
			{
				lastScreenOffset = new FlxPoint;
				var group:LayerGroup = App.getApp().CurrentLayer as LayerGroup;
				if ( group )
				{
					HistoryStack.BeginOperation( new OperationMoveLayers( group ) );
				}
			}
			return SELECTED_ITEM;
		}
		
		override protected function MoveSelection( screenOffsetFromOriginalPos:FlxPoint ):void
		{
			if ( MovingGroup )
			{
				var group:LayerGroup = App.getApp().CurrentLayer as LayerGroup;
				if ( !group )
					return;
					
				var screenOffset:FlxPoint = screenOffsetFromOriginalPos.copy();
				
				var i:int;
				for ( i = 0; i < group.children.length; i++ )
				{
					var layer:LayerEntry = group.children[i] as LayerEntry;
					var mapLayer:LayerMap = layer as LayerMap;
					if ( mapLayer )
					{
						if (GuideLayer.SnappingEnabled )
						{
							screenOffset.x = Math.floor( screenOffset.x / mapLayer.map.tileWidth ) * mapLayer.map.tileWidth;
							screenOffset.y = Math.floor( screenOffset.y / mapLayer.map.tileHeight ) * mapLayer.map.tileHeight;
							break;
						}
					}
				}
				i = group.children.length;
				while (i--)
				{
					layer = group.children[i] as LayerEntry;
					mapLayer = layer as LayerMap;
					if ( mapLayer )
					{
						mapLayer.map.subFrom( lastScreenOffset );
						mapLayer.map.addTo(screenOffset);
					}
					else
					{
						var avatarLayer:LayerAvatarBase = layer as LayerAvatarBase;
						if ( avatarLayer )
						{
							var j:int = avatarLayer.sprites.members.length;
							while ( j-- )
							{
								var avatar:EditorAvatar = avatarLayer.sprites.members[j];
								avatar.subFrom( lastScreenOffset );
								avatar.addTo(screenOffset);
							}
							avatarLayer.minx -= lastScreenOffset.x;
							avatarLayer.miny -= lastScreenOffset.y;
							avatarLayer.maxx -= lastScreenOffset.x;
							avatarLayer.maxy -= lastScreenOffset.y;
							avatarLayer.minx += screenOffset.x;
							avatarLayer.miny += screenOffset.y;
							avatarLayer.maxx += screenOffset.x;
							avatarLayer.maxy += screenOffset.y;
						}
					}
				}
				lastScreenOffset.copyFrom(screenOffset);
			}
		}
		
		override protected function ConfirmMovement( ):void
		{
			if ( MovingGroup )
			{
				var group:LayerGroup = App.getApp().CurrentLayer as LayerGroup;
				if ( !group )
					return;
			}
		}
		
	}

}