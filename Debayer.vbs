'TDG-Debayer (TD0G's DCRAW GIMP Debayer) Processor
'Written by Tyler Gerritsen 
'td0g.ca

'Run this script in folder with raw images
'  or drag and drop images onto script.

'This tool will automatically process the raw images into tiffs using DCRAW, 
'  then will create a .bat file which the user can review and run at her/his pleasure
'  to split the tiffs into their component channels

'On a Canon 450D, the components (0 - 3) are in the following order: RGGB

'Prerequisites: 
'  GIMP (tested with 2.10)
'  DCRAW (download from http://www.centrostudiprogressofotografico.it/en/dcraw/)

'###################################################################################

			'Script Configuration

'###################################################################################
			
			'Install folder for GIMP
			pgmLoc = "C:\Program Files\GIMP 2\bin\"
			
			'List of All Usable File Extensions
			dim fileExtList
			fileExtList = split("cr2, crw")	'Currently only supports Canon RAW images
			
			'Parameters to call in DCRAW
			'dcrawParams = "-d -6 -T"		'BT.709 Gamma Curve 16-bit
			dcrawParams = "-d -4 -T"		'Linear 16-bit
			
			
'###################################################################################

			'Changelog

'###################################################################################

'v1.0
	'2018-10-24
	'Functional
		
'###################################################################################

			'Load Arguments (Photos & Configuration File)

'###################################################################################

'Variables and Objects		
	'Shell Object
	sFolder = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set folder = fso.GetFolder(sFolder)
	Set files = folder.Files

	'Photos
	rawListSize = 10000
	dim rawList (10000,2)
	fileListSize = 10000
	dim fileList (10000, 2)									'input, output filepaths
	totalImageCount=0																						'Get image dimensions
	dim imageDim()

'###################################################################################

			'Prepare Windows Shell

'###################################################################################

'Get GIMP executable path
Set pgmFolder = fso.GetFolder(pgmLoc)
Set pgmFiles = pgmFolder.Files
for each file In pgmFiles
	if inStr(file.name, "gimp-console-") > 0 and right(file.name, 4) = ".exe" then
		if isNumeric(mid(file.name,inStr(file.name, "gimp-")+13,1)) then
		pgmFullPath = file.path
		end if
	end if
next

'###################################################################################

			'Check incoming arguments for photos and config file

'###################################################################################

