#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=favicon.ico
#AutoIt3Wrapper_outfile=MousePointClicker.exe
#AutoIt3Wrapper_UseUpx=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Opt("MouseCoordMode", 2)
Opt("PixelCoordMode", 2)
Opt("SendKeyDownDelay", 50)

#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiStatusBar.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#Region ### START Koda GUI section ### Form=D:\Faisal\Projects\GFBot\MousePointClicker.kxf
$Form1 = GUICreate("Mouse Point Clicker", 313, 74, 192, 124)
$Label1 = GUICtrlCreateLabel("Click Delay", 8, 16, 92, 24)
GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")
$delayInput = GUICtrlCreateInput("400", 112, 16, 57, 21)
$waypointLabel = GUICtrlCreateLabel("0", 176, 16, 30, 20)
GUICtrlSetFont(-1, 15, 400, 0, "MS Sans Serif")
$infoStatus = _GUICtrlStatusBar_Create($Form1)
_GUICtrlStatusBar_SetMinHeight($infoStatus, 25)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

HotKeySet("!s", "InsertRight")
HotKeySet("!a", "InsertLeft")
HotKeySet("!c", "ClearWayPoints")
HotKeySet("!x", "_Exit")
HotKeySet("!z", "_doActions")


Global $WayPointIndex = 0
Global $WayPointCount = 0
Global $WayPoints[1][2], $click[1]
Global $pid = -1, $processName = "Grand Fantasia", $doNow = False, $delay

Func _Exit()
	Exit
EndFunc

Func ClearWayPoints()
	$WayPointIndex = 0
	$WayPointCount = 0
	ReDim $WayPoints[1][3]
	ReDim $click[1]
	GUICtrlSetData($waypointLabel, $WayPointCount)
	setStatus("Waypoints cleared")
EndFunc

Func InsertRight()
	InsertWayPoint("right")
EndFunc

Func InsertLeft()
	InsertWayPoint("left")
EndFunc

Func InsertWayPoint($dir = "left")
	If $WayPointCount == 0 Then
		$WayPointIndex = 0
	EndIf
	$WayPointCount = $WayPointCount + 1
	ReDim $WayPoints[$WayPointCount][2]
	ReDim $click[$WayPointCount]
	$coords = MouseGetPos()
	$WayPoints[$WayPointCount-1][0] = $coords[0]
	$WayPoints[$WayPointCount-1][1] = $coords[1]
	$click[$WayPointCount-1] = $dir
	GUICtrlSetData($waypointLabel, $WayPointCount)
	setStatus("Recorded")
EndFunc

Func setStatus($status = "")
	_GUICtrlStatusBar_SetText($infoStatus, $status)
EndFunc

Func _doActions()
	$doNow = True
EndFunc

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
	EndSwitch
	If $pid == -1 Then
		WinWait($processName)
		$pid = WinGetProcess($processName)
		WinActivate($processName)
		SendKeepActive($processName)
	EndIf
	If $doNow Then
		setStatus("Doing actions...Press Alt+x to quit")
		If $WayPointIndex == $WayPointCount Then
			$WayPointIndex = 0
		EndIf
		MouseMove($WayPoints[$WayPointIndex][0], $WayPoints[$WayPointIndex][1], 0)
		Sleep(100)
		MouseDown($click[$WayPointIndex])
		Sleep(50)
		MouseUp($click[$WayPointIndex])
		$WayPointIndex += 1
		Sleep(GUICtrlRead($delayInput))
	EndIf

WEnd
