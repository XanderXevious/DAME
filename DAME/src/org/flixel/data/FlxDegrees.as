package org.flixel.data
{
   public class FlxDegrees {
      public var value:Number=0;
      public function FlxDegrees( input:Number=0 ) { value = input; }
      public function to_radians():FlxRadians {
         return new FlxRadians( (value*Math.PI)/180 );
      }
   }
}