package org.flixel
{
	import flash.geom.Point;
	import org.flixel.data.FlxDegrees;
	import org.flixel.data.FlxLine;
	/**
		* Stores a 2D floating point coordinate.
		*/
	public class FlxPoint
	{
		/**
		* @default 0
		*/
		public var x:Number;
		/**
		* @default 0
		*/
		public var y:Number;

		/**
		* Instantiate a new point object.
		*
		* @param   X      The X-coordinate of the point in space.
		* @param   Y      The Y-coordinate of the point in space.
		*/
		public function FlxPoint( arg0:Number=0, arg1:Object=null ) {
			if ( arg1 is Number )
				create_from_points( arg0, Number(arg1) );
			else if ( arg1 is int )
				create_from_points( arg0, int( arg1 ) );
			else if ( arg1 == null )
				create_from_points( 0,0 );
			/*else if ( arg1 is FlxRadians )
				create_from_FlxRadians( arg0, FlxRadians(arg1) );*/
			else if ( arg1 is Point )
				create_from_flashPoint( arg1 as Point );
			//else create_from_FlxDegrees( arg0, FlxDegrees(arg1) );
			else
			{
				x = y = 0;
			}
		}

		static public function CreateObject( source:FlxPoint ) : FlxPoint
		{
			return new FlxPoint(source.x, source.y);
		}
		
		public function create_from_flashPoint( pt:Point ):void 
		{
			x = pt.x;
			y = pt.y;
		}

		public function create_from_points( xx:Number, yy:Number ):void {
			x = xx;
			y = yy;
		}
		/*public function create_from_FlxRadians( mag:Number, rad:FlxRadians ):void {
			x = mag * Math.cos( rad.value );
			y = mag * Math.sin( rad.value );
		}
		public function create_from_FlxDegrees( mag:Number, deg:FlxDegrees ):void {
			x = mag * Math.cos( deg.to_radians().value );
			y = mag * Math.sin( deg.to_radians().value );
		}*/


		// Math Operations on FlxPoint's
		public function v_add( v2:FlxPoint ):FlxPoint { return new FlxPoint( this.x + v2.x, this.y + v2.y ); }
		public function v_sub( v2:FlxPoint ):FlxPoint { return new FlxPoint( this.x - v2.x, this.y - v2.y ); }
		public function v_mul( v2:FlxPoint ):FlxPoint { return new FlxPoint( this.x * v2.x, this.y * v2.y ); }
		public function v_div( v2:FlxPoint ):FlxPoint { return new FlxPoint( this.x / v2.x, this.y / v2.y ); }
		public function v_mod( v2:FlxPoint ):FlxPoint { return new FlxPoint( this.x % v2.x, this.y % v2.y ); }

		// Math Operations on FlxPoint's
		public function addTo( v2:FlxPoint ):void { this.x += v2.x; this.y += v2.y; }
		public function subFrom( v2:FlxPoint ):void { this.x -= v2.x; this.y -= v2.y; }
		public function multiplyBy( n:Number ): void { x *= n; y *= n; }

		// Scalar Math Operations
		public function s_add( s:Number ):FlxPoint { return new FlxPoint( this.x + s, this.y + s ); }
		public function s_sub( s:Number ):FlxPoint { return new FlxPoint( this.x - s, this.y - s ); }
		public function s_mul( s:Number ):FlxPoint { return new FlxPoint( this.x * s, this.y * s ); }
		public function s_div( s:Number ):FlxPoint { return new FlxPoint( this.x / s, this.y / s ); }
		public function s_mod( s:Number ):FlxPoint { return new FlxPoint( this.x % s, this.y % s ); }
/*
		// Returns a new FlxPoint containing the floor of this FlxPoint
		public function floor():FlxPoint {
			return new FlxPoint( Math.floor(x), Math.floor(y) );
		}

		// Returns a new FlxPoint containing the ceil of this FlxPoint
		public function ceil():FlxPoint {
			return new FlxPoint( Math.ceil(x), Math.ceil(y) );
		}
*/
		// Returns the radians angle of this point (considered a vector)
		public function radians():Number {
			return Math.atan2( y, x );
		}

		// Returns a copy of the FlxPoint
		public function copy():FlxPoint {
			return new FlxPoint( x,y );
		}
		
		public function copyFrom( source:FlxPoint):void
		{
			x = source.x;
			y = source.y;
		}

		// Return a new FlxPoint containing the abs of this FlxPoint
		public function abs():FlxPoint {
			return new FlxPoint( Math.abs(x), Math.abs(y) );
		}

		// Returns "(x,y)"
		public function print():String {
			return new String( "(" + x + "," + y + ")" );
		}

		// Get the FlxPoint at same angle with a magnitue of 1
		public function normalized():FlxPoint
		{
			var mag:Number = magnitude();
			if ( mag )
			{
				return new FlxPoint( x / mag, y / mag );
			}
			return new FlxPoint(0,0);
		}
		
		public function normalize():void
		{
			var mag:Number = magnitude();
			if ( mag )
			{
				x /= mag;
				y /= mag;
			}
		}

		// Dot product with another FlxPoint
		public function dot( v2:FlxPoint ):Number {
			return this.x*v2.x + this.y*v2.y;
		}

		// Cross Product with another FlxPoint
		public function cross( v2:FlxPoint ):Number {
			return (this.x*v2.y - this.y*v2.x);
		}

		// Project this FlxPoint onto a FlxLine
		// Returns the FlxPoint on the FlxLine
		public function projection_on( line:FlxLine ):FlxPoint {
			var p1:FlxPoint = line.pt1;
			var A:FlxPoint = this.v_sub( p1 );
			var B:FlxPoint = line.pt2.v_sub( p1 );
			return p1.v_add( B.s_mul(A.dot(B) / B.dot(B)) );
		}

		// Distance to another FlxPoint
		public function distance_to( other:FlxPoint ):Number
		{
			return (other.v_sub(this)).magnitude();
		}
		
		// Distance to another FlxPoint
		public function squareDistance( other:FlxPoint ):Number
		{
			var x:Number = other.x - x;
			var y:Number = other.y - y;
			return (x * x) + (y * y);
		}
		
		// Distance to another FlxPoint
		public function squareDistanceToCoords( x1:Number, y1:Number ):Number
		{
			var x:Number = x1 - x;
			var y:Number = y1 - y;
			return (x * x) + (y * y);
		}
		
		// Distance to another FlxPoint
		public function distanceToCoords( x1:Number, y1:Number):Number
		{
			var xDist:Number = x - x1;
			var yDist:Number = y - y1;
			return (Math.sqrt( (xDist*xDist) + (yDist*yDist) ) );
		}

		// Magnitude of this FlxPoint
		public function magnitude():Number
		{
			return Math.sqrt( (x*x) + (y*y) );
		}

		// Clamps FlxPoint onto a line
		/*public function clamped( line:FlxLine ):FlxPoint
		{
			var p1:FlxPoint = line.pt1;
			var p2:FlxPoint = line.pt2;
			var A:FlxPoint = this.v_sub( p1 );
			var B:FlxPoint = p2.v_sub( p1 );
			var t_num:Number = A.dot( B );

			if ( t_num < 0 )
				return p1;
			var t_den:Number = B.dot( B );
			if ( t_num > t_den )
				return p2;
			var td:Number = t_num/t_den;
			return p1.v_add( (new FlxPoint( td, td )).v_mul( B ) );
		}*/

		// Normal of the FlxPoint
		/*public function normal():FlxPoint {
			return new FlxPoint( -y, x );
		}*/

		public function equals( testPos: FlxPoint ):Boolean
		{
			return (testPos.x == x && testPos.y == y );
		}
		
		public function toPoint():Point
		{
			return new Point(x, y);
		}

		/**
		* Convert object to readable string name.  Useful for debugging, save games, etc.
		*/
		public function toString():String
		{
			return FlxU.getClassName(this,true);
		}
	}
}

