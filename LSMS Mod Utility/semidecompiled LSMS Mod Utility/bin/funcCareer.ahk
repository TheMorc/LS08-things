











ParseCareerXMLFile(file){
	temp := ParseXMLFile(file, "<careerVehicles>", "</careerVehicles>", "Section")
	return %temp%
}





















ParseXMLFile(file, startTag, endTag, switchMode){
	global
	local switchParse
	local maxArrayCount
	local actualLine
	local lines
	switchParse := false
	maxArrayCount = 0
	LOOP, READ, %file%
	{
		actualLine = %A_LoopReadLine%

		if actualLine <>
		{
			if (actualLine = startTag) OR (switchMode = "All") {
				switchParse := true
			}
			else if (actualLine = endTag) AND (switchMode != "All") {
				switchParse := false
			}
			else if (switchParse) {

				lines = %lines% `n %actualLine%
				maxArrayCount += 1
				arrX%maxArrayCount% =
				arrY%maxArrayCount%	=
				arrZ%maxArrayCount%	=
				arrRY%maxArrayCount%	=
				arrRX%maxArrayCount%	=
				arrRZ%maxArrayCount%	=
				arrA%maxArrayCount%	=
				arrF%maxArrayCount%	=
				GetVehiclesDataFromLine(actualLine, arrX%maxArrayCount%, arrY%maxArrayCount%, arrZ%maxArrayCount%, arrRX%maxArrayCount%, arrRY%maxArrayCount%, arrRZ%maxArrayCount%, arrA%maxArrayCount%, arrF%maxArrayCount%)
			}
		}
	}


	return %maxArrayCount%
}
















GetVehiclesDataFromLine(lineWithData, ByRef varPosX, ByRef varOffY, ByRef varPosZ, ByRef varRotX, ByRef varRotY, ByRef varRotZ, ByRef varAbs, ByRef varFile){
	varPosX := GetValueOfAttr(lineWithData, "xPosition")
	varOffY := GetValueOfAttr(lineWithData, "yOffset")
	if(varOffY = "null"){
		varOffY := GetValueOfAttr(lineWithData, "yPosition")
	}
	varPosZ := GetValueOfAttr(lineWithData, "zPosition")
	varRotY := GetValueOfAttr(lineWithData, "yRotation")
	varRotX := GetValueOfAttr(lineWithData, "xRotation")
	varRotZ := GetValueOfAttr(lineWithData, "zRotation")
	varAbs	:= GetValueOfAttr(lineWithData, "absolute")
	varFile := GetValueOfAttr(lineWithData, "filename")
}










PrintParsedValues(maxArrayCount){
	Loop %maxArrayCount%
	{
		F := arrF%A_Index%
		X := arrX%A_Index%
		Y := arrY%A_Index%
		Z := arrZ%A_Index%
		RX := arrRX%A_Index%
		RY := arrRY%A_Index%
		RZ := arrRZ%A_Index%
		message = %message% `n filename: %F%, X: %X%, Y: %Y%, Z: %Z%, RotationX: %RX%, RotationY: %RY%, RotationZ: %RZ%
	}
	msgbox, %message%
}












GetValueOfAttr(sLine, attribute) {

	result := "null"

	posAttribute := InStr(sLine, attribute)

	if (posAttribute > 0){
		lengthToCut := StrLen(sLine) - posAttribute + 1
		StringRight, tempStr, sLine, lengthToCut
		StringGetPos, posFirstQuote, tempStr, ", L1
		posFirstQuote := posFirstQuote + posAttribute + 1
		StringGetPos, posSecondQuote, tempStr, ", L2
		posSecondQuote := posSecondQuote + posAttribute
		posSecondQuote -= posFirstQuote
		result := SubStr(sLine, posFirstQuote, posSecondQuote)
	}
	Return result
}
