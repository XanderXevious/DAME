package com.Operations 
{
	import com.Utils.Misc;
	import com.UI.TileBrushesWindow;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationModifyTileBrushes extends IOperation
	{		
		private var brush:Object = null;
		private var brushIndex:uint;
		private var added:Boolean;
		
		public function OperationModifyTileBrushes( index:uint, add:Boolean ) 
		{
			added = add;
			brushIndex = index;
			if ( !add )
			{
				brush = TileBrushesWindow.brushes[index];
			}
		}
		
		override public function Undo():void
		{
			var app:App = App.getApp();
			
			if ( added )
			{
				if ( app.brushesWindow.ListBrushes.selectedIndex == brushIndex && TileBrushesWindow.brushes.length > 0)
				{
					app.brushesWindow.ListBrushes.selectedItem = TileBrushesWindow.brushes[0];
				}
				TileBrushesWindow.brushes.removeItemAt( brushIndex );
				app.brushesWindow.recalcPreview();
			}
			else // if deleted
			{
				TileBrushesWindow.brushes.addItemAt( brush, brushIndex );
				if ( app.brushesWindow && app.brushesWindow.Active && TileBrushesWindow.brushes.length == 1 )
				{
					app.brushesWindow.ListBrushes.selectedItem = brush;
					app.brushesWindow.recalcPreview();
				}
			}
			
		}
		
	}

}
