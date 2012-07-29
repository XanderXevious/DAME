package com.Tiles
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
    
	import com.EditorState;
	import com.Game.SpriteFrames.SpriteFrameShapes;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
    import mx.collections.ArrayCollection;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import org.flixel.FlxRect;
    
    public class SpriteEntry
	{
        public var name:String;
		public var className:String;
		public var creationText:String = "";
		public var constructorText:String;
		public var bitmap:Bitmap;
		public var previewBitmap:Bitmap;
		public var previewIndex:uint = 0;
		public var tilePreviewIndex:int = -1;
        public var children:ArrayCollection = null;
		
		public var IsTileSprite:Boolean = false;
		public var TileOrigin:FlxPoint = new FlxPoint(0, 0);
		
		public var Exports:Boolean = true;
		public var CanScale:Boolean = true;
		public var CanRotate:Boolean = true;
		public var IsSurfaceObject:Boolean = false;	// used for Iso aligned sprites only.
		
		public var numFrames:uint = 1;	// Only ever a guess as we don't know if a frame is empty or not.
		
		// Corresponds to the offset and width/height value in flixel - the position and dimensions of the boundingbox.
		public var Bounds:FlxRect = new FlxRect(0, 0, 1, 1);
		// The offset that dictates where attachments are made from and whatever else you want to handle.
		public var Anchor:FlxPoint = new FlxPoint(0, 0);
		public var CenterAnchor:Boolean = false;
		
		private var _imageFile:File = null;
		public function get imageFile():File { return _imageFile; }
		
		public var properties:ArrayCollection = new ArrayCollection();
		
		private static var entryCount:uint = 0;
		public static function GetEntryCount():uint { return entryCount; }
		// Quick reference id.
		public var id:uint = 0;
		
		private var customCallback:Function = null;
		private var callbackData:Object = null;
		
		// If set then any sprites that update their sprite entry shouldn't update dimensions.
		public var dontRefreshSpriteDims:Boolean = false;
		
		public var anims:Vector.<TileAnim> = new Vector.<TileAnim>;
		
		public var shapes:SpriteFrameShapes = new SpriteFrameShapes;
		
        public function SpriteEntry( _name:String, _children:ArrayCollection = null) : void
		{
            name = _name;
			className = "";
			children = _children;
			bitmap = null;
			previewBitmap = null;
			
			id = entryCount;
			entryCount++;
		}
		
		public static function ResetSpriteEntryIds( newValue:uint = 0):void
		{
			// Requires updating;
			entryCount = newValue;
		}
		
		public function UpdateSpriteEntryId():void
		{
			id = entryCount;
			entryCount++;
		}
		
		public function LoadBitmap( newImageFile:File ): SpriteEntry
		{
			ImageBank.LoadImage( newImageFile, imageLoaded, imageChangedCallback );
			ImageBank.RemoveImageRef( _imageFile );
			
			_imageFile = newImageFile;
			
			return this;
        }
		
		public function imageChangedCallback( file:File, _bmp:Bitmap ):void
		{
			if ( Misc.FilesMatch(_imageFile, file) )
			{
				bitmap = _bmp;
				//previewBitmap = _bmp;
				if ( IsTileSprite )
					recalcTiledBitmapPreview();
				else
					recalcBitmapPreview();
				
				App.getApp().spriteData.itemUpdated(this);
				
				var currentState:EditorState = FlxG.state as EditorState;
				if ( currentState )
				{
					currentState.RefreshSpriteGraphicsAndProperties( this );
				}
			}
		}
		
		private function recalcTiledBitmapPreview( ):void
		{
			var sourceRect:Rectangle = new Rectangle( TileOrigin.x, TileOrigin.y, previewBitmap.width, previewBitmap.height);
			var flashPoint:Point = new Point(0, 0);

			previewBitmap = new Bitmap( new BitmapData( previewBitmap.width, previewBitmap.height,true,0xffffff) );
			previewBitmap.bitmapData.copyPixels( bitmap.bitmapData, sourceRect, flashPoint );
		}
		
		private function recalcBitmapPreview( ):void
		{
			var numRows:uint = Math.ceil( bitmap.height / previewBitmap.height );
			var numColumns:uint = Math.ceil( bitmap.width / previewBitmap.width );
			
			var currentRow:uint = previewIndex / numColumns;
			var currentColumn:uint = previewIndex % numColumns;
				
			var sourceRect:Rectangle = new Rectangle( currentColumn * previewBitmap.width, currentRow * previewBitmap.height, 1, 1);
			var flashPoint:Point = new Point(0, 0);

			sourceRect.width = previewBitmap.width;
			sourceRect.height = previewBitmap.height;
			previewBitmap = new Bitmap( new BitmapData( previewBitmap.width, previewBitmap.height,true,0xffffff) );
			previewBitmap.bitmapData.copyPixels( bitmap.bitmapData, sourceRect, flashPoint );
		}
		
		public function SetImageFileNoLoad( _file:File):SpriteEntry
		{
			_imageFile = _file;
			return this;
		}
		
		public function SetImageFile( _file:File, _callback:Function=null, _callbackData:Object=null, _loadFailCallback:Function=null ):SpriteEntry
		{
			customCallback = _callback;
			callbackData = _callbackData;
			ImageBank.LoadImage( _file, imageLoadedCustomCallback,imageChangedCallback,_loadFailCallback );
			ImageBank.RemoveImageRef( imageFile );
			_imageFile = _file;
			return this;
		}
		
		private function imageLoadedCustomCallback( data:Bitmap, path:String ):void
		{
			bitmap = data;
			previewBitmap = data;
			
			if ( customCallback != null )
			{
				customCallback( this, callbackData );
				callbackData = null;
				customCallback = null;
			}
		}
		
		private function imageLoaded( data:Bitmap, path:String ):void
		{
			// Cope with the possibility of this data already being set
			Bounds.x = Math.min( Bounds.x, data.width - 1 );
			Bounds.y = Math.min( Bounds.y, data.height - 1 );
			Bounds.width = data.width - Bounds.x;
			Bounds.height = data.height - Bounds.y;
			
			bitmap = data;
			previewBitmap = data;
		}
		
		public function isSprite():Boolean
		{
			return children == null;// bitmap != null;
		}
		
		public function SetBitmap( _bitmap:Bitmap ):SpriteEntry
		{
			bitmap = _bitmap;
			return this;
		}
		
		public function SetPreviewBitmap( _bitmap:Bitmap ):SpriteEntry
		{
			previewBitmap = _bitmap;
			return this;
		}
		
		public function SetPreviewIndex( _index:uint ):SpriteEntry
		{
			previewIndex = _index;
			return this;
		}
		
		public function SetClassName( _class:String ):SpriteEntry
		{
			className = _class;
			return this;
		}
		
		public function SetConstructorText( _text:String ):SpriteEntry
		{
			constructorText = _text;
			return this;
		}
		
		public function SetCreationText( _text:String ):SpriteEntry
		{
			creationText = _text;
			return this;
		}
		
		public function FindMatch( entry:SpriteEntry ):SpriteEntry
		{
			if ( children )
			{
				var i:uint = children.length;
				while ( i-- )
				{
					var foundSprite:SpriteEntry = children[i].FindMatch( entry );
					if( foundSprite )
					{
						return foundSprite;
					}
				}
			}
			else if( Matches( entry ) )
			{
				return this;
			}
			return null;
		}
		
		public function Matches( entry:SpriteEntry ):Boolean
		{
			if ( entry.children && entry.children.length )
			{
				return false;
			}
			return ( name == entry.name &&
					className == entry.className &&
					(_imageFile == entry.imageFile || _imageFile.nativePath == entry._imageFile.nativePath ) &&
					TileOrigin.equals( entry.TileOrigin ) &&
					Anchor.equals( entry.Anchor ) &&
					Bounds.equals( entry.Bounds ) &&
					previewIndex == entry.previewIndex
			);
		}
		
		public function get DisplayName():String
		{
			return ( name && name.length ) ? name : className; 
		}

    }
    

}
