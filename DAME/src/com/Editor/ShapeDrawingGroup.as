package com.Editor 
{
	import com.EditorState;
	import com.Layers.LayerEntry;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import org.flixel.FlxG;
	import org.flixel.FlxGroup;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author ...
	 */
	public class ShapeDrawingGroup extends FlxGroup
	{
		private var _shape:Shape = new Shape;
		private var _layer:LayerEntry;
		private var _from:FlxPoint = new FlxPoint;
		
		public function ShapeDrawingGroup() 
		{
			active = false;
		}
		
		public function Disable():void
		{
			if ( active )
			{
				var layerIndex:int = EditorState.lyrStage.members.indexOf(this);
				if ( layerIndex != -1 )
				{
					EditorState.lyrStage.members.splice(layerIndex, 1);
				}
			}
			active = false;
			visible = false;
		}
		
		public function EnableForLayer(layer:LayerEntry):void
		{
			// Ensure the shapes group is in the right position.
			var lyrStage:FlxGroup = EditorState.lyrStage
			var layerIndex:int = lyrStage.members.indexOf(this);
			if ( layerIndex != -1 )
			{
				lyrStage.members.splice(layerIndex, 1);
			}
			layerIndex = lyrStage.members.indexOf(layer.map);
			if ( layerIndex != -1 )
			{
				lyrStage.members.splice(layerIndex + 1, 0, this );
			}
			visible = true;
			active = true;
			scrollFactor.create_from_points(layer.xScroll, layer.yScroll);
			_layer = layer;
			_shape.graphics.clear();
		}
		
		public function DrawLine(from:FlxPoint, to:FlxPoint, colour:uint, alpha:Number, thickness:uint ):void
		{
			_from.copyFrom(from);
			_shape.graphics.clear();
			_shape.graphics.lineStyle(thickness, colour, alpha, true );
			_shape.graphics.moveTo(from.x,from.y);
			_shape.graphics.lineTo(to.x, to.y);
		}
		
		public function DrawPolyLine(points:Vector.<FlxPoint>, colour:uint, alpha:Number, thickness:uint, fillColour:uint, fillAlpha:Number):void
		{
			_shape.graphics.clear();
			if ( points.length == 0 )
				return;

			_from.copyFrom(points[0]);
			
			_shape.graphics.lineStyle(thickness, colour, alpha, true );
			if( fillAlpha )
				_shape.graphics.beginFill(fillColour, fillAlpha);
			_shape.graphics.moveTo(points[0].x, points[0].y);
			for ( var i:uint = 0; i < points.length; i++ )
			{
				_shape.graphics.lineTo(points[i].x,points[i].y);
			}
			_shape.graphics.endFill();
		}
		
		public function DrawCircle(from:FlxPoint, to:FlxPoint, colour:uint, alpha:Number, thickness:uint, fillColour:uint, fillAlpha:Number ):void
		{
			_from.copyFrom(from);
			var radius:Number = from.distance_to(to);
			_shape.graphics.clear();
			// pixel hinting is off because it makes circles and ellipses look irregular and ugly.
			_shape.graphics.lineStyle(thickness, colour, alpha, false );
			_shape.graphics.moveTo(from.x, from.y);
			_shape.graphics.beginFill(fillColour, fillAlpha);
			_shape.graphics.drawCircle(from.x, from.y, radius);
			_shape.graphics.endFill();
		}
		
		public function DrawEllipse(from:FlxPoint, to:FlxPoint, colour:uint, alpha:Number, thickness:uint, fillColour:uint, fillAlpha:Number ):void
		{
			_from.copyFrom(from);
			_shape.graphics.clear();
			// pixel hinting is off because it makes circles and ellipses look irregular and ugly.
			_shape.graphics.lineStyle(thickness, colour, alpha,false ); 
			_shape.graphics.beginFill(fillColour, fillAlpha);
			_shape.graphics.drawEllipse(from.x, from.y, to.x - from.x, to.y - from.y);
			_shape.graphics.endFill();
		}
		
		public function DrawBox(from:FlxPoint, to:FlxPoint, colour:uint, alpha:Number, thickness:uint, fillColour:uint, fillAlpha:Number ):void
		{
			_from.copyFrom(from);
			_shape.graphics.clear();
			_shape.graphics.lineStyle(thickness, colour, alpha, true );
			_shape.graphics.beginFill(fillColour, fillAlpha);
			_shape.graphics.drawRect(from.x, from.y, to.x - from.x, to.y - from.y);
			_shape.graphics.endFill();
		}
		
		public function GetShape():Shape
		{
			return _shape;
		}
		
		override public function render():void
		{
			var mat:Matrix = new Matrix;
			var screenFrom:FlxPoint = EditorState.getScreenXYFromMapXY(_from.x + _layer.map.x, _from.y + _layer.map.y, scrollFactor.x, scrollFactor.y);
			mat.translate(screenFrom.x - _from.x, screenFrom.y - _from.y);
			
			FlxG.buffer.draw(_shape, mat);
		}
		
	}

}