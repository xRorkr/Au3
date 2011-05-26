#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=favicon.ico
#AutoIt3Wrapper_Outfile=GFBot.exe
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Array.au3>
#include <Misc.au3>
#include <Math.au3>
#include <Date.au3>

If @ScriptName == "GFBot.exe" Then
	$filename = InputBox("WARNING", "Please rename your application to something else for your own protection.", "explorer.exe")
	If StringInStr($filename, ".exe") And Not FileExists($filename) Then
		FileMove("GFBot.exe", $filename)
		ShellExecute($filename)
	Else
		MsgBox(0, "Error", "Please put .exe or make sure filename does not exists in same directory")
	EndIf
	Exit
EndIf

Global $processName = "Grand Fantasia", $settingsFile = "GFBot.ini", $configFile
Global $VERSION = "v1.1.1.9"

#include <Login.au3>

Global $pid = -1, $mid
Global $botState = False, $moving = False
Global $timers
Global $mapShortcut = "m", $sitShortcut = "x", $followShortcut = "f", $ptShortcut = "t"
Global $mapState = 1
Global $pixelFinder = False, $debugMode = False

Global $config, $configMem, $configSetting, $configMemWrite

Global $HP, $MP, $targetState = 0, $HPCAP, $MPCAP, $SIT, $CURSED, $T, $C, $M, $SAFE, $EXP, $EXPCAP = 0, $CharName = "", $Level = 0, $CH = 0, $SHP, $SHPCAP, $RANGE, $THP, $THPCAP, $PHP, $PHPCAP, $DMG = 0, $DMGCAP

Global $WayPointIndex = 0, $WayPointCount = 0, $WayPoints[1][3], $zoneWaypoints[2][3], $zones[2] = ["safezone", "storenpc"], $zoneCoords[2][2]
Global $clientSize, $antiStuckCoords[3][2]
Global $safeZone[2], $npcCoord[2], $gotoSafe = False, $safeRecover = False, $camperMode = False, $oldSafeRecoverCond = ""
Global $kills = 0, $kph = 0, $killTimer = 0, $maxUsage
Global $LOGS[200], $SYSLOGS[999]
Global Const $PI = 3.14159265358979

$safeZone[0] = 0
$safeZone[1] = 0

Opt("SendKeyDownDelay", 50)

#include <NomadMemory.au3>
#include <GFBotGUI.au3>
#include <Bot.au3>
#include <LoadConfig.au3>
#include <LoadDefaults.au3>

;AutoItSetOption ("CaretCoordMode", 0)
Opt("MouseCoordMode", 2)
Opt("PixelCoordMode", 2)
AutoItSetOption("MouseClickDelay", 1)

Func _initBot()
	$timers = ObjCreate("Scripting.Dictionary")
	$maxUsage = ObjCreate("Scripting.Dictionary")
	$killTimer = TimerInit()
	$kills = 0
	$botState = True
	setStatus("Bot starting...")
	WinActivate($processName)
	SendKeepActive($processName)
	If $config.Item("Misc" ).Exists("skillset") Then
		Send("+" & $config.Item("Misc" ).Item("skillset"))
	EndIf
EndFunc   ;==>_initBot

Func _startBot()
	If GUICtrlRead($startStopButton) == "Stop" Then
		setStatus("Already started, press alt+x to stop")
	Else
		GUICtrlSetData($startStopButton, "Stop")
		_initBot()
		_initMemory()
		If IsDeclared("_mapX") And $mapX = 0 Then
			updateMapCoords()
		EndIf
		SaveWayPoint()
		$lastChatIndex = 0
		$lastChat = ""
		chatLog()
	EndIf
EndFunc   ;==>_startBot

Func _stopBot()
	If GUICtrlRead($startStopButton) == "Start" Then
		setStatus("Already stopped, press alt+z to start")
	Else
		GUICtrlSetData($startStopButton, "Start")
		setStatus("Bot stopped")
		$botState = False
	EndIf
EndFunc   ;==>_stopBot

HotKeySet("!p", "_switchPixelFinder")
HotKeySet("!q", "_Exit")

