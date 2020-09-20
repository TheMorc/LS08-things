



ShowVehicleMap(p_CareerFile, p_CareerLine = "null"){
	global


	p_DefaultPosX := -99999.0
	p_DefaultPosZ := -99999.0
	p_DefaultRotationY := -9999.0
	p_DefaultAbsolute := false
	p_DefaultRotationX := -9999.0
	p_DefaultRotationZ := -9999.0
	p_DefaultFile := "null"
	p_DefaultPosY := 90
	p_DefaultLine := p_CareerLine

	if(p_CareerLine != "null"){
		GetVehiclesDataFromLine(p_DefaultLine,  p_DefaultPosX, p_DefaultPosY, p_DefaultPosZ, p_DefaultRotationX, p_DefaultRotationY, p_DefaultRotationZ, p_DefaultAbsolute, p_DefaultFile)
	}

	if(p_DefaultRotationX = "null"){
		p_DefaultRotationX := -9999.0
	}
	if(p_DefaultRotationZ = "null"){
		p_DefaultRotationZ := -9999.0
	}




	VM_OLX := 190
	VM_RX  := 180
	VM_RY  := 550
	VM_PGW := 16
	VM_PGH := 16
	VM_PGW2 := 12
	VM_PGH2 := 12
	VM_XMLFILE := p_CareerFile
	VM_DEFAULT_POS_X := p_DefaultPosX
	VM_DEFAULT_POS_Z := p_DefaultPosZ
	VM_DEFAULT_ROTATION_X := p_DefaultRotationX
	VM_DEFAULT_ROTATION_Y := p_DefaultRotationY
	VM_DEFAULT_ROTATION_Z := p_DefaultRotationZ
	VM_DEFAULT_ABSOLUTE := getBoolean(p_DefaultAbsolute)

	DetectionMode := GetDetectionMode()

	textDDL := GetStringForDDLWithDefault()

	defaultMapValue := GetDefaultMap()

	GetMapValues(defaultMapValue, name, ow, oh, px1, pz1, px2, pz2, mx1, mz1, mx2,  mz2, MapFile)



	VM_STEERABLE_TITLE	= %t_130%
	VM_TRAILER_TITLE	= %t_131%
	VM_TOOL_TITLE		= %t_132%
	VM_OTHER_TITLE		= %t_133%






	ShowingVehicleMap:

		Gui, 2: +LabelVM


		Gui, 2: Font, S12 Cblack, Arial
		Gui, 2: Add, GroupBox, x6 y6 w160 h70 , Map
		Gui, 2: Font, S8 Cblack, Arial
		Gui, 2: Add, DropDownList, x16 y36 w140 h30 r5 AltSubmit vMapIndex gClickDDL, %textDDL%


		Gui, 2: Font, S12 Cblack, Arial
		Gui, 2: Add, GroupBox, x6 y84 w160 h90 , %t_6%
		Gui, 2: Font, S10 Cblack, Arial
		Gui, 2: Add, Edit, x56 y116 w100 h20 Center Number -Multi vPosX,
		Gui, 2: Add, Text, x26 y116 w20 h20 , X:
		Gui, 2: Add, Text, x26 y146 w20 h20 , Z:
		Gui, 2: Add, Edit, x56 y146 w100 h20 Center vPosZ Number -Multi,


		Gui, 2: Font, S12 Cblack, Arial
		Gui, 2: Add, GroupBox, x6 y181 w160 h160 , Rotation
		Gui, 2: Font, S12 CDefault Bold, Wingdings
		Gui, 2: Add, Button, x26 y211 w30 h30 gClickOL, ë
		Gui, 2: Add, Button, x66 y211 w40 h30 gClickO, é
		Gui, 2: Add, Button, x116 y211 w30 h30 gClickOR, ì
		Gui, 2: Add, Button, x26 y251 w30 h40 gClickL, ç
		Gui, 2: Add, Button, x116 y251 w30 h40 gClickR, è
		Gui, 2: Add, Button, x26 y301 w30 h30 gClickUL, í
		Gui, 2: Add, Button, x66 y301 w40 h30 gClickU, ê
		Gui, 2: Add, Button, x116 y301 w30 h30 gClickUR, î
		Gui, 2: Font, S8 CDefault norm, Arial
		Gui, 2: Add, Edit, x66 y261 w40 h20 -Multi Number Center Limit3 vRotationValue gClickVMRotationValue,


		Gui, 2: Font, S8 CDefault, Arial
		Gui, 2: Add, GroupBox, x6 y349 w160 h100 ,
		Gui, 2: Add, Progress, x16 y364 w%VM_PGW2% h%VM_PGH2% BackgroundRed,
		Gui, 2: Add, Text, x46 y364 w110 h15 , %VM_STEERABLE_TITLE%
		Gui, 2: Add, Progress, x16 y384 w%VM_PGW2% h%VM_PGH2% BackgroundBlue,
		Gui, 2: Add, Text, x46 y384 w110 h15 , %VM_TRAILER_TITLE%
		Gui, 2: Add, Progress, x16 y404 w%VM_PGW2% h%VM_PGH2% BackgroundOlive,
		Gui, 2: Add, Text, x46 y404 w110 h15 , %VM_TOOL_TITLE%
		Gui, 2: Add, Progress, x16 y424 w%VM_PGW2% h%VM_PGH2% BackgroundPurple,
		Gui, 2: Add, Text, x46 y424 w110 h15 , %VM_OTHER_TITLE%


		Gui, 2: Font, S10 CDefault, Arial
		Gui, 2: Add, GroupBox, x6 y456 w160 h100 ,
		Gui, 2: Add, Button, x16 y476 w140 h30 gClickVMApply, %t_62%
		Gui, 2: Add, Button, x16 y516 w140 h30 gClickVMCancel, %t_63%


		Gui, 2: Add, Pic, x%VM_OLX% y0 hwndPICID gKlickVM vMapPic, %MapFile%


		Gui, 2: Add, Progress, w0 h0 BackgroundLime HwndGreenPointerMain
		Gui, 2: Add, Progress, w0 h0 BackgroundLime HwndGreenPointerRota


		Gosub CalcVMWindowSize
		Gosub ShowVMGui
		Gosub FaktorBerechnenVM
		Gui, Submit, Nohide
		if(defaultMapValue > 0 ){
			tmMapValue := defaultMapValue + 1
			GuiControl, 2: Choose, MapIndex, %tmpMapValue%
			gosub LoadVehicles
			gosub InitVMPointer
		}
	Return

	InitVMPointer:

		defPosX := VM_DEFAULT_POS_X
		defPosZ := VM_DEFAULT_POS_Z
		defRotX := VM_DEFAULT_ROTATION_X
		defRotY := VM_DEFAULT_ROTATION_Y
		defRotZ := VM_DEFAULT_ROTATION_Z
		defAbsolute := VM_DEFAULT_ABSOLUTE



		if(defPosX <> -99999.0) and (defPosZ <> -99999.0){
			SpielZuPixel(defPosX, defPosZ, fx, fy, px1, pz1, px2, pz2, mx1, mz1, mx2, mz2, px, pz, ph, pw)
			if (IsPositionInArea(defPosX, defPosZ, px, pz, pw, ph)){

				SetPointer(defPosX, defPosZ, GreenPointerMain, VM_PGW, VM_PGH, GreenPointerRota)

				GuiControl, 2: ,PosX, %VM_DEFAULT_POS_X%
				GuiControl, 2: ,PosZ, %VM_DEFAULT_POS_Z%


				if(defRotY <> -9999.0){
					if(defAbsolute) and ((defRotX = -9999.0) or (defRotZ = -9999.0)){
						msgbox, ERROR: Wenn `"Absolute`" gesetzt ist, müssen xRotation, yRotation und zRotation ZWINGEND gesetzt sein.`nDefault-Rotation konnte NICHT initialisiert werden.
					}else{

						if(defAbsolute){

							tmpRV := getCorrectRotation(defRotX, defRotY, defRotZ, defAbsolute)
						}else{

							tmpRV := getCorrectRotation(0, defRotY, 0)
						}



						GuiControl, 2: ,RotationValue, %tmpRV%
						Gui, 2: Submit, NoHide

						gosub ActualizePointer
					}
				}
			}
		}else{
			GuiControl, 2: ,PosX,
			GuiControl, 2: ,PosZ,
			GuiControl, 2: ,RotationValue,
		}
	return

	CalcVMWindowSize:
		ControlGetPos, PX, PZ, PW, PH, , ahk_id %PICID%

		windowWidth := VM_OLX + PW
		windowHeight := PH

		FW := 1
		FH := 1


		if(windowHeight < VM_RY){
			windowHeight := VM_RY
		}

		virtualScreenHeight := A_ScreenHeight - 60
		virtualScreenWidth := A_ScreenWidth - VM_OLX - 20


		if(PW > virtualScreenWidth) or (windowHeight > virtualScreenHeight){


			FW := virtualScreenWidth / PW
			FH := virtualScreenHeight / windowHeight


			FW := RoundDown(FW)
			FH := RoundDown(FH)


			if(FW < FH){
				newPW := floor(PW * FW)
				newPH := floor(PH * FW)
				FH := FW
			}else{
				newPW := floor(PW * FH)
				newPH := floor(PH * FH)
				FW := FH
			}

			GuiControl, 2: ,MapPic, *w%newPW% *h%newPH% %MapFile%
			windowWidth := VM_OLX + newPW
			windowHeight := newPH
			if(windowHeight < VM_RY){
						windowHeight := VM_RY
			}
		}

	return

	ShowVMGui:
		title = %t_64%: %name%
		Gui, 2: Show, H%windowHeight% W%windowWidth% , %title%
		CenterWindow(title)
	return

	FaktorBerechnenVM:

		ControlGetPos, PX, PZ, PW, PH, , ahk_id %PICID%


		MX1 *= FW
		MX2 *= FW
		MZ1 *= FH
		MZ2 *= FH
		FX := (PX1 - PX2) / (MX1 - MX2)
		FY := (PZ1 - PZ2) / (MZ1 - MZ2)
		if(DetectionMode = 1){
			FX := 1
			FY := 1
		}
	return

	KlickVM:
		Gui, 2: Submit, NoHide

		MouseGetPos, MX, MY

		if(MapIndex > 1){
			SetPointer(MX, MY, GreenPointerMain, VM_PGW, VM_PGH, GreenPointerRota)
			gosub ActualizePointer

			PixelZuSpiel(mx, my, fx, fy, px1, pz1, px2, pz2, mx1, mz1, mx2, mz2, px, pz, ph, pw, detectionMode)

			Gui, 2: Submit, Nohide
			GuiControl, 2: ,PosX, %MX%
			GuiControl, 2: ,PosZ, %MY%
			Gui, 2: Submit, Nohide
		}else{
			DeletePointer(GreenPointerMain)
			DeletePointer(GreenPointerRota)
		}

	Return

	ClickVMApply:

		default := MapIndex - 1
		WriteDefaultMap(default)
		Gui, 2: Submit, NoHide

		xPosition4Outlaw := PosX
		zPosition4Outlaw := PosZ
		if(xPosition4Outlaw != "") and (zPosition4Outlaw != "") and (RotationValue != ""){
			if(VM_DEFAULT_ROTATION_X <> -9999.0){
				xRotation4Outlaw := VM_DEFAULT_ROTATION_X
			}else{
				xRotation4Outlaw := 0
			}
			if(VM_DEFAULT_ROTATION_Z <> -9999.0){
				zRotation4Outlaw := VM_DEFAULT_ROTATION_Z
			}else{
				zRotation4Outlaw := 0
			}
			if(getBoolean(VM_DEFAULT_ABSOLUTE)){
				absolute4Outlaw := "true"
				yRotation4Outlaw := Deg2Rad(RotationValue)
			}else{
				absolute4Outlaw := "false"
				yRotation4Outlaw := RotationValue
			}



			if(p_DefaultLine = "null"){
				new__car = %A_SPACE%xPosition="%xPosition4Outlaw%"%A_SPACE%yPosition="%p_DefaultPosY%"%A_SPACE%zPosition="%zPosition4Outlaw%"%A_SPACE%xRotation="%xRotation4Outlaw%"%A_SPACE%yRotation="%yRotation4Outlaw%"%A_SPACE%zRotation="%zRotation4Outlaw%"%A_SPACE%absolute="%absolute4Outlaw%"/>
			}else{
				new__car = <vehicle%A_SPACE%filename="%p_DefaultFile%"%A_SPACE%xPosition="%xPosition4Outlaw%"%A_SPACE%yPosition="%p_DefaultPosY%"%A_SPACE%zPosition="%zPosition4Outlaw%"%A_SPACE%xRotation="%xRotation4Outlaw%"%A_SPACE%yRotation="%yRotation4Outlaw%"%A_SPACE%zRotation="%zRotation4Outlaw%"%A_SPACE%absolute="%absolute4Outlaw%"/>
			}

			if(!getBoolean(VM_DEFAULT_ABSOLUTE)){
				StringReplace, new__car, new__car, yPosition, yOffset, All
			}


			gosub CloseVMWindow
			gosub apply_utility
		}else{
			MsgBox, "Du musst eine Position bestimmen!"
		}

	return

	VMClose:
	VMEscape:
	ClickVMCancel:





		Gosub CloseVMWindow

	return

	ClickVMReset:








		gosub InitVMPointer

	return

	CloseVMWindow:

		Gui, 2: Destroy
	return

	ClickDDL:

		Gui, 2: Submit, Nohide
		actualMapIndex := MapIndex - 1
		GetMapValues(actualMapIndex, name, ow, oh, px1, pz1, px2, pz2, mx1, mz1, mx2,  mz2, MapFile)
		GuiControl, ,MapPic, *w%ow% *h%oh% %MapFile%
		gosub CalcVMWindowSize
		gosub ShowVMGui
		DeletePointer(GreenPointerMain)
		DeletePointer(GreenPointerRota)
		gosub FaktorBerechnenVM
		gosub DeleteVehicles
		if(actualMapIndex > 0){
			gosub LoadVehicles
			gosub InitVMPointer
		}else{
			GuiControl, 2: ,PosX,
			GuiControl, 2: ,PosZ,
			GuiControl, 2: ,RotationValue,
		}
		SplashTextOff
	return

	DeleteVehicles:
		arrCounter := ParseCareerXMLFile(VM_XMLFILE)
		Loop %arrCounter%
		{
			if VehiclePointer%A_Index%Main <>
			{
				DeletePointer(VehiclePointer%A_Index%Main)
				DeletePointer(VehiclePointer%A_Index%Rota)
			}
		}
	return

	LoadVehicles:





		arrCounter := ParseCareerXMLFile(VM_XMLFILE)

		Loop %arrCounter%
		{

			F := arrF%A_Index%
			X := arrX%A_Index%
			Y := arrY%A_Index%
			Z := arrZ%A_Index%
			RX := arrRX%A_Index%
			RY := arrRY%A_Index%
			RZ := arrRZ%A_Index%
			ABS := GetBoolean(arrA%A_Index%)

			correctRotation := GetCorrectRotation(RX, RY, rz, abs)

			SpielZuPixel(x, z, fx, fy, px1, pz1, px2, pz2, mx1, mz1, mx2, mz2, px, pz, ph, pw)
			if (IsPositionInArea(x, z, px, pz, pw, ph) = true)
			{
				pointerColor := GetColor(F)
				Gui, 2: Add, Progress, w%VM_PGW2% h%VM_PGH2% Background%pointerColor% HwndVehiclePointer%A_Index%Main
				Gui, 2: Add, Progress, w%VM_PGW2% h%VM_PGH2% Background%pointerColor% HwndVehiclePointer%A_Index%Rota
				SetPointer(X, z, VehiclePointer%A_Index%Main, VM_PGW2, VM_PGH2, VehiclePointer%A_Index%Rota, correctRotation)
			}
		}


	return




	ClickOL:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue,  45
	return

	ClickO:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 0
	return

	ClickOR:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 315
	return

	ClickR:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 270
	return

	ClickUR:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 225
	return

	ClickU:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 180
	return

	ClickUL:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 135
	return

	ClickL:
		Gui, 2: Submit, NoHide
		GuiControl, 2: ,RotationValue, 90
	return

	ClickVMRotationValue:
		Gui, 2: Submit, NoHide

		gosub ActualizePointer

	return

	ActualizePointer:
		Gui, 2: Submit, NoHide
		ControlGetPos, oldX, oldY, oldW, oldH, , ahk_id %GreenPointerMain%
		if( ExistsPointer(GreenPointerMain) ){
			usedX := oldX + (0.5 * oldW)
			usedY := oldY + (0.5 * oldH)

			if RotationValue =
			{
				SetPointer(usedX, usedY, GreenPointerMain, oldW, oldH, GreenPointerRota)
			}
			else
			{
				tmpRV := GetCorrectRotation(0,RotationValue,0)
				GuiControl, 2: ,RotationValue, %tmpRV%
				Gui, 2: Submit, NoHide
				SetPointer(usedX, usedY, GreenPointerMain, oldW, oldH, GreenPointerRota, RotationValue)

				GuiControl, 2: Focus, RotationValue
				send {end}
			}
		}
	return

}



