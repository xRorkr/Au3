
Func convertCondition($condition)
	Dim $vars[6][2] = [["true","True"], [" or "," OR "], [" and "," AND "], [" not ", " Not "], ["!=", "<>"]]
	For $i = 0 To 4
		$condition = StringReplace($condition, $vars[$i][0], $vars[$i][1], 0)
	Next
;	For $dv In $configMem.Keys
;		$condition = StringReplace($condition, "_" & $dv, "$_" & $dv, 0, 2)
;	Next
	$condition = StringRegExpReplace($condition, "(?<![$])(?<=\W|^)((AN[^D]|O[^R]|No[^t]|Tru[^e]|Fals[^e]|(?<!AN|O|No|Tru|Fals)[A-Za-z_][0-9]?)+(\W|$))", "\$$1")
	$condition = StringRegExpReplace($condition, '(\d+)[%](\s+[<>=!][=>]?\s+[$]([A-Za-z0-9_]{1,}))', "($1/100) * \$$3CAP$2")
	$condition = StringRegExpReplace($condition, '([A-Za-z0-9_]{1,})\s+([<>=!][=>]?)\s+(\d+)[%]', "$1 $2 \$$1CAP * ($3/100)")
	Return $condition
EndFunc

Func convertTime($t)
	Dim $lastChar = StringRight($t, 1)
	If $lastChar = "h" Then
		Return Number($t) * 60 * 60 * 1000
	ElseIf $lastChar = "m" Then
		Return Number($t) * 60 * 1000
	Else
		Return Number($t) * 1000
	EndIf
EndFunc

