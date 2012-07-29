package com.Operations 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Game.SpriteFrames.SpriteFrameShapes;
	import com.Layers.LayerAvatarBase;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import com.Tiles.TileAnim;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationModifySpriteFrames extends IOperation
	{
		private var previewBmp:BitmapData;
		private var bmp:BitmapData;
		private var numFrames:uint;
		private var sprite:SpriteEntry;
		public var anims:Vector.<TileAnim> = new Vector.<TileAnim>;
		public var shapes:SpriteFrameShapes = new SpriteFrameShapes;
		private var spriteData:Vector.<SpriteData> = new Vector.<SpriteData>;
		
		public function OperationModifySpriteFrames( Sprite:SpriteEntry) 
		{
			sprite = Sprite;
			bmp = sprite.bitmap.bitmapData.clone();
			previewBmp = sprite.previewBitmap.bitmapData.clone();
			numFrames = sprite.numFrames;
			for ( var i:uint = 0; i < sprite.anims.length; i++ )
			{
				var anim:TileAnim = new TileAnim;
				anim.CopyFrom(sprite.anims[i]);
				anims.push(anim);
			}
			shapes.CopyFrom( sprite.shapes );
			
			var currentState:EditorState = FlxG.state as EditorState;
			if ( App.getApp().layerGroups.length )
			{
				currentState.CallFunctionOnGroupForSprite( App.getApp().layerGroups[0], sprite, storeSprites );
			}
		}
		
		private function storeSprites( testAvatar:EditorAvatar, layer:LayerAvatarBase, index:uint, ... arguments ):int
		{
			if ( testAvatar.animIndex != -1 )
			{
				spriteData.push( new SpriteData(testAvatar) );
			}
			return index;
		}
		
		override public function Undo():void
		{
			sprite.bitmap.bitmapData = bmp;
			sprite.previewBitmap.bitmapData = previewBmp;
			sprite.numFrames = numFrames;
			
			sprite.anims.length = 0;
			for ( var i:uint = 0; i < anims.length; i++ )
			{
				var anim:TileAnim = new TileAnim;
				anim.CopyFrom(anims[i]);
				sprite.anims.push(anim);
			}
			
			sprite.shapes.CopyFrom( shapes );
			
			sprite.dontRefreshSpriteDims = true;
			ImageBank.MarkImageAsChanged( sprite.imageFile, sprite.bitmap );
			sprite.dontRefreshSpriteDims = false;
			
			var state:EditorState = FlxG.state as EditorState;
			var editor:EditorType = state.getCurrentEditor(App.getApp());
			if ( editor )
			{
				var spriteEntry:SpriteEntry = editor.GetSelectedSpriteEntry();
				if ( spriteEntry == sprite)
				{
					EditorType.updateTileListForSprite(spriteEntry, editor.TileListHasBlankFirstTile, null, editor.ModifySprites );
				}
			}
			
			for each( var data:SpriteData in spriteData )
			{
				data.sprite.SetAnimIndex( data.frame );
			}
		}
		
	}

}
import com.Game.EditorAvatar;

internal class SpriteData
{
	public var sprite:EditorAvatar;
	public var frame:int;
	
	public function SpriteData(Sprite:EditorAvatar )
	{
		sprite = Sprite;
		frame = sprite.animIndex;
	}
}