SetPointer(xk, yk, pointerMain, w0, h0, pointerRota = "null", rotVal = -9999){

	w0 *= 1.0
	h0 *= 1.0
	xk *= 1.0
	yk *= 1.0

	DeletePointer(pointerMain)

	x0 := xk - (0.5 * w0)
	y0 := yk - (0.5 * h0)
	ControlMove, , %x0%, %y0%, %w0%, %h0%, ahk_id %pointerMain%
	if (pointerRota <> "null") and (rotVal <> -9999)
	{
		DeletePointer(pointerRota)

		w1 := (0.5 * w0)
		h1 := (0.5 * h0)

		rotVal := GetNormalizedRotation(rotVal)

		if (rotVal = 45){
			x1 := xk - (1.5 * w1)
			y1 := yk - (1.5 * h1)
		}else{
			if (rotVal = 90){
				x1 := xk - (1.5 * w1)
				y1 := yk - (0.5 * h1)
			}else{
				if (rotVal = 135){
					x1 := xk - (1.5 * w1)
					y1 := yk + (0.5 * h1)
				}else{
					if (rotVal = 180){
						x1 := xk - (0.5 * w1)
						y1 := yk + (0.5 * h1)
					}else{
						if (rotVal = 225){
							x1 := xk + (0.5 * w1)
							y1 := yk + (0.5 * h1)
						}else{
							if (rotVal = 270){
								x1 := xk + (0.5 * w1)
								y1 := yk - (0.5 * h1)
							}else{
								if (rotVal = 315){
									x1 := xk + (0.5 * w1)
									y1 := yk - (1.5 * h1)
								}else{

									x1 := xk - (0.5 * w1)
									y1 := yk - (1.5 * h1)
								}
							}
						}
					}
				}
			}
		}

		ControlMove, , %x1%, %y1%, %w1%, %h1%, ahk_id %pointerRota%
	}

}

