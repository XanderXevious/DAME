package com.Layers 
{
	import com.Game.EditorAvatar;
	import com.Layers.LayerEntry;
	import com.Tiles.ImageBank;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.filesystem.File;
	import mx.collections.ArrayCollection;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LayerImage extends LayerAvatarBase
	{
		public var imageFile:File = null;
		public var sprite:EditorAvatar;
		public var opacity:Number = 1;
		
		public function LayerImage( _parent:LayerGroup, _name:String ):void
		{
			super( _parent, _name);
			_exports = false;	// default.
			sprite = new EditorAvatar(0, 0, this);
			sprites.add(sprite, true);
			properties = new ArrayCollection();
		}
		
		public function SetImage(newImageFile:File):LayerImage
		{
			ImageBank.LoadImage( newImageFile, imageLoaded, imageChangedCallback );
			ImageBank.RemoveImageRef( imageFile );
			imageFile = newImageFile;
			return this;
		}
		
		private function imageLoaded( bmp:Bitmap, file:File ):void
		{
			sprite.SetFromBitmap( bmp, bmp.width, bmp.height);
		}
		
		public function imageChangedCallback( file:File, bmp:Bitmap ):void
		{
			if ( Misc.FilesMatch( imageFile, file) )
			{
				sprite.SetFromBitmap(bmp, bmp.width, bmp.height);
			}
		}
		
		public function SetOpacity( value:Number ):void
		{
			sprite.overrideAlpha = opacity = value;
		}
		
		override public function UpdateVisibility( ):void
		{
			super.UpdateVisibility( );
			
			sprite.visible = visible && parent.visible;
		}
		
		override public function Clone( _parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry
		{
			return new LayerImage( _parent, _name).CopyData(this, copyContents);
		}
		
		override protected function CopyData(sourceLayer:LayerEntry, copyContents:Boolean):LayerEntry
		{
			sprites.remove(sprite,true);
			var sourceImageLayer:LayerImage = sourceLayer as LayerImage;
			if ( sourceImageLayer )
			{
				super.CopyData(sourceLayer, true);	// needs to copy the sprite so always copyContents for this layer type
				
				if ( sourceImageLayer.sprite )
				{
					sprite = sprites.members[0];
				}
				if ( sourceImageLayer.imageFile )
				{
					SetImage( sourceImageLayer.imageFile.clone() );
				}
				SetOpacity(sourceImageLayer.opacity);
			}
			return this;
			
		}
		
		// This is needed for the exporter
		override public function IsImageLayer():Boolean
		{
			return true;
		}
		
	}

}