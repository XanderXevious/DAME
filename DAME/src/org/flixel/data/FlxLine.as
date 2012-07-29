package org.flixel.data
{
   import org.flixel.FlxPoint;
   
   public class FlxLine {
      public var pt1:FlxPoint;
      public var pt2:FlxPoint;
      
      public function FlxLine( p1:FlxPoint, p2:FlxPoint ) {
         pt1 = p1;
         pt2 = p2;
      }
      
      // Returns the center of the line
      public function center():FlxPoint {
         return (pt1.v_add( pt2 ) ).s_div(2.0);
      }
      
      // Returns the midpoint of the line (yes, same as center)
      public function midpoint():FlxPoint {
         return (pt1.v_add( pt2 ) ).s_div(2.0);
      }
      
      // Returns length of the line
      public function length():Number {
         return (pt2.v_sub( pt1 ) ).magnitude();
      }
      
      // Return the point of intersection with another line
      public function intersection( line:FlxLine ):FlxPoint {
         var P1:FlxPoint = this.pt1;
         var P2:FlxPoint = this.pt2;
         var P3:FlxPoint = line.pt1;
         var P4:FlxPoint = line.pt2;
         var A:FlxPoint = P2.v_sub( P1 );
         var B:FlxPoint = P4.v_sub( P3 );
         var C:FlxPoint = P3.v_sub( P1 );
         var den:Number = B.cross( A );
         var t0:Number = B.cross( C ) / den;
         var t1:Number = A.cross( C ) / den;
         if( t0 < 0.0 || t0 > 1.0 || t1 < 0.0 || t1 > 1.0 ) return null;
         return P1.v_add( A.s_mul( t0 ) );
      }
      
      // Return whether or not this line intersects with another
      public function intersects_line( line:FlxLine ):Boolean {
         if( this.intersection( line ) is null ) return false;
         else return true;
      }
      
   }
}