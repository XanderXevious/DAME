package com.Operations 
{
	import com.Layers.LayerMap;
	import com.Operations.IOperation;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationMoveMap extends IOperation
	{
		private var layer:LayerMap;
		public var x:Number;
		public var y:Number;
		
		public function OperationMoveMap( _layer:LayerMap ) 
		{
			layer = _layer;
			x = layer.map.x;
			y = layer.map.y;
		}
		
		override public function Undo():void
		{
			layer.map.x = x;
			layer.map.y = y;
		}
		
	}

}