HotKeySet("!c", "ClearWayPoints")
HotKeySet("^!c", "ClearLastWayPoints")
HotKeySet("!a", "NormalWayPoint")
HotKeySet("!h", "ShowHelp")
HotKeySet("!s", "SafeWayPoint")
HotKeySet("!n", "NPCWayPoint")
HotKeySet("!w", "SetWayPointMode")
HotKeySet("!g", "clickMapPoint")
HotKeySet("!z", "_startBot")
HotKeySet("!x", "_stopBot")
HotKeySet("!l", "logActions")
HotKeySet("!r", "reloadConfig")
HotKeySet("!d", "_switchDebugger")

Func reloadConfig()
	loadSettings()
	loadConfig()
	defaultSettings()
	defaultConfig()
EndFunc   ;==>reloadConfig

Func money($total)
	$match = StringRegExp($total, "([0-9]{1,})G([0-9]{1,})S([0-9]{1,})", 1)
	If UBound($match) > 1 Then
		$total = $match[0] * 10000
		$total += $match[1] * 100
		$total += $match[2]
		Return $total
	Else
		Dim $C = Mod($total, 100)
		$total = Floor($total / 100)
		Dim $s = Mod($total, 100)
		$total = Floor($total / 100)
		Dim $g = Mod($total, 100)
		Return $g & "G" & $s & "S" & $C & "C"
	EndIf
EndFunc   ;==>money

Func niceTime($time, $strFormat = False)
	If $time < 0 Then
		Return ""
	EndIf
	$d = 1000 * 60 * 60 * 24
	$h = 1000 * 60 * 60
	$M = 1000 * 60
	$s = 1000
	$day = Floor($time / $d)
	$r = Mod($time, $d)
	$hr = Floor($r / $h)
	$r = Mod($r, $h)
	$min = Floor($r / $M)
	$r = Mod($r, $M)
	$sec = Floor($r / $s)
	$r = Mod($r, $s)

	Dim $T = ""
	If $strFormat Then
		If $day > 0 Then
			$T = $day & "d"
		EndIf
		If $hr > 0 Then
			$T &= $hr & "h"
		EndIf
		If $min > 0 Then
			$T &= $min & "m"
		EndIf
		If $T == "" Then
			$T = "less than 1 minute"
		EndIf
	Else
		If $day > 0 Then
			$T = $day & ":"
		EndIf
		$T &= $hr & ":" & $min & ":" & $sec
	EndIf
	Return $T
EndFunc   ;==>niceTime

Func setStatus($status = "", $logIt = True)
	_GUICtrlStatusBar_SetText($infoStatus, $status)
	If $logIt Then _ArrayPush($LOGS, _Now() & " - HP:" & $HP & " MP:" & $MP & " Lvl:" & $Level & " C:" & $C & " SIT:" & $SIT & " Kills:" & $kills & " T:" & $targetState & " Status:" & $status)
	Return $status
EndFunc   ;==>setStatus

Func sysLog($sys = "")
	_ArrayPush($SYSLOGS, _Now() & " - " & $sys)
	Return $sys
EndFunc   ;==>sysLog

Func _switchDebugger()
	If $debugMode Then
		$debugMode = False
	Else
		$debugMode = True
	EndIf
	;playerAlert()
	;$C = chatLog()
	;_ArrayDisplay($C)
EndFunc   ;==>_switchDebugger

Func debugText()
	Dim $str = "Debug:"
	If $configSetting.Exists("debug") Then
		$tmp = StringSplit($configSetting.Item("debug"), ",")
		For $debug In $tmp
			If IsDeclared("_" & $debug) Then
				$str &= " " & $debug & ":" & Eval("_" & $debug)
			EndIf
		Next
		Return $str
	EndIf
EndFunc   ;==>debugText

