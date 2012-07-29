package com.Operations 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Layers.LayerMap;
	import com.Tiles.ImageBank;
	import com.Tiles.SpriteEntry;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationDraw extends IOperation
	{
		private var layer:LayerEntry;
		private var pixels:BitmapData;
		private var sprite:SpriteEntry = null;
		
		public function OperationDraw( _layer:LayerEntry, _sprite:SpriteEntry = null ) 
		{
			layer = _layer;
			if( _layer.map )
				pixels = layer.map.GetPixelData().clone();
			if ( _sprite )
			{
				sprite = _sprite;
				pixels = _sprite.bitmap.bitmapData.clone();
			}
		}
		
		override public function Undo():void
		{
			var app:App = App.getApp();
			if ( !layer.map )
			{
				if ( sprite )
				{
					sprite.dontRefreshSpriteDims = true;
					ImageBank.MarkImageAsChanged( sprite.imageFile, new Bitmap(pixels) );
					sprite.dontRefreshSpriteDims = false;
					if ( app.animEditor )
					{
						app.animEditor.UpdateData();
					}
					var state:EditorState = FlxG.state as EditorState;
					var editor:EditorType = state.getCurrentEditor(app);
					if ( editor )
					{
						var spriteEntry:SpriteEntry = editor.GetSelectedSpriteEntry();
						if ( spriteEntry == sprite)
						{
							EditorType.updateTileListForSprite(spriteEntry, editor.TileListHasBlankFirstTile, null, editor.ModifySprites );
						}
					}
				}
				return;
			}
			var bmp:BitmapData = layer.map.GetPixelData();
			
			var mapLayer:LayerMap = layer as LayerMap;
			bmp.lock();
			bmp.copyPixels( pixels, new Rectangle(0,0,pixels.width,pixels.height), new Point, null, null, false);
			bmp.unlock();
			
			ImageBank.MarkImageAsChanged(mapLayer.imageFileObj, new Bitmap(bmp));
			
			if ( app.CurrentLayer && app.CurrentLayer is LayerMap && app.CurrentLayer.map.GetPixelData() == bmp )
			{
				var currentState:EditorState = FlxG.state as EditorState;
				currentState.UpdateCurrentTileList(layer);
			}
			
			if ( app.brushesWindow && app.brushesWindow.visible )
			{
				app.brushesWindow.recalcPreview();
			}
			
			
			
		}
		
	}

}