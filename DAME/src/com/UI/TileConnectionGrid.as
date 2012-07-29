package com.UI 
{
	import com.Editor.EditorTypeTileMatrix;
	import com.EditorState;
	import com.Tiles.TileConnectionList;
	import com.Tiles.TileConnections;
	import com.UI.Tiles.TileGrid;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.flixel.FlxG;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileConnectionGrid extends TileGrid
	{
		protected var shapesBitmap:Bitmap;
		private var shapes:Shape = new Shape();
		
		private var connections:TileConnectionList = null;
		public function set Connections(_connections:TileConnectionList):void
		{
			connections = _connections;
			_dirty = true;
			_dirtyThisFrame = true;
		}
		
		public function get Connections():TileConnectionList { return connections; }
		
		public function TileConnectionGrid( wid:uint, ht:uint, numColumns:uint, numRows:uint, _connections:TileConnectionList ) 
		{
			super(wid, ht, numColumns, numRows);
			
			shapesBitmap = new Bitmap();
			addChild(shapesBitmap);
			
			shapesBitmap.bitmapData = new BitmapData(wid, ht, true, 0x00000000);
			connections = _connections;
		}
		
		override protected function onEnterFrame(event:Event):void
		{			
			super.onEnterFrame(event);
			
			if ( connections )
			{
				for ( var i:uint = 0; i < connections.tiles.length; i++ )
				{
					if ( connections.tiles[i].lastChanged + 1 == EditorState.FrameNum )
					{
						_dirtyThisFrame = true;
					}
				}
			}
			
			if ( _dirtyThisFrame || isDraggingOver || wasDraggingOver )
			{
				renderGrid();
			}
		}
		
		private function renderGrid():void
		{			
			var i:uint;
			var wid:uint = ColumnCount * TileWidth;
			var ht:uint = RowCount * TileHeight;
			var edgeWidth:Number = TileWidth / 5;
			var edgeHeight:Number = TileHeight / 5;
			var radius:Number = edgeWidth / 2.3;
			
			shapes.graphics.clear();
			if ( connections == null )
			{
				return;
			}
			
			shapes.graphics.lineStyle(1, 0x000000, 1, true);
			
			for ( var y:uint = 0; y < ht; y += TileHeight )
			{
				for ( var x:uint = 0; x < wid && i < connections.tiles.length; x += TileWidth )
				{
					// Top left
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.TOP_LEFT, connections.tiles[i].RedTiles & TileConnections.TOP_LEFT, false );
					shapes.graphics.drawRoundRectComplex(x, y, edgeWidth, edgeHeight, 0, 0, 0, radius);
					
					// Top middle
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.TOP_CENTER, connections.tiles[i].RedTiles & TileConnections.TOP_CENTER, true );
					shapes.graphics.drawRoundRectComplex(x + (edgeWidth * 2), y, edgeWidth, edgeHeight, 0, 0, radius, radius);
					
					// Top right
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.TOP_RIGHT, connections.tiles[i].RedTiles & TileConnections.TOP_RIGHT, true );
					shapes.graphics.drawRoundRectComplex(x + (edgeWidth*4), y, edgeWidth, edgeHeight, 0, 0, radius, 0);
				
					// middle left
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.MID_LEFT, connections.tiles[i].RedTiles & TileConnections.MID_LEFT, true );
					shapes.graphics.drawRoundRectComplex(x, y + (edgeHeight*2), edgeWidth, edgeHeight, 0, radius, 0, radius);
				
					// middle right
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.MID_RIGHT, connections.tiles[i].RedTiles & TileConnections.MID_RIGHT, true );
					shapes.graphics.drawRoundRectComplex(x + (edgeWidth*4), y + (edgeHeight*2), edgeWidth, edgeHeight, radius, 0, radius, 0);
			
					// Bottom left
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.BOTTOM_LEFT, connections.tiles[i].RedTiles & TileConnections.BOTTOM_LEFT, true );
					shapes.graphics.drawRoundRectComplex(x, y + (edgeHeight*4), edgeWidth, edgeHeight, 0, radius, 0, 0);
				
					// Bottom middle
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.BOTTOM_CENTER, connections.tiles[i].RedTiles & TileConnections.BOTTOM_CENTER, true );
					shapes.graphics.drawRoundRectComplex(x + (edgeWidth*2), y + (edgeHeight*4), edgeWidth, edgeHeight, radius, radius, 0, 0);
				
					// Bottom right
					DrawConnection( highlightIndex == i, connections.tiles[i].GreenTiles & TileConnections.BOTTOM_RIGHT, connections.tiles[i].RedTiles & TileConnections.BOTTOM_RIGHT, true );
					shapes.graphics.drawRoundRectComplex(x + (edgeWidth*4), y + (edgeHeight*4), edgeWidth, edgeHeight, radius, 0, 0, 0);
				
					shapes.graphics.endFill();
					i++;
				}
			}
			
			shapesBitmap.bitmapData = new BitmapData(width, height, true, 0x00000000);
			shapesBitmap.bitmapData.draw(shapes);
		}
		
		private function DrawConnection(highlighted:Boolean, green:uint, red:uint, endPrevious:Boolean ):void
		{
			if ( endPrevious )
			{
				shapes.graphics.endFill();
			}

			var fillColor:uint = green ? 0x00ff00 : 0xff0000;
			if ( highlighted )
			{
				shapes.graphics.lineStyle(1, 0x000000, 1, true);
				if ( green || red )
					shapes.graphics.beginFill(fillColor, 0.8);
			}
			else
			{
				shapes.graphics.lineStyle(1, 0x000000, 0.1, true);
				if ( green || red )
					shapes.graphics.beginFill(fillColor, 0.05);
			}
		}
		
		private function changeNode():Boolean
		{
			var mx:int = MouseX;
			var my:int = MouseY;
			if ( mx < 0 || my < 0 || mx >= width || my >= height )
			{
				return false;
			}
			
			if ( !connections )
			{
				return false;
			}
			
			if( highlightIndex >= 0 && highlightIndex < connections.tiles.length )
			{
				var edgeWidth:Number = TileWidth / 5;
				var edgeHeight:Number = TileHeight / 5;
				var radius:Number = edgeWidth / 2.3;
				
				var x:int = TileWidth * highlightIndex;
				var y:int = 0;
				
				// Find the node the mouse is over, if any.
				if ( my < y + edgeHeight )
				{
					if ( mx < x + edgeWidth )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.TOP_LEFT );
						return true;
					}
					else if ( ( mx > x + (edgeWidth * 2) ) && ( mx < x + (edgeWidth * 3) ) )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.TOP_CENTER );
						return true;
					}
					else if ( ( mx > x + (edgeWidth * 4) ) && ( mx < x + TileHeight ) )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.TOP_RIGHT );
						return true;
					}
				}
				else if ( ( my > y + (edgeHeight * 2) ) && ( my < y + (edgeHeight * 3) ) )
				{
					if ( mx < x + edgeWidth )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.MID_LEFT );
						return true;
					}
					else if ( ( mx > x + (edgeWidth * 4) ) && ( mx < x + TileWidth ) )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.MID_RIGHT );
						return true;
					}
				}
				else if ( ( my > y + (edgeHeight * 4) ) && ( my < y + TileHeight ) )
				{
					if ( mx < x + edgeWidth )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.BOTTOM_LEFT );
						return true;
					}
					else if ( ( mx > x + (edgeWidth * 2) ) && ( mx < x + (edgeWidth * 3) ) )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.BOTTOM_CENTER );
						return true;
					}
					else if ( ( mx > x + (edgeWidth * 4) ) && ( mx < x + TileHeight ) )
					{
						connections.tiles[highlightIndex].CycleRedGreen( TileConnections.BOTTOM_RIGHT );
						return true;
					}
				}
				
			}
			return false;
		}
		
		override protected function mousePressed(event:MouseEvent):void
		{
			if ( changeNode() )
			{
				var editorState:EditorState = FlxG.state as EditorState;
				var tileMatrixEditor:EditorTypeTileMatrix = editorState.getCurrentEditor(App.getApp()) as EditorTypeTileMatrix;
				if ( tileMatrixEditor )
				{
					tileMatrixEditor.RedrawTiles();
				}
			}
			
		}
		
	}

}