Func SaveWayPoint()
	Dim $str = "", $coords = ""
	If $WayPointCount > 0 Then
		$str = "waypoints="
		$coords = "waypointcoords="
		For $i = 0 To $WayPointCount - 1
			$str &= $WayPoints[$i][0] & "," & $WayPoints[$i][1] & "," & $WayPoints[$i][2]
			$coords &= $waypointCoord[$i][0] & "," & $waypointCoord[$i][1]
			If $i < $WayPointCount - 1 Then
				$str &= "|"
				$coords &= "|"
			EndIf
		Next
		$str &= @LF & $coords & @LF
	EndIf
	$coords = ""
	For $i = 0 To UBound($zones) - 1
		If $zoneWaypoints[$i][0] > 0 Then
			$str &= $zones[$i] & "=" & $zoneWaypoints[$i][0] & "," & $zoneWaypoints[$i][1] & "," & $zoneWaypoints[$i][2] & @LF
			$str &= $zones[$i] & "coords=" & $zoneCoords[$i][0] & "," & $zoneCoords[$i][1] & @LF
		EndIf
	Next
	If IsDeclared("_mapX") Then
		$str &= "map=" & $mapX & "," & $mapY & @LF
	EndIf
	IniWriteSection($configFile, "Waypoint", $str)
	setStatus("Waypoint saved")
EndFunc   ;==>SaveWayPoint

Func logActions()
	logToFile(IniRead($settingsFile, "Settings", "logcount", 5))
EndFunc   ;==>logActions

Func logToFile($logCount = 5)
	Dim $logString = "Last " & $logCount & " actions" & @LF, $tmp, $tmp2, $fileDate, $filename, $tmpLog
	$fileDate = StringReplace(StringReplace(StringReplace(_Now(), "/", ""), ":", ""), " ", "-")
	$filename = "logs\GFBotLogs-" & $fileDate & ".log"
	$file = FileOpen($filename, 10)
	If $file = -1 Then
		MsgBox(0, "Error", "Unable to open file.")
		Exit
	EndIf
	$tmpLog = $SYSLOGS
	For $i = 0 To UBound($tmpLog) - 1
		$tmp = _ArrayPop($tmpLog)
		If $tmp = "" Then ExitLoop
		FileWriteLine($file, $tmp)
	Next
	FileClose($file)
	If $i = 0 And $tmp = "" Then FileDelete($filename)

	$filename = "logs\GFBotActionLogs-" & $fileDate & ".log"
	$file = FileOpen($filename, 10)
	If $file = -1 Then
		MsgBox(0, "Error", "Unable to open file.")
		Exit
	EndIf
	$tmpLog = $LOGS
	For $i = 0 To UBound($tmpLog) - 1
		$tmp = _ArrayPop($tmpLog)
		If $i < $logCount Then
			$tmp2 = StringMid($tmp, StringInStr($tmp, "Status:") + 7)
			If IsString($tmp2) Then
				$logString &= $tmp2 & @LF
			EndIf
		EndIf
		If $tmp = "" Then ExitLoop
		FileWriteLine($file, $tmp)
	Next
	FileClose($file)
	If $i = 0 And $tmp = "" Then FileDelete($filename)
	ReDim $LOGS[1]
	$LOGS[0] = ""
	ReDim $SYSLOGS[1]
	$SYSLOGS[0] = ""
	ReDim $LOGS[200]
	ReDim $SYSLOGS[999]
	setStatus("Log files created.", False)
	Return $logString
EndFunc   ;==>logToFile

Func SetWayPointMode()
	If $botState Then
		MsgBox(0, "Error", "Please stop the bot to add waypoints")
		Return
	EndIf
EndFunc   ;==>SetWayPointMode

Func updateZone()
	Dim $z = "", $ZoneName[2] = ["Safe", "Store"]
	For $i = 0 To UBound($zones) - 1
		If $zoneWaypoints[$i][0] > 0 Then $z &= "[" & $ZoneName[$i] & "] "
	Next
	updateGUI($zoneLabel, $z)
EndFunc   ;==>updateZone

Func SafeWayPoint()
	InsertWayPoint(0, "Safe Zone")
EndFunc   ;==>SafeWayPoint

Func NPCWayPoint()
	InsertWayPoint(1, "Store NPC")
EndFunc   ;==>NPCWayPoint

Func NormalWayPoint()
	InsertWayPoint()
EndFunc   ;==>NormalWayPoint

Func ShowHelp()
	setStatus("Visit www.general-discussion.com for help")
