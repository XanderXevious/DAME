package com.Layers
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
    
	import com.Tiles.FlxTilemapExt;
	import com.Utils.GUID;
    import mx.collections.ArrayCollection;
	import org.flixel.FlxPoint;
    
    public class LayerEntry
	{
		public var properties:ArrayCollection = null;
        public var name:String;
        public var children:ArrayCollection = null;
		public var map:FlxTilemapExt;
		public var visible:Boolean;
		public var parent:LayerGroup;
		private var _xScroll:Number = 1;
		public function get xScroll():Number { return _xScroll; }
		private var _yScroll:Number = 1;
		public function get yScroll():Number { return _yScroll; }
		
		private var _locked:Boolean = false;
		public function Locked( includeParent:Boolean = true ):Boolean
		{
			return _locked || (includeParent && parent && parent.Locked() );
		}
		public function set locked(isLocked:Boolean):void
		{
			_locked = isLocked;
		}
		
		public static var entryCount:uint = 0;
		public var id:uint = 0;
		
		public var isTemplateSource:Boolean = false;
		//public var templatedBy:LayerEntry = null;
		
		protected var _exports:Boolean = true;
		public function Exports(includeParent:Boolean = true ):Boolean
		{
			if ( _exports )
			{
				if (includeParent && parent )
				{
					return parent.Exports();
				}
				else
				{
					return true;
				}
			}
			return false;
		}
		public function set exports(willExport:Boolean):void
		{
			_exports = willExport;
		}
		
        public function LayerEntry( _parent:LayerGroup, _name:String, _map:FlxTilemapExt, _children:ArrayCollection = null) : void
		{
			parent = _parent;
            name = _name;
			map = _map;
			visible = true;
			children = _children;
			
			id = entryCount;
			entryCount++;
        }
		
		public static function ResetLayerEntryIds( newValue:uint = 0):void
		{
			// Requires calling UpdateLayerEntryId on all layers;
			entryCount = newValue;
		}
		
		public function UpdateLayerEntryId():void
		{
			id = entryCount;
			entryCount++;
		}
		
		
		public function SetScrollFactors( newXScroll:Number, newYScroll:Number ) :void
		{
			_xScroll = newXScroll;
			_yScroll = newYScroll;
		}
		
		public function IsGroup():Boolean
		{
			return false;
		}
		
		public function UpdateVisibility( ):void
		{
		}
		
		public function IsVisible():Boolean
		{
			return visible && (!parent || parent.visible);
		}
		
		// Override in layers that handle this and returns a valid point if found.
		public function GetLayerCenter( ):FlxPoint { return null; }
		
		// Override in layers that handle this and returns a valid point if found.
		public function GetPreviousItemPos( currentX:Number, currentY:Number, forceSelect:Boolean ):FlxPoint { return null; }
		
		// Override in layers that handle this and returns a valid point if found.
		public function GetNextItemPos( currentX:Number, currentY:Number, forceSelect:Boolean ):FlxPoint { return null; }
		
		// To be overriden.
		public function Clone(_parent:LayerGroup, _name:String, copyContents:Boolean ):LayerEntry { return null; }
		
		// to be overriden.
		protected function CopyData(sourceLayer:LayerEntry, copyContents:Boolean ):LayerEntry
		{
			SetScrollFactors(sourceLayer._xScroll, sourceLayer._yScroll);
			_exports = sourceLayer._exports;

			if ( sourceLayer.properties )
			{
				if ( properties == null )
				{
					properties = new ArrayCollection;
				}
				for ( var i:uint = 0; i < sourceLayer.properties.length; i++ )
				{
					properties.addItem(sourceLayer.properties[i].Clone());
				}
			}
			
			UpdateVisibility();
			return this;
		}
		
		public function IsMasterLayer():Boolean { return false; }

    }
    

}