package com.Tiles 
{
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.*;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import com.UI.AlertBox;
	import com.Utils.ImageSaver;
	import flash.net.URLLoaderDataFormat;
	import com.FileHandling.images.BMPDecoder;
	import org.flixel.FlxG;
	 
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class ImageBank
	{
		private static var images:Vector.<ImageData>;
		private static var backupImages:Vector.<ImageData> = null;
		
		private static var numberOfFilesQueued:uint = 0;
		private static var hadFileError:Boolean = false;
		
		public static function Initialize():void
		{
			images = new Vector.<ImageData>();
		}
		
		public static function LoadImage( file:File, _callback:Function = null, _onChangedCallback:Function = null, _loadFailedCallback:Function = null ):void
		{
			var pattern:RegExp = /\\/g;
			//filename = filename.replace(pattern, "/" );
			
			//filename = Misc.FixMacFilePaths(filename);

			if ( file == null )
			{
				if ( _loadFailedCallback != null )
				{
					_loadFailedCallback(file);
				}
				return;
			}
		
			var i:uint = images.length;
			while( i-- )
			{
				var data:ImageData = images[i];
				if ( Misc.FilesMatch(data.file,file) )
				{
					data.refCount++;
					if ( _callback != null )
					{
						if ( data.image!=null )
						{
							_callback( data.image, data.file );
						}
						else
						{
							data.callbacks.push(_callback);
						}
					}
					if ( _onChangedCallback != null )
					{
						data.onChangedCallbacks.push(_onChangedCallback);
					}
					return;
				}
			}
			
			data = new ImageData;
			data.file = file;
			data.loadFailedCallback = _loadFailedCallback;
			data.image = null;
			data.refCount = 1;
			data.callbacks = new Vector.<Function>();
			if ( _callback != null )
			{
				data.callbacks.push(_callback);
			}
			if ( _onChangedCallback != null )
			{
				data.onChangedCallbacks.push(_onChangedCallback);
			}
			images.push( data );
			
			LoadImageData(data);
		}
		
		private static function LoadImageData( data:ImageData ):void
		{
			numberOfFilesQueued++;
			var ext:String = getExtension( data.file.url );
			var imageRequest:URLRequest = new URLRequest(data.file.url);
			
			switch( ext.toUpperCase() )
			{		
				case "BMP" :
				var loader:BMPURLLoader = new BMPURLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.addEventListener( Event.COMPLETE, imageLoaded,false,0,true);
				loader.addEventListener(IOErrorEvent.IO_ERROR, genericErrorHandler,false,0,true);
				loader.load( imageRequest );
				break;
				
				default:
				var imageLoader:Loader = new Loader();
				imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded, false, 0, true);
				imageLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, genericErrorHandler,false,0,true);
				imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, genericErrorHandler, false, 0, true);
				// Still appears to be no way of getting an error when the image loaded is too big.
				imageLoader.load(imageRequest);
				break;
			}
		}
		
		private static function getExtension( filename:String ):String
		{
			var arr:Array = filename.split(".");
			var len:uint = arr.length;
			return arr[len - 1];
		}
		
		
		private static function genericErrorHandler(event:Event):void
		{
			numberOfFilesQueued--;
			hadFileError = true;
			//AlertBox.Show("Error" + event.text, "Warning", AlertBox.OK);
			if ( numberOfFilesQueued == 0)
			{
				purgeListAndShowErrors();
			}
		}
		
		private static function EnsureImageHasAlpha(bmp:Bitmap):Bitmap
		{
			// Need to do this mainly for onion skin, as bitmaps always need alpha in them for that to work.
			var sourceBmpdata:BitmapData = bmp.bitmapData;
			bmp.bitmapData = new BitmapData( sourceBmpdata.width, sourceBmpdata.height, true, 0x00000000 );
			bmp.bitmapData.copyPixels( sourceBmpdata, sourceBmpdata.rect, new Point, null, null, true );
			return bmp;
		}
		
		private static function imageLoaded(event:Event):void
		{
			if (event.target is BMPURLLoader )
			{
				var urlloader:BMPURLLoader = event.target as BMPURLLoader;
			}
			else
			{
				var loader:Loader = Loader(event.target.loader);
			}
			
			var i:uint = images.length;
			while( i-- )
			{
				var data:ImageData = images[i];
				if ( event.target.url.indexOf( data.file.url) != -1 )
				{
					var ext:String = getExtension( data.file.url );
					if ( data.image == null )
					{
						if ( ext.toUpperCase() == "BMP" )
						{
							var decoder:BMPDecoder = new BMPDecoder();
							data.image = new Bitmap(decoder.decode( urlloader.data ));
						}
						else
						{
							data.image = event.target.content;
						}
						data.image = EnsureImageHasAlpha(data.image);
					}
					else if ( data.reloading )
					{
						if ( ext.toUpperCase() == "BMP" )
						{
							decoder = new BMPDecoder();
							data.image.bitmapData = decoder.decode( urlloader.data );
						}
						else
						{
							data.image.bitmapData = event.target.content.bitmapData;
						}
						data.image = EnsureImageHasAlpha(data.image);
						data.reloading = false;
						ImageReloaded(data);
						numberOfFilesQueued--;
						purgeListAndShowErrors();
						return;
					}
					for each( var callback:Function in data.callbacks )
					{
						callback( data.image, data.file );
					}
					data.loadFailedCallback = null;
					data.callbacks.length = 0;
					break;
				}
			}
			
			numberOfFilesQueued--;
			purgeListAndShowErrors();
			
		}
		
		public static function RemoveImageRef( file:File ):void
		{
			var i:uint;
			var data:Object;
			
			//var pattern:RegExp = /\\/g;
			//filename = filename.replace(pattern, "/" );
			
			for ( i = 0; i < images.length; i++ )
			{
				data = images[i];
				if (  Misc.FilesMatch( data.file, file ) )
				{
					data.refCount--;
					if ( data.refCount == 0 )
					{
						images.splice(i, 1);
					}
					return;
				}
			}
		}
		
		private static function purgeListAndShowErrors():void
		{
			// If there are no more files left to load and we had some errors then
			// display error messages and remove the entries from the list.
			if ( numberOfFilesQueued == 0 && hadFileError )
			{
				hadFileError = false;
				numberOfFilesQueued = 0;
				var fileError:String = "";
				var i:uint;
				var data:ImageData;
				var errorCount:uint = 0;
				for ( i = 0; i < images.length; i++ )
				{
					data = images[i];
					if ( data.image == null )
					{
						if ( data.loadFailedCallback != null )
						{
							data.loadFailedCallback( data.file );
						}
						errorCount++;
						if( errorCount <= 15 )
							fileError += "\n" + data.file.nativePath;
						trace("file error: " + data.file.nativePath);
						images.splice(i, 1);
						i -= 1;
					}
				}
				AlertBox.Show("Failed to load " + errorCount + " images: " + fileError, "Warning", AlertBox.OK);
			}
		}
		
		public static function ReloadImageFile( file:File, reloadCallback:Function = null ):void
		{
			//var pattern:RegExp = /\\/g;
			//filename = filename.replace(pattern, "/" );
			//filename = Misc.FixMacFilePaths(filename);
			
			var i:uint = images.length;
			while ( i-- )
			{
				if ( Misc.FilesMatch(images[i].file,file) )
				{
					images[i].reloading = true;
					images[i].reloadCallback = reloadCallback;
					LoadImageData(images[i]);
					return;
				}
			}
		}
		
		private static function ImageReloaded(data:ImageData):void
		{
			MarkImageAsChanged(data.file, data.image, false);
			if ( data.reloadCallback != null )
			{
				data.reloadCallback( data.file, data.image );
			}
			data.changed = false;
		}
		
		public static function MarkImageAsChanged( file:File, newBitmap:Bitmap, saveFile:Boolean = false ):Boolean
		{			
			var i:uint = images.length;
			while ( i-- )
			{
				if ( Misc.FilesMatch(images[i].file,file) )
				{
					images[i].image = newBitmap;
					images[i].changed = true;
					var j:uint = images[i].onChangedCallbacks.length;
					while ( j-- )
					{
						images[i].onChangedCallbacks[j]( file, newBitmap );
					}
					if ( saveFile )
					{
						ImageSaver.Save( images[i].image.bitmapData, images[i].file );
					}
					return true;
				}
			}
			return false;
		}
		
		public static function MarkImageAsChangedMarkOnly( file:File ):void
		{			
			var i:uint = images.length;
			while ( i-- )
			{
				if ( Misc.FilesMatch(images[i].file,file) )
				{
					images[i].changed = true;
					return;
				}
			}
		}
		
		public static function CreateNewImage( file:File, image:Bitmap ):void
		{
			if ( MarkImageAsChanged(file, image, true) )
			{
				return;
			}
			//var pattern:RegExp = /\\/g;
			//filename = filename.replace(pattern, "/" );
			//filename = Misc.FixMacFilePaths(filename);
			
			ImageSaver.Save( image.bitmapData, file );
			
			var data:ImageData = new ImageData;
			data.file = file;
			data.image = image;
			data.refCount = 1;
			data.callbacks = new Vector.<Function>();
			images.push( data );
		}
		
		public static function SaveChangedImages():void
		{
			var i:uint = images.length;
			while ( i-- )
			{
				if ( images[i].changed )
				{
					ImageSaver.Save( images[i].image.bitmapData, images[i].file );
					images[i].changed = false;
				}
			}
		}
		
		public static function Clear( backup:Boolean = false ):void
		{
			if ( backup )
			{
				if ( backupImages == images )
				{
					return;
				}
				var newImages:Vector.<ImageData> = images;
				images = backupImages;
			}
			var i:uint = images.length;
			while ( i-- )
			{
				if ( images[i].image &&  images[i].image.bitmapData )
				{
					images[i].image.bitmapData.dispose();
				}
				if ( !backup )
				{
					FlxG.removeCachedBitmap( images[i].file.nativePath );
				}
			}
			images.length = 0;
			if ( backup)
			{
				backupImages = null;
				images = newImages;
			}
		}
		
		public static function BackUp():void
		{
			backupImages = images;
		}
		
		public static function RestoreBackup():void
		{
			if ( backupImages != images )
			{
				Clear();
				images = backupImages;
				backupImages = null;
			}
			
		}
		
	}

}
import flash.display.Bitmap;
import flash.filesystem.File;
import flash.net.URLStream;
import flash.net.URLVariables;
import flash.utils.ByteArray;

