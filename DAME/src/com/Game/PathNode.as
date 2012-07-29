package com.Game 
{
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class PathNode extends FlxPoint
	{
		public var tangent1:FlxPoint = null;
		public var tangent2:FlxPoint = null;
		
		public function PathNode( X:Number, Y:Number, isCurved:Boolean ) 
		{
			x = X;
			y = Y;
			if ( isCurved )
			{
				tangent1 = new FlxPoint(0, 30);
				tangent2 = new FlxPoint(0, -30);
			}
		}
		
		public function CopyNode():PathNode
		{
			var newNode:PathNode = new PathNode( x, y, tangent1 != null);
			if( tangent1 )
				newNode.tangent1.copyFrom(tangent1);
			if( tangent2 )
				newNode.tangent2.copyFrom(tangent2);
			return newNode;
		}
		
	}

}