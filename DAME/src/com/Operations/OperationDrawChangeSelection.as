package com.Operations 
{
	import com.Editor.DrawTileData;
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Layers.LayerMap;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import com.Editor.EditorTypeDraw;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationDrawChangeSelection extends IOperation
	{
		private var obj:Object;
		private var pixels:BitmapData;
		private var selectionTopLeft:FlxPoint;
		private var selectionBotRight:FlxPoint;
		private var selectionBitmap:BitmapData;
		private var _drawnTiles:Vector.<DrawTileData>;
		
		public function OperationDrawChangeSelection( _obj:Object, topLeftSelection:FlxPoint, botRightSelection:FlxPoint, image:BitmapData, drawnTiles:Vector.<DrawTileData> ) 
		{
			obj = _obj;
			var layer:LayerMap = obj as LayerMap;
			if ( layer )
			{
				pixels = layer.map.GetPixelData().clone();
			}
			else 
			{
				var sprite:EditorAvatar = obj as EditorAvatar;
				if ( sprite )
				{
					pixels = sprite.spriteEntry.bitmap.bitmapData.clone();
				}
			}
			selectionTopLeft = topLeftSelection ? topLeftSelection.copy() : null;
			selectionBotRight = botRightSelection ? botRightSelection.copy() : null;
			selectionBitmap = image ? image.clone() : null;
			_drawnTiles = drawnTiles;
		}
		
		override public function Undo():void
		{
			var app:App = App.getApp();
			if ( pixels )
			{
				var bmp:BitmapData;
				
				var layer:LayerMap = obj as LayerMap;
				var sprite:EditorAvatar = obj as EditorAvatar;
				var file:File;
				if ( layer )
				{
					bmp = layer.map.GetPixelData();
					file = layer.imageFileObj;
				}
				else if ( sprite )
				{
					bmp = sprite.spriteEntry.bitmap.bitmapData;
					file = sprite.spriteEntry.imageFile;
				}
				
				bmp.lock();
				bmp.copyPixels( pixels, new Rectangle(0,0,pixels.width,pixels.height), new Point, null, null, false);
				bmp.unlock();
				
				ImageBank.MarkImageAsChanged(file, new Bitmap(bmp));
				var currentState:EditorState = FlxG.state as EditorState;
				if ( layer )
				{
					if ( app.CurrentLayer && app.CurrentLayer is LayerMap && app.CurrentLayer.map.GetPixelData() == bmp )
					{
						
						currentState.UpdateCurrentTileList(layer);
					}
					
					if ( app.brushesWindow && app.brushesWindow.visible )
					{
						app.brushesWindow.recalcPreview();
					}
				}
				else if ( sprite )
				{
					if ( app.animEditor )
					{
						app.animEditor.UpdateData();
					}
					var editor:EditorType = currentState.getCurrentEditor(App.getApp());
					if ( editor )
					{
						var spriteEntry:SpriteEntry = editor.GetSelectedSpriteEntry();
						if ( spriteEntry == sprite.spriteEntry)
						{
							EditorType.updateTileListForSprite(spriteEntry, editor.TileListHasBlankFirstTile, null, editor.ModifySprites );
						}
					}
				}
			}
			
			var state:EditorState = FlxG.state as EditorState;
			state.drawEditor.RestoreSelection( selectionTopLeft, selectionBotRight, selectionBitmap, obj, _drawnTiles );
			
		}
		
	}

}