Func loadSettings()
	Dim $basePointer = "BasePointer", $VER = ""
	$processPath = _ProcessGetLocation($pid)
	$VER = IniRead(StringLeft($processPath, StringInStr($processPath,"\",0,-1)) & "locate.ini", "Setting", "Locate", "")
	If $VER <> "US" Then $basePointer &= "-" & $VER
	$gfConfig = IniReadSection($settingsFile, "Settings")

	$configMem = ObjCreate("Scripting.Dictionary")
	$configMemWrite = ObjCreate("Scripting.Dictionary")
	$configSetting = ObjCreate("Scripting.Dictionary")

	If @error Then
		MsgBox(4096, "", "Error occurred, [Settings] not found in " & $settingsFile)
	Else
		For $i = 1 To $gfConfig[0][0]
			$configSetting.add($gfConfig[$i][0], $gfConfig[$i][1])
		Next
	EndIf

	$gfConfig = IniReadSection($settingsFile, $basePointer)
	If @error Then
		MsgBox(4096, "", "Error occurred, [" & $basePointer & "] not found in " & $settingsFile)
	Else
		For $i = 1 To $gfConfig[0][0]
			$configMem.add($gfConfig[$i][0], $gfConfig[$i][1])
		Next
	EndIf
	$gfConfig = IniReadSection($settingsFile, "PointerOffset")
	Dim $finalVal
	If @error Then
		MsgBox(4096, "", "Error occurred, [PointerOffset] not found in " & $settingsFile)
	Else
		$baseKeys = IniReadSection($settingsFile, $basePointer)
		For $i = 1 To $gfConfig[0][0]
			For $j = 1 To $baseKeys[0][0]
				$gfConfig[$i][1] = StringReplace($gfConfig[$i][1],$baseKeys[$j][0],$baseKeys[$j][1])
			Next
			$configMem.add($gfConfig[$i][0], StringSplit($gfConfig[$i][1], ","))
		Next
	EndIf

	$gfConfig = IniReadSection($settingsFile, "PointerDataType")
	If @error Then
		MsgBox(4096, "", "Error occurred, [PointerDataType] not found in " & $settingsFile)
	Else
		For $i = 1 To $gfConfig[0][0]
			$configMem.add($gfConfig[$i][0] & "_DataType", $gfConfig[$i][1])
		Next
	EndIf

	$gfConfig = IniReadSection($settingsFile, "MemoryWrite")
	If Not @error Then
		For $i = 1 To $gfConfig[0][0]
			$configMemWrite.add($gfConfig[$i][0], $gfConfig[$i][1])
		Next
	EndIf
	setStatus("Settings Loaded")
EndFunc

Func loadConfig()
	$config = ObjCreate("Scripting.Dictionary")
	$configFile = $configSetting.Item("ConfigFile")
	If StringInStr($configFile, "__CharName__") > 0 Then
		$configFile = StringReplace($configFile, "__CharName__", Eval("_Name"))
	EndIf
	If StringInStr($configFile, "__Map__") > 0 Then
		$configFile = StringReplace($configFile, "__Map__", loadMem("CurrentLoc"))
	EndIf
	$gfConfig = IniReadSectionNames($configFile)
	If @error Then
		MsgBox(4096, "", "Error occurred, " & $configFile & " not found")
	Else
		For $i = 1 To $gfConfig[0]
			$tmp = IniReadSection($configFile, $gfConfig[$i])
			$tmpConfig = ObjCreate("Scripting.Dictionary")
			For $j = 1 To $tmp[0][0]
				If $gfConfig[$i] == "Gambits" Or $gfConfig[$i] == "PartyGambits" Then
					$val = convertCondition($tmp[$j][1])
				ElseIf $gfConfig[$i] == "StoreGambits" Or $gfConfig[$i] == "SpriteGambits"  Then
					$val = StringSplit($tmp[$j][1], "|")
				ElseIf $gfConfig[$i] == "ChatGambits" Then
					$val = StringSplit($tmp[$j][1], "|")
					If UBound($val) < 5 Then ContinueLoop
					$val[UBound($val) - 1] = convertTime($val[UBound($val) - 1])
				ElseIf $gfConfig[$i] == "Delay" Or $gfConfig[$i] == "ActionDelay" Then
					$val = convertTime($tmp[$j][1])
				Else
					$val = $tmp[$j][1]
				EndIf
				$tmpConfig.add($tmp[$j][0], $val)
			Next
			$config.add($gfConfig[$i], $tmpConfig)
		Next
	EndIf

	Dim $checkSections[11] = ["ActionDelay", "Delay", "Shortcut", "Gambits", "Misc", "PartyGambits", "ChatGambits", "MaxUsage", "Waypoint","StoreGambits","SpriteGambits"]

	For $section In $checkSections
		If Not $config.Exists($section) Then
			$config.add($section, ObjCreate("Scripting.Dictionary"))
		EndIf
	Next
	setStatus("Config Loaded")
EndFunc

Func GlobalAssign($varName, $data = "", $prefix = "_")
	Assign($prefix & $varName, $data, 2)
	Return $data
EndFunc

Func ReadMemoryOffset($pointer, $offset = 0, $type = "dword")
	Dim $tmp
	If IsArray($pointer) Then
		$tmp = ReadMemoryOffset($pointer[1])
		For $i = 2 To UBound($pointer) -1
			If UBound($pointer) - 1 = $i Then
				$tmp = ReadMemoryOffset($tmp, $pointer[$i], $type)
			Else
				$tmp = ReadMemoryOffset($tmp, $pointer[$i])
			EndIf
		Next
		Return $tmp
	Else
		If $offset == 0 Then
			$tmp = $pointer
		Else
			$tmp = "0x" & Hex($pointer + Dec($offset))
		EndIf
		Return _MemoryRead($tmp, $mid, $type)
	EndIf
EndFunc

Func WriteMemoryOffset($data, $pointer, $offset = 0, $type = 'dword')
	Dim $tmp
	If IsArray($pointer) Then
		$tmp = ReadMemoryOffset($pointer[1])
		For $i = 2 To UBound($pointer) -1
			If UBound($pointer) - 1 = $i Then
				$tmp = WriteMemoryOffset($data, $tmp, $pointer[$i], $type)
			Else
				$tmp = ReadMemoryOffset($tmp, $pointer[$i])
			EndIf
		Next
		Return $tmp
	Else
		If $offset == 0 Then
			$tmp = $pointer
		Else
			$tmp = "0x" & Hex($pointer + Dec($offset))
		EndIf
		Return _MemoryWrite($tmp, $mid, $data, $type)
	EndIf
EndFunc