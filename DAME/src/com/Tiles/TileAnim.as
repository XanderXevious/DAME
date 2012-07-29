package com.Tiles 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class TileAnim
	{
		public var tiles:Vector.<uint>;
		public var fps:Number = 0;
		public var name:String = "";
		public var currentFrame:int = -1;
		private var totalAnimTime:Number = 0;
		public var looped:Boolean = true;
		
		public function TileAnim() 
		{
			tiles = new Vector.<uint>;
		}
		
		public function Start():void
		{
			currentFrame = tiles[0];
			totalAnimTime = 0;
		}
		
		public function Update(elapsed:Number ):void
		{
			if ( fps <= 0 )
			{
				return;
			}
			var newTotalAnimTime:Number = totalAnimTime + elapsed;
			var maxTime:Number = tiles.length / fps;
			if ( newTotalAnimTime > maxTime )
			{
				newTotalAnimTime = newTotalAnimTime - maxTime;
			}
			totalAnimTime = newTotalAnimTime;
			
			var newFrameIdx:uint = Math.floor( totalAnimTime * fps );
			var newFrame:uint = tiles[newFrameIdx];
			if ( newFrame != currentFrame )
			{
				currentFrame = newFrame;
			}
		}
		
		public function CopyFrom(sourceAnim:TileAnim):void
		{
			for ( var i:int = 0; i < sourceAnim.tiles.length; i++ )
			{
				tiles.push(sourceAnim.tiles[i]);
			}
			fps = sourceAnim.fps;
			currentFrame = sourceAnim.currentFrame;
			totalAnimTime = sourceAnim.totalAnimTime;
			looped = sourceAnim.looped;
			name = sourceAnim.name;
		}
		
		public function Save(tileAnimsXml:XML):void
		{
			if ( tiles.length )
			{
				var tileString:String = tiles[0].toString();
				
				for ( var tileId:uint = 1; tileId < tiles.length; tileId++ )
				{
					tileString += "," + tiles[tileId];
				}
				tileAnimsXml.appendChild( <anim name={name} fps={fps} loops={looped}>{tileString}</anim> );
			}
		}
		
		public function Load(animXml:XML):void
		{
			var animStr:String = String(animXml);
			var tileIds:Array = animStr.split(",");
			for each( var id:String in tileIds)
			{
				tiles.push(uint(id));
			}
			fps = animXml.@fps;
			if( animXml.hasOwnProperty("@name") )
				name = animXml.@name;
			if( animXml.hasOwnProperty("@loops") )
				looped = animXml.@loops == true;
		}
	}

}