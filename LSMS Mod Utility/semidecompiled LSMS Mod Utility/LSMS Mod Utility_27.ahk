; <COMPILER: v1.0.47.6>
#notrayicon
#noenv
#SingleInstance force
setworkingdir, %A_scriptdir%
FileCreateDir, %A_SCRIPTDIR%\bin\
FileCreateDir, %A_SCRIPTDIR%\bin\maps\

version = 1.32
mapcount_write = 11










#NoEnv









#NoEnv
SendMode Input





GetStringForDDLWithDefault(){
	default := GetDefaultMap()
	temp := GetStringForDDL(default)
	return %temp%
}

GetStringForDDL(defaultMap = 0){
	tmp =|
	mapCount := GetMapCount()
	path := GetIniPath()
	Loop %mapCount%
	{
		Iniread, temp, %path%, coordmaps, map%A_Index%_name
		if(A_Index = defaultMap){
			tmp = %tmp%%temp%||
		}else{
			tmp = %tmp%%temp%|
		}
	}

	return %tmp%
}

GetMapValues(index, byref name, byref ow, byref oh, byref px1, byref pz1, byref px2, byref pz2, byref mx1, byref mz1, byref mx2,  byref mz2, byref file){
	if(index = 0){

		name	:=	"NoMap"
		ow		:=	800
		oh		:=	600
		px1		:=	0
		pz1		:=	0
		px2		:=	0
		pz2		:=	0
		mx1		:=	0
		mz1		:=	0
		mx2		:=	0
		mz2		:=	0
		file	:=	"bin\maps\NoMap.jpg"
	}else{

		Iniread, name, bin\coord.ini, coordmaps, map%index%_name
		Iniread, ow, bin\coord.ini, coordmaps, map%index%_OW
		Iniread, oh, bin\coord.ini, coordmaps, map%index%_OH
		Iniread, px1, bin\coord.ini, coordmaps, map%index%_PX1
		Iniread, pz1, bin\coord.ini, coordmaps, map%index%_PZ1
		Iniread, px2, bin\coord.ini, coordmaps, map%index%_PX2
		Iniread, pz2, bin\coord.ini, coordmaps, map%index%_PZ2
		Iniread, mx1, bin\coord.ini, coordmaps, map%index%_MX1
		Iniread, mz1, bin\coord.ini, coordmaps, map%index%_MZ1
		Iniread, mx2, bin\coord.ini, coordmaps, map%index%_MX2
		Iniread, mz2, bin\coord.ini, coordmaps, map%index%_MZ2
		Iniread, file, bin\coord.ini, coordmaps, map%index%_pic
	}
}

GetMapCount(){
	value := ReadFromUtilityIni("coordmaps", "mapcount", 0)

	return %value%
}

ReadFromUtilityIni(section, attribute, default){
	path := GetIniPath()
	INIREAD, value, %path%, %section%, %attribute%, %default%
	if value =
	{
		value = %default%
	}
	return %value%
}

WriteToUtilityIni(section, attribute, value){
	path := GetIniPath()
	INIWRITE, %value%, %path%, %section%, %attribute%
}

GetIniPath(){
	return "bin\coord.ini"
}



GetDetectionMode(){
	value := ReadFromUtilityIni("coordmaps", "detectionMode", 0)
	return %value%
}

GetCareerPath(){
	path := "bin\settings.ini"
	INIREAD, value, %path%, "soft", "dir", ""
	value = %value%data\careervehicles.xml
	return %value%
}

WriteDefaultMap(mapindex){
	path := GetIniPath()
	IniWrite, %mapindex%, %path%, coordmaps, defaultmap
}

GetDefaultMap(){
	temp := ReadFromUtilityIni("coordmaps", "defaultmap", 0)
	return %temp%
}
#include bin\funcIni.ahk
#include bin\funcCareer.ahk
#include bin\funcRotation.ahk
#include bin\funcMap.ahk
#include bin\startevents.ahk
