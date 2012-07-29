package com.Layers 
{
	import com.Tiles.ImageBank;
	import com.Properties.PropertyType;
	import com.Tiles.StackTileInfo;
	import com.Tiles.TileAnim;
	import com.Utils.DebugDraw;
	import com.Utils.Global;
	import com.Utils.Misc;
	import com.Utils.WeakReference;
	import flash.display.Bitmap;
	import com.Tiles.FlxTilemapExt;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import org.flixel.FlxPoint;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerMap extends LayerEntry
	{
		public static const TileType2d:String = "2d";
		public static const TileTypeDiamond:String = "Diamond";
		public static const TileTypeStaggeredDiamond:String = "Staggered Diamond";
		public static const TileTypeSkewRight:String = "Skew Right";
		public static const TileTypeSkewLeft:String = "Skew Left";
		public static const TileTypeSkewUp:String = "Skew Up";
		public static const TileTypeSkewDown:String = "Skew Down";
		public static const TileTypeCustom:String = "Custom Iso";
		
		// These values only used for determining the type of UI to display.
		public var tilemapType:String = TileType2d;
		public var hasHeight:Boolean = false;
			
		public var mapFile:File = null;
		private var _imageFile:File = null;
		public function get imageFile():String { return _imageFile ? _imageFile.nativePath : ""; }
		public function get imageFileObj():File { return _imageFile; }
		
		private var mapData:String = "";
		public var imageData:Bitmap = null;
		
		public var tileWidth:uint;
		public var tileHeight:uint;
		
		public var HasHits:Boolean = false;
		private var masterLayer:Boolean = false;
		
		//public var SelectedTileIdx:uint = 0;
		public var EraseTileIdx:uint = 0;
		
		public var ImageLoadedCallback:Function = null;
		
		public function LayerMap( _parent:LayerGroup, _name:String ):void
		{
			super( _parent, _name, null, null);
			properties = new ArrayCollection();
		}
		
		public function LoadMap( _mapFile:File, newImageFile:File, _tileWidth:uint, _tileHeight:uint ):LayerMap
		{
			map = new FlxTilemapExt();
			mapFile = _mapFile;// mapFile = Misc.FixMacFilePaths(_mapFile);
			tileWidth = _tileWidth;
			tileHeight = _tileHeight;
			
			ImageBank.LoadImage( newImageFile, imageLoaded, imageChangedCallback );
			ImageBank.RemoveImageRef( _imageFile );
			_imageFile = newImageFile;
			
			var urlRequest:URLRequest = new URLRequest(_mapFile.url);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT; // default
			urlLoader.addEventListener(Event.COMPLETE, urlLoader_complete,false,0,false);
			urlLoader.load(urlRequest);
			 
			function urlLoader_complete(event:Event):void
			{
				mapData = urlLoader.data;
				if ( imageData != null )
				{
					createMap();
				}
			}
			return this;
		}
		
		public function CreateEmptyMap( newImageFilename:String, _tileWidth:uint, _tileHeight:uint, _width:uint, _height:uint, tileSpacingX:uint, tileSpacingY:uint, xStagger:int, tileOffsetX:int, tileOffsetY:int ):LayerMap
		{
			map = new FlxTilemapExt();
			map.width = _width;
			map.height = _height;
			mapFile = null;//"";
			tileWidth = _tileWidth;
			tileHeight = _tileHeight;
			map.tileSpacingX = tileSpacingX;
			map.tileSpacingY = tileSpacingY;
			map.xStagger = xStagger;
			map.tileOffsetX = tileOffsetX;
			map.tileOffsetY = tileOffsetY;
			
			mapData = new String();
			var emptyRow:String = new String("0");
			var i:uint;
			for ( i = 1; i < _width; i++ )
			{
				emptyRow += ",0";
			}
			for ( i = 0; i < _height; i++ )
			{
				mapData += emptyRow + "\n";
			}
			
			var newImageFile:File = new File(newImageFilename);
			
			// Must load the image after we set the mapData in case the callback fires instantly.
			ImageBank.LoadImage( newImageFile, imageLoaded, imageChangedCallback );
			ImageBank.RemoveImageRef( _imageFile );
			_imageFile = newImageFile;
			 
			return this;
		}
		
		public function CreateMapFromString( newImageFile:File, mapString:String, _tileWidth:uint, _tileHeight:uint, tileSpacingX:uint, tileSpacingY:uint, xStagger:int, tileOffsetX:int, tileOffsetY:int ):LayerMap
		{
			map = new FlxTilemapExt();
			mapFile = null;// "";
			tileWidth = _tileWidth;
			tileHeight = _tileHeight;
			map.tileSpacingX = tileSpacingX;
			map.tileSpacingY = tileSpacingY;
			map.xStagger = xStagger;
			map.tileOffsetX = tileOffsetX;
			map.tileOffsetY = tileOffsetY;
			
			mapData = mapString;
			
			// Must load the image after we set the mapData in case the callback fires instantly.
			ImageBank.LoadImage( newImageFile, imageLoaded, imageChangedCallback, imageLoadFailed );
			ImageBank.RemoveImageRef( _imageFile );
			_imageFile = newImageFile;
			 
			return this;
		}
		
		public function SetTilesetImageFile( newImageFile:File ):void
		{
			if ( !Misc.FilesMatch(newImageFile, _imageFile ) )
			{
				if ( imageData == null )
				{
					ImageBank.LoadImage( newImageFile, imageLoaded, imageChangedCallback );
				}
				else
				{
					ImageBank.LoadImage( newImageFile, imageLoadedForChange, imageChangedCallback );
				}
				ImageBank.RemoveImageRef( _imageFile );
				_imageFile = newImageFile;
			}
		}
		
		private function imageLoadedForChange( data:Bitmap, file:File ):void
		{
			imageData = data;
			if ( map )
			{
				map.changeMapGraphic( data.bitmapData );
			}
			if ( ImageLoadedCallback != null )
			{
				ImageLoadedCallback( this );
			}
		}
		
		private function imageLoaded( data:Bitmap, file:File ):void
		{
			imageData = data;
			if ( mapData != null )
			{
				createMap();
			}
			if ( map.desiredAlpha < 1 )
			{
				map.setAlpha(map.desiredAlpha, true);
			}
			if ( ImageLoadedCallback != null )
			{
				ImageLoadedCallback( this );
			}
		}
		
		private function imageLoadFailed(file:File):void
		{
			if ( imageData == null )
			{
				imageData = new Bitmap( new BitmapData( tileWidth, tileHeight ) );
			}
			if ( mapData != null )
			{
				createMap();
			}
		}
		
		private function createMap():void
		{
			//map.drawIndex = 0;
			map.loadExternalMap( mapData, imageData.bitmapData, tileWidth, tileHeight );
			DebugDraw.singleton.HasCachedShape = false;	// force a refresh
		}
		
		public function imageChangedCallback( file:File, _bmp:Bitmap ):void
		{
			if ( Misc.FilesMatch(_imageFile, file) )
			{
				imageData = _bmp;
				map.RefreshPixelData();
				// Need this so that I can reload the tile image file if needed.
				map.changeMapGraphic(_bmp.bitmapData, map.tileWidth, map.tileHeight);
				if ( map.desiredAlpha < 1 )
				{
					map.setAlpha(map.desiredAlpha, true);
				}
			}
		}
		
		override public function UpdateVisibility( ):void
		{
			super.UpdateVisibility( );
			map.visible = visible && ( parent==null || parent.visible );
		}
		
		override public function SetScrollFactors( newXScroll:Number, newYScroll:Number ) :void
		{
			super.SetScrollFactors( newXScroll, newYScroll );
			
			if ( map != null )
			{
				map.scrollFactor.x = newXScroll;
				map.scrollFactor.y = newYScroll;
			}
		}
		
		override public function GetLayerCenter( ):FlxPoint
		{
			return new FlxPoint( map.x + (map.width / 2 ), map.y + (map.height / 2 ) );
		}
		
		override public function Clone( _parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry
		{
			return new LayerMap( _parent, _name).CopyData(this, copyContents);
		}
		
		override protected function CopyData(sourceLayer:LayerEntry, copyContents:Boolean):LayerEntry
		{
			var sourceMapLayer:LayerMap = sourceLayer as LayerMap;
			if ( sourceMapLayer )
			{
				var tiles:Array = sourceLayer.map.GetTileIdDataArray();
				var wid:uint = sourceLayer.map.widthInTiles;
				var ht:uint = sourceLayer.map.heightInTiles;
				mapData = "";
				if ( copyContents )
				{
					for ( var y:uint = 0; y < ht; y++ )
					{
						var rowIndex:uint = y * wid;
						var row:String = "";
						if ( ht > 1 )
						{
							row += tiles[rowIndex];
						}
						var tileIndex:uint = rowIndex+1;
						for ( var x:uint = 1; x < wid; x++ )
						{
							row += "," + tiles[tileIndex];
							tileIndex++;
						}
						mapData += row + "\n";
					}
				}
				else
				{
					for ( y = 0; y < ht; y++ )
					{
						rowIndex = y * wid;
						row = "";
						if ( ht > 1 )
						{
							row += "0";
						}
						tileIndex = rowIndex+1;
						for ( x = 1; x < wid; x++ )
						{
							row += ",0";
							tileIndex++;
						}
						mapData += row + "\n";
					}
				}
				_imageFile = sourceMapLayer._imageFile.clone();
				CreateMapFromString( _imageFile , mapData, sourceMapLayer.map.tileWidth, sourceMapLayer.map.tileHeight, sourceMapLayer.map.tileSpacingX, sourceMapLayer.map.tileSpacingY, sourceMapLayer.map.xStagger, sourceMapLayer.map.tileOffsetX, sourceMapLayer.map.tileOffsetY );

				map.x = sourceMapLayer.map.x;
				map.y = sourceMapLayer.map.y;
				map.repeatingX = sourceMapLayer.map.repeatingX;
				map.repeatingY = sourceMapLayer.map.repeatingY;
				HasHits = sourceMapLayer.HasHits;
				hasHeight = sourceMapLayer.hasHeight;
				map.collideIndex = sourceMapLayer.map.collideIndex;
				EraseTileIdx = sourceMapLayer.EraseTileIdx;
				map.UpdateDrawIndex(sourceMapLayer.map.drawIndex);
				map.repeatingX = sourceMapLayer.map.repeatingX;
				map.repeatingY = sourceMapLayer.map.repeatingY;
				tilemapType = sourceMapLayer.tilemapType;
				if ( sourceMapLayer.map.tileAnims )
				{
					map.tileAnims = new Vector.<TileAnim>;
					for each( var anim:TileAnim in sourceMapLayer.map.tileAnims )
					{
						var newAnim:TileAnim = new TileAnim;
						newAnim.CopyFrom(anim);
						map.tileAnims.push(newAnim);
					}
				}
				if ( sourceMapLayer.map.stackedTiles && copyContents)
				{
					map.numStackedTiles = sourceMapLayer.map.numStackedTiles;
					map.stackHeight = sourceMapLayer.map.stackHeight;
					map.highestStack = sourceMapLayer.map.highestStack;
					map.stackedTiles = new Dictionary;
					for (var key:Object in sourceMapLayer.map.stackedTiles)
					{
						var tileInfo:StackTileInfo = sourceMapLayer.map.stackedTiles[key];
						map.stackedTiles[key] = tileInfo.Clone();
					}
				}
			}

			super.CopyData(sourceLayer, copyContents);
			return this;
		}
		
		override public function IsMasterLayer():Boolean
		{
			return masterLayer;
		}
		
		public function SetMasterLayer( isMaster:Boolean ):void
		{
			if ( isMaster )
			{
				for each (var layer:LayerEntry in parent.children )
				{
					var mapLayer:LayerMap = layer as LayerMap;
					if ( mapLayer )
					{
						mapLayer.SetMasterLayer(false);
					}
				}
			}
			masterLayer = isMaster;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		public function GetTileProperties():Vector.<ArrayCollection>
		{
			if ( SharesTileProperties() )
				return FlxTilemapExt.sharedProperties[imageFile];
			else
				return map.propertyList;
		}
		
		public function SharesTileProperties():Boolean
		{
			return FlxTilemapExt.sharedProperties[imageFile] != null;
		}
		
		public function SetSharesTileProperties(share:Boolean):void
		{
			if ( share )
			{
				// even if it was already shared, ensure we're pointing to the correct data.
				FlxTilemapExt.sharedProperties[imageFile] = map.propertyList;
			}
			else if ( !share && SharesTileProperties())
			{
				// about to unshare = properties are now copied from current share for all similar layers
				var app:App = App.getApp();
				var propList:Vector.<ArrayCollection> = CopyTileProperties( FlxTilemapExt.sharedProperties[imageFile] );
				if ( propList && propList.length )
				{
					for each( var group:LayerGroup in app.layerGroups )
					{
						for each( var layer:LayerEntry in group.children )
						{
							var mapLayer:LayerMap = layer as LayerMap;
							
							if ( mapLayer && mapLayer.imageFile == imageFile )
							{
								mapLayer.map.propertyList = CopyTileProperties(propList);
							}
						}
					}
				}
				FlxTilemapExt.sharedProperties[imageFile] = null;
			}
		}
		
		private function CopyTileProperties( sourceList:Vector.<ArrayCollection> ):Vector.<ArrayCollection>
		{
			if ( sourceList == null )
			{
				return null;
			}
			var propertyList:Vector.<ArrayCollection> = new Vector.<ArrayCollection>;
			for ( var i:int = 0; i < sourceList.length; i++ )
			{
				var oldList:ArrayCollection = sourceList[i] as ArrayCollection;
				if ( oldList )
				{
					var newList:ArrayCollection = new ArrayCollection;
					propertyList.push(newList);
					for ( var j:int = 0; j < oldList.length; j++)
					{
						var propType:PropertyType = oldList[j] as PropertyType;
						if ( propType )
						{
							newList.addItemAt( propType.Clone(), newList.length );
						}
					}
				}
				else
				{
					propertyList.push( null );
				}
			}
			return propertyList;
		}
		
		//////////////////////////////////////////////////////////////////
		
		public function GetTileAnims():Vector.<TileAnim>
		{
			if ( SharesTileAnims() )
				return FlxTilemapExt.sharedTileAnims[imageFile];
			else
				return map.tileAnims;
		}
		
		public function SharesTileAnims():Boolean
		{
			return FlxTilemapExt.sharedTileAnims[imageFile] != null;
		}
		
		public function SetSharesTileAnims(share:Boolean):void
		{
			if ( share )
			{
				// even if it was already shared, ensure we're pointing to the correct data.
				FlxTilemapExt.sharedTileAnims[imageFile] = map.tileAnims;
			}
			else if ( !share && SharesTileAnims())
			{
				var oldtileAnims:Vector.<TileAnim> = CopyTileAnims( GetTileAnims() );
				var app:App = App.getApp();
				if ( oldtileAnims )
				{
					for each( var group:LayerGroup in app.layerGroups )
					{
						for each( var layer:LayerEntry in group.children )
						{
							var mapLayer:LayerMap = layer as LayerMap;
							
							if ( mapLayer && mapLayer.imageFile == imageFile )
							{
								mapLayer.map.tileAnims = CopyTileAnims(oldtileAnims);
							}
						}
					}
				}
				FlxTilemapExt.sharedTileAnims[imageFile] = null;
			}
		}
		
		private function CopyTileAnims( sourceList:Vector.<TileAnim> ):Vector.<TileAnim>
		{
			if ( sourceList == null )
			{
				return null;
			}
			var tileAnims:Vector.<TileAnim> = new Vector.<TileAnim>;
			for each( var anim:TileAnim in sourceList )
			{
				var newAnim:TileAnim = new TileAnim;
				newAnim.CopyFrom(anim);
				tileAnims.push(newAnim);
			}
			return tileAnims;
		}
		
		public function NumberOfTileAnims():uint
		{
			if ( map.tileAnims )
			{
				return map.tileAnims.length;
			}
			return 0;
		}
	}

}
