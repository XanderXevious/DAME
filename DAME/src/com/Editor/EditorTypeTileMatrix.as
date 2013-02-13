package com.Editor 
{
	import com.Editor.EditorType;
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerMap;
	import com.Operations.HistoryStack;
	import com.Operations.IOperation;
	import com.Operations.OperationTileMatrix;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.TileConnections;
	import com.UI.TileConnectionGrid;
	import com.UI.Tiles.TileGrid;
	import com.UI.TileMatrix;
	import com.Utils.Global;
	import com.Utils.Hits;
	import com.Utils.Misc;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import mx.events.CloseEvent;
	import org.flixel.FlxPoint;
	import com.Utils.DebugDraw;
	import org.flixel.FlxG;
	import com.UI.AlertBox;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeTileMatrix extends EditorType
	{		
		private var startDrawPos:FlxPoint = new FlxPoint;
		private var drawingBox:Rectangle = new Rectangle();
		private var lastDrawnBox:Rectangle = new Rectangle();
		private var oldTiles:Vector.<RowEntry>;
		public static var ConfirmMatrix:Boolean = false;
		public static var CancelMatrix:Boolean = false;
		public static var RandomizeMiddleTiles:Boolean = true;
		public static var IgnoreClearTiles:Boolean = false;
		public static var IgnoreMapEdges:Boolean = true;
		public static var AllowSpecialTiles:Boolean = false;
		public static var UseMatrixMagnet:Boolean = false;
		public static var SelectOnlyVisible:Boolean = false;
		private var editLayer:LayerMap = null;
		
		private var paintOperation:IOperation = null;
		private var awaitCancelConfirm:Boolean = false;
	
		
		public function EditorTypeTileMatrix( editor:EditorState ) 
		{
			super( editor );
			
			allowContinuousPainting = true;
			oldTiles = new Vector.<RowEntry>;
		}
		
		private function cancelConfirm( event:CloseEvent ):void
		{
			if ( event.detail == AlertBox.NO )
			{
				CancelMatrix = true;
			}
			else
			{
				ConfirmMatrix = true;
			}
		}
		
		override public function Update(isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			if ( (!isActive || App.getApp().CurrentLayer!= editLayer ) && !awaitCancelConfirm && oldTiles.length )
			{
				if ( Global.KeepTileMatrixOnExitAnswer )
				{
					cancelConfirm(new CloseEvent( "AlertClosed", false, false, Global.KeepTileMatrixOnExitAnswer) );
				}
				else
				{
					AlertBox.Show("Keep this matrix (YES) or revert it (NO)?", "Leaving Tile Matrix", AlertBox.YES|AlertBox.NO, null, cancelConfirm, AlertBox.YES, true, "LeaveTileMatrix" );
					awaitCancelConfirm = true;
				}
			}
			if ( isActive )
			{
				var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
				
				UpdateCurrentTile( mapLayer ? mapLayer.map : null, mousePos.x - mapLayer.map.x * FlxG.extraZoom, mousePos.y - mapLayer.map.y * FlxG.extraZoom );
			}
			if ( CancelMatrix )
			{
				if ( paintOperation )
				{
					HistoryStack.CancelLastOperation( paintOperation );
					paintOperation = null;
				}
				RevertTiles();
				CancelMatrix = false;
				awaitCancelConfirm = false;
			}
			
			if (ConfirmMatrix )
			{
				if ( oldTiles.length > 0 )
				{
					if ( paintOperation )
					{
						HistoryStack.CancelLastOperation( paintOperation );
						paintOperation = null;
					}
					HistoryStack.BeginOperation( new OperationTileMatrix( editLayer, oldTiles ) );
					// By creating a new list of tiles this effectively saves the version we passed into the history stack.
					oldTiles = new Vector.<RowEntry>;
					editLayer.map.stickyTiles = null;
				}
				ConfirmMatrix = false;
				awaitCancelConfirm = false;
			}
		}
		
		public function RestoreTileMatrix( layer:LayerMap, savedOldTiles:Object ):void
		{
			if ( savedOldTiles != null )
			{
				oldTiles = savedOldTiles as Vector.<RowEntry>;
			}
			RevertTiles();
		}
		
		private function RevertTiles():void
		{
			if ( editLayer != null )
			{
				editLayer.map.stickyTiles = null;
				for each( var row:RowEntry in oldTiles )
				{
					for each( var tile:TileEntry in row.tiles )
					{
						//if ( editLayer.map.xStagger )
							editLayer.map.setTile( tile.realX, tile.realY, tile.tileId);
						//else
						//	editLayer.map.setTile( tile.x, row.y, tile.tileId);
					}
				}
			}
			oldTiles.length = 0;
		}
		
		override protected function UpdateDisplay( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( mapLayer == null || mapLayer.map == null || !mapLayer.map.visible )
			{
				return;
			}
			
			DebugDraw.DrawBox( mapLayer.map.x>>FlxG.zoomBitShifter, mapLayer.map.y>>FlxG.zoomBitShifter, (mapLayer.map.x + mapLayer.map.width)>>FlxG.zoomBitShifter, (mapLayer.map.y + mapLayer.map.height)>>FlxG.zoomBitShifter, 0, mapLayer.map.scrollFactor, false, Global.MapBoundsColour, true);
			
			if( currentTileValid )
				DrawBoxAroundTile( mapLayer.map, currentTileWorldPos.x, currentTileWorldPos.y, Global.TileUnderCursorColour, 0, true );
		}
		
		override public function GetCurrentObjectProperties():ArrayCollection
		{
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			if ( mapLayer )
			{
				return mapLayer.properties;
			}
			return null;
		}
		
		override protected function Paint( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( mapLayer != editLayer )
			{
				RevertTiles();
				editLayer = null;
			}
			
			if ( !mapLayer.map.visible )
			{
				return;
			}
			
			var unitMapPosX:int = currentTile.x;
			var unitMapPosY:int = currentTile.y;
			
			drawingBox.right = unitMapPosX;
			drawingBox.bottom = unitMapPosY;
			
			if ( UseMatrixMagnet )
			{
				// Just paint one tile. Better than using line drawing as this requires more placement precision from user.
				drawingBox.left = drawingBox.right;
				drawingBox.top = drawingBox.bottom;
			}
			
			var updateRect:Rectangle = drawingBox.clone();

			if ( updateRect.left > updateRect.right )
			{
				updateRect.x = updateRect.right;
				updateRect.width = -updateRect.width;
			}
			if ( updateRect.top > updateRect.bottom )
			{
				updateRect.y = updateRect.bottom;
				updateRect.height = -updateRect.height;
			}
			
			if ( layer.map.xStagger )
			{
				var startRectPos:FlxPoint = new FlxPoint;
				var endRectPos:FlxPoint = new FlxPoint;
			
				startRectPos.copyFrom(startDrawPos);
				endRectPos.copyFrom(mousePos);
				
				if ( UseMatrixMagnet )
				{
					// Just paint one tile.
					startRectPos.copyFrom(endRectPos);
				}
			
				var tileOffsetX:int = -layer.map.xStagger;
				var tileOffsetY:int = layer.map.xStagger;
				var topRight:FlxPoint = new FlxPoint;
				Hits.LineRayIntersection( startRectPos.x, startRectPos.y, startRectPos.x + layer.map.tileSpacingX, startRectPos.y + tileOffsetY,
										endRectPos.x, endRectPos.y, endRectPos.x - tileOffsetX, endRectPos.y - layer.map.tileSpacingY,
										topRight );
										
				var topLeft:FlxPoint = new FlxPoint();
				var bottomRight:FlxPoint = new FlxPoint();
				
				GetTileInfo(mapLayer.map, startRectPos.x - mapLayer.map.x, startRectPos.y - mapLayer.map.y, topLeft, null);
				GetTileInfo(mapLayer.map, endRectPos.x - mapLayer.map.x, endRectPos.y - mapLayer.map.y, bottomRight, null);
				
				var topLeftUnits:FlxPoint = new FlxPoint(Math.min(topLeft.x,bottomRight.x), Math.min(topLeft.y,bottomRight.y));
				var bottomRightUnits:FlxPoint = new FlxPoint(Math.max(topLeft.x,bottomRight.x), Math.max(topLeft.y,bottomRight.y));
						
				ConvertStaggerPosToIso(mapLayer.map, startRectPos, endRectPos, topRight, bottomRight, topLeft, topLeftUnits, bottomRightUnits );
				
				updateRect.x = topLeftUnits.x;
				updateRect.y = topLeftUnits.y;
				updateRect.width = Math.abs(bottomRightUnits.x - topLeftUnits.x);
				updateRect.height = Math.abs(bottomRightUnits.y - topLeftUnits.y);
				
				var tx:int = topLeft.x;
				var ty:int = topLeft.y;
				var storedPos:FlxPoint = new FlxPoint(tx, ty);
				var evenRow:int = layer.map.xStagger > 0 ? 0 : 1;
			}
			
			if ( updateRect.equals(lastDrawnBox))
			{
				return;	// nothing's changed
			}
			
			var row:RowEntry;
			var tile:TileEntry;
			
			var listWasEmpty:Boolean = (oldTiles.length == 0);
			
			if ( updateRect.x > lastDrawnBox.x ||
				updateRect.y > lastDrawnBox.y ||
				updateRect.right < lastDrawnBox.right ||
				updateRect.bottom < lastDrawnBox.bottom )
			{
				// Restore the old tiles from the previous box that fall outside the current one.
				for ( var indexY:uint = 0; indexY < oldTiles.length; indexY++ )
				{
					row = oldTiles[indexY];
					var rowOutside:Boolean = ( row.y < updateRect.y || row.y > updateRect.bottom );
					for ( var indexX:uint = 0; indexX < row.tiles.length; indexX++ )
					{
						tile = row.tiles[ indexX ];
						if ( tile.inCurrentBox && 
							(rowOutside || ( tile.x < updateRect.x || tile.x > updateRect.right ) ) )
						{
							mapLayer.map.setTile( tile.realX, tile.realY, tile.tileId);
							row.tiles.splice( indexX, 1 );
							indexX--;
						}
					}
				}
			}
			
			// Add the new tiles.
			
			for ( var y:int = updateRect.top; y <= updateRect.bottom; y++ )
			{
				if ( !mapLayer.map.xStagger && ( y < 0  || y >= mapLayer.map.heightInTiles ) )
				{
					continue;
				}
				
				var currentRow:RowEntry = null;
				var bestInsertIndexY:uint = 0;
				
				for each( row in oldTiles )
				{
					if ( row.y == y )
					{
						currentRow = row;
					}
					else if ( row.y < y )
					{
						bestInsertIndexY++;
					}
					else
					{
						break;	// gone too far.
					}
				}
				
				if ( currentRow == null )
				{
					currentRow = new RowEntry();
					currentRow.y = y;
					currentRow.tiles = new Vector.<TileEntry>;
					oldTiles.splice(bestInsertIndexY, 0, currentRow);
				}
				
				for ( var x:int = updateRect.left; x <= updateRect.right; x++ )
				{
					if ( !mapLayer.map.xStagger && ( x < 0 || x >= mapLayer.map.widthInTiles ) )
					{
						continue;
					}
					var addedTile:Boolean = false;
					// Add the old tile to the list if it's not already in there.
					
					var bestInsertIndexX:uint = 0;
					for each( tile in currentRow.tiles )
					{
						if ( tile.x == x )
						{
							addedTile = true;
							break;
						}
						else if ( tile.x < x )
						{
							bestInsertIndexX++;
						}
						else
						{
							break;	// gone too far.
						}
					}
					if ( !addedTile )
					{
						tile = new TileEntry();
						tile.x = x;
						if ( mapLayer.map.xStagger )
						{
							tile.realX = tx;
							tile.realY = ty;
							
							tile.tileId = mapLayer.map.getTile( tx, ty );
						}
						else
						{
							tile.realX = x;
							tile.realY = y;
							tile.tileId = mapLayer.map.getTile( x, y );
						}
						if ( !SelectOnlyVisible || tile.tileId >= mapLayer.map.drawIndex )
						{
							tile.inCurrentBox = true;
							currentRow.tiles.splice(bestInsertIndexX, 0, tile );
							addedTile = true;
							// Store the current layer we're working on.
							editLayer = mapLayer;
							tile.sticky = UseMatrixMagnet;
							if ( UseMatrixMagnet )
							{
								if ( mapLayer.map.stickyTiles == null )
								{
									mapLayer.map.stickyTiles = new Dictionary;
								}
								mapLayer.map.stickyTiles[ ( tile.realY * mapLayer.map.widthInTiles ) + tile.realX ] = true;
								// Don't use box selection when making sticky tiles.
								tile.inCurrentBox = false;
							}
						}
					}
					
					if ( mapLayer.map.xStagger )
					{
						// if on even then move (0,1), if odd then move (1,1)
						if ( ty % 2 == evenRow )
						{
							ty += 1;
						}
						else
						{
							tx += 1;
							ty += 1;
						}
					}
					
				}
				
				if ( mapLayer.map.xStagger )
				{
					// if on even then move (-1,1), if odd then move (0,1)
					if ( storedPos.y % 2 == evenRow )
					{
						tx = storedPos.x = storedPos.x - 1;
						ty = storedPos.y = storedPos.y + 1;
					}
					else
					{
						tx = storedPos.x;
						ty = storedPos.y = storedPos.y + 1;
					}
				}
			}
			
			if ( addedTile && listWasEmpty )
			{
				// pass null as the oldTiles because this is just so that we can cancel before we have confirmed.
				paintOperation = new OperationTileMatrix( editLayer, null );
				HistoryStack.BeginOperation( paintOperation );
			}
			
			RedrawTiles();
			
			lastDrawnBox = updateRect;
			
		}
		
		public function RedrawTiles():void
		{
			var line:Vector.<TileEntry> = new Vector.<TileEntry>;
			// Apply the new tile matrix to the map.
			for ( var indexY:uint = 0; indexY < oldTiles.length; indexY++ )
			{
				var row:RowEntry = oldTiles[indexY];
				
				line.length = 0;
				var lastX:int = -1;
				var startIndexX:uint = 0;
				var indexX:uint = 0;
				for each( var tile:TileEntry in row.tiles )
				{
					if ( lastX != -1 && lastX != tile.x - 1 )
					{
						// There's been a break in the continuous line so we know we have a block now.
						applyMatrixToLine( editLayer, line, indexY, startIndexX );
						startIndexX = indexX;
					}
					line.push(tile);
					lastX = tile.x;
					indexX++;
				}
				applyMatrixToLine(editLayer, line, indexY, startIndexX );
			}
		}
		
		private function evalPositionOfTileEntryInRow( tile:TileEntry ):uint
		{
			return tile.x;
		}
		
		// This applies the matrix to a continuous row of tiles, the top left at indexX and indexY
		private function applyMatrixToLine( mapLayer:LayerMap, line:Vector.<TileEntry>, indexY:uint, indexX:uint ):void
		{
			if ( line.length == 0)
			{
				return;
			}
			
			var y:int = oldTiles[indexY].y;
			
			var aboveRow:Vector.<TileEntry> = null;
			var belowRow:Vector.<TileEntry> = null;
			if ( indexY > 0 && oldTiles[indexY - 1].y == y - 1 )
			{
				aboveRow = oldTiles[indexY - 1].tiles;
			}
			if ( indexY < oldTiles.length - 1 && oldTiles[indexY + 1].y == y + 1 )
			{
				belowRow = oldTiles[indexY + 1].tiles;
			}
			
			var tileMatrix:TileGrid = App.getApp().tileMatrix;
			
			var halfGridWidth:uint = (tileMatrix.ColumnCount - 1) / 2;
			var halfGridIndexOnRight:uint = halfGridWidth + ((tileMatrix.ColumnCount - 1) % 2);
			var halfGridHeight:uint = (tileMatrix.RowCount - 1) / 2;
			var halfGridIndexFromTop:uint = halfGridHeight + ((tileMatrix.RowCount - 1) % 2);
			
			// Due to the realignment it's impossible to ignore map edges on staggered iso maps.
			var ignoreEdges:Boolean = IgnoreMapEdges && !mapLayer.map.xStagger;
			
			for ( var i:uint = 0; i < line.length; i++ )
			{
				var iModified:uint = i;
				var gridX:uint = 0;
				var gridY:uint = 0;
				
				var x:int = line[i].x;
				
				if ( oldTiles[indexY].tiles[indexX + i].sticky )
				{
					continue;
				}
				
				var tileAbove:Boolean = (Misc.binarySearch(aboveRow, x, evalPositionOfTileEntryInRow) != -1);
				var tileBelow:Boolean = (Misc.binarySearch(belowRow, x, evalPositionOfTileEntryInRow) != -1);
				var calculateGridX:Boolean = true;
				var tileTopLeft:Boolean = (Misc.binarySearch(aboveRow, x - 1, evalPositionOfTileEntryInRow) != -1);
				var tileTopRight:Boolean = (Misc.binarySearch(aboveRow, x + 1, evalPositionOfTileEntryInRow) != -1);
				var tileBottomLeft:Boolean = (Misc.binarySearch(belowRow, x - 1, evalPositionOfTileEntryInRow) != -1);
				var tileBottomRight:Boolean = (Misc.binarySearch(belowRow, x + 1, evalPositionOfTileEntryInRow) != -1);
				
				
				if ( ignoreEdges )
				{
					if ( y == 0 )
					{
						tileAbove = true;
						tileTopLeft = true;
						tileTopRight = true;
					}
					else if ( y == mapLayer.map.heightInTiles - 1 )
					{
						tileBelow = true;
						tileBottomLeft = true;
						tileBottomRight = true;
					}
					if ( line[i].x == 0 )
					{
						if ( line.length == 2 )
						{
							calculateGridX = false;
							gridX = Math.min( 1, tileMatrix.ColumnCount - 2 );
						}
						else if ( line.length > 2 )
						{
							iModified = 1;
						}
					}
					else if ( line[i].x == mapLayer.map.widthInTiles - 1 )
					{
						if ( line.length == 1 )
						{
							gridX = 0;
							calculateGridX = false;
						}
						else if ( line.length == 2 )
						{
							calculateGridX = false;
							gridX = Math.max( 0, tileMatrix.ColumnCount - 2 );
						}
						else
						{
							iModified--; 
						}
					}
				}
				
				if ( calculateGridX )
				{
					if ( iModified == line.length-1 )
					{
						gridX = tileMatrix.ColumnCount - 1;
					}
					else if ( iModified > 0 )
					{
						if ( RandomizeMiddleTiles )
						{
							gridX = Math.max( 0, Math.ceil( Math.random() * (tileMatrix.ColumnCount - 2) ) );
						}
						else
						{
							// For ordered tiles it splits the matrix and the row in the middle and
							// places them in order until it hits the middle tiles, which will all be the same tile.
							var numToLeft:uint = iModified;
							var numToRight:uint = (line.length - 1) - iModified;
							if ( numToLeft < numToRight )
							{
								gridX = Math.min(numToLeft,halfGridWidth);
							}
							else
							{
								gridX = Math.max((tileMatrix.ColumnCount - 1) - numToRight, halfGridIndexOnRight);
							}
						}
					}
				}
				
				
				if ( !tileBelow )
				{
					gridY = tileMatrix.RowCount - 1;
				}
				else if ( tileAbove )
				{
					if ( RandomizeMiddleTiles )
					{
						gridY = Math.max( 0, Math.ceil( Math.random() * (tileMatrix.RowCount - 2) ) );
					}
					else
					{
						var lastY:uint = y - 1;
						var numAbove:uint = 1;	// We know there is at least 1 tile above and 1 below this row in this case.
						for ( var j:int = indexY - 2; j >= 0; j-- )
						{
							if ( oldTiles[j].y == lastY - 1 )
							{
								if ( Misc.binarySearch(oldTiles[j].tiles, line[i].x, evalPositionOfTileEntryInRow) != -1 )
								{
									lastY--;
									numAbove++;
								}
							}
							else
							{
								break;
							}
						}
						var numBelow:uint = 1;
						lastY = y + 1;
						for ( j = indexY + 2; j < oldTiles.length; j++ )
						{
							if ( oldTiles[j].y == lastY + 1 )
							{
								if ( Misc.binarySearch(oldTiles[j].tiles, line[i].x, evalPositionOfTileEntryInRow) != -1 )
								{
									lastY++;
									numBelow++;
								}
							}
							else
							{
								break;
							}
						}
						
						if ( numAbove < numBelow )
						{
							gridY = Math.min(numAbove,halfGridHeight);
						}
						else
						{
							gridY = Math.max((tileMatrix.RowCount - 1) - numBelow, halfGridIndexFromTop);
						}
					}
				}
				var tileId:uint = tileMatrix.GetMetaDataFromGridCoords(gridX, gridY) as uint;
				
				if ( AllowSpecialTiles )
				{
					var overrideTile:Boolean = false;
					
					var tileMatrixUI:TileMatrix = Global.windowedApp.tileMatrix;
					var specialRows:Array = tileMatrixUI.SpecialTilesRows.getChildren();
					for ( var n:uint = 0; n < specialRows.length && !overrideTile; n++ )
					{
						var grid:TileConnectionGrid = specialRows[n].tiles;
						var t:uint = grid.Connections.tiles.length;
						while (t-- && !overrideTile )
						{
							var nodeFailed:Boolean = false;
							var tileCon:TileConnections = grid.Connections.tiles[t];
							// Don't consider the tile if all nodes are set to ignore.
							if ( tileCon.GreenTiles || tileCon.RedTiles )
							{
								var testTileId:uint = grid.GetMetaDataAtIndex(t) as uint;
								if ( testTileId > 0 )
								{
									var nodePassed:Boolean = false;
									// Check all the coords of the tile connection to see if all connections pass the test.
									var valid:int = tileCon.IsConnectionValid(tileTopLeft, TileConnections.TOP_LEFT);
									if (!valid)
										nodeFailed = true;
									nodePassed = (valid == 1);
									if ( !nodeFailed )
									{
										valid = tileCon.IsConnectionValid(tileAbove, TileConnections.TOP_CENTER);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( !nodeFailed)
									{
										valid = tileCon.IsConnectionValid(tileTopRight, TileConnections.TOP_RIGHT);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( !nodeFailed )
									{
										var tileAtLeft:Boolean = i > 0 || ( ignoreEdges && (line[iModified].x == 0) );
										valid = tileCon.IsConnectionValid( tileAtLeft, TileConnections.MID_LEFT);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( !nodeFailed )
									{
										var tileAtRight:Boolean = i + 1 < line.length || ( ignoreEdges && (line[iModified].x == mapLayer.map.widthInTiles - 1) );
										valid = tileCon.IsConnectionValid( tileAtRight, TileConnections.MID_RIGHT);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( !nodeFailed )
									{
										valid = tileCon.IsConnectionValid(tileBottomLeft, TileConnections.BOTTOM_LEFT);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( !nodeFailed )
									{
										valid = tileCon.IsConnectionValid(tileBelow, TileConnections.BOTTOM_CENTER);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( !nodeFailed )
									{
										valid = tileCon.IsConnectionValid(tileBottomRight, TileConnections.BOTTOM_RIGHT);
										if (!valid)
											nodeFailed = true;
										nodePassed = nodePassed || (valid == 1);
									}
									if ( nodePassed && !nodeFailed )
									{
										tileId = testTileId;
										overrideTile = true;
									}
								}
							}
						}
					}
				}
				
				var tx:int = line[i].realX;
				var ty:int = line[i].realY;
				//var tx:int = mapLayer.map.xStagger ? line[i].realX : line[i].x;
				//var ty:int = mapLayer.map.xStagger ? line[i].realY : y;
				if ( tileId == 0 && IgnoreClearTiles )
				{
					// It's likely that we've set a tile to one of the drawn tiles while painting so we need to ensure
					// that the hidden tiles are reverted back to the tile that's actually beneath them.
					mapLayer.map.setTile( tx, ty, oldTiles[indexY].tiles[indexX+i].tileId );
				}
				else
				{
					mapLayer.map.setTile( tx, ty, tileId );
				}
			}
			
			line.length = 0;
		}
		
		override protected function PaintSecondary( layer:LayerEntry ):void
		{
			var mapLayer:LayerMap = layer as LayerMap;
			
			if ( !mapLayer.map.visible )
			{
				return;
			}			
			
			if ( editLayer == mapLayer && oldTiles.length > 0 )
			{
				revertAllTilesInLine( mapLayer.map, lastHeldTileIdx.x, lastHeldTileIdx.y, currentTile.x, currentTile.y);
				//revertAllTilesInLine( mapLayer.map, lastHeldMousePos.x, lastHeldMousePos.y, currentTileWorldPos.x, currentTileWorldPos.y);
				RedrawTiles();
			}
		}
		
		override protected function BeginPainting( layer:LayerEntry, leftMouse:Boolean ):void
		{
			/*var mapPos:FlxPoint = EditorState.getMapXYFromScreenXY(mouseScreenPos.x, mouseScreenPos.y, layer.xScroll, layer.yScroll );
			mapPos.subFrom(layer.map);
			
			var unitMapPosX:int = mapPos.x / layer.map.tileWidth;
			var unitMapPosY:int = mapPos.y / layer.map.tileHeight;*/
			
			var unitMapPosX:int = currentTile.x;
			var unitMapPosY:int = currentTile.y;
			
			drawingBox.x = unitMapPosX;
			drawingBox.y = unitMapPosY;
			drawingBox.width = 0;
			drawingBox.height = 0;
			
			startDrawPos.copyFrom(mousePos);
			
			// Enforce the last used tileset as the one tied to this matrix.
			var mapLayer:LayerMap = App.getApp().CurrentLayer as LayerMap;
			// Ensure that if this matrix comes from saved tile matrix data then that gets assigned this tileset too.
			//Global.windowedApp.tileMatrix.UpdateMatrixDataTileset(mapLayer);
		}
		
		override protected function EndPainting( layer:LayerEntry ):void
		{
			for each( var row:RowEntry in oldTiles )
			{
				for each ( var tile:TileEntry in row.tiles )
				{
					tile.inCurrentBox = false;
				}
			}
		}
		
		//{ region private
		
		private function drawStaggerCallback( x:int, y:int, drawData:Object ):void
		{
			for each( var row:RowEntry in oldTiles )
			{
				var index:int = row.tiles.length;
				while(index--)
				{
					var tile:TileEntry = row.tiles[index];
					if ( tile.realX == x && tile.realY == y )
					{
						editLayer.map.setTile( x, y, tile.tileId);
						if ( editLayer.map.stickyTiles && editLayer.map.stickyTiles[ (y* editLayer.map.widthInTiles ) + x ] == true )
						{
							delete editLayer.map.stickyTiles[ ( y * editLayer.map.widthInTiles ) + x ];
						}
						row.tiles.splice(index, 1);
						return;
					}
				}
			}
		}
		
		private function drawCallback( x:int, y:int, drawData:Object ):void
		{
			for each( var row:RowEntry in oldTiles )
			{
				if ( row.y == y )
				{
					var index:int = Misc.binarySearch(row.tiles, x, evalPositionOfTileEntryInRow);
					if ( index != -1 )
					{
						editLayer.map.setTile( x, y, row.tiles[index].tileId);
						if ( editLayer.map.stickyTiles && editLayer.map.stickyTiles[ (y* editLayer.map.widthInTiles ) + x ] == true )
						{
							delete editLayer.map.stickyTiles[ ( y * editLayer.map.widthInTiles ) + x ];
						}
						row.tiles.splice(index, 1);
					}
				}
			}
		}
		
		private function revertAllTilesInLine( map:FlxTilemapExt, x1:int, y1:int, x2:int, y2:int ):void
		{
			if ( lastHeldMousePos.x == -1 || lastHeldMousePos.y == -1 )
			{
				if ( map.xStagger )
					drawStaggerCallback( x2, y2, null );
				else
					drawCallback( x2, y2, null );
				return;
			}
			
			Misc.DrawCustomLine( x1, y1, x2, y2, ( map.xStagger ? drawStaggerCallback : drawCallback ), null );
		}
		
		//} endregion
		
	}

}

internal class TileEntry
{
	public var x:int;
	public var tileId:uint = 0;
	// This tile is in the box we are currently painting and so will be refreshed until we stop painting this box.
	public var inCurrentBox:Boolean = false; 
	// If sticky then we don't update the graphics for the tile but consider it as a neighbour in all calculations.
	public var sticky:Boolean = false;
	
	// This is only needed if dealing with staggered maps, but stored always to avoid branching.
	// The realX and realY correspond to the top left of the row. The rest can be calculated.
	public var realX:int;
	public var realY:int;
}

internal class RowEntry
{
	public var y:int = 0;
	public var tiles:Vector.<TileEntry>;
}
