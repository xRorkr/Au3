#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Obfuscator=y
#Obfuscator_Parameters=/sf /sv
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <NomadMemory.au3>

HotKeySet("!q", "_Exit")
HotKeySet("!z", "_inputZoom")
Func _Exit()
	Exit
EndFunc   ;==>_Exit

Func _inputZoom()
	$newZoom = InputBox("Zoom Value", "Input zoom value", $currentZoom)
	WriteMemoryOffset($newZoom, $zoomPointer, 0, "float")
EndFunc   ;==>_inputZoom

#include <GUIConstants.au3>

Global Const $tagTRACKMOUSEEVENT = "dword Size;dword Flags;hwnd hWndTrack;dword HoverTime"

; See http://msdn2.microsoft.com/en-us/library/ms645617.aspx for more info on WM_MOUSEWHEEL

Global Const $WM_LBUTTONDBLCLK = 0x203
Global Const $WM_LBUTTONDOWN = 0x201
Global Const $WM_LBUTTONUP = 0x202
Global Const $WM_MBUTTONDBLCLK = 0x209
Global Const $WM_MBUTTONDOWN = 0x207
Global Const $WM_MBUTTONUP = 0x208
;~ Global Const $WM_MOUSEACTIVATE   = 0x21
Global Const $WM_MOUSEHOVER = 0x2A1
Global Const $WM_MOUSELEAVE = 0x2A3
Global Const $WM_MOUSEMOVE = 0x200
Global Const $WM_MOUSEWHEEL = 0x020A
;~ Global Const $WM_NCHITTEST       = 0x84
;~ Global Const $WM_NCLBUTTONDBLCLK = 0xA3
;~ Global Const $WM_NCLBUTTONDOWN   = 0xA1
;~ Global Const $WM_NCLBUTTONUP     = 0xA2
;~ Global Const $WM_NCMBUTTONDBLCLK = 0xA9
;~ Global Const $WM_NCMBUTTONDOWN   = 0xA7
;~ Global Const $WM_NCMBUTTONUP     = 0xA8
Global Const $WM_NCMOUSEHOVER = 0x2A0
Global Const $WM_NCMOUSELEAVE = 0x2A2
;~ Global Const $WM_NCMOUSEMOVE     = 0xA0
;~ Global Const $WM_NCRBUTTONDBLCLK = 0xA6
;~ Global Const $WM_NCRBUTTONDOWN   = 0xA4
;~ Global Const $WM_NCRBUTTONUP     = 0xA5
Global Const $WM_NCXBUTTONDBLCLK = 0xAD
Global Const $WM_NCXBUTTONDOWN = 0xAB
Global Const $WM_NCXBUTTONUP = 0xAC
Global Const $WM_RBUTTONDBLCLK = 0x206
Global Const $WM_RBUTTONDOWN = 0x204
Global Const $WM_RBUTTONUP = 0x205
Global Const $WM_XBUTTONDBLCLK = 0x20D
Global Const $WM_XBUTTONDOWN = 0x20B
Global Const $WM_XBUTTONUP = 0x20C

Global Const $MK_CONTROL = 0x8
Global Const $MK_LBUTTON = 0x1
Global Const $MK_MBUTTON = 0x10
Global Const $MK_RBUTTON = 0x2
Global Const $MK_SHIFT = 0x4
Global Const $MK_XBUTTON1 = 0x20
Global Const $MK_XBUTTON2 = 0x40


Global Const $TME_CANCEL = 0x80000000
Global Const $TME_HOVER = 0x1
Global Const $TME_LEAVE = 0x2
Global Const $TME_NONCLIENT = 0x10
Global Const $TME_QUERY = 0x40000000

Global Const $HOVER_DEFAULT = 0xFFFFFFFF

Global $X_Prev, $Y_Prev, $mid, $processName = "Grand Fantasia", $pid = -1, $zoomPointer = StringSplit(IniRead("GFZoom.ini", "Setting", "ZoomPointer", "0x009BB078,58"), ",")
Global $currentZoom = 0

$hGui = GUICreate("GFZoom", 200, 30)
$LabelId = GUICtrlCreateLabel("Zoom:", 10, 10, 40, 30)
$LabelZoom = GUICtrlCreateLabel("0", 50, 10, 30, 30)
$LabelState = GUICtrlCreateLabel("H+Shift 10x - Alt+Z", 80, 10, 150, 30)
GUISetState()

$hDLL = DllOpen("user32.dll")

If Not _TrackMouseEvent() Then Exit

GUIRegisterMsg($WM_MOUSEWHEEL, "WM_MOUSEWHEEL")
While 1
	$MsgId = GUIGetMsg()
	If $MsgId = $GUI_EVENT_CLOSE Then
		Exit
	ElseIf $pid == -1 And WinExists($processName) Then
		$pid = WinGetProcess($processName)
		$mid = _MemoryOpen($pid)
	ElseIf $pid <> -1 Then
		$currentZoom = Round(ReadMemoryOffset($zoomPointer, 0, "float"), 2)
		If $currentZoom <> GUICtrlRead($LabelZoom) Then
			GUICtrlSetData($LabelZoom, $currentZoom)
		EndIf
	EndIf
WEnd
DllClose($hDLL)

Func WM_MOUSEWHEEL($hWndGui, $MsgId, $WParam, $LParam)
	Dim $shift = 1
	If BitAND(BitAND($WParam, 0xFFFF), $MK_SHIFT) Then $shift = 10
	$X = BitShift($LParam, 16)
	$Y = BitAND($LParam, 0xFFFF)
	;ToolTip("Wheel Delta: " & BitShift($WParam, 16), Default, Default, "Mouse", 1, 1)
	If BitShift($WParam, 16) < 0 Then
		WriteMemoryOffset($currentZoom + $shift, $zoomPointer, 0, "float")
	Else
		WriteMemoryOffset($currentZoom - $shift, $zoomPointer, 0, "float")
	EndIf
	Return 0
EndFunc   ;==>WM_MOUSEWHEEL

Func _TrackMouseEvent()
	Local $pMouseEvent, $iResult, $iMouseEvent
	Local $tMouseEvent = DllStructCreate($tagTRACKMOUSEEVENT)

	$iMouseEvent = DllStructGetSize($tMouseEvent)
	DllStructSetData($tMouseEvent, "Flags", $TME_HOVER)
	DllStructSetData($tMouseEvent, "hWndTrack", $hGui)
	DllStructSetData($tMouseEvent, "HoverTime", $HOVER_DEFAULT) ; 400 milliseconds
	DllStructSetData($tMouseEvent, "Size", $iMouseEvent)
	$ptrMouseEvent = DllStructGetPtr($tMouseEvent)
	$iResult = DllCall($hDLL, "int", "TrackMouseEvent", "ptr", $ptrMouseEvent)
	Return $iResult[0] <> 0
EndFunc   ;==>_TrackMouseEvent

Func ReadMemoryOffset($pointer, $offset = 0, $type = "dword")
	Dim $tmp
	If IsArray($pointer) Then
		$tmp = ReadMemoryOffset($pointer[1])
		For $i = 2 To UBound($pointer) - 1
			If UBound($pointer) - 1 == $i Then
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
EndFunc   ;==>ReadMemoryOffset

Func WriteMemoryOffset($data, $pointer, $offset = 0, $type = 'dword')
	Dim $tmp
	If IsArray($pointer) Then
		$tmp = ReadMemoryOffset($pointer[1])
		For $i = 2 To UBound($pointer) - 1
			If UBound($pointer) - 1 == $i Then
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
EndFunc   ;==>WriteMemoryOffset