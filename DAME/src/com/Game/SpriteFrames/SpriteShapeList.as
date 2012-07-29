package com.Game.SpriteFrames 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpriteShapeList
	{
		public var shapes:Vector.<SpriteShapeData> = new Vector.<SpriteShapeData>;
		
		public function SpriteShapeList() 
		{
			
		}
		
		public function CopyFrom(other:SpriteShapeList):void
		{
			shapes = new Vector.<SpriteShapeData>;
			for each( var data:SpriteShapeData in other.shapes )
			{
				var newData:SpriteShapeData = new SpriteShapeData;
				newData.copyFrom( data );
				shapes.push( newData );
			}
		}
		
	}

}