DeletePointer(pointer){
	global VM_OLX
	x := VM_OLX
	y := 0
	ControlMove, , %x%, %y%, 0, 0, ahk_id %pointer%
}

CenterWindow(WinTitle)
{
	WinGetPos,,, Width, Height, %WinTitle%

	if (Width >= A_ScreenWidth) {
		winX := 0
	} else{
		winX := (A_ScreenWidth/2)-(Width/2)
	}

	if (height >= A_ScreenHeight){
		winY := 0
	} else{
		winY := (A_ScreenHeight/2)-(Height/2)
	}

	WinMove, %WinTitle%,, %winX%, %winY%
}

PixelZuSpiel(ByRef mx, ByRef my, fx, fy, px1, pz1, px2, pz2, mx1, mz1, mx2, mz2, px, pz, ph, pw, detectionMode){

	MX -= PX
	MY -= PZ
	If (PX1 > PX2) {

	   MX := PW - MX
	   MY := PH - MY
	   if(DetectionMode = 0)
	   {
			MX := PX2 + ((MX - MX2) * FX)
			MY := PZ2 + ((MY - MZ2) * FY)
	   }
	} Else {

	   if(DetectionMode = 0)
	   {
			MX := PX1 + ((MX - MX1) * FX)
			MY := PZ1 + ((MY - MZ1) * FY)
		}
	}
}

