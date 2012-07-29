/**
 * FlxBitmapFont
 * 
 * Part of the Flixel Power Tools set
 * 
 * @version 1.2 - March 31st 2011
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 * @see Requires FlxMath
*/

package com.photonstorm.flixel 
{
	import com.Game.EditorAvatar;
	import com.Tiles.ImageBank;
	import flash.display.Bitmap;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import org.flixel.*;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class FlxBitmapFont extends EditorAvatar
	{
		/**
		 * Alignment of the text when multiLine = true. Set to FlxBitmapFont.ALIGN_LEFT (default), FlxBitmapFont.ALIGN_RIGHT or FlxBitmapFont.ALIGN_CENTER.
		 */
		public var align:String = "left";
		
		/**
		 * If set to true all carriage-returns in text will form new lines (see align). If false the font will only contain one single line of text (the default)
		 */
		public var multiLine:Boolean = false;
		
		/**
		 * Automatically convert any text to upper case. Lots of old bitmap fonts only contain upper-case characters, so the default is true.
		 */
		public var autoUpperCase:Boolean = true;
		
		/**
		 * Adds horizontal spacing between each character of the font, in pixels. Default is 0.
		 */
		public var customSpacingX:uint = 0;
		
		/**
		 * Adds vertical spacing between each line of multi-line text, set in pixels. Default is 0.
		 */
		public var customSpacingY:uint = 0;
		
		public var scaler:Number = 1;
		
		private var _text:String;
		
		public var bmpFile:File = null;
		
		public var characterSetType:String;
		public var characterSet:String;
		
		public var lineSplitText:String = "";
		public var autoTrim:Boolean = true;

		
		/**
		 * Align each line of multi-line text to the left.
		 */
		public static const ALIGN_LEFT:String = "left";
		
		/**
		 * Align each line of multi-line text to the right.
		 */
		public static const ALIGN_RIGHT:String = "right";
		
		/**
		 * Align each line of multi-line text in the center.
		 */
		public static const ALIGN_CENTER:String = "center";
		
		/**
		 * Text Set 1 = !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
		 */
		public static const TEXT_SET1:String = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
		
		/**
		 * Text Set 2 =  !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ
		 */
		public static const TEXT_SET2:String = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		
		/**
		 * Text Set 3 = ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 
		 */
		public static const TEXT_SET3:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ";
		
		/**
		 * Text Set 4 = ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789
		 */
		public static const TEXT_SET4:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789";
		
		/**
		 * Text Set 5 = ABCDEFGHIJKLMNOPQRSTUVWXYZ.,/() '!?-*:0123456789
		 */
		public static const TEXT_SET5:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,/() '!?-*:0123456789";
		
		/**
		 * Text Set 6 = ABCDEFGHIJKLMNOPQRSTUVWXYZ!?:;0123456789\"(),-.' 
		 */
		public static const TEXT_SET6:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ!?:;0123456789\"(),-.' ";
		
		/**
		 * Text Set 7 = AGMSY+:4BHNTZ!;5CIOU.?06DJPV,(17EKQW\")28FLRX-'39
		 */
		public static const TEXT_SET7:String = "AGMSY+:4BHNTZ!;5CIOU.?06DJPV,(17EKQW\")28FLRX-'39";
		
		/**
		 * Text Set 8 = 0123456789 .ABCDEFGHIJKLMNOPQRSTUVWXYZ
		 */
		public static const TEXT_SET8:String = "0123456789 .ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		
		/**
		 * Text Set 9 = ABCDEFGHIJKLMNOPQRSTUVWXYZ()-0123456789.:,'\"?!
		 */
		public static const TEXT_SET9:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ()-0123456789.:,'\"?!";
		
		/**
		 * Text Set 10 = ABCDEFGHIJKLMNOPQRSTUVWXYZ
		 */
		public static const TEXT_SET10:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		
		/**
		 * Text Set 11 = ABCDEFGHIJKLMNOPQRSTUVWXYZ.,\"-+!?()':;0123456789
		 */
		public static const TEXT_SET11:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,\"-+!?()':;0123456789";
		
		public static const fontSets:Array = [FlxBitmapFont.TEXT_SET1,
											FlxBitmapFont.TEXT_SET2,
											FlxBitmapFont.TEXT_SET3,
											FlxBitmapFont.TEXT_SET4,
											FlxBitmapFont.TEXT_SET5,
											FlxBitmapFont.TEXT_SET6,
											FlxBitmapFont.TEXT_SET9,
											FlxBitmapFont.TEXT_SET11,
											FlxBitmapFont.TEXT_SET7,
											FlxBitmapFont.TEXT_SET8,
											FlxBitmapFont.TEXT_SET10,
											""];
		[Bindable]
		public static var fontCharactersArray:Array = [
				"Full Set",
				"Half Set",
				"Alpha Num 1",
				"Alpha Num 2",
				"Alpha Symbol Num 1",
				"Alpha Symbol Num 2",
				"Alpha Symbol Num 3",
				"Alpha Symbol Num 4",
				"AGMSY",
				"Num Alpha",
				"Alpha",
				"Other" ];
		
		/**
		 * Internval values. All set in the constructor. They should not be changed after that point.
		 */
		public var fontSet:BitmapData;
		private var offsetX:uint;
		private var offsetY:uint;
		public var characterWidth:uint;
		public var characterHeight:uint;
		public var characterSpacingX:uint;
		public var characterSpacingY:uint;
		public var characterPerRow:uint;
		private var grabData:Array;
		
		/**
		 * Loads 'font' and prepares it for use by future calls to .text
		 * 
		 * @param	font		The font set graphic class (as defined by your embed)
		 * @param	width		The width of each character in the font set.
		 * @param	height		The height of each character in the font set.
		 * @param	chars		The characters used in the font set, in display order. You can use the TEXT_SET consts for common font set arrangements.
		 * @param	charsPerRow	The number of characters per row in the font set.
		 * @param	xSpacing	If the characters in the font set have horizontal spacing between them set the required amount here.
		 * @param	ySpacing	If the characters in the font set have vertical spacing between them set the required amount here
		 * @param	xOffset		If the font set doesn't start at the top left of the given image, specify the X coordinate offset here.
		 * @param	yOffset		If the font set doesn't start at the top left of the given image, specify the Y coordinate offset here.
		 */
        public function FlxBitmapFont(bmp:BitmapData, width:uint, height:uint, chars:String, charsPerRow:uint, xSpacing:uint = 0, ySpacing:uint = 0, xOffset:uint = 0, yOffset:uint = 0):void
        {
			super(0, 0, null);
			//	Take a copy of the font for internal use
			fontSet = bmp;
			
			characterWidth = width;
			characterHeight = height;
			characterSpacingX = xSpacing;
			characterSpacingY = ySpacing;
			characterPerRow = charsPerRow;
			offsetX = xOffset;
			offsetY = yOffset;
			
			characterSet = chars;
			
			constructGrabData();
		}
		
		private function constructGrabData():void
		{
			grabData = new Array();
			
			//	Now generate our rects for faster copyPixels later on
			var currentX:uint = offsetX;
			var currentY:uint = offsetY;
			var r:uint = 0;
			
			for (var c:uint = 0; c < characterSet.length; c++)
			{
				//	The rect is hooked to the ASCII value of the character
				grabData[characterSet.charCodeAt(c)] = new Rectangle(currentX, currentY, characterWidth, characterHeight);
				
				r++;
				
				//if (r == characterPerRow)
				if( currentX + characterWidth >= fontSet.width )
				{
					r = 0;
					currentX = offsetX;
					currentY += characterHeight + characterSpacingY;
				}
				else
				{
					currentX += characterWidth + characterSpacingX;
				}
			}
        }
		
		/**
		 * Set this value to update the text in this sprite. Carriage returns are automatically stripped out if multiLine is false. Text is converted to upper case if autoUpperCase is true.
		 * 
		 * @return	void
		 */ 
		public function set text(content:String):void
		{
			var newText:String;
			
			if (autoUpperCase)
			{
				newText = content.toUpperCase();
			}
			else
			{
				newText = content;
			}
			
			// Smart update: Only change the bitmap data if the string has changed
			if (newText != _text)
			{
				_text = newText;
				
				removeUnsupportedCharacters(multiLine);
				
				buildBitmapFontText();
			}
		}
		
		public function get text():String
		{
			return _text;
		}
		
		/**
		 * A helper function that quickly sets lots of variables at once, and then updates the text.
		 * 
		 * @param	content				The text of this sprite
		 * @param	multiLines			Set to true if you want to support carriage-returns in the text and create a multi-line sprite instead of a single line (default is false).
		 * @param	characterSpacing	To add horizontal spacing between each character specify the amount in pixels (default 0).
		 * @param	lineSpacing			To add vertical spacing between each line of text, set the amount in pixels (default 0).
		 * @param	lineAlignment		Align each line of multi-line text. Set to FlxBitmapFont.ALIGN_LEFT (default), FlxBitmapFont.ALIGN_RIGHT or FlxBitmapFont.ALIGN_CENTER.
		 * @param	allowLowerCase		Lots of bitmap font sets only include upper-case characters, if yours needs to support lower case then set this to true.
		 */
		public function setText(content:String, multiLines:Boolean = false, characterSpacing:uint = 0, lineSpacing:uint = 0, lineAlignment:String = "left", allowLowerCase:Boolean = false):void
		{
			customSpacingX = characterSpacing;
			customSpacingY = lineSpacing;
			align = lineAlignment;
			multiLine = multiLines;
			
			if (allowLowerCase)
			{
				autoUpperCase = false;
			}
			else
			{
				autoUpperCase = true;
			}
			
			if (content.length > 0)
			{
				text = content;
			}
		}
		
		private function getHorizLineStartForAlignment( text:String ):int
		{
			var cx:int = 0;
			switch (align)
			{
				case ALIGN_LEFT:
					cx = 0;
					break;
					
				case ALIGN_RIGHT:
					cx = width - (text.length * (characterWidth + customSpacingX) * scaler);
					break;
					
				case ALIGN_CENTER:
					cx = (width / 2) - ((text.length * (characterWidth + customSpacingX) * scaler) / 2);
					cx += ( scaler * customSpacingX )/ 2;
					break;
			}
			return cx;
		}
		
		/**
		 * Updates the BitmapData of the Sprite with the text
		 * 
		 * @return	void
		 */
		public function buildBitmapFontText():void
		{
			var temp:BitmapData;
			
			if (multiLine)
			{
				
				
				var cx:int = 0;
				var cy:int = 0;
				
				lineSplitText = autoTrim ? buildLineString(_text ) : _text;
				// yep, that entire first pass was just to get the dimensions of the bmp
				
				var lines:Array = lineSplitText.split("\r");
				
				temp = new BitmapData(width, height, true, 0xf);
				//	Loop through each line of text
				for ( var i:uint = 0; i < lines.length; i++)
				{
					//	This line of text is held in lines[i] - need to work out the alignment
					cx = getHorizLineStartForAlignment(lines[i]);
					
					var numLinesAdded:int = pasteLine(temp, lines[i], cx, cy, customSpacingX);
					
					cy += scaler * (characterHeight + customSpacingY) * numLinesAdded;
				}
			}
			else
			{
				temp = new BitmapData(_text.length * (characterWidth + customSpacingX), characterHeight, true, 0xf);
			
				pasteLine(temp, _text, 0, 0, customSpacingX);
			}
			
			pixels = temp;
		}
		
		/**
		 * Returns a single character from the font set as an FlxsSprite.
		 * 
		 * @param	char	The character you wish to have returned.
		 * 
		 * @return	An <code>FlxSprite</code> containing a single character from the font set.
		 */
		public function getCharacter(char:String):FlxSprite
		{
			var output:FlxSprite = new FlxSprite();
			
			var temp:BitmapData = new BitmapData(characterWidth, characterHeight, true, 0xf);

			if (grabData[char.charCodeAt(0)] is Rectangle && char.charCodeAt(0) != 32)
			{
				temp.copyPixels(fontSet, grabData[char.charCodeAt(0)], new Point(0, 0));
			}
			
			output.pixels = temp;
			
			return output;
		}
		
		private function buildLineString( line:String ):String
		{
			var numLines:int = 1;
			var firstChar:Boolean = true;
			var newLine:Boolean = true;
			var outputString:String = "";
			var x:uint = 0;
			var y:uint = 0;
			var numQueuedSpaces:int = 0;
			for (var c:uint = 0; c < line.length && y < height; c++)
			{
				if ( x + (scaler * characterWidth ) > width )
				{
					x = 0;
					newLine = true;
					outputString += "\r";
					numQueuedSpaces = 0;
					numLines++;
				}
				//	If it's a space then there is no point copying, so leave a blank space
				if (line.charAt(c) == " ")
				{
					if ( !newLine )
					{
						// Only add a space if not at the start of the line.
						x += scaler * ( characterWidth + customSpacingX );
						numQueuedSpaces++;
					}
					firstChar = true;
				}
				else if ( line.charAt(c) == "\r" )
				{
					firstChar = true;
					newLine = true;
					outputString += "\r";
					numLines++;
					numQueuedSpaces = 0;
					x = 0;
				}
				else
				{
					//	If the character doesn't exist in the font then we don't want a blank space, we just want to skip it
					if (grabData[line.charCodeAt(c)] is Rectangle)
					{
						if (firstChar && !newLine)
						{
							// Look ahead to see if the continuous block of non white space will fit into the line. If not then start on a new line.
							var c2X:uint = x;
							for ( var c2:uint = c; c2 < line.length; c2++ )
							{
								if ( line.charAt(c2) == " " )
									break;
								c2X += scaler * (characterWidth + customSpacingX);
								if ( c2X > width )
								{
									firstChar = true;
									x = 0;
									numLines++;
									newLine = true;
									outputString += "\r";
									numQueuedSpaces = 0;
									break;
								}
							}
						}
						while ( numQueuedSpaces )
						{
							outputString += " ";
							numQueuedSpaces--;
						}
						newLine = false;
						firstChar = false;
						x += scaler * (characterWidth + customSpacingX);
						outputString += line.charAt(c);
					}
				}
			}
			return outputString;
		}
		
		/**
		 * Internal function that takes a single line of text (2nd parameter) and pastes it into the BitmapData at the given coordinates.
		 * Used by getLine and getMultiLine
		 * 
		 * @param	output			The BitmapData that the text will be drawn onto
		 * @param	line			The single line of text to paste
		 * @param	x				The x coordinate
		 * @param	y
		 * @param	customSpacingX
		 * 
		 * returns number of lines pasted
		 */
		private function pasteLine(output:BitmapData, line:String, x:uint = 0, y:uint = 0, customSpacingX:uint = 0):int
		{
			var numLines:int = 1;
			var firstChar:Boolean = true;
			var newLine:Boolean = true;
			for (var c:uint = 0; c < line.length && y < height; c++)
			{
				/*if ( x + (scaler * characterWidth ) > width )
				{
					x = getHorizLineStartForAlignment(line);
					y += scaler * (characterHeight + customSpacingY);
					newLine = true;
					numLines++;
				}*/
				//	If it's a space then there is no point copying, so leave a blank space
				if (line.charAt(c) == " ")
				{
					// Only add a space if not at the start of the line.
					x += scaler * ( characterWidth + customSpacingX );
					firstChar = true;
				}
				else
				{
					//	If the character doesn't exist in the font then we don't want a blank space, we just want to skip it
					if (grabData[line.charCodeAt(c)] is Rectangle)
					{
						/*if (firstChar && !newLine)
						{
							// Look ahead to see if the continuous block of non white space will fit into the line. If not then start on a new line.
							var c2X:uint = x;
							for ( var c2:uint = c; c2 < line.length; c2++ )
							{
								if ( line.charAt(c2) == " " )
									break;
								c2X += scaler * (characterWidth + customSpacingX);
								if ( c2X > width )
								{
									firstChar = true;
									cx = getHorizLineStartForAlignment(line);
									y += scaler * (characterHeight + customSpacingY);
									numLines++;
									newLine = true;
									break;
								}
							}
						}
						newLine = false;*/
						firstChar = false;
						if ( scaler != 1)
						{
							var rect:Rectangle = grabData[line.charCodeAt(c)];
							var mat:Matrix = new Matrix;
							
							mat.translate( -rect.x, -rect.y);
							mat.scale(scaler, scaler);
							mat.translate( x, y);
							rect = rect.clone();
							rect.x = x;
							rect.y = y;
							rect.width *= scaler;
							rect.height *= scaler;
							output.draw(fontSet, mat, null, null, rect );
						}
						else
						{
							output.copyPixels(fontSet, grabData[line.charCodeAt(c)], new Point(x, y));
						}
						x += scaler * (characterWidth + customSpacingX);
					}
				}
			}
			return numLines;
		}
		
		/**
		 * Works out the longest line of text in _text and returns its length
		 * 
		 * @return	A value
		 */
		private function getLongestLine():uint
		{
			var longestLine:uint = 0;
			
			if (_text.length > 0)
			{
				var lines:Array = _text.split("\r");
				
				for (var i:uint = 0; i < lines.length; i++)
				{
					if (lines[i].length > longestLine)
					{
						longestLine = lines[i].length;
					}
				}
			}
			
			return longestLine;
		}
		
		/**
		 * Internal helper function that removes all unsupported characters from the _text String, leaving only characters contained in the font set.
		 * 
		 * @param	stripCR		Should it strip carriage returns as well? (default = true)
		 * 
		 * @return	A clean version of the string
		 */
		private function removeUnsupportedCharacters(stripCR:Boolean = true):String
		{
			var newString:String = "";
			
			for (var c:uint = 0; c < _text.length; c++)
			{
				if (grabData[_text.charCodeAt(c)] is Rectangle || _text.charCodeAt(c) == 32 || (stripCR == false && _text.charAt(c) == "\n"))
				{
					newString = newString.concat(_text.charAt(c));
				}
			}
			
			return newString;
		}
		
		public function loadImage():void
		{
			ImageBank.LoadImage( bmpFile, imageLoaded );
		}
		
		private function imageLoaded( data:Bitmap, file:File ):void
		{
			width = data.width;
			height = data.height;
			fontSet = data.bitmapData;
			
			constructGrabData();
			//setText( text, true, customSpacingX, customSpacingY, align, false);
			buildBitmapFontText();
		}
	}

}