-- Display the settings for the exporter.

DAME.AddHtmlTextLabel("Ensure you use the <b>FlashPunkDemo</b> PlayState.as file in the samples as the original template for any code. <b>Rotate Sprite Positions</b> above should be ticked.")
DAME.AddBrowsePath("AS3 dir:","AS3Dir",false, "Where you place the Actionscript files.")
DAME.AddBrowsePath("CSV dir:","CSVDir",false)

DAME.AddTextInput("Base Class", "BaseLevel", "BaseClass", true, "What to call the base class that all levels will extend." )
DAME.AddTextInput("Game package", "com", "GamePackage", true, "package for your game's .as files." )
DAME.AddTextInput("FlashPunk package", "net.flashpunk", "FlashPunkPackage", true, "package use for flashpunk .as files." )
DAME.AddTextInput("TileMap class", "TileMapEntity", "TileMapClass", true, "Base class used for tilemaps. TileMapEntity.as is generated in the export." )
DAME.AddMultiLineTextInput("Imports", "", "Imports", 50, true, "Imports for each level class file go here" )

DAME.AddCheckbox("Export only CSV","ExportOnlyCSV",false,"If ticked then the script will only export the map CSV files and nothing else.")

return 1
