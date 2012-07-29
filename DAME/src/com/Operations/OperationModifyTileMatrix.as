package com.Operations 
{
	import com.Tiles.TileMatrixData;
	import com.Utils.Misc;
	import com.UI.TileMatrix;
	import com.Utils.Global;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationModifyTileMatrix extends IOperation
	{		
		private var matrix:TileMatrixData = null;
		private var matrixIndex:uint;
		private var added:Boolean;
		private var deleted:Boolean;
		private var changed:Boolean;
		
		public function OperationModifyTileMatrix( index:uint, add:Boolean, del:Boolean, change:Boolean ) 
		{
			added = add;
			deleted = del;
			changed = change;
			matrixIndex = index;
			if ( !add )
			{
				if ( Global.windowedApp.tileMatrix && index == Global.windowedApp.tileMatrix.MatrixChooser.selectedIndex )
				{
					// When it's the current matrix (most likely) the saved data might not be up to date.
					matrix = new TileMatrixData();
					Global.windowedApp.tileMatrix.setSavedMatrixData( matrix, false )
					matrix.name = Global.windowedApp.tileMatrix.MatrixChooser.selectedLabel;
				}
				else
				{
					matrix = App.getApp().tileMatrices[index].Clone();
				}
				
			}
		}
		
		override public function Undo():void
		{
			var app:App = App.getApp();
			var tileMatrix:TileMatrix = Global.windowedApp.tileMatrix;
			
			if ( added )
			{
				if ( tileMatrix )
				{
					tileMatrix.DeleteMatrix( matrixIndex );
				}
				else
				{
					app.tileMatrices.removeItemAt( matrixIndex );
				}
			}
			else if( deleted )
			{
				app.tileMatrices.addItemAt( matrix, matrixIndex );
				if ( tileMatrix && app.tileMatrices.length == 1 )
				{
					tileMatrix.MatrixChooser.selectedItem = matrix;
					tileMatrix.MatrixChooser.validateNow();
					tileMatrix.ChangeMatrix();
				}
			}
			else if ( changed )
			{
				app.tileMatrices[matrixIndex] = matrix;
				if ( tileMatrix && tileMatrix.MatrixChooser.selectedIndex == matrixIndex )
				{
					tileMatrix.MatrixChooser.selectedItem = matrix;
					tileMatrix.MatrixChooser.validateNow();
					tileMatrix.ChangeMatrix();
				}
			}
			
			
			
			// This needs to handle removal of matrix Sets (not restoring them, but coping)
		}
		
	}

}