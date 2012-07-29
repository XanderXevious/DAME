package com.Operations 
{
	import com.Editor.TileEditorLayerEntry;
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.ImageBank;
	import com.Tiles.TileAnim;
	import com.Tiles.TileMatrixData;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxG;
	import com.UI.TileBrushesWindow;
	import com.UI.TileMatrix;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationModifyTiles extends IOperation
	{
		private var layer:LayerMap;
		private var pixels:BitmapData;
		private var tileDatas:Vector.<LayerTiles> = new Vector.<LayerTiles>;
		private var tileCount:uint;
		
		private var brushes:Vector.<TileEditorLayerEntry> = new Vector.<TileEditorLayerEntry>;
		private var matrices:Vector.<TileMatrixData> = new Vector.<TileMatrixData>;
		
		public function OperationModifyTiles( _layer:LayerMap) 
		{
			layer = _layer;
			pixels = layer.map.GetPixelData().clone();
			tileCount = layer.map.tileCount;
			
			
			for each( var group:LayerGroup in App.getApp().layerGroups )
			{
				for each( var testlayer:LayerEntry in group.children )
				{
					var testMapLayer:LayerMap = testlayer as LayerMap;
					
					if ( testMapLayer != null && Misc.FilesMatch(layer.imageFileObj,testMapLayer.imageFileObj) )
					{
						tileDatas.push( new LayerTiles( testMapLayer) );
					}
				}
			}
			
			for ( var i:uint = 0; i < TileBrushesWindow.brushes.length; i++ )
			{
				var layerData:TileEditorLayerEntry = TileBrushesWindow.brushes[i].entry;
				if ( Misc.FilesMatch( layer.imageFileObj, layerData.imageFile ) )
				{
					brushes.push(layerData.Clone());
				}
				else
				{
					brushes.push(null);
				}
			}
			
			var tileMatrix:TileMatrix = Global.windowedApp.tileMatrix;
			
			for ( i = 0; i < App.getApp().tileMatrices.length; i++ )
			{
				var matrix:TileMatrixData = App.getApp().tileMatrices[i] as TileMatrixData;
				if ( Misc.FilesMatch( layer.imageFileObj, matrix.tilesetImageFile ) )
				{
					if ( tileMatrix && tileMatrix.MatrixChooser.selectedItem == matrix )
					{
						// When it's the current matrix (most likely) the saved data might not be up to date.
						matrix = new TileMatrixData();
						tileMatrix.setSavedMatrixData( matrix, false )
						matrix.name = tileMatrix.MatrixChooser.selectedLabel;
					}
					else
					{
						matrix = matrix.Clone();
					}
				}
				else
				{
					matrix = null;
				}
				matrices.push(matrix);
			}
			
			
		}
		
		override public function Undo():void
		{
			/*var bmp:BitmapData = layer.map.GetPixelData();
			
			bmp.lock();
			bmp.copyPixels( pixels, new Rectangle(0,0,pixels.width,pixels.height), new Point, null, null, false);
			bmp.unlock();*/
			var bmp:BitmapData = pixels;
			
			ImageBank.MarkImageAsChanged(layer.imageFileObj, new Bitmap(bmp));
			
			var app:App = App.getApp();
			
			for each( var layerData:LayerTiles in tileDatas )
			{
				layerData.layer.map.SetTileIdData( layerData.tileData );
				if ( tileCount < layerData.layer.map.tileCount )
				{
					layerData.layer.EraseTileIdx = Math.min(Math.max(layerData.layer.EraseTileIdx, 0), tileCount - 1);
				}
				layerData.layer.map.tileCount = tileCount;
				if ( layerData.tileAnims != null )
				{
					layerData.layer.map.tileAnims = layerData.tileAnims;
					FlxTilemapExt.sharedTileAnims[layerData.layer.imageFile] = layerData.layer.map.tileAnims;
				}
				
				layerData.layer.map.stackedTiles = layerData.stackedTiles;
				layerData.layer.map.numStackedTiles = layerData.numStackedTiles;
				layerData.layer.map.propertyList = layerData.tileProperties;
				FlxTilemapExt.sharedProperties[layerData.layer.imageFile] = layerData.layer.map.propertyList;
			}
			
			for ( var i:uint = 0; i < brushes.length; i++ )
			{
				if ( brushes[i] != null )
				{
					TileBrushesWindow.brushes[i].entry = brushes[i];
				}
			}
			if ( app.brushesWindow && app.brushesWindow.visible )
			{
				app.brushesWindow.recalcPreview();
			}
			
			var currentIndex:uint = 0;
			var tileMatrix:TileMatrix = Global.windowedApp.tileMatrix;
			if ( tileMatrix )
			{
				currentIndex = Global.windowedApp.tileMatrix.MatrixChooser.selectedIndex;
			}
			
			for ( i = 0; i < matrices.length; i++ )
			{
				var matrix:TileMatrixData = matrices[i];
				if ( matrix != null )
				{
					app.tileMatrices[i] = matrix;
					if ( tileMatrix && tileMatrix.MatrixChooser.selectedIndex == i )
					{
						tileMatrix.MatrixChooser.selectedItem = matrix;
						tileMatrix.MatrixChooser.validateNow();
						tileMatrix.ChangeMatrix();
					}
				}
			}
			
			var currentState:EditorState = FlxG.state as EditorState;
			currentState.UpdateCurrentTileList(layer);
			
		}
		
	}

}
import com.Layers.LayerMap;
import com.Tiles.TileAnim;
import flash.utils.Dictionary;
import mx.collections.ArrayCollection;

internal class LayerTiles
{
	public var layer:LayerMap;
	public var tileData:Array;
	public var tileAnims:Vector.<TileAnim> = null;
	public var tileProperties:Vector.<ArrayCollection>;
	public var stackedTiles:Dictionary = null;
	public var numStackedTiles:int = 0;
	
	public function LayerTiles( _layer:LayerMap )
	{
		layer = _layer;
		tileData = layer.map.GetTileIdDataArray()
		tileData = tileData.slice(0, tileData.length );	// Ensure we have a copy and not a reference.
		
		if ( layer.map.tileAnims != null )
		{
			tileAnims = new Vector.<TileAnim>;
			for each( var anim:TileAnim in layer.map.tileAnims )
			{
				var newAnim:TileAnim = new TileAnim;
				newAnim.CopyFrom( anim );
				tileAnims.push( newAnim );
			}
		}
		
		if ( layer.map.stackedTiles )
		{
			var oldStack:Dictionary = layer.map.stackedTiles;
			stackedTiles = new Dictionary;
			for (var key:Object in oldStack)
			{
				stackedTiles[key] = oldStack[key].Clone();
			}
			numStackedTiles = layer.map.numStackedTiles;
		}
		
		tileProperties = new Vector.<ArrayCollection>;
		for each( var prop:ArrayCollection in layer.map.propertyList )
		{
			tileProperties.push( prop );	// Just a straight copy.
		}
	}
}