SpielZuPixel(ByRef mx, ByRef my, fx, fy, px1, pz1, px2, pz2, mx1, mz1, mx2, mz2, px, pz, ph, pw){
	If (PX1 > PX2) {

		MX := MX2 + ((MX - PX2) / FX)
		MY := MZ2 + ((MY - PZ2) / FY)

		MX := PW - MX
		MY := PH - MY
	} Else {

	   	MX := MX1 + ((MX - PX1) / FX)
		MY := MZ1 + ((MY - PZ1) / FY)
	}

	MX += PX
	MY += PZ
}

GetColor(filename){
	myfile := filename
	returnValue =
	IfInString, myfile, /trailers/
	{

		returnValue = Blue
	}
	else
	{
		ifinstring, myfile, /steerable/
		{

			returnValue = Red
		}
		else
		{
			ifinstring, myfile, /tools/
			{

				returnValue = Olive
			}
			else
			{

				returnValue = Purple
			}
		}
	}
	return %returnValue%
}

ExistsPointer(name){
	ControlGetPos, , , pointerW, pointerH, , ahk_id %name%
	if(pointerW > 0) and (pointerH > 0){
		return true
	}else{
		return false
	}
}

IsPositionInArea(x, z, px, pz, pw, ph){
	result := false
	lowerBound := px
	upperBound := px + pw
	if x between %lowerBound% and %upperBound%
	{
		lowerBound := pz
		upperBound := pz + ph
		if z between %lowerBound% and %upperBound%
		{
			result := true
		}
	}
	return %result%
}

RoundDown(toRound, decimalPlaces = 3){
	vorKomma := floor(toRound)
	nachKomma := toRound - vorKomma
	nachKomma := nachKomma * (10**decimalPlaces)
	nachKomma := floor(nachKomma)
	nachKomma := round(nachKomma/(10**decimalPlaces),decimalPlaces)
	result := vorKomma + nachKomma
	return %result%
}
