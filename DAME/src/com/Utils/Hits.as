package com.Utils 
{
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Hits
	{
		
		/*static public function PointInTriangle( P:FlxPoint, A:FlxPoint, B:FlxPoint, C:FlxPoint ):Boolean
		{
			// Barycentric Method outlined at http://www.blackpawn.com/texts/pointinpoly/default.html
			
			// Compute vectors        
			var v0:FlxPoint = C - A
			var v1:FlxPoint = B - A
			var v2:FlxPoint = P - A

			// Compute dot products
			var dot00:Number = dot(v0, v0)
			var dot01:Number = dot(v0, v1)
			var dot02:Number = dot(v0, v2)
			var dot11:Number = dot(v1, v1)
			var dot12:Number = dot(v1, v2)

			// Compute barycentric coordinates
			var invDenom:Number = 1 / (dot00 * dot11 - dot01 * dot01)
			u = (dot11 * dot02 - dot01 * dot12) * invDenom
			v = (dot00 * dot12 - dot01 * dot02) * invDenom

			// Check if point is in triangle
			return (u > 0) && (v > 0) && (u + v < 1)

		}*/
		
		// Test if a point is in a rectangle by passing in the test point and any three points of the rectangle.
		static public function PointInRectangle( testPt:FlxPoint, cornerPt:FlxPoint, ptB:FlxPoint, ptC:FlxPoint, posOUT:FlxPoint = null ):Boolean
		{
			// Barycentric Method outlined at http://www.blackpawn.com/texts/pointinpoly/default.html
			// modified to account for rotated rectangles.
			// Will expect the box to be rectangle ( of any orientation ) or parallelogram. But opposite sides must be parallel.
			
			// Compute vectors        
			var v0:FlxPoint = ptC.v_sub(cornerPt);
			var v1:FlxPoint = ptB.v_sub(cornerPt);
			var v2:FlxPoint = testPt.v_sub(cornerPt)

			// Compute dot products
			var dot00:Number = v0.dot(v0);
			var dot01:Number = v0.dot(v1);
			var dot02:Number = v0.dot(v2);
			var dot11:Number = v1.dot(v1);
			var dot12:Number = v1.dot(v2);

			// Compute barycentric coordinates
			var invDenom:Number = 1 / (dot00 * dot11 - dot01 * dot01);
			var u:Number = (dot11 * dot02 - dot01 * dot12) * invDenom;
			var v:Number = (dot00 * dot12 - dot01 * dot02) * invDenom;

			if ( posOUT )
			{
				posOUT.x = u;
				posOUT.y = 1-v;
			}
			// Check if point is in box
			return (u > 0) && (v > 0) && (u < 1) && (v < 1)

		}
		
		static public function PointIsInUnrotatedRectangleRange( pt:FlxPoint, x1:Number, y1:Number, range:Number ):Boolean
		{
			return Math.abs(x1 - pt.x) < range &&  Math.abs(y1 - pt.y) < range;
		}
		
		// Infinite line intersection. Returns true if intersection occurs within the line.
		// pt will contain the intersection point, wherever it is.
		static public function LineRayIntersection(x1:Number, y1:Number, x2:Number, y2:Number, rayX:Number, rayY:Number, rayDirX:Number, rayDirY:Number, pt:FlxPoint):Boolean
		{
			var bx:Number = x2 - x1;
			var by:Number = y2 - y1;
			var dx:Number = rayDirX - rayX;
			var dy:Number = rayDirY - rayY; 
			var b_dot_d_perp:Number = bx*dy - by*dx;
			if (b_dot_d_perp == 0)
			{
				pt.x = rayX;
				pt.y = rayY;
				return false;
			}
			var cx:Number = rayX-x1; 
			var cy:Number = rayY-y1;
			var t:Number = (cx * dy - cy * dx) / b_dot_d_perp; 
			
			//if(t < 0 || t > 1)
			//	return null;

			/* Use this to do a LineLineIntersection
			var u:Number  = (cx * by - cy * bx) / b_dot_d_perp;
			if(u < 0 || u > 1)
				return null;
			}*/


			/*if ( pt == null )
			{
				pt = new FlxPoint();
			}*/
			pt.create_from_points(x1 + t * bx, y1 + t * by);
			
			return (t >= 0 && t < 1);
			//return pt; 
		}
		
		/**
		 *  Line is (x1,y1) to (x2,y2), point is (px,py).
		 *
		 *  http://wiki.processing.org/w/Find_which_side_of_a_line_a_point_is_on
		 * Returns -ive if to the left of the line.
		 * Returns +ive if to the right of the line.
		 */
		static public function LinePointSide( x1:Number, y1:Number, x2:Number, y2:Number, px:Number, py:Number ):Number
		{
			return (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1);   
		}
		
		
		static public function IntersectAxis(min1:Number, max1:Number, min2:Number, max2:Number, diraxis:Number, returnData:Object ):Boolean
		{
			const intrEps:Number = 1e-9;

			// Carefully check for diraxis==0 using an epsilon.
			if ( Math.abs(diraxis) < intrEps )
			{
				if ((min1 >= max2) || (max1 <= min2))
				{
					// No movement in the axis, and they don't overlap, hence no intersection.
					return false;
				} 
				else 
				{
					// Stationary in the axis, with overlap at t=0 to t=1
					return true;
				}
			} 
			else 
			{
				var start:Number = (min1 - max2) / diraxis;
				var leave:Number = (max1 - min2) / diraxis;

				// Swap to make sure our intervals are correct.
				if(start > leave)
				{
					var temp:Number = start;
					start = leave;
					leave = temp;
				}

				if(start > returnData.tEnter)
					returnData.tEnter = start;
				if(leave < returnData.tLeave)
					returnData.tLeave = leave; 
				if(returnData.tEnter > returnData.tLeave)
					return false;
			}
			return true;
		}

		public static function IntersectBox3d( topLeftA:FlxPoint, botRightA:FlxPoint, heightA:Number, topLeftB:FlxPoint, botRightB:FlxPoint, heightB:Number, xDir:Number, yDir:Number, zDir:Number, returnData:Object):Boolean
		{
			returnData.tEnter = 0.0;
			returnData.tLeave = 1.0;
			//returnData.tX = 1.0;
			//returnData.tY = 1.0;

			if( !IntersectAxis(topLeftA.x, botRightA.x, topLeftB.x, botRightB.x, xDir, returnData))
				return false;
			//returnData.tX = returnData.tLeave;
			//returnData.tLeave = 1.0;
			if( !IntersectAxis(topLeftA.y, botRightA.y, topLeftB.y, botRightB.y, yDir, returnData))
				return false;
			//returnData.tY = returnData.tLeave;
			//returnData.tLeave = 1.0;
			//else if(IntersectAxis(topLeftA.y, topLeftA.y + heightA, topLeftB, topLeftB + heightA, zDir, returnData) == false)
			//	return false;
			//else
				return true;
		}

	}

}