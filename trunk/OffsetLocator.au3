#RequireAdmin
#include <NomadMemory.au3>
#include <Array.au3>

HotKeySet("!k", "GetOffsets")
HotkeySet("!t", "TestOffset")
HotKeySet("{Esc}", "EmptyLogs")

Local $LOGS[200]
Local $pid = WinGetProcess("Grand Fantasia")
Local $mid = _MemoryOpen($pid)
Func EmptyLogs()
	Exit
EndFunc



Func TestOffset()
	_ArrayDisplay($LOGS)
EndFunc
Dim $base[1] = [0x009AD9C8]
Func GetOffsets()
	ToolTip("Looking values...", 50,60)
	;For $b In $base
		For $i = 8 To 12
			For $j = 300 To 2000
				$m = _MemoryRead("0x" & Hex(_MemoryRead("0x" & Hex(_MemoryRead(0x009AD9C8, $mid) + $i), $mid) + $j), $mid)
				If $m == 1 Then
					_ArrayPush($LOGS," - Off1:" & Hex($i) & " Off2:" & Hex($j) & " = " & $m)
					TestOffset()
					Exit
				EndIf
			Next
		Next
	;Next
	MsgBox(0,"Not Found","Nothing found")
EndFunc

Func ReadMemoryOffset($pointer, $offset = 0, $type = "dword")
	Dim $tmp
	If IsArray($pointer) Then
		$tmp = ReadMemoryOffset($pointer[1])
		For $i = 2 To UBound($pointer) -1
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
EndFunc

Func WriteMemoryOffset($data, $pointer, $offset = 0, $type = 'dword')
	Dim $tmp
	If IsArray($pointer) Then
		$tmp = ReadMemoryOffset($pointer[1])
		For $i = 2 To UBound($pointer) -1
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
EndFunc


GetOffsets()