internal class ImageData
{
	public var changed:Boolean = false;
	public var file:File;
	public var refCount:uint = 1;
	public var image:Bitmap;
	public var callbacks:Vector.<Function>;
	public var onChangedCallbacks:Vector.<Function> = new Vector.<Function>();
	public var reloading:Boolean = false;
	public var reloadCallback:Function = null;
	public var loadFailedCallback:Function = null;
}

// BMPURLLoader needed as we can't determine the url from Event.Complete callbacks with URLLoader.
import flash.events.EventDispatcher;
import flash.net.URLRequest;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;

internal class BMPURLLoader extends EventDispatcher
{     
    private var _urlRequest:URLRequest; //the built-in URLLoader doesn't give you any access to the requested URL...
    private var _stream:URLStream;
    public var dataFormat:String;// = "text"
    private var _data:*;
    private var _bytesLoaded:uint;// = 0
    private var _bytesTotal:uint;// = 0
	
	public function get url():String { return _urlRequest.url;}

    public function get request():URLRequest { return _urlRequest;}     
    public function get fileName():String { return _urlRequest.url.match(/(?:\\|\/)([^\\\/]*)$/)[1];}       
    //public function get dataFormat():String { return _dataFormat;}      
    public function get data():* { return _data; }      
    public function get bytesLoaded():uint { return _bytesLoaded; }     
    public function get bytesTotal():uint { return _bytesTotal; }       

