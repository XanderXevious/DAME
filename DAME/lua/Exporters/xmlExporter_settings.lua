-- Display the settings for the exporter.

DAME.AddBrowsePath("directory:","DataDir",false, "Where you place the data files.")

DAME.AddCheckbox("Export only CSV","ExportOnlyCSV",false,"If ticked then the script will only export the map CSV files and nothing else.")

return 1
