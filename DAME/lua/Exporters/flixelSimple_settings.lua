-- Display the settings for the exporter.

DAME.AddHtmlTextLabel("Ensure you use the <b>SimpleClaws</b> PlayState.as file in the samples as the original template for any code.")
DAME.AddBrowsePath("AS3 dir:","AS3Dir",false, "Where you place the Actionscript files.")
DAME.AddBrowsePath("CSV dir:","CSVDir",false)

versions = as3.class.Array.new()
versions.push("2.43")
versions.push("2.5")
DAME.AddDropDown("Flixel version:","FlixelVersion",versions,"2.43","Select the version of Flixel relevant to you.");
DAME.AddTextInput("Base Class", "BaseLevel", "BaseClass", true, "What to call the base class that all levels will extend." )
DAME.AddTextInput("Level Name", "", "LevelName", true, "The name you wish to call this level." )
DAME.AddTextInput("Main Layer", "", "MainLayer", true, "Name of the tilemap layer to use as the main layer for hits." )
DAME.AddTextInput("Game package", "com", "GamePackage", true, "package for your game's .as files." )
DAME.AddTextInput("Flixel package", "org.flixel", "FlixelPackage", true, "package use for flixel .as files." )
DAME.AddTextInput("TileMap class", "FlxTilemap", "TileMapClass", true, "Base class used for tilemaps." )
DAME.AddMultiLineTextInput("Imports", "", "Imports", 50, true, "Imports for each level class file go here" )

DAME.AddCheckbox("Export only CSV","ExportOnlyCSV",false,"If ticked then the script will only export the map CSV files and nothing else.");

return 1
