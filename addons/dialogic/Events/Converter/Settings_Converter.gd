@tool
extends HBoxContainer

var folderStructure

var timelineFolderBreakdown:Dictionary = {}
var characterFolderBreakdown:Dictionary = {}
var definitionFolderBreakdown:Dictionary = {}
var themeFolderBreakdown:Dictionary = {}
var definitionsFile = {}

var conversionRootFolder = "res://converted-dialogic"

var contents

var conversionReady = false

var varSubsystemInstalled = false
var anchorNames = {}

func refresh():
	pass

func _on_verify_pressed():
	
	var file = File.new()
	
	%OutputLog.text = ""
	
	if file.file_exists("res://dialogic/settings.cfg"):
		%OutputLog.text += "[√] Dialogic 1.x data [color=green]found![/color]\r\n"
		
		if file.file_exists("res://dialogic/definitions.json"):
			%OutputLog.text += "[√] Dialogic 1.x definitions [color=green]found![/color]\r\n"
		else:
			%OutputLog.text += "[X] Dialogic 1.x definitions [color=red]not found![/color]\r\n"
			%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
			
		if file.file_exists("res://dialogic/settings.cfg"):
			%OutputLog.text += "[√] Dialogic 1.x settings [color=green]found![/color]\r\n"
		else:
			%OutputLog.text += "[X] Dialogic 1.x settings [color=red]not found![/color]\r\n"
			%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
		
		%OutputLog.text += "\r\n"
		
		%OutputLog.text += "Verifying data:\r\n"
		file.open("res://dialogic/folder_structure.json",File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			folderStructure = json_object.get_data()
			#print(folderStructure)
		else:
			print("JSON Parse Error: ", json_object.get_error_message(), " in ", error, " at line ", json_object.get_error_line())
			%OutputLog.text += "Dialogic 1.x folder structure [color=red]could not[/color] be read!\r\n"
			%OutputLog.text += "Please check the output log for the error the JSON parser encountered.\r\n"
			return
		#folderStructure = json_object.get_data()
		
		%OutputLog.text += "Dialogic 1.x folder structure read successfully!\r\n"
		
		#I'm going to build a new, simpler tree here, as the folder structure is too complicated
			
		
		recursive_search("Timeline", folderStructure["folders"]["Timelines"], "/")
		recursive_search("Character", folderStructure["folders"]["Characters"], "/")
		recursive_search("Definition", folderStructure["folders"]["Definitions"], "/")
		recursive_search("Theme", folderStructure["folders"]["Themes"], "/")
		
		
		%OutputLog.text += "Timelines found: " + str(timelineFolderBreakdown.size()) + "\r\n"
		%OutputLog.text += "Characters found: " + str(characterFolderBreakdown.size()) + "\r\n"
		%OutputLog.text += "Definitions found: " + str(definitionFolderBreakdown.size()) + "\r\n"
		%OutputLog.text += "Themes found: " + str(themeFolderBreakdown.size()) + "\r\n"
		
		%OutputLog.text += "\r\n"
		%OutputLog.text += "Verifying count of JSON files for match with folder structure:\r\n"
		
		var timelinesDirectory = list_files_in_directory("res://dialogic/timelines")
		if timelinesDirectory.size() ==  timelineFolderBreakdown.size():
			%OutputLog.text += "Timeline files found: [color=green]" + str(timelinesDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Timeline files found: [color=red]" + str(timelinesDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
		
		var characterDirectory = list_files_in_directory("res://dialogic/characters")
		if characterDirectory.size() ==  characterFolderBreakdown.size():
			%OutputLog.text += "Character files found: [color=green]" + str(characterDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Character files found: [color=red]" + str(characterDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		
		file.open("res://dialogic/definitions.json",File.READ)
		fileContent = file.get_as_text()
		json_object = JSON.new()
		
		error = json_object.parse(fileContent)
		
		if error == OK:
			definitionsFile = json_object.get_data()
			#print(folderStructure)
		else:
			print("JSON Parse Error: ", json_object.get_error_message(), " in ", error, " at line ", json_object.get_error_line())
			%OutputLog.text += "Dialogic 1.x definitions file [color=red]could not[/color] be read!\r\n"
			%OutputLog.text += "Please check the output log for the error the JSON parser encountered.\r\n"
			return
		
		if (definitionsFile["glossary"].size() + definitionsFile["variables"].size())  ==  definitionFolderBreakdown.size():
			%OutputLog.text += "Definitions found: [color=green]" + str((definitionsFile["glossary"].size() + definitionsFile["variables"].size())) + "[/color]\r\n"
			%OutputLog.text += " • Glossaries found: " + str(definitionsFile["glossary"].size()) + "\r\n"
			%OutputLog.text += " • Variables found: " + str(definitionsFile["variables"].size()) + "\r\n"
			
			for variable in definitionsFile["variables"]:
				var varPath = definitionFolderBreakdown[variable["id"]]
				var variableInfo = {}
				variableInfo["type"] = "variable"
				variableInfo["path"] = varPath
				variableInfo["name"] = variable["name"]
				variableInfo["value"] = variable["value"]
				definitionFolderBreakdown[variable["id"]] = variableInfo
			
			for variable in definitionsFile["glossary"]:
				var varPath = definitionFolderBreakdown[variable["id"]]
				var variableInfo = {}
				variableInfo["type"] = "glossary"
				variableInfo["path"] = varPath
				variableInfo["name"] = variable["name"]
				variableInfo["text"] = variable["text"]
				variableInfo["title"] = variable["title"]
				variableInfo["extra"] = variable["extra"]
				variableInfo["glossary_type"] = variable["type"]
				definitionFolderBreakdown[variable["id"]] = variableInfo
		else:
			%OutputLog.text += "Definition files found: [color=red]" + str(definitionsFile.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		var themeDirectory = list_files_in_directory("res://dialogic/themes")
		if themeDirectory.size() ==  themeFolderBreakdown.size():
			%OutputLog.text += "Theme files found: [color=green]" + str(themeDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Theme files found: [color=red]" + str(themeDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		# dirty check for the variable subsystem, as properly calling has subsystem is complicated currently
		varSubsystemInstalled = file.file_exists("res://addons/dialogic/Events/Variable/event.gd")
		
		if !varSubsystemInstalled:
			%OutputLog.text += "[color=yellow]Variable subsystem is not present in this Dialogic! Variables will not be converted![/color]"
			
		%OutputLog.text += "\r\n"
		
		%OutputLog.text += "Initial integrity check completed!\r\n"
		
		
		var directory = Directory.new()
		var directoryCheck = directory.dir_exists(conversionRootFolder)
		
		if directoryCheck: 
			%OutputLog.text += "[color=yellow]Conversion folder already exists, coverting will overwrite existing files.[/color]\r\n"
		else:
			%OutputLog.text += conversionRootFolder
			%OutputLog.text += "Folders are being created in " + conversionRootFolder + ". Converted files will be located there.\r\n"
			directory.open("res://")
			directory.make_dir(conversionRootFolder)
			directory.open(conversionRootFolder)	
			directory.make_dir("characters")
			directory.make_dir("timelines")
			directory.make_dir("themes")
		
		conversionReady = true
		$RightPanel/Begin.disabled = false
		
	else:
		%OutputLog.text += "[X] Dialogic 1.x data [color=red]not found![/color]\r\n"
		%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"


func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".json") || file.ends_with(".cfg"):
				files.append(file)

	dir.list_dir_end()
	return files

func recursive_search(currentCheck, currentDictionary, currentFolder):
	for structureFile in currentDictionary["files"]:
		match currentCheck:
			"Timeline": timelineFolderBreakdown[structureFile] = currentFolder
			"Character": characterFolderBreakdown[structureFile] = currentFolder
			"Definition": definitionFolderBreakdown[structureFile] = currentFolder
			"Theme": themeFolderBreakdown[structureFile] = currentFolder
	
	for structureFolder in currentDictionary["folders"]:
		recursive_search(currentCheck, currentDictionary["folders"][structureFolder], currentFolder + structureFolder + "/")






func _on_begin_pressed():
	%OutputLog.text += "-----------------------------------------\r\n"
	%OutputLog.text += "Beginning file conversion:\r\n"
	%OutputLog.text += "\r\n"
	
	#Character conversion needs to be before timelines, so the character names are available
	convertCharacters()
	convertTimelines()
	convertVariables()
	convertGlossaries()
	convertThemes()
	
	%OutputLog.text += "All conversions complete!\r\n"
	

func convertTimelines():
	%OutputLog.text += "Converting timelines: \r\n"
	for item in timelineFolderBreakdown:
		var folderPath = timelineFolderBreakdown[item]
		%OutputLog.text += "Timeline " + folderPath + item +": "
		var jsonData = {}
		var file = File.new()
		file.open("res://dialogic/timelines/" + item,File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			contents = json_object.get_data()
			var fileName = contents["metadata"]["name"]
			%OutputLog.text += "Name: " + fileName + ", " + str(contents["events"].size()) + " timeline events"
			
			var directory = Directory.new()
			var directoryCheck = directory.dir_exists(conversionRootFolder + "/timelines" + folderPath)
			if !directoryCheck: 
				directory.open(conversionRootFolder + "/timelines")
				
				var progresiveDirectory = ""
				for pathItem in folderPath.split('/'):
					directory.open(conversionRootFolder + "/timelines" + progresiveDirectory)
					if pathItem!= "":
						progresiveDirectory += "/" + pathItem
					if !directory.dir_exists(conversionRootFolder + "/timelines" + progresiveDirectory):
						directory.make_dir(conversionRootFolder + "/timelines" + progresiveDirectory)
				
			var newFilePath = conversionRootFolder + "/timelines" + folderPath + "/" + fileName + ".dtl"	
			file.open(newFilePath,File.WRITE)
			
			# update the new location so we know where second pass items are
			timelineFolderBreakdown[item] = newFilePath
			
			var processedEvents = 0
			
			var depth = 0
			for event in contents["events"]:
				processedEvents += 1
				var eventLine = ""
				
				for i in depth:
					eventLine += "	"
				
				if "dialogic_" in event["event_id"]:
					match event["event_id"]:
						"dialogic_001":
							#Text Event
							if event['character'] != "" && event['character']:
								eventLine += characterFolderBreakdown[event['character']]['name']
								if event['portrait'] != "":
									eventLine += "(" +  event['portrait'] + ")"
								
								eventLine += ": "
							if '\n' in event['text']:
								var splitCount = 0
								var split = event['text'].split('\n')
								for splitItem in split:
									if splitCount == 0:
										file.store_line(eventLine + splitItem + "\\")
									else:
										file.store_line(splitItem + "\\")
									splitCount += 1
							else: 
								file.store_string(eventLine + event['text'])
						"dialogic_002":
							# Character event
							match event['type']:
								1:
									eventLine += "Join "
									eventLine += characterFolderBreakdown[event['character']]['name']
									if (event['portrait'] != ""):
										eventLine += " (" + event['portrait'] + ") "
									
									for i in event['position']:
										if event['position'][i] == true:
											eventLine += i
									
									if event['animation'] != "[Default]" && event['animation'] != "":
										# Note: due to Anima changes, animations will be converted into a default. Times and wait will be perserved
										eventLine += " [animation=\"Instant In Or Out\" "
										eventLine += "length=\"" +  str(event['animation_length']) + "\""
										if event["animation_wait"]:
											eventLine += " wait=\"true\""
										eventLine += "]"
										
								2:
									eventLine += "Update "
									eventLine += characterFolderBreakdown[event['character']]['name']
									if (event['portrait'] != ""):
										eventLine += " (" + event['portrait'] + ") "

									var positionCheck = false
									for i in event['position']:
										
										if event['position'][i] == true:
											positionCheck = true
											eventLine += i
											
									if !positionCheck:
										%OutputLog.text += "\r\n[color=yellow]Warning: Character update with no positon set, this was possible in 1.x but not 2.0\r\nCharacter will be set to position 3[/color]\r\n"
										eventLine += "3"
										
									if event['animation'] != "[Default]" && event['animation'] != "":
										# Note: due to Anima changes, animations will be converted into a default. Times and wait will be perserved
										eventLine += " [animation=\"Heartbeat\" "
										eventLine += "length=\"" +  str(event['animation_length']) + "\""
										if event["animation_wait"]:
											eventLine += " wait=\"true\""
										if "animation_repeat" in event:
											eventLine += " repeat=\"" + event['animation_repeat'] + "\""
										eventLine += "]"
										
											
								3:
									eventLine += "Leave "
									eventLine += characterFolderBreakdown[event['character']]['name']
									
									if event['animation'] != "[Default]" && event['animation'] != "":
										# Note: due to Anima changes, animations will be converted into a default. Times and wait will be perserved
										eventLine += " [animation=\"Instant In Or Out\" "
										eventLine += "length=\"" +  str(event['animation_length']) + "\""
										if event["animation_wait"]:
											eventLine += " wait=\"true\""
										eventLine += "]"
								
							file.store_string(eventLine)	
						"dialogic_010":
							# Question event
							# With the change in 2.0, the root of the Question block is simply text event
							if event['character'] != "" && event['character']:
								eventLine += characterFolderBreakdown[event['character']]['name']
								if event['portrait'] != "":
									eventLine += "(" +  event['portrait'] + ")"
								
								eventLine += ": "
							if '\n' in event['question']:
								var splitCount = 0
								var split = event['text'].split('\n')
								for splitItem in split:
									if splitCount == 0:
										file.store_line(eventLine + splitItem + "\\")
									else:
										file.store_line(splitItem + "\\")
									splitCount += 1
							else: 
								file.store_string(eventLine + event['question'])
								
							depth +=1
						"dialogic_011":
							#Choice event
							eventLine += " - "
							eventLine += event['choice']
							file.store_string(eventLine)
							print("choice node")
							print ("bracnh depth now" + str(depth))
						"dialogic_012":
							#If event
							eventLine += "if true:"
							file.store_string(eventLine)
							print("if branch node")
							depth +=1
							print ("bracnh depth now" + str(depth))
						"dialogic_013": 
							#End Branch event
							# doesnt actually make any lines, just adjusts the tab depth
							print("end branch node")
							depth -= 1
							print ("bracnh depth now" + str(depth))
						"dialogic_014":
							#Set Value event
							if varSubsystemInstalled:
								#creating as a comment for now, because it doesnt seme to work correctly in timeline editor currently
								eventLine += " # "
								eventLine += "VAR "
								var path = definitionFolderBreakdown[event['definition']]['path']
								path.replace("/", ".")
								if path[0] == '.':
									path = path.erase(0,1)
								if path[path.length() - 1] != '.':
									path += "."
									
								eventLine += path + definitionFolderBreakdown[event['definition']]['name']
								file.store_string(eventLine)
							else:
								file.store_string(eventLine + "# Set variable function. Variables subsystem is disabled")
						"dialogic_015":
							#Label event
							file.store_string(eventLine + "[label name=" + event['name'] +"]")
							anchorNames[event['id']] = event['name']
						"dialogic_016":
							#Goto event
							# Dialogic 1.x only allowed jumping to labels in the same timeline
							# But since it is stored as a ID reference, we will have to get it on the second pass
							
							#file.store_string(eventLine + "[jump label=<" + event['anchor_id'] +">]")
							file.store_string(eventLine + "# jump label, just a comment for testing")
						"dialogic_020":
							#Change Timeline event
							# we will need to come back to this one on second pass, since we may not know the new path yet
							
							#file.store_string(eventLine + "[jump timeline=<" + event['change_timeline'] +">]")
							file.store_string(eventLine + "# jump timeline, just a comment for testing")
						"dialogic_021":
							#Change Background event
							file.store_string(eventLine + "[background path=\"" + event['background'] +"\"]")
						"dialogic_022":
							#Close Dialog event
							file.store_string(eventLine + "[end_timeline]")
						"dialogic_023":
							#Wait event
							file.store_string(eventLine + "[wait time=\"" + str(event['wait_seconds']) +"\"]")
						"dialogic_024":
							#Change Theme event
							file.store_string(eventLine + "# Theme change event, not currently implemented")
						"dialogic_025": 
							#Set Glossary event
							file.store_string(eventLine + "# Set Glossary event, not currently implemented")
						"dialogic_026":
							#Save event 
							if event['use_default_slot']:
								file.store_string(eventLine + "[save slot=\"Default\"]")
							else:
								file.store_string(eventLine + "[save slot=\"" + event['custom_slot'] + "\"]")
							
						"dialogic_030":
							#Audio event
							file.store_string(eventLine + "# Audio event, not currently implemented")
						"dialogic_031":
							#Background Music event
							file.store_string(eventLine + "# Background music event, not currently implemented")
						"dialogic_040":
							#Emit Signal event
							file.store_string(eventLine + "[signal arg=\"" + event['emit_signal'] +"\"]")
						"dialogic_041":
							#Change Scene event
							file.store_string(eventLine + "# Change scene event is deprecated. Scene called was: " + event['change_scene'])
						"dialogic_042":
							#Call Node event
							eventLine += "[call_node path=\"" + event['call_node']['target_node_path'] + "\" "
							eventLine += "method=\"" + event['call_node']['target_node_path'] + "\" "
							eventLine += "args=\"["
							for arg in event['call_node']['arguments']:
								eventLine += "\"" + arg + "\", "
							
							#remove the last comma and space
							eventLine = eventLine.left(-2)
							
							eventLine += "]"
							file.store_string(eventLine)
						_: 
							file.store_string(eventLine + "# unimplemented Dialogic control with unknown number")
						
						
					
					
				else: 
					eventLine += "# Custom event: "
					eventLine += str(event)
					eventLine = eventLine.replace("{", "*")
					eventLine = eventLine.replace("}", "*")
					
					file.store_string(eventLine)
				
				file.store_string("\r\n\r\n")
			file.close()
			
			
			
			%OutputLog.text += "Processed events: " + str(processedEvents) + "\r\n"
		else:
			%OutputLog.text += "[color=red]There was a problem parsing this file![/color]\r\n"
		
	%OutputLog.text += "\r\n"
	
	#second pass
	for item in timelineFolderBreakdown:
		print(item)
	


func convertCharacters(): 
	%OutputLog.text += "Converting characters: \r\n"
	for item in characterFolderBreakdown:
		var folderPath = characterFolderBreakdown[item]
		%OutputLog.text += "Character " + folderPath + item +": "
		var jsonData = {}
		var file = File.new()
		file.open("res://dialogic/characters/" + item,File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			contents = json_object.get_data()
			var fileName = contents["name"]
			%OutputLog.text += "Name: " + fileName
			
			if ("[" in fileName) || ("]" in fileName):
				%OutputLog.text += " [color=yellow]Stripping brackets from name![/color]"
				fileName = fileName.replace("[","")
				fileName = fileName.replace("]","")
				
			
			var directory = Directory.new()
			var directoryCheck = directory.dir_exists(conversionRootFolder + "/characters" + folderPath)
			if !directoryCheck: 
				directory.open(conversionRootFolder + "/characters")
				
				var progresiveDirectory = ""
				for pathItem in folderPath.split('/'):
					directory.open(conversionRootFolder + "/characters" + progresiveDirectory)
					if pathItem!= "":
						progresiveDirectory += "/" + pathItem
					if !directory.dir_exists(conversionRootFolder + "/characters" + progresiveDirectory):
						directory.make_dir(conversionRootFolder + "/characters" + progresiveDirectory)
			
			# using the resource constructor for this one
			
			var current_character = DialogicCharacter.new()
			current_character.resource_path = conversionRootFolder + "/characters" + folderPath + "/" + fileName + ".dch"
			# Everything needs to be in exact order

			current_character.color = Color.html(contents["color"])
			var customInfoDict = {}
			customInfoDict["sound_moods"] = {}
			customInfoDict["theme"] = ""
			current_character.custom_info = customInfoDict
			current_character.description = contents["description"]
			if contents["display_name"] == "":
				current_character.display_name = contents["name"]
			else:
				current_character.display_name = contents["display_name"]
			current_character.mirror = contents["mirror_portraits"]
			current_character.name = contents["name"]
			current_character.nicknames = []
			current_character.offset = Vector2(0,0)
			current_character.portraits = {}
			current_character.scale = 1.0
			
			ResourceSaver.save(current_character.resource_path, current_character)	

			# Before we're finished here, update the folder breakdown so it has the proper character name
			var infoDict = {}
			infoDict["path"] = characterFolderBreakdown[item]
			infoDict["name"] = contents["name"]
			
			characterFolderBreakdown[item] = infoDict
			
			%OutputLog.text += "\r\n"
		else:
			%OutputLog.text += "[color=red]There was a problem parsing this file![/color]\r\n"
			
	
	%OutputLog.text += "\r\n"
	

func convertVariables():
	%OutputLog.text += "Converting variables: \r\n"
	
	# Creating a file with a format identical to how the variables are stored in project settings
	if varSubsystemInstalled:
		var newVariableDictionary = {}
		for varItem in definitionFolderBreakdown:
			if definitionFolderBreakdown[varItem]["type"] == "variable":
				if definitionFolderBreakdown[varItem]["path"] == "/":
					newVariableDictionary[definitionFolderBreakdown[varItem]["name"]] = definitionFolderBreakdown[varItem]["value"]
				else:
					# I will fill this one in later, need to figure out the recursion for it
					pass
							
							
		
		var file = File.new()
		file.open(conversionRootFolder + "/variables.json",File.WRITE)
		var json_object = JSON.new()
		var output_string = json_object.stringify(newVariableDictionary, "\n")
		file.store_string(output_string)
		file.close()
	else:
		%OutputLog.text += "[color=yellow]Variable subsystem is not present! Variables were not converted![/color]\r\n"
	
	
	
	%OutputLog.text += "\r\n"
	

func convertGlossaries():
	%OutputLog.text += "Converting glossaries: [color=red]not currently implemented[/color] \r\n"
	
	%OutputLog.text += "\r\n"

func convertThemes():
	%OutputLog.text += "Converting themes: [color=red]not currently implemented[/color] \r\n"
	
	%OutputLog.text += "\r\n"

