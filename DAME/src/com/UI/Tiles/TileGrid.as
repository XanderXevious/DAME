package com.UI.Tiles 
{
	import com.Layers.LayerMap;
	import com.Tiles.FlxTilemapExt;
	import com.UI.Tiles.TileList;
	import com.Utils.Misc;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.display.BitmapData;
	import flash.filesystem.File;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileGrid extends TileList
	{
		private var linesBitmap:Bitmap;
		private var lines:Shape = new Shape();
		
		public var RowCount:uint;
		
		public var OnPreDragDropCallback:Function = null;
		
		public function TileGrid( wid:uint, ht:uint, numColumns:uint, numRows:uint ) 
		{
			super();
			
			contextMenu = null;
			
			linesBitmap = new Bitmap();
			addChild(linesBitmap);
			
			linesBitmap.bitmapData = new BitmapData(wid, ht,true, 0x00000000);
			TileWidth = wid / numColumns;
			TileHeight = ht / numRows;
			ColumnCount = numColumns;
			RowCount = numRows;

			for ( var i:uint = 0; i < numColumns * numRows; i++ )
			{
				var obj:TileListData = new TileListData( new BitmapData(1,1), 0);
				_data.push(obj);
			}
			Selectable = false;
		}
		
		public function Resize( numColumns:uint, numRows:uint):void
		{
			var newData:Vector.<TileListData> = new Vector.<TileListData>();
			
			TileWidth = parent.width / numColumns;
			TileHeight = parent.height / numRows;
			// Keep the tiles square shaped.
			if ( !tileOffsetX && !tileOffsetY )
			{
				TileWidth = Math.min(TileWidth, TileHeight );
				TileHeight = TileWidth;
			}
			
			
			for ( var i:uint = 0; i < numColumns * numRows; i++ )
			{
				var obj:TileListData = new TileListData( new BitmapData(1,1, true, 0), -1);
				newData.push(obj);
			}
			
			var x:uint = 0;
			var j:uint = 0;
			
			for ( i = 0; i < _data.length && j < newData.length; i++ )
			{
				if ( x < Math.min( numColumns, ColumnCount ) )
				{
					newData[j] = _data[i];
					j++;
				}
				x++;
				if ( x == ColumnCount )
				{
					x = 0;
					if ( numColumns > ColumnCount )
					{
						j += numColumns - ColumnCount;
					}
				}
			}
			
			ColumnCount = numColumns;
			RowCount = numRows;
			
			_data = newData;
			_dirty = true;
			if ( _selectedIndex > _data.length )
			{
				_selectedIndex = -1;
			}
		}
		
		override protected function onEnterFrame(event:Event):void
		{
			var doRender:Boolean = ( _dirty || isDraggingOver || wasDraggingOver );
			
			super.onEnterFrame(event);
			if ( doRender )
			{
				renderGrid();
			}
		}
		
		private function renderGrid():void
		{
			lines.graphics.clear();
			var i:uint;
			lines.graphics.lineStyle(1, 0x888888, 1);
			
			//if ( tileOffsetX || tileOffsetY )
			{
				var endxx:Number = (tSpacingX * ColumnCount) - posX;
				var endxy:Number = (tOffsetY * ColumnCount);
				
				var startX:int = (tilesStartX - tOffsetX) - posX;
				var startY:int = ( tilesStartY + (tHeight - tSpacingY) );
				if ( tileOffsetY > 0 )
				{
					startY -= tOffsetY;
				}
				if ( tileOffsetX > 0 )
				{
					startX += tOffsetX;
				}
				
				
				var currentX:int = startX;
				var currentY:int = startY;
				for ( i = 0; i <= RowCount; i++ )
				{
					lines.graphics.moveTo( currentX, currentY);
					lines.graphics.lineTo( currentX + endxx, currentY + endxy);
					currentX += tOffsetX;
					currentY += tSpacingY;
				}
				var endyx:Number = tOffsetX * RowCount;
				var endyy:Number = tSpacingY * RowCount;
				currentX = startX;
				currentY = startY;
				for ( i = 0; i <= ColumnCount; i++ )
				{
					lines.graphics.moveTo( currentX, currentY);
					lines.graphics.lineTo( currentX + endyx, currentY + endyy);
					currentX += tSpacingX;
					currentY += tOffsetY;
				}
				
				if ( isDraggingOver && _highlightIndex!=-1)
				{
					var hx:int = _highlightIndex % ColumnCount;
					var hy:int = Math.floor( _highlightIndex / ColumnCount );
					lines.graphics.lineStyle(2, 0x4400FF, 1);
					currentX = startX + ( tSpacingX * hx ) + ( tOffsetX * hy );
					currentY = startY + ( tSpacingY * hy ) + ( tOffsetY * hx );
					lines.graphics.moveTo( currentX, currentY);
					lines.graphics.lineTo( currentX + tSpacingX, currentY + tOffsetY );
					lines.graphics.lineTo( currentX + tSpacingX + tOffsetX, currentY + tOffsetY + tSpacingY );
					lines.graphics.lineTo( currentX + tOffsetX, currentY + tSpacingY );
					lines.graphics.lineTo( currentX, currentY );
				}
			}
			linesBitmap.bitmapData = new BitmapData(width, height, true, 0x00000000);
			linesBitmap.bitmapData.draw(lines);
		}
		
		public function GetMetaDataFromGridCoords(x:uint, y:uint ):Object
		{
			return _data[ ( y * ColumnCount ) + x ].metadata;
		}
		
		// Shifts tileIds up or down by 1 based on the id inserted or removed.
		public function ShiftTileIds( id:int, insert:Boolean ):void
		{
			var i:uint = _data.length;
			while ( i-- )
			{
				var intData:int = int(_data[i].metadata);
				if ( intData > id )
				{
					if ( insert )
					{
						intData++;
					}
					else
					{
						intData--;
					}
					_data[i].metadata = intData;
				}
				else if ( !insert && intData == id )
				{
					_data[i].icon = new BitmapData(1, 1);
					_data[i].metadata = -1;
					_dirty = true;
				}
			}
		}
		
		override public function OnPreDragDrop():void
		{			
			if ( OnPreDragDropCallback != null )
			{
				OnPreDragDropCallback();
			}
		}
		
		public function ReplaceImageData( tileId:int, newBmp:BitmapData ):void
		{
			var i:uint = _data.length;
			while ( i-- )
			{
				if ( _data[i].metadata == tileId )
				{
					_data[i].icon = newBmp;
					_dirty = true;
				}
			}
		}
		
		public function ReplaceAllTilesFromTilemap( map:FlxTilemapExt, allowIso:Boolean = true ):void
		{
			for ( var i:uint = 0; i < _data.length; i++ )
			{
				var tileId:int = int(_data[i].metadata);
				if( tileId < map.tileCount )
				{
					_data[i].icon = map.GetTileBitmap(tileId);
				}
				else
				{
					_data[i].icon = new BitmapData(1, 1,true,0);
				}
			}
			if ( allowIso )
			{
				if ( map.xStagger )
				{
					tileSpacingX = map.tileSpacingX / (2 * map.tileWidth );
					tileSpacingY = map.tileSpacingY / map.tileHeight;
					tileOffsetX = -map.xStagger / map.tileWidth;
					tileOffsetY = tileSpacingY;
				}
				else
				{
					tileOffsetX = map.tileOffsetX / map.tileWidth;
					tileOffsetY = map.tileOffsetY / map.tileHeight;
					tileSpacingX = map.tileSpacingX / map.tileWidth;
					tileSpacingY = map.tileSpacingY / map.tileHeight;
				}
			}
			else
			{
			}
			
			Resize(ColumnCount, RowCount);
			regenBoxes = true;
			_dirty = true;
		}
		
		public function SetTileIdForIndex( index:uint, tileId:int, bmp:BitmapData):void
		{
			_data[index].metadata = tileId;
			_data[index].icon = bmp;
			_dirty = true;
		}
		
		
		
	}

}