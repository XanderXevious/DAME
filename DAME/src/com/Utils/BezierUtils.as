//
// BezierUtils.as - A small collection of static utilities for use with single-segment Bezier curves, or more generally
// any curve implementing the IParametric interface
//
// copyright (c) 2006-2008, Jim Armstrong.  All Rights Reserved.
//
// This software program is supplied 'as is' without any warranty, express, implied, 
// or otherwise, including without limitation all warranties of merchantability or fitness
// for a particular purpose.  Jim Armstrong shall not be liable for any special incidental, or 
// consequential damages, including, without limitation, lost revenues, lost profits, or 
// loss of prospective economic advantage, resulting from the use or misuse of this software 
// program.
//
// Programmed by Jim Armstrong, Singularity (www.algorithmist.net)
//
// Version 1.0
//

package com.Utils
{ 
  import org.flixel.FlxPoint;
  //import Singularity.Geom.IParametric;
  //import Singularity.Geom.Bezier2;
  //import Singularity.Geom.Bezier3;
  
  //import Singularity.Numeric.SimpleRoot;
  //import Singularity.Numeric.Bisect;
  
  //import flash.geom.Point;
  //import Singularity.Geom.Bezier;
  
  public class BezierUtils
  {
  	private static const MAX_DEPTH:uint = 64;                                 // maximum recursion depth
  	private static const EPSILON:Number = 1.0 * Math.pow(2, -MAX_DEPTH-1);    // flatness tolerance
  	
  	// pre-computed z(i,j)
  	private static const Z_CUBIC:Array = [1.0, 0.6, 0.3, 0.1, 0.4, 0.6, 0.6, 0.4, 0.1, 0.3, 0.6, 1.0];
  	private static const Z_QUAD:Array  = [1.0, 2/3, 1/3, 1/3, 2/3, 1.0];
  	
  	private static var __dMinimum:Number = 0; // minimum distance (cached for accessor)
  	
    /*public function BezierUtils()
    {
      __dMinimum = 0;
    }*/
    
/**
* minDistance():Number [get] access the minimum distance
*
* @return Number mimimum distance from specified point to point on the Bezier curve.  Call after <code>closestPointToBezier()</code>.
*
* @since 1.0
*
*/   
    public function get minDistance():Number { return __dMinimum; }
    
/**
* closestPointToBezier( _curve:IParametric, _p:FlxPoint ):Number
*
* @param _curve:IParametric reference (must be Bezier2 or Bezier3) to a Bezier curve
* @param _p:FlxPoint reference to <code>Point</code> to which the closest point on the Bezier curve is desired
*
* @return Number t-parameter of the closest point on the parametric curve.  The <code>getX</code> and <code>getY</code> methods may be called to
* return the (x,y) coordinates on the curve at that t-value.  Returns 0 if the input is <code>null</code> or not a reference to a Bezier curve.
*
* This code is derived from the Graphic Gem, "Solving the Nearest-Point-On-Curve Problem", by P.J. Schneider, published in 'Graphic Gems', 
* A.S. Glassner, ed., Academic Press, Boston, 1990, pp. 607-611.
*
* @since 1.0
*
*/
    public static function closestPointToBezier( Anchor1:FlxPoint, Control1:FlxPoint, Control2:FlxPoint, Anchor2:FlxPoint, _p:FlxPoint, closestPtResult:FlxPoint ):Number
    {
      /*if( _curve == null )
      {
      	return 0;
      }
      
      // tbd - dispatch a warning event in this instance
      if( !(_curve is Bezier2) && !(_curve is Bezier3) )
      {
      	return 0;
      }*/
      
      // record distances from point to endpoints
      var x0:Number     = Anchor1.x;// _curve.getX(0);
      var y0:Number     = Anchor1.y;// _curve.getY(0);
      var deltaX:Number = x0-_p.x;
      var deltaY:Number = y0-_p.y;
      var d0:Number     = Math.sqrt(deltaX*deltaX + deltaY*deltaY);
      
      var x1:Number = Anchor2.x;// _curve.getX(1);
      var y1:Number = Anchor2.y;// _curve.getY(1);
      deltaX        = x1-_p.x;
      deltaY        = y1-_p.y;
      var d1:Number = Math.sqrt(deltaX*deltaX + deltaY*deltaY);
      
      var n:uint = 3;// _curve.degree;  // degree of input Bezier curve
      
      // array of control points
      var v:Array = new Array();
      /*for( var i:uint=0; i<=n; ++i )
      {
      	v.push(_curve.getControlPoint(i));
      }*/
	  v.push(Anchor1);
	  v.push(Control1);
	  v.push(Control2);
	  v.push(Anchor2);
      
      // instaead of power form, convert the function whose zeros are required to Bezier form
      var w:Array = toBezierForm(_p, v);
      
      // Find roots of the Bezier curve with control points stored in 'w' (algorithm is recursive, this is root depth of 0)
      var roots:Array = findRoots(w, 2*n-1, 0);
      
      // compare the candidate distances to the endpoints and declare a winner :)
      if( d0 < d1 )
      {
      	var tMinimum:Number = 0;
      	__dMinimum          = d0;
      }
      else
      {
      	tMinimum   = 1;
      	__dMinimum = d1;
      }
	  
	  var deltas:FlxPoint = new FlxPoint();
	  
	  var i:uint;
      
      // tbd - compare 2-norm squared
      for( i=0; i<roots.length; ++i )
      {
      	var t:Number = roots[i];
      	if( t >= 0 && t <= 1 )
      	{
      	  //deltaX       = _curve.getX(t) - _p.x;
      	  //deltaY       = _curve.getY(t) - _p.y;
		  Misc.GetPositionOnBezierSegment(t, Anchor1, Control1, Control2, Anchor2, deltas);
		  deltaX       = deltas.x - _p.x;
      	  deltaY       = deltas.y - _p.y;
		  
      	  var d:Number = Math.sqrt(deltaX*deltaX + deltaY*deltaY);
      	  
      	  if( d < __dMinimum )
      	  {
      	    tMinimum    = t;
      	    __dMinimum = d;
      	  }
      	}
      }
	  
      // tbd - alternate optima.
	  Misc.GetPositionOnBezierSegment(tMinimum, Anchor1, Control1, Control2, Anchor2, closestPtResult );
      return tMinimum;
    } 
    
	/*
 *  ConvertToBezierForm :
 *		Given a point and a Bezier curve, generate a 5th-degree
 *		Bezier-format equation whose solution finds the point on the
 *      curve nearest the user-defined point.
 */
    // compute control points of the polynomial resulting from the inner product of B(t)-P and B'(t), constructing the result as a Bezier
    // curve of order 2n-1, where n is the degree of B(t).
    private static function toBezierForm(_p:FlxPoint, _v:Array):Array
    {
      var row:uint    = 0;  // row index
      var column:uint = 0;	// column index
      
      var c:Array = new Array();  // V(i) - P
      var d:Array = new Array();  // V(i+1) - V(i)
      var w:Array = new Array();  // control-points for Bezier curve whose zeros represent candidates for closest point to the input parametric curve
   
      var n:uint      = _v.length-1;    // degree of B(t)
      var degree:uint = 2*n-1;          // degree of B(t) . P
      
      var pX:Number = _p.x;
      var pY:Number = _p.y;
      
      for( var i:uint=0; i<=n; ++i )
      {
        var v:FlxPoint = _v[i];
        c[i]        = new FlxPoint(v.x - pX, v.y - pY);
      }
      
      var s:Number = Number(n);
      for( i=0; i<=n-1; ++i )
      {
      	v            = _v[i];
      	var v1:FlxPoint = _v[i+1];
      	d[i]         = new FlxPoint( s*(v1.x-v.x), s*(v1.y-v.y) );
      }
      
      var cd:Array = new Array();
      
      // inner product table
      for( row=0; row<=n-1; ++row )
      {
      	var di:FlxPoint  = d[row];
      	var dX:Number = di.x;
      	var dY:Number = di.y;
      	
      	for( var col:uint=0; col<=n; ++col )
      	{
      	  var k:uint = getLinearIndex(n+1, row, col);
      	  cd[k]      = dX*c[col].x + dY*c[col].y;
      	  k++;
      	}
      }
      
      // Bezier is uniform parameterized
      var dInv:Number = 1.0/Number(degree);
      for( i=0; i<=degree; ++i )
      {
      	w[i] = new FlxPoint(Number(i)*dInv, 0);
      }
      
      // reference to appropriate pre-computed coefficients
      var z:Array = n == 3 ? Z_CUBIC : Z_QUAD;
      
      // accumulate y-coords of the control points along the skew diagonal of the (n-1) x n matrix of c.d and z values
      var m:uint = n-1;
      for( k=0; k<=n+m; ++k ) 
      {
        var lb:uint = Math.max(0, k-m);
        var ub:uint = Math.min(k, n);
        for( i=lb; i<=ub; ++i) 
        {
          var j:uint     = k - i;
          var p:FlxPoint    = w[i+j];
          var index:uint = getLinearIndex(n+1, j, i);
          p.y           += cd[index]*z[index];
          w[i+j]         = p;
        }
      }
      
      return w;	
    }
    
    // convert 2D array indices in a k x n matrix to a linear index (this is an interim step ahead of a future implementation optimized for 1D array indexing)
    private static function getLinearIndex(_n:uint, _row:uint, _col:uint):uint
    {
      // no range-checking; you break it ... you buy it!
      return _row*_n + _col;
    }
    
    // how many times does the Bezier curve cross the horizontal axis - the number of roots is less than or equal to this count
    private static function crossingCount(_v:Array, _degree:uint):uint
    {
      var nCrossings:uint = 0;
      var sign:int        = _v[0].y < 0 ? -1 : 1;
      var oldSign:int     = sign;
      for( var i:int=1; i<=_degree; ++i) 
      {
        sign = _v[i].y < 0 ? -1 : 1;
        if( sign != oldSign ) 
          nCrossings++;
             
         oldSign = sign;
      }
      
      return nCrossings;
    }
    
    // is the control polygon for a Bezier curve suitably linear for subdivision to terminate?
    private static function isControlPolygonLinear(_v:Array, _degree:uint):Boolean 
    {
      // Given array of control points, _v, find the distance from each interior control point to line connecting v[0] and v[degree]
    
      // implicit equation for line connecting first and last control points
      var a:Number = _v[0].y - _v[_degree].y;
      var b:Number = _v[_degree].x - _v[0].x;
      var c:Number = _v[0].x * _v[_degree].y - _v[_degree].x * _v[0].y;
    
      var abSquared:Number = a*a + b*b;
      var distance:Array   = new Array();       // Distances from control points to line
    
      for( var i:uint=1; i<_degree; ++i) 
      {
        // Compute distance from each of the points to that line
        distance[i] = a * _v[i].x + b * _v[i].y + c;
        if( distance[i] > 0.0 ) 
        {
          distance[i] = (distance[i] * distance[i]) / abSquared;
        }
        if( distance[i] < 0.0 ) 
        {
          distance[i] = -((distance[i] * distance[i]) / abSquared);
        }
      }
    
      // Find the largest distance
      var maxDistanceAbove:Number = 0.0;
      var maxDistanceBelow:Number = 0.0;
      for( i=1; i<_degree; ++i) 
      {
        if( distance[i] < 0.0 ) 
        {
          maxDistanceBelow = Math.min(maxDistanceBelow, distance[i]);
        }
        if( distance[i] > 0.0 ) 
        {
          maxDistanceAbove = Math.max(maxDistanceAbove, distance[i]);
        }
      }
    
      // Implicit equation for zero line
      var a1:Number = 0.0;
      var b1:Number = 1.0;
      var c1:Number = 0.0;
    
      // Implicit equation for "above" line
      var a2:Number = a;
      var b2:Number = b;
      var c2:Number = c + maxDistanceAbove;
    
      var det:Number  = a1*b2 - a2*b1;
      var dInv:Number = 1.0/det;
        
      var intercept1:Number = (b1*c2 - b2*c1)*dInv;
    
      //  Implicit equation for "below" line
      a2 = a;
      b2 = b;
      c2 = c + maxDistanceBelow;
        
      var intercept2:Number = (b1*c2 - b2*c1)*dInv;
    
      // Compute intercepts of bounding box
      var leftIntercept:Number  = Math.min(intercept1, intercept2);
      var rightIntercept:Number = Math.max(intercept1, intercept2);
    
      var error:Number = 0.5*(rightIntercept-leftIntercept);    
        
      return error < EPSILON;
    }
    
    // compute intersection of line segnet from first to last control point with horizontal axis
    private static function computeXIntercept(_v:Array, _degree:uint):Number
    {
      var XNM:Number = _v[_degree].x - _v[0].x;
      var YNM:Number = _v[_degree].y - _v[0].y;
      var XMK:Number = _v[0].x;
      var YMK:Number = _v[0].y;
    
      var detInv:Number = - 1.0/YNM;
    
      return (XNM*YMK - YNM*XMK) * detInv;
    }
    
    // return roots in [0,1] of a polynomial in Bernstein-Bezier form
    private static function findRoots(_w:Array, _degree:uint, _depth:uint):Array
    {  
      var t:Array = new Array(); // t-values of roots
      var m:uint  = 2*_degree-1;
      
      switch( crossingCount(_w, _degree) ) 
      {
        case 0: 
          return [];   
        break;
           
        case 1: 
          // Unique solution - stop recursion when the tree is deep enough (return 1 solution at midpoint)
          if( _depth >= MAX_DEPTH ) 
          {
            t[0] = 0.5*(_w[0].x + _w[m].x);
            return t;
          }
            
          if( isControlPolygonLinear(_w, _degree) ) 
          {
            t[0] = computeXIntercept(_w, _degree);
            return t;
          }
        break;
      }
 
      // Otherwise, solve recursively after subdividing control polygon
      var left:Array  = new Array();
      var right:Array = new Array();
       
      // child solutions
         
      subdivide(_w, 0.5, left, right);
      var leftT:Array  = findRoots(left,  _degree, _depth+1);
      var rightT:Array = findRoots(right, _degree, _depth+1);
     
      // Gather solutions together
      for( var i:uint= 0; i<leftT.length; ++i) 
        t[i] = leftT[i];
       
      for( i=0; i<rightT.length; ++i) 
        t[i+leftT.length] = rightT[i];
    
      return t;
    }
    
/**
* subdivide( _c:Array, _t:Number, _left:Array, _right:Array ) - deCasteljau subdivision of an arbitrary-order Bezier curve
*
* @param _c:Array array of control points for the Bezier curve
* @param _t:Number t-parameter at which the curve is subdivided (must be in (0,1) = no check at this point
* @param _left:Array reference to an array in which the control points, <code>Array</code> of <code>Point</code> references, of the left control cage after subdivision are stored
* @param _right:Array reference to an array in which the control points, <code>Array</code> of <code>Point</code> references, of the right control cage after subdivision are stored
* @return nothing 
*
* @since 1.0
*
*/
    public static function subdivide( _c:Array, _t:Number, _left:Array, _right:Array ):void
    {
      var degree:uint = _c.length-1;
      var n:uint      = degree+1;
      var p:Array     = _c.slice();
      var t1:Number   = 1.0 - _t;
      
      for( var i:uint=1; i<=degree; ++i ) 
      {  
        for( var j:uint=0; j<=degree-i; ++j ) 
        {
          var vertex:FlxPoint = new FlxPoint();
          var ij:uint      = getLinearIndex(n, i, j);
          var im1j:uint    = getLinearIndex(n, i-1, j);
          var im1jp1:uint  = getLinearIndex(n, i-1, j+1);
          
          vertex.x = t1*p[im1j].x + _t*p[im1jp1].x;
          vertex.y = t1*p[im1j].y + _t*p[im1jp1].y;
          p[ij]    = vertex;
        }
      }
      
      for( j=0; j<=degree; ++j )
      {
      	var index:uint = getLinearIndex(n, j, 0);
        _left[j]       = p[index];
      }
        
      for( j=0; j<=degree; ++j) 
      {
      	index     = getLinearIndex(n, degree-j, j);
        _right[j] = p[index];
      }
    }
  }
}