If WScript.Arguments.Count > 0 Then 																'Script was started by dropping files onto it
	For Each Arg in Wscript.Arguments 
		if UBound(Filter(fileExtList, lcase(right(Arg,len(Arg) - instrrev(Arg,"."))))) > -1 then 	'Argument contains phtos - add to photo list
			fileList(totalImageCount, 0) = Replace(arg, "\", "/")
			fileList(totalImageCount, 1) = fileList(totalImageCount, 0)								'Filetype recognized by Windows - just add to list
			totalImageCount = totalImageCount + 1
		end if
	Next 
else 																												'Script was started by double-clicking
	For each folderIdx In files																						'Loop through all files in folder and find photos
		Arg = ucase(right(folderIdx.name,4))
		if UBound(Filter(fileExtList, lcase(right(Arg,len(Arg) - instrrev(Arg,"."))))) > -1 then
			if totalImageCount = fileListSize then
				fileListSize = fileListSize + 1000
				redim preserve fileList(fileListSize, 2)
			end if
			fileList(totalImageCount, 1) = Replace(folderIdx.path, "\", "/")
			totalImageCount = totalImageCount + 1
		end if
	next
end if

'###################################################################################

			'Check that DCRAW.exe is available
			
'###################################################################################

dcrawFile = ""
for each folderIdx in files
	if right(folderIdx.name, 4) = ".exe" and inStr(lCase(folderIdx.name),"dcraw") > -1 then 
		dcrawFile = sFolder & folderIdx.name
		exit for
	end if
next
	
	
'###################################################################################

			'Check that images and config file are loaded and DCRAW.exe is available before proceeding

'###################################################################################

if dcrawFile = "" then
	msgbox "DCRAW.exe not found" & vbNewLine & "Please download from http://www.centrostudiprogressofotografico.it/en/dcraw/"
	Wscript.Quit
end if

if totalImageCount = 0 then
	msgbox "No photos found"
	Wscript.Quit
end if

'###################################################################################

			'Process RAW Images Into TIFFs

'###################################################################################
	
outFile = sFolder & "debayer.bat"
Set objFSO=CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.CreateTextFile(outFile,True)

oCmd = ""
dim wsh
Set wsh = WScript.CreateObject("WScript.Shell")	
for i = 0 to totalImageCount - 1
	if oCmd <> "" then oCmd = oCmd & vbNewLine
	oCmd = oCmd & Chr(34)  & dcrawFile & Chr(34) & " " & dcrawParams & " " & Chr(34) & fileList(i, 1) & Chr(34)
	fileList(i, 1) = left(fileList(i, 1), inStrRev(fileList(i, 1), ".")) & "tiff"
	fileList(i, 0) = left(fileList(i, 0), inStrRev(fileList(i, 0), ".")) & "tiff"
next
wsh.run oCmd, 1, True	

'###################################################################################

			'Prepare Batch File

'###################################################################################

getDimensions()
	
B = "-b " & Chr(34)
oCmd = Chr(34) & pgmFullPath & Chr(34) & " " & " -d -f --verbose --batch-interpreter plug-in-script-fu-eval "	'Don't load fonts

'Universal Variables
GIMPimage = 1
GIMPlayer = 2

'Prepare strings for each thread
for i = 0 to totalImageCount - 1
	for j = 0 to 3	'Each Channel
		'GIMP expects forward slashes in file name
		iCompleteName = Replace(fileList(i, 1), "\", "/")
		iFileName = right(iCompleteName, len(iCompleteName) - inStrRev(iCompleteName,"/"))
		oCompleteName = Replace(fileList(i, 1), "\", "/")
		oCompleteName = left(oCompleteName, inStrRev(oCompleteName,".")-1) & right(oCompleteName, len(oCompleteName)-inStrRev(oCompleteName,".")+1)
		
		loadImage = B & "(gimp-file-load 1 \" & Chr(34) & iCompleteName & "\" & Chr(34) & " \" & Chr(34) & iCompleteName & "\" & Chr(34) & ")" & Chr(34) & " "
		'Populate IMAGE and DRAWABLE (layer) variables in raw GIMP commands
		rotateArg = ""
		if j = 0 then
			rotateArg = B & "(gimp-image-flip " & GIMPimage & " " & 1 & ")" & Chr(34) & " "
		elseif j = 2 then
			rotateArg = B & "(gimp-image-flip " & GIMPimage & " " & 0 & ")" & Chr(34) & " " & B & "(gimp-image-flip " & GIMPimage & " 1)" & Chr(34) & " "
		elseif j = 3 then
			rotateArg = B & "(gimp-image-flip " & GIMPimage & " " & 0 & ")" & Chr(34) & " "
		end if
		scaleArg = B & "(gimp-image-scale-full " & GIMPimage & " " & imageDim(i, 0) / 2 & " " & imageDim(i, 1) / 2 & " 0)" & Chr(34) & " "
		newOutName = replace(oCompleteName, ".tiff", "_CH" & j & ".tiff")
		saveImage = B & "(gimp-file-save 1 " & GIMPimage & " " & GIMPlayer & " \" & Chr(34) & newOutName & "\" & Chr(34) & " \" & Chr(34) & newOutName & " \" & Chr(34) & ")" & Chr(34) & " "
		closeImage = B & "(gimp-image-delete " & GIMPimage & ")" & Chr(34) & " "

	'Construct entire Shell Command for current image
		oCmd = oCmd & loadImage
		oCmd = oCmd & rotateArg
		oCmd = oCmd & scaleArg
		oCmd = oCmd & rotateArg
		oCmd = oCmd & saveImage
		oCmd = oCmd & closeImage
		
		'Iteration-Specific Variables
		GIMPlayer = GIMPlayer + 2
		GIMPimage = GIMPimage + 1
	Next
Next

'Write to .bat file
objFile.write oCmd
objFile.Close

'Notify user that we are finished
msgbox "DONE" & vbNewLine & vbNewLine & "Please run debayer.bat to separate into component images" & vbNewLine & vbNewLine & "Channels should be in the following order: RGGB"

'###################################################################################

			'Public Procedures

'###################################################################################

Sub getDimensions()
	if not dimensions then
	dimensions = true	
		redim imageDim(totalImageCount,2)
		set oShell = CreateObject("Shell.Application")
		set oFolder = oShell.Namespace(replace(left(fileList(0, 1), inStrRev(fileList(0, 1),"/")),"/","\"))
		for ii = 0 to totalImageCount-1
			set oFolderItem = oFolder.parsename(right(fileList(ii, 1), len(fileList(ii, 1))-inStrRev(fileList(ii, 1),"/")))
			oString = oFolder.getdetailsof(oFolderItem,31)
			oStringParse = split(oString)
			imageDim(ii,0) = CInt(right(oStringParse(0), len(oStringParse(0))-1))
			imageDim(ii,1) = CInt(left(oStringParse(2), len(oStringParse(2))-1))
		next
	end if
End Sub