    public function BMPURLLoader(request:URLRequest = null)
	{
        super();
        _stream = new URLStream();
        _stream.addEventListener(Event.OPEN, openHandler,false,0,true);
        _stream.addEventListener(ProgressEvent.PROGRESS, progressHandler,false,0,true);
        _stream.addEventListener(Event.COMPLETE, completeHandler,false,0,true);
        _stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler,false,0,true);
        _stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler,false,0,true);
        _stream.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler,false,0,true);
        if (request != null){
            load(request);
        };
    }
    public function load(request:URLRequest):void {
        _urlRequest = request;
        _stream.load(_urlRequest);
    }
    public function close():void{
        _stream.close();
    }

    private function progressHandler(event:ProgressEvent):void {
        _bytesLoaded = event.bytesLoaded;
        _bytesTotal = event.bytesTotal;
        dispatchEvent(event);
    }
    private function completeHandler(event:Event):void{
        var bytes:ByteArray = new ByteArray();
        _stream.readBytes(bytes);
        switch (dataFormat){
            case "binary":
                _data = bytes;
                break;
            case "variables":
                if (bytes.length > 0){
                    _data = new URLVariables(bytes.toString());
                    break;
                };
            case "text":
            default:
                _data = bytes.toString();
                break;
        };
        trace("URLLoader: (" + fileName + "): " + event.type);
        dispatchEvent(event);
    }
    private function openHandler(event:Event):void {
        trace("URLLoader: ("+fileName+"): " + event.type +" "+_urlRequest.url);
         dispatchEvent(event);
    }
    private function securityErrorHandler(event:SecurityErrorEvent):void {
        trace("URLLoader ("+fileName+"): " + event.type + " - " + event.text);
        dispatchEvent(event);
    }
    private function httpStatusHandler(event:HTTPStatusEvent):void {          
        dispatchEvent(event);
    }   
    private function ioErrorHandler(event:IOErrorEvent):void {
         trace("URLLoader ("+fileName+"): " + event.type + " - " + event.text);
        dispatchEvent(event);
    }       
}
