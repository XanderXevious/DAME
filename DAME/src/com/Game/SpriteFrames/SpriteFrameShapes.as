package com.Game.SpriteFrames
{
	import flash.utils.Dictionary;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpriteFrameShapes
	{
		public var frames:Dictionary = new Dictionary;
		public var numFrames:int = 0;
		
		public function SpriteFrameShapes() 
		{
			
		}
		
		public function AddPoint(frame:uint, x:int, y:int):SpriteShapeData
		{
			var frameList:SpriteShapeList = frames[frame];
			if ( !frameList )
			{
				frameList = new SpriteShapeList();
				numFrames++;
			}
			frames[frame] = frameList;
			var shape:SpriteShapeData = new SpriteShapeData;
			shape.type = SpriteShapeData.SHAPE_POINT;
			shape.create_from_points(x,y);
			frameList.shapes.push(shape);
			return shape;
		}
		
		public function AddCircle(frame:uint, x:int, y:int, radius:int):SpriteShapeData
		{
			var frameList:SpriteShapeList = frames[frame];
			if ( !frameList )
			{
				frameList = new SpriteShapeList();
				numFrames++;
			}
			frames[frame] = frameList;
			var shape:SpriteShapeData = new SpriteShapeData;
			shape.type = SpriteShapeData.SHAPE_CIRCLE;
			shape.create_from_points(x, y);
			shape.radius = radius;
			frameList.shapes.push(shape);
			return shape;
		}
		
		public function AddBox(frame:uint, x:int, y:int, width:int, height:int):SpriteShapeData
		{
			var frameList:SpriteShapeList = frames[frame];
			if ( !frameList )
			{
				frameList = new SpriteShapeList();
				numFrames++;
			}
			frames[frame] = frameList;
			var shape:SpriteShapeData = new SpriteShapeData;
			shape.type = SpriteShapeData.SHAPE_BOX;
			shape.create_from_points(x, y);
			shape.width = width;
			shape.height = height;
			frameList.shapes.push(shape);
			return shape;
		}
		
		public function CopyFrom(other:SpriteFrameShapes):void
		{
			frames = new Dictionary;
			numFrames = other.numFrames;
			for (var key:Object in other.frames )
			{
				var frameNum:int = key as int;
				var otherShapes:SpriteShapeList = other.frames[frameNum];
				var shapes:SpriteShapeList = new SpriteShapeList;
				shapes.CopyFrom( otherShapes );
				frames[frameNum] = shapes;
			}
		}
		
		public function Save(parentXml:XML):void
		{
			var shapesXml:XML = <shapes/>;
			var numFramesOutput:int = 0;
			for (var key:Object in frames )
			{
				var shapeList:SpriteShapeList = frames[key];
				if ( shapeList.shapes.length )
				{
					var frameNum:int = key as int;
					var frameXml:XML = <frame num={frameNum}/>
					shapesXml.appendChild(frameXml);
					
					for ( var i:int = 0; i < shapeList.shapes.length; i++ )
					{
						var shape:SpriteShapeData = shapeList.shapes[i];
						var type:String;
						if ( shape.type == SpriteShapeData.SHAPE_BOX )
							type = "box";
						else if ( shape.type == SpriteShapeData.SHAPE_CIRCLE )
							type = "circle";
						else if ( shape.type == SpriteShapeData.SHAPE_POINT )
							type = "point";
						else if ( shape.type == SpriteShapeData.SHAPE_LINE )
							type = "line";
						var shapeXml:XML = <shape name={shape.name} x={shape.x} y={shape.y} type={type}/>
						shapeXml[ "@width"] = shape.width;
						shapeXml[ "@height"] = shape.height;
						shapeXml[ "@radius"] = shape.radius;
						frameXml.appendChild(shapeXml);
					}
					numFramesOutput++;
				}
			}
			if ( numFramesOutput )
			{
				parentXml.appendChild(shapesXml);
			}
		}
		
		public function Load(parentXml:XML):void
		{
			if ( parentXml.hasOwnProperty("shapes") == true )
			{
				for each( var frameXml:XML in parentXml.shapes.frame )
				{
					var frameList:SpriteShapeList = new SpriteShapeList;
					frames[int(frameXml.@num)] = frameList;
					numFrames++;
					for each( var shapeXml:XML in frameXml.shape )
					{
						var shape:SpriteShapeData = new SpriteShapeData;
						frameList.shapes.push(shape);
						shape.x = int(shapeXml.@x);
						shape.y = int(shapeXml.@y);
						shape.name = String(shapeXml.@name);
						if( shapeXml.@type == "box" )
						{
							shape.type = SpriteShapeData.SHAPE_BOX;
							shape.width = int(shapeXml.@width);
							shape.height = int(shapeXml.@height);
						}
						else if( shapeXml.@type == "circle" )
						{
							shape.type = SpriteShapeData.SHAPE_CIRCLE;
							shape.radius = int(shapeXml.@radius);
						}
						else if( shapeXml.@type == "point" )
						{
							shape.type = SpriteShapeData.SHAPE_POINT;
						}
						else if ( shapeXml.@type == "line" )
						{
							shape.type = SpriteShapeData.SHAPE_LINE;
						}
						
					}
				}
			}
		}
		
	}

}