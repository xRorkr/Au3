#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <GuiStatusBar.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <TabConstants.au3>
#include <WindowsConstants.au3>

Func URLEncode($urlText)
    $url = ""
    For $i = 1 To StringLen($urlText)
        $acode = Asc(StringMid($urlText, $i, 1))
        Select
            Case ($acode >= 48 And $acode <= 57) Or _
                    ($acode >= 65 And $acode <= 90) Or _
                    ($acode >= 97 And $acode <= 122)
                $url = $url & StringMid($urlText, $i, 1)
            Case $acode = 32
                $url = $url & "+"
            Case Else
                $url = $url & "%" & Hex($acode, 2)
        EndSelect
    Next
    Return $url
EndFunc   ;==>URLEncode

Dim $usernameInput, $passwordInput
Func _authUser($u = "", $p = "")
	If $u = "" Then $u = GUICtrlRead($usernameInput)
	If $p = "" Then $p = GUICtrlRead($passwordInput)
	If $u = "" Or $p = "" Then
		$oReceived = "0|Please put your username/password"
	Else
		Dim $loginUrl = "http://www.general-discussion.com/Services.php?action=validate_user"
		$oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
		$oHTTP.Open("POST", "http://www.general-discussion.com/?action=login2", False)
		$oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.0.10) Gecko/2009042316 Firefox/3.0.10 (.NET CLR 4.0.20506)")
		$oHTTP.SetRequestHeader("Referrer", $loginUrl)
		$oHTTP.SetRequestHeader("Connection", "Close")
		$oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
		$oHTTP.Send("user=" & URLEncode($u) & "&passwrd=" & URLEncode($p) & "&cookielength=-1&submit=Login")
		$oHTTP.Open("GET", $loginUrl , False)
		$oHTTP.Send()
		$oReceived = $oHTTP.ResponseText
	EndIf
	$oReceived = StringSplit($oReceived, "|")
	Return $oReceived
EndFunc

Dim $skipLogin = True
If IniRead($settingsFile, "GeneralDiscussion", "username", "") <> "" And IniRead($settingsFile, "GeneralDiscussion", "password", "") <> "" Then
	$result = _authUser(IniRead($settingsFile, "GeneralDiscussion", "username", ""), IniRead($settingsFile, "GeneralDiscussion", "password", ""))
	If $result[1] = "1" Then
		$skipLogin = True
	Else
		MsgBox(0,"Auto Login Warning", $result[2])
	EndIf
EndIf

If Not $skipLogin Then
	#Region ### START Koda GUI section ### Form=C:\Documents and Settings\VirtualXP\My Documents\Projects\Koda\Forms\LoginForm.kxf
	$loginForm = GUICreate("General Discussion Login", 242, 94, 192, 114)
	GUISetIcon("gdfavicon.ico")
	$Label1 = GUICtrlCreateLabel("Username:", 8, 8, 90, 24)
	GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")
	$Label2 = GUICtrlCreateLabel("Password:", 13, 40, 86, 24)
	GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")
	$usernameInput = GUICtrlCreateInput("", 104, 8, 129, 21)
	$passwordInput = GUICtrlCreateInput("", 104, 40, 129, 21, BitOR($ES_PASSWORD,$ES_AUTOHSCROLL))
	$loginButton = GUICtrlCreateButton("Login", 168, 64, 65, 25, $WS_GROUP)
	$registerLabel = GUICtrlCreateLabel("Create an Account", 32, 70, 113, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "MS Sans Serif")
	GUICtrlSetColor(-1, 0x0000FF)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				Exit
			Case $loginButton
				$result = _authUser()
				If $result[1] = "1" Then
					GUIDelete($loginForm)
					ExitLoop
				Else
					MsgBox(0,"Login Warning", $result[2])
				EndIf
			Case $registerLabel
				ShellExecute("http://www.general-discussion.com/register/")
		EndSwitch
	WEnd
EndIf
