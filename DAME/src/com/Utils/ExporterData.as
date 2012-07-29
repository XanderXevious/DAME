package com.Utils 
{
	import com.FileHandling.ExporterSetting;
	/**
	 * ...
	 * @author ...
	 */
	public class ExporterData 
	{
		public var settings:Vector.<ExporterSetting> = new Vector.<ExporterSetting>();
		public var lastExporterName:String = "none";
		public var useRelativePaths:Boolean = false;
		static public var useProjectExporterOnly:Boolean = false;
		static public var exportSpritePos:String = LuaInterface.ExportSpritePosType_TopLeft;
		static public var exportRotatedSpritePos:Boolean = false;
		
		public function ExporterData() 
		{
			
		}
		
		public function Save( parentXml:XML, rootName:String, isGlobalSave:Boolean = false ):XML
		{
			var exporterXml:XML = < {rootName} name = { lastExporterName } 
									spritepos = { exportSpritePos } 
									rotatedSpritePos = { exportRotatedSpritePos }
									relativePaths = { useRelativePaths }
									useProjectExporterOnly = { isGlobalSave ? false : useProjectExporterOnly }/>;
			for each( var setting:ExporterSetting in settings )
			{
				exporterXml.appendChild( < setting name = { setting.name } > { setting.value } </setting> );
			}
			
			parentXml.appendChild( exporterXml );
			return exporterXml;
		}
		
		public function Load( xml:XMLList ):Boolean
		{
			if ( xml == null )
				return false;

			lastExporterName = xml.@name;
			exportSpritePos = xml.@spritepos;
			exportRotatedSpritePos = (xml.@rotatedSpritePos == true);
			if ( xml.hasOwnProperty("@relativePaths") )
			{
				useRelativePaths = (xml.@relativePaths == true);
			}
			if ( xml.hasOwnProperty("@useProjectExporterOnly") )
			{
				useProjectExporterOnly = (xml.@useProjectExporterOnly == true);
			}
			else
			{
				useProjectExporterOnly = false;
			}
			
			var xmlList:XMLList = xml.setting;
			for each (var settingXml:XML in xmlList)
			{
				var setting:ExporterSetting = new ExporterSetting(settingXml.@name, settingXml);
				var i:int = settings.length;
				var found:Boolean = false;
				while (i-- && !found)
				{
					if ( settings[i].name == settingXml.@name )
					{
						settings[i] = setting;
						found = true;
					}
				}
				if ( !found )
					settings.push(setting );
			}
			return true;
		}
		
	}

}