EndFunc   ;==>ShowHelp

Func _switchPixelFinder()
	If $pixelFinder Then
		setStatus("Pixel finder disabled")
		$pixelFinder = False
	Else
		setStatus("Pixel finder enabled")
		$pixelFinder = True
	EndIf
EndFunc   ;==>_switchPixelFinder

Func _Exit()
	logToFile()
	Exit
EndFunc   ;==>_Exit

Func sendMail($body, $background = 0)
	If $config.Exists("Misc") And $config.Item("Misc" ).Exists("notifyalarm") Then
		ShellExecute($config.Item("Misc" ).Item("notifyalarm"))
	EndIf
	If $config.Exists("Misc") And $config.Item("Misc" ).Exists("notifyemail") Then
		InetGet("http://www.general-discussion.com/services/sendmail.php?subject=" & Eval("_Name") & " Notifications&message=" & $body & "&email=" & $config.Item("Misc" ).Item("notifyemail"), @TempDir & "sendmail.html", 1, $background)
	EndIf
EndFunc   ;==>sendMail

Func _ProcessGetLocation($iPID)
	Local $aProc = DllCall('kernel32.dll', 'hwnd', 'OpenProcess', 'int', BitOR(0x0400, 0x0010), 'int', 0, 'int', $iPID)
	If $aProc[0] = 0 Then Return SetError(1, 0, '')
	Local $vStruct = DllStructCreate('int[1024]')
	DllCall('psapi.dll', 'int', 'EnumProcessModules', 'hwnd', $aProc[0], 'ptr', DllStructGetPtr($vStruct), 'int', DllStructGetSize($vStruct), 'int_ptr', 0)
	Local $aReturn = DllCall('psapi.dll', 'int', 'GetModuleFileNameEx', 'hwnd', $aProc[0], 'int', DllStructGetData($vStruct, 1), 'str', '', 'int', 2048)
	If StringLen($aReturn[3]) = 0 Then Return SetError(2, 0, '')
	Return $aReturn[3]
EndFunc   ;==>_ProcessGetLocation

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			_Exit()
		Case $startStopButton
			If GUICtrlRead($startStopButton) == "Start" Then
				_startBot()
			Else
				_stopBot()
			EndIf
		Case $Label18
			ShellExecute("http://www.general-discussion.com/grand-fantasia/grand-fantasia-trainer-bot-guide/")
	EndSwitch
	If $pixelFinder Then
		$M = MouseGetPos()
		$var = PixelGetColor($M[0], $M[1])
		setStatus("Dec: " & $var & " - Hex:" & StringReplace(Hex($var), "00", "0x", 1) & " - " & $M[0] & "x" & $M[1])
	EndIf
	If $pid = -1 Then
		setStatus("Waiting for Grand Fantasia client")
	EndIf
	WinWait($processName)
	If $pid = -1 Then
		$pid = WinGetProcess($processName)
		loadSettings()
		WinActivate($processName)
		SendKeepActive($processName)
		$clientSize = WinGetClientSize($processName)
		$antiStuckCoords[0][0] = $clientSize[0] - 15
		$antiStuckCoords[0][1] = $clientSize[1] - 15
		$antiStuckCoords[1][0] = $clientSize[0] - 15
		$antiStuckCoords[1][1] = $clientSize[1] - ($clientSize[1] / 4)
		$antiStuckCoords[2][0] = $clientSize[0] - 15
		$antiStuckCoords[2][1] = $clientSize[1] - ($clientSize[1] / 2)
		$mid = _MemoryOpen($pid)
		defaultSettings()
		setStatus("Waiting for character selection...")
		While loadMem("HP") <= 0
			Sleep(500)
		WEnd
		_initMemory()
		loadConfig()
		defaultConfig()
		setStatus("Bot ready, add waypoints with alt+a")
	ElseIf Not $botState Then
		updateValues()
	ElseIf $exitDie = 1 And IsNumber($HP) And $HP <= 0 Then
		closeAndExit()
	ElseIf $botState Then
		If Not WinActive($processName) Then
			WinActivate($processName)
			Sleep(100)
		EndIf
		processBot()
	EndIf
WEnd