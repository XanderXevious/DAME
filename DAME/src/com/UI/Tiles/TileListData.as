package com.UI.Tiles 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	/**
	 * ...
	 * @author ...
	 */
	public class TileListData 
	{
		private var _icon:BitmapData = null;
		public var metadata:Object = null;
		public var valid:Boolean = true;
		private var scaledIcon:BitmapData = null;
		private var scaleX:Number = 1;
		private var scaleY:Number = 1;
		private var cachedIcon:BitmapData = null;
		
		public function TileListData( Bmp:BitmapData, Metadata:Object ) 
		{
			_icon = Bmp;
			metadata = Metadata;
		}
		
		public function GetScaledTileData( xScale:Number, yScale:Number, smoothDraw:Boolean ):BitmapData
		{
			if ( scaledIcon!=null && cachedIcon == _icon && scaleX == xScale && scaleY == yScale )
			{
				return scaledIcon;
			}
			if ( !_icon)
			{
				return null;
			}
			var matrix:Matrix = new Matrix();
			matrix.scale( xScale, yScale );
			scaleX = xScale;
			scaleY = yScale;
			//var colorTrans:ColorTransform = showInvalidTiles && !item.valid ? new ColorTransform(0.5, 0.5, 0.5) : null;
			scaledIcon = new BitmapData(_icon.width * xScale, _icon.height * yScale, true, 0x00000000);
			scaledIcon.draw( new Bitmap(_icon), matrix, null/*colorTrans*/, null, null, smoothDraw);
			cachedIcon = _icon;
			return scaledIcon;
		}
		
		public function get icon():BitmapData
		{
			return _icon;
		}
		
		public function set icon(bmp:BitmapData):void
		{
			_icon = bmp;
			scaledIcon = null;	// force a redraw of any scales;
			cachedIcon = null;
		}
		
		
	}

}