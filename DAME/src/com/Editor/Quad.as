package com.Editor 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Quad
	{
		public var x1:Number = 0;
		public var y1:Number = 0;
		public var x2:Number = 0;
		public var y2:Number = 0;
		public var x3:Number = 0;
		public var y3:Number = 0;
		public var x4:Number = 0;
		public var y4:Number = 0;
		
		public var selected:Boolean = false;
		
		public function Quad( )
		{
			
		}
		
		public function SetupQuad( X1:Number, Y1:Number, X2:Number, Y2:Number, X3:Number, Y3:Number, X4:Number, Y4:Number ):void 
		{
			x1 = X1;
			y1 = Y1;
			x2 = X2;
			y2 = Y2;
			x3 = X3;
			y3 = Y3;
			x4 = X4;
			y4 = Y4;
		}
		
	}

}