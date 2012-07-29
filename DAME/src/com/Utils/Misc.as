package com.Utils 
{
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Misc
	{
		static public const DEG_TO_RAD:Number = 0.01745329;
		static public const RAD_TO_DEG:Number = 57.2957796;
		
		private static var testPt:Point = new Point;
		
		static public function getFrac( val:Number, min:Number, max:Number ):Number
		{
			var denom:Number = max - min;
			return denom ? ( val - min ) / denom : 1;
		}
		
		static public function mapValueOntoRange( srcVal:Number, srcMin:Number, srcMax:Number, destMin:Number, destMax:Number ):Number
		{
			return lerp( getFrac( srcVal, srcMin, srcMax ), destMin, destMax );
		}
		
		static public function clamp( val:Number, min:Number, max:Number ):Number
		{
			if ( val < min )
				return min;
			else if ( val > max )
				return max;
			return val;
		}
		
		static public function moveValueTowards( value:Number, desired:Number, rate:Number):Number
		{
			if ( value < desired )
			{
				value += rate;
				if ( value > desired )
				{
					value = desired;
				}
			}
			else if (value > desired )
			{
				value -= rate;
				if ( value < desired )
				{
					value = desired;
				}
			}
			return value;
		}
		
		static public function sign(value:Object):int
		{
			return ( value >= 0 ? 1 : -1 );
		}
		
		static public function lerp(t:Number, min:Number, max:Number ): Number
		{
			return min + ( t * ( max - min ) );
		}
		
		static public function squareDistance( pt1:FlxPoint, pt2:FlxPoint):Number
		{
			var dx:Number = pt1.x - pt2.x;
			var dy:Number = pt1.y - pt2.y;
			return( dx * dx ) + ( dy * dy );
		}
		
		// blendRGB uses this Number prototype
		// converts a (hex) number to r,g, and b.
		static public function HEXtoARGB( color:uint):Object
		{
			return {red:(color >> 16)& 0xff, green:(color >> 8) & 0xff, blue:color & 0xff, alpha:(color >> 24)& 0xff};
		}
		
		static public function ARGBtoHEX( color:Object):uint
		{
			return (color.red << 16) | 
				(color.green << 8) | 
				(color.blue) |
				(color.alpha << 24);
		}
		
		static public function blendARGB(c1:uint, c2:uint, t:Number):uint
		{
			if (t <= 0)
			{
				return c1;
			}
			else if (t >= 1)
			{
				return c2;
			}
			var c1ARGB:Object = HEXtoARGB(c1);
			var c2ARGB:Object = HEXtoARGB(c2);
			var res:uint = (lerp(t, c1ARGB.red, c2ARGB.red) << 16) | 
				(lerp(t, c1ARGB.green, c2ARGB.green) << 8) | 
				(lerp(t, c1ARGB.blue, c2ARGB.blue)) |
				(lerp(t, c1ARGB.alpha, c2ARGB.alpha) << 24);
			return res;
		}
		
		static public function blendRGB(c1:uint, c2:uint, t:Number):uint
		{
			if (t <= 0)
			{
				return c1;
			}
			else if (t >= 1)
			{
				return c2;
			}
			var c1ARGB:Object = HEXtoARGB(c1);
			var c2ARGB:Object = HEXtoARGB(c2);
			var res:uint = (lerp(t, c1ARGB.red, c2ARGB.red) << 16) | 
				(lerp(t, c1ARGB.green, c2ARGB.green) << 8) | 
				(lerp(t, c1ARGB.blue, c2ARGB.blue)) |
				(c1ARGB.alpha << 24);
			return res;
		}
		
		static public function uintToHexStr8Digits(value:uint, prefix:String = "0x"):String
		{
			var hexStr:String = value.toString(16);
			while ( hexStr.length < 8 )
			{
				hexStr = "0" + hexStr;
			}
			hexStr = prefix + hexStr;
			return hexStr;
		}
		
		static public function uintToHexStr6Digits(value:uint, prefix:String = "0x"):String
		{
			var argb:Object = HEXtoARGB(value);
			value = (argb.red << 16) | (argb.green << 8) | argb.blue;
			var hexStr:String = value.toString(16);
			while ( hexStr.length < 6 )
			{
				hexStr = "0" + hexStr;
			}
			hexStr = prefix + hexStr;
			return hexStr;
		}
		
		// Returns index of entry or -1 if not found.
		// if exactMatch is false then it returns the index that this entry should be inserted.
		static public function binarySearch(keys:*, target:Object, evalFunction:Function, exactMatch:Boolean = true ):int
		{
			if ( keys == null )
			{
				return -1;
			}
			
			var high:int = keys.length;
			var low:int = -1;
			
			if ( evalFunction == null )
			{
				// evalFunction(keys[n]) == number evaluation of the position of the element.
				throw new Error("No evalFunction provided for binarySearch");
			}
		 
			while (high - low > 1)
			{
				var probe:int = (low + high) >>> 1; // Bit operations helps to speed up the process
				if ( evalFunction( keys[probe] ) > target)
				{
					high = probe;
				}
				else
				{
					low = probe;
				}
			}
			
			if ( low != -1 && evalFunction( keys[low] ) === target )
			{
				return low;
			}
			
			return ( exactMatch ? -1 :  Math.max(0, low + 1) );
		}
		
		// CUBIC BEZIERS:
		
		// positions a point or movieclip (pnt) along a BezierCurve based on position t
		// t is a number from 0 to 1, where 0 is at endpoint1 and 1 is at endpoint2
		static public function GetPositionOnBezierSegment(t:Number, Anchor1:FlxPoint, Control1:FlxPoint, Control2:FlxPoint, Anchor2:FlxPoint, Out:FlxPoint = null):FlxPoint
		{
			var square:Number = t * t;
			var cube:Number = t*t*t;
			var inv:Number = 1 - t;
			var invsquare:Number = inv * inv;
			var invcube:Number = inv * inv * inv;
			if ( Out == null )
			{
				Out = new FlxPoint();
			}
			Out.x = (invcube * Anchor1.x) + (3 * t * invsquare * Control1.x) + (3 * square * inv * Control2.x) + (cube * Anchor2.x);
			Out.y = (invcube * Anchor1.y) + (3 * t * invsquare * Control1.y) + (3 * square * inv * Control2.y) + (cube * Anchor2.y);
			return Out;
		}
		
		
		static public function GetLengthOfBezierSegment(Anchor1:FlxPoint, Control1:FlxPoint, Control2:FlxPoint, Anchor2:FlxPoint, lengths:Vector.<Number>, points:Vector.<FlxPoint>, includeFirstPoint:Boolean, numDivisions:uint = 10 ):Number
		{
			var length:Number = 0;
			var oldx:Number = Anchor1.x;
			var oldy:Number = Anchor1.y;
			var x:Number;
			var y:Number;
			
			var div:Number = 1 / numDivisions;
			
			var pt:FlxPoint = new FlxPoint;
			var segLen:Number;
			
			if( includeFirstPoint )
				points.push( Anchor1.copy() );
			
			for ( var t:Number = 0.1; t < 1; t+=div )
			{
				GetPositionOnBezierSegment(t, Anchor1, Control1, Control2, Anchor2, pt );
				x = pt.x;
				y = pt.y;
				
				segLen = Math.sqrt( ((x - oldx) * (x - oldx)) + ((y - oldy) * (y - oldy)) );
				
				oldx = x;
				oldy = y;
				
				
				points.push( pt.copy() );
				lengths.push( segLen );
				length += segLen;
			}
			segLen = Math.sqrt( ((Anchor2.x - oldx) * (Anchor2.x - oldx)) + ((Anchor2.y - oldy) * (Anchor2.y - oldy)) );

			points.push( Anchor2.copy() );
			lengths.push( segLen );
			length += segLen;
			
			return length;// Math.sqrt(length);
		}
		
		static public function ClosestPointOnSegment( lineStart:FlxPoint, lineEnd:FlxPoint, p:FlxPoint, closestPtResult:FlxPoint ):Number
		{
			var d:FlxPoint = lineEnd.v_sub(lineStart);
			var numer:Number = d.dot( p.v_sub(lineStart) );
			if (numer <= 0.0)
			{
				closestPtResult.copyFrom(lineStart);
				return 0;
			}
			var denom:Number = d.dot(d);
			if (numer >= denom)
			{
				closestPtResult.copyFrom(lineEnd);
				return 1;
			}
			var t:Number = numer / denom;
			d.multiplyBy( t );
			closestPtResult.copyFrom(lineStart.v_add( d ) );
			return t;
		}
		
		static public function FilesMatch(file1:File, file2:File ):Boolean
		{
			if ( !file1 || !file2 )
			{
				return false;
			}
			var pattern:RegExp = /\\/g;
			return ( file1.url.replace(pattern, "/" ).toLowerCase() == file2.url.replace(pattern, "/" ).toLowerCase() );
		}
			
		static public function FilenamesMatch(filename1:String, filename2:String ):Boolean
		{
			var pattern:RegExp = /\\/g;
			return ( filename1.replace(pattern, "/" ).toLowerCase() == filename2.replace(pattern, "/" ).toLowerCase() );
		}
		
		static public function FixMacFilePaths(filename:String):String
		{
			/*if ((Capabilities.os.indexOf("Mac OS") > -1 || Capabilities.os.indexOf("linux") > -1) && filename.indexOf("file://")==-1)
			{
				filename = "file://" + filename;
			}*/
			return filename;
		}
		
		static public function GetRelativePath( baseDirectory:String, file:File, keyword:String):String
		{
			if ( baseDirectory && baseDirectory.length )
			{
				try
				{
					var sourceFile:File = new File(baseDirectory);
					var path:String = sourceFile.getRelativePath( file, true );
					return path;
				}
				catch (error:Error){}
			}
			return file.nativePath;
		}
		
		static public function RoundNumberToDecimalPlaces( number:Number, decimals:uint ):Number
		{
			var num:Number = number * decimals;
			num = Math.round( num );
			num /= decimals;
			return num;
		}
		
		static public function ModulateAngle( angle:Number ):Number
		{
			while ( angle > 360 )
			{
				angle -= 360;
			}
			while ( angle < 0 )
			{
				angle += 360;
			}
			return angle;
		}
		
		static public function DrawCustomRect( x1:int, y1:int, x2:int, y2:int, drawFunction:Function, drawData:Object ):void
		{
			DrawCustomLine( x1, y1, x2, y1, drawFunction, drawData );
			DrawCustomLine( x2, y1, x2, y2, drawFunction, drawData );
			DrawCustomLine( x2, y2, x1, y2, drawFunction, drawData );
			DrawCustomLine( x1, y2, x1, y1, drawFunction, drawData );
		}
		
		static public function DrawCustomLine( x1:int, y1:int, x2:int, y2:int, drawFunction:Function, drawData:Object ):void
		{			
			// Plot using Bresenham.
			
			var deltax:int = Math.abs(x2 - x1);        // The difference between the x's
			var deltay:int = Math.abs(y2 - y1);        // The difference between the y's
			var x:int = x1;                       // Start x off at the first pixel
			var y:int = y1;                       // Start y off at the first pixel
			var xinc1:int;
			var xinc2:int;
			var yinc1:int;
			var yinc2:int;

			if (x2 >= x1)                 // The x-values are increasing
			{
				xinc1 = 1;
				xinc2 = 1;
			}
			else                          // The x-values are decreasing
			{
				xinc1 = -1;
				xinc2 = -1
			}

			if (y2 >= y1)                 // The y-values are increasing
			{
				yinc1 = 1;
				yinc2 = 1;
			}
			else                          // The y-values are decreasing
			{
				yinc1 = -1;
				yinc2 = -1;
			}
			
			var den:int;
			var num:int;
			var numpixels:int;
			var numadd:int;

			if (deltax >= deltay)         // There is at least one x-value for every y-value
			{
				xinc1 = 0;                  // Don't change the x when numerator >= denominator
				yinc2 = 0;                  // Don't change the y for every iteration
				den = deltax;
				num = deltax / 2;
				numadd = deltay;
				numpixels = deltax;         // There are more x-values than y-values
			}
			else                          // There is at least one y-value for every x-value
			{
				xinc2 = 0;                  // Don't change the x for every iteration
				yinc1 = 0;                  // Don't change the y when numerator >= denominator
				den = deltay;
				num = deltay / 2;
				numadd = deltax;
				numpixels = deltay;         // There are more y-values than x-values
			}

			for (var curpixel:int = 0; curpixel <= numpixels; curpixel++)
			{
				drawFunction(x, y, drawData );
				
				num += numadd;              // Increase the numerator by the top of the fraction
				if (num >= den)             // Check if numerator >= denominator
				{
					num -= den;               // Calculate the new numerator value
					x += xinc1;               // Change the x as appropriate
					y += yinc1;               // Change the y as appropriate
				}
				x += xinc2;                 // Change the x as appropriate
				y += yinc2;                 // Change the y as appropriate
			}
		}
		
		public static function IsPosOverObject( obj:Object, screenX:int, screenY:int ):Boolean
		{
			testPt.x = obj.x;
			testPt.y = obj.y;
			if ( !obj.parent || !obj.parent.stage )
				return false;
				
			testPt = obj.parent.localToGlobal( testPt );
			testPt = obj.parent.stage.nativeWindow.globalToScreen( testPt );
			return ( screenX >= testPt.x && screenX <= testPt.x + obj.width
				&& screenY >= testPt.y && screenY <= testPt.y + obj.height );
		}
		
		public static function ReplaceAllStrings( sourceString:String, keyword:String, replaceText:String ):String
		{
			var testForMatch:RegExp = new RegExp(keyword, "g");
			return sourceString.replace(testForMatch, replaceText);
		}
		
		//////////////////////////////////////////////////////////////////////////////
		// Spritesheet manipulation functions.
		
		public static function GetTileBitmap( bitmap:BitmapData, tileIndex:uint, tileWidth:uint, tileHeight:uint ):BitmapData
		{
			var rx:uint = tileIndex * tileWidth;
			var ry:uint = 0;
			if(rx >= bitmap.width)
			{
				ry = uint(rx/bitmap.width)*tileHeight;
				rx %= bitmap.width;
			}
			var sourceRect:Rectangle = new Rectangle(rx, ry, tileWidth, tileHeight);
			testPt.x = 0;
			testPt.y = 0;
			var bitmapOut:BitmapData = new BitmapData(tileWidth, tileHeight, true, 0xffffff);
			bitmap.lock();
			bitmapOut.copyPixels(bitmap, sourceRect, testPt, null, null, true);
			bitmap.unlock();
			return bitmapOut;
		}
		
		public static function SetTileBitmap( bitmap:BitmapData, tileIndex:uint, tileWidth:uint, tileHeight:uint, newTile:BitmapData, extraBitmap:BitmapData = null ):void
		{
			var rx:uint = tileIndex * tileWidth;
			var ry:uint = 0;
			if(rx >= bitmap.width)
			{
				ry = uint(rx/bitmap.width)*tileHeight;
				rx %= bitmap.width;
			}
			var sourceRect:Rectangle = new Rectangle(0, 0, tileWidth, tileHeight);
			testPt.x = rx;
			testPt.y = ry;
			bitmap.lock();
			// No merge alpha so this just overwrites the existing bitmap.
			bitmap.copyPixels(newTile, sourceRect, testPt, null, null, false);
			bitmap.unlock();
			if ( extraBitmap )
			{
				extraBitmap.copyPixels(newTile, sourceRect, testPt, null, null, false);
			}
			/*
			if ( alpha < 1 )
			{
				setAlpha(alpha, true);
			}*/
		}
		
		public static function insertNewTile( sourceBitmap:BitmapData, sourceTileId:int, insertAfterTileId:int, tileWidth:int, tileHeight:int, originalTileCount:uint ):BitmapData
		{
			var i:int;
			
			var bmp:BitmapData;
			
			// The maximum width of a bitmap in Flash is 8000 in either direction.
			
			// Calculate the actual used dimensions of the bitmap by tiles.
			var rx:uint = originalTileCount * tileWidth;
			var ry:uint = 0;
			if(rx > sourceBitmap.width)
			{
				// This image already has multiple rows.
				ry = uint(rx/sourceBitmap.width);
				rx %= sourceBitmap.width;
			}
			else
			{
				// It's a one row image.
				rx = 0;
				ry = 0;
			}
			
			var newBitmap:BitmapData = sourceBitmap;
			
			// First determine if the entire bitmap needs resizing...
			// This only happens if we're shunting down to a new line.
			if ( rx == 0 )
			{
				var sourceRect:Rectangle = new Rectangle(0, 0, sourceBitmap.width, sourceBitmap.height );
				testPt.x = 0;
				testPt.y = 0;
				if ( ry == 0 && sourceBitmap.width + tileWidth < 4000 )
				{
					// width must increase by 1 tile
					bmp = new BitmapData( sourceBitmap.width + tileWidth, sourceBitmap.height,true,0x00000000 );
					bmp.copyPixels( sourceBitmap, sourceRect, testPt );
				}
				else
				{
					// height must increase by 1 tile.
					bmp = new BitmapData( sourceBitmap.width, sourceBitmap.height + tileHeight ,true,0x00000000 );
					bmp.copyPixels( sourceBitmap, sourceRect, testPt );
				}
				newBitmap = bmp;
			}
			
			var sourceTileBmp:BitmapData;
			
			if ( sourceTileId >= 0 )
			{
				sourceTileBmp = GetTileBitmap( sourceBitmap, sourceTileId, tileWidth, tileHeight);
			}
			else
			{
				sourceTileBmp = new BitmapData(tileWidth, tileHeight, true,0x00000000 );
			}
			
			// Shunt all following tiles up 1.
			for ( i = originalTileCount - 1; i >= insertAfterTileId; i-- )
			{
				bmp = GetTileBitmap( sourceBitmap, i, tileWidth, tileHeight);
				SetTileBitmap( newBitmap, i + 1, tileWidth, tileHeight, bmp );
			}
			
			SetTileBitmap( newBitmap, insertAfterTileId + 1, tileWidth, tileHeight, sourceTileBmp );
			return newBitmap;
		}
		
		public static function removeTileAndShuntDown( sourceBitmap:BitmapData, tileId:uint, tileWidth:int, tileHeight:int, originalTileCount:uint ):BitmapData
		{
			var i:uint;
			
			var bmp:BitmapData;
			
			// Calculate the actual used dimensions of the bitmap by tiles.
			var rx:uint = (originalTileCount-1) * tileWidth;
			var ry:uint = 0;
			if(rx > sourceBitmap.width)
			{
				// This image already has multiple rows.
				ry = uint(rx/sourceBitmap.width);
				rx %= sourceBitmap.width;
			}
			else
			{
				// It's a one row image.
				rx = 0;
				ry = 0;
			}
			
			var sourceRect:Rectangle;
			var newBitmap:BitmapData = sourceBitmap;
			if ( ry > 0 && rx == 0 )
			{
				// The image will lose a row, so resize it
				sourceRect = new Rectangle(0, 0, sourceBitmap.width, sourceBitmap.height - tileHeight );
				testPt.x = 0;
				testPt.y = 0;
				bmp = new BitmapData( sourceBitmap.width, sourceBitmap.height - tileHeight ,true );
				bmp.copyPixels( sourceBitmap, sourceRect, testPt );
				newBitmap = bmp;
			}
			else if ( ry == 0 )
			{
				// The width will decrease by 1.
				sourceRect = new Rectangle(0, 0, sourceBitmap.width - tileWidth, sourceBitmap.height );
				testPt.x = 0;
				testPt.y = 0;
				bmp = new BitmapData( sourceBitmap.width - tileWidth, sourceBitmap.height ,true );
				bmp.copyPixels( sourceBitmap, sourceRect, testPt );
				newBitmap = bmp;
			}
			
			
			// Set the tile to tile 0 just in case...
			bmp = GetTileBitmap( sourceBitmap, 0, tileWidth, tileHeight);
			SetTileBitmap( newBitmap, tileId, tileWidth, tileHeight, bmp );
			
			// Shunt all the following tiles down by 1.
			for ( i = tileId + 1; i < originalTileCount; i++ )
			{
				bmp = GetTileBitmap( sourceBitmap, i, tileWidth, tileHeight);
				SetTileBitmap( newBitmap, i - 1, tileWidth, tileHeight, bmp );
			}
			return newBitmap;
		}

	}

}