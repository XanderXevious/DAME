package com.Game 
{
	import com.FileHandling.Serialize;
	import com.Tiles.SpriteEntry;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class SpriteTrailData
	{
		public var sprites:Vector.<SpriteTrailEntry> = new Vector.<SpriteTrailEntry>;
		public var RotateFollows:Boolean = false;
		public var RotationOffset:Number = 0;
		public var SpriteSeparation:Number = 50;
		public var CleverSpread:Boolean = true;
		public var EdgeSprites:Boolean = true;
		public var RandomSprites:Boolean = true;
		public var RandomSeed:Number = 1;
		
		public function SpriteTrailData() 
		{
			
		}
		
		public function CopyFrom( source:SpriteTrailData ):void
		{
			sprites.length = 0;
			for each( var entry:SpriteTrailEntry in source.sprites )
			{
				sprites.push( entry );
			}
			RotateFollows = source.RotateFollows;
			RotationOffset = source.RotationOffset;
			SpriteSeparation = source.SpriteSeparation;
			CleverSpread = source.CleverSpread;
			EdgeSprites = source.EdgeSprites;
			RandomSprites = source.RandomSprites;
			RandomSeed = source.RandomSeed;
		}
		
		public function Clone( ):SpriteTrailData
		{
			var newData:SpriteTrailData	= new SpriteTrailData;
			newData.CopyFrom( this );
			return newData;
		}
		
		public function Save( ):XML
		{
			var newXml:XML = < spriteTrailData
					RotateFollows = { RotateFollows }
					RotationOffset = { RotationOffset }
					SpriteSeparation = { SpriteSeparation }
					CleverSpread = { CleverSpread }
					EdgeSprites = { EdgeSprites }
					RandomSprites = { RandomSprites }
					RandomSeed = { RandomSeed }
					/> ;
			var spriteXml:XML = < sprites />;
			newXml.appendChild( spriteXml );
			for each( var entry:SpriteTrailEntry in sprites )
			{
				var entryXml:XML = < sprite id = { entry.sprite.id } />;
				if ( entry.sprite.IsTileSprite )
				{
					if ( entry.offset )
					{
						entryXml["@x"] = entry.offset.x;
						entryXml["@y"] = entry.offset.y;
					}
					if ( entry.dims )
					{
						entryXml["@wid"] = entry.dims.x;
						entryXml["@ht"] = entry.dims.y;
					}
				}
				else
				{
					entryXml["@frame"] = entry.frame;
				}
				if ( entry.anchor )
				{
					entryXml["@anchorX"] = entry.anchor.x;
					entryXml["@anchorY"] = entry.anchor.y;
				}
				spriteXml.appendChild( entryXml );
			}
			return newXml;
		}
		
		public function Load( xml:XML, rootspriteEntry:SpriteEntry, spriteIdxOffset:int ):void
		{
			if ( xml.spriteTrailData.length() )
			{
				var trailXml:XML = xml.spriteTrailData[0];
				RotateFollows = trailXml.@RotateFollows == true;
				RotationOffset = trailXml.@RotationOffset;
				SpriteSeparation = trailXml.@SpriteSeparation;
				CleverSpread = trailXml.@CleverSpread == true;
				EdgeSprites = trailXml.@EdgeSprites == true;
				RandomSprites = trailXml.@RandomSprites == true;
				RandomSeed = trailXml.@RandomSeed;
				var spritesXml:XMLList = trailXml.sprites.sprite;
				sprites.length = 0;
				for each( var spriteXml:XML in spritesXml )
				{
					var entry:SpriteEntry = Serialize.GetSpriteEntryFromIndex( rootspriteEntry, spriteIdxOffset + spriteXml.@id );
					if ( entry )
					{
						var newSpriteData:SpriteTrailEntry = new SpriteTrailEntry( entry );
						sprites.push( newSpriteData );
						if ( spriteXml.hasOwnProperty("@frame") )
						{
							newSpriteData.frame = spriteXml.@frame;
						}
						if ( spriteXml.hasOwnProperty("@x") )
						{
							var x:int = spriteXml.@x;
							var y:int = spriteXml.@y;
							newSpriteData.offset = new FlxPoint( x, y );
						}
						if ( spriteXml.hasOwnProperty("@wid") )
						{
							var wid:int = spriteXml.@wid;
							var ht:int = spriteXml.@ht;
							newSpriteData.dims = new FlxPoint( wid, ht );
						}
						if ( spriteXml.hasOwnProperty("@anchorX") )
						{
							var ax:int = spriteXml.@anchorX;
							var ay:int = spriteXml.@anchorY;
							newSpriteData.anchor = new FlxPoint( ax, ay );
						}
					}
				}
			}
		}
	}

}