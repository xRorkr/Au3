Dim $lostDelay = 25000, $stuckDelay = 1000, $safeCond = "$HP < (15/100) * $HPCAP", $safeRecoverCond = "$HP = $HPCAP AND $MP = $MPCAP", $sitCond = "1 = 0"
Dim $escapeFight = 0, $lastEscapeFight, $waypointRadius = 0, $sitActions[1], $safeRunActions, $waitActions[1], $exitLevel = 0, $exitTimer = 0, $exitBot = False, $escapeFromSafe = False
Dim $memRealTime, $memPerLevel, $memPerKill
Dim $ignoreMonsters = "", $attackMonsters = "", $killWait = False, $statusAtk, $statusDef, $Zoom, $safeStatus = "", $playerAlertDelay = 60000 * 5, $trainOffset = Dec("2B4"), $collectOffset = Dec("2A8")
Dim $escapeHex, $radius, $waypointRetry, $arrowHex, $lastIndex = 0, $lastPartyHP = 0, $partyListPointer, $ignoreAntiKs = False, $partyIndex = 0, $exitDie = 1
Dim $lastTarget = 0, $lostTimes = 0, $miniMapWidth = 140, $stuckIndex = -1, $lastCoords, $groupData, $firstExp = 0, $firstGold = 0, $lastTargetHP = 0, $minSprStamina = 100
Dim $targetIgnoreDistance, $targetAttackDistance, $fightStuckDelay = 8000, $waypointDelay = 3000, $rangeBugCounter = 0, $freezeDelay = "stuckDelay", $safeSitDelay = 120000, $checkListDelay = 10000
Dim $waypointCoord[1][2], $playerAlert, $oldSafeCond = "", $lastChat = "", $lastChatIndex = 0, $allowLoot = False, $partyMembers = 0, $cursorDistance = 50, $mapX = 0, $mapY = 0
Dim $BreakWeapon = False, $BreakArmor = False, $gotoStore = False, $dest = "safe zone", $inventoryFull = False, $destRange = 0, $maplessAntiSleep = 3000, $autoRoute = 0, $doAntiStuck = False

Dim $lootMessage = "[System]There is nothing to pick up.", $backpackFull = "[System]You do not have enough space in your backpack."
Dim $chatCommands[3] = ["SAFESIT", "NOTIFY","QUIT"], $wpm = 60, $shortcutCommands[5] = ["REVIVE", "SAFESIT", "SUMMON_SPR_1", "SUMMON_SPR_2", "SUMMON_SPR_3"], $chatSys = 1, $antiStuck = True, $spriteChat = 10

Func loadMem($type)
	Select
		Case $type == "RealTime"
			$mem = $memRealTime
		Case $type == "PerKill"
			$mem = $memPerKill
		Case $type == "PerLevel"
			$mem = $memPerLevel
		Case Else
			If $configMem.Exists($type & "_DataType") Then
				$val = ReadMemoryOffset($configMem.Item($type), 0 , $configMem.Item($type & "_DataType"))
			Else
				$val = ReadMemoryOffset($configMem.Item($type))
			EndIf
			GlobalAssign($type, $val)
			Return $val
	EndSelect
	writeMem($type)
	For $i = 1 To UBound($mem) - 1
		If $configMem.Exists($mem[$i] & "_DataType") Then
			$value = ReadMemoryOffset($configMem.Item($mem[$i]), 0 , $configMem.Item($mem[$i] & "_DataType"))
		Else
			$value = ReadMemoryOffset($configMem.Item($mem[$i]))
		EndIf
		GlobalAssign($mem[$i], $value)
	Next
EndFunc

Func writeMem($type, $data = 0)
	Select
		Case $type == "RealTime"
			$mem = $memRealTime
		Case $type == "PerKill"
			$mem = $memPerKill
		Case $type == "PerLevel"
			$mem = $memPerLevel
		Case Else
			If $configMem.Exists($type & "_DataType") Then
				$val = WriteMemoryOffset($data, $configMem.Item($type), 0 , $configMem.Item($type & "_DataType"))
			Else
				$val = WriteMemoryOffset($data, $configMem.Item($type))
			EndIf
			GlobalAssign($type, $data)
			Return $data
	EndSelect
	$memKeys = $configMemWrite.Keys
	For $write In $memKeys
		$search = _ArraySearch($mem, $write)
		If $search <> -1 Then
			$data = $configMemWrite.Item($write)
			If $configMem.Exists($write & "_DataType") Then
				$value = WriteMemoryOffset($data, $configMem.Item($write), 0 , $configMem.Item($write & "_DataType"))
			Else
				$value = WriteMemoryOffset($data, $configMem.Item($write))
			EndIf
			GlobalAssign($write, $data)
		EndIf
	Next
EndFunc

Func _initMemory()
	loadMem("PerLevel")
	If IsDeclared("_Name") Then
		updateGUI($nameLabel, Eval("_Name"))
	EndIf
	If IsDeclared("_ExpCap") Then
		$EXPCAP = Eval("_ExpCap")
		$firstExp = Eval("_Exp")
		updateGUI($expProgress, Floor(($firstExp/$EXPCAP)*100))
	EndIf
	$Level = Eval("_Level")
	$firstGold = Eval("_Gold")
	$statusAtk = Eval("_Atk")
	$statusDef = Eval("_Def")
	updateGUI($levelLabel, $Level)
	If $exitLevel = $Level Then
		$safeCond = "1=1"
		$exitBot = True
		setStatus("Exit level activated")
	EndIf
EndFunc

Func updateValues()
	If $pid <> -1 Then
		;Status
		loadMem("RealTime")
		If IsDeclared("_TargetName") And Not StringRegExp(Eval("_TargetName"), "^[A-Za-z]{1,}[A-Za-z0-9\-_ ]{1,}[^\s]{2,}[A-Za-z0-9\-_ ]{1,}") Then
			Dim $tmpTargetPointer = $configMem.Item("TargetName")
			ReDim $tmpTargetPointer[UBound($tmpTargetPointer) + 1]
			$tmpTargetPointer[UBound($tmpTargetPointer) - 1] = "0"
			GlobalAssign("TargetName", ReadMemoryOffset($tmpTargetPointer, 0, $configMem.Item("TargetName_DataType")))
		EndIf
		If $HP - Eval("_HP") > 0 Then $DMG = $HP - Eval("_HP")
		$lastTargetHP = $THP
		$SIT = Eval("_Sit")
		$CURSED = Eval("_Curse")
		$MP = Eval("_MP")
		$MPCAP = Eval("_MPCAP")
		$HPCAP = Eval("_HPCAP")
		$DMGCAP = $HPCAP
		$HP = Eval("_HP")
		$CH = Eval("_Charge")
		$SHP = Eval("_SHP")
		$SHPCAP = Eval("_SHPCap")
		$THP = Eval("_TargetHP")
		$THPCAP = Eval("_TargetHPCap")
		$targetState = Eval("_Target")
		If $targetState = 1 Then
			$RANGE = Round(getDistance(Eval("_tX"), Eval("_tY"), Eval("_pX"), Eval("_pY")), 1)
		Else
			$RANGE = 0
		EndIf
		If $lastTarget = 1 And $targetState = 0 And $botState And Not $gotoSafe Then
			If $killWait Then
				setStatus("Killed " & Eval("_TargetName"))
				$kills += 1
				$ignoreAntiKs = False
				$allowLoot = True
				$maxUsage.RemoveAll()
				$antiStuck = True
				;If $timers.Exists($freezeDelay) Then $timers.remove($freezeDelay)
			EndIf
			$DMG = 0
			$killWait = False
			$lastTarget = 0
			updateGUI($etLabel, niceTime(TimerDiff($killTimer), True))
			$kph = Ceiling(($kills * 1000 * 60 * 60) / TimerDiff($killTimer))
			loadMem("PerKill")
			$EXP = Eval("_Exp")
			$EPH = Ceiling((($EXP - $firstExp) * 1000 * 60 * 60) / TimerDiff($killTimer))
			updateGUI($ephLabel, $EPH)
			$GOLD = Eval("_Gold")
			$GPH = Ceiling((($GOLD - $firstGold) * 1000 * 60 * 60) / TimerDiff($killTimer))
			updateGUI($goldLabel, money($GOLD - $firstGold))
			updateGUI($gphLabel, money($GPH))
			updateGUI($killsLabel, $kills)
			updateGUI($kphLabel, $kph)
			If $EXPCAP > 0 And $botState Then
				If $Level < Eval("_Level") Then
					setStatus("You gained a level!")
					_initMemory()
				EndIf
				updateGUI($expProgress, Floor(($EXP/$EXPCAP)*100))
				updateGUI($ttlLabel, niceTime((($EXPCAP - $EXP)/$EPH) * 60 * 60 * 1000, True))
			EndIf
			If $CURSED = 0 And IsDeclared("_Atk") And IsDeclared("_Def") Then
				If $BreakArmor And $statusDef <> Eval("_Def") Then
					$BreakArmor = False
					$statusDef = Eval("_Def")
				ElseIf $BreakWeapon And $statusAtk <> Eval("_Atk") Then
					$BreakWeapon = False
					$statusAtk = Eval("_Atk")
				ElseIf $statusAtk > Eval("_Atk") Or $statusDef > Eval("_Def") Then
					If Not breakGambits() Then
						$safeCond = "1=1"
						$exitBot = True
						setStatus("Equipment broke")
					Else
						If $statusAtk > Eval("_Atk") Then
							$BreakWeapon = True
							$statusAtk = Eval("_Atk")
						EndIf
						If $statusDef > Eval("_Def") Then
							$BreakArmor = True
							$statusDef = Eval("_Def")
						EndIf
					EndIf
				EndIf
			EndIf
		ElseIf $targetState = 1 Then
			$lastTarget = 1
		EndIf
		;If $moving Then
		;	$M = 1
		;Else
		;	$M = 0
		;EndIf
		$C = $CURSED
		$T = $targetState
		Sleep(100)
		Dim $st = "Good"
		If $CURSED = 1 Then
			$st = "Cursed "
		EndIf
		If $debugMode Then
			setStatus(debugText())
		EndIf
		updateGUI($rangeLabel, $RANGE)
		updateGUI($statusLabel, $st)
		updateGUI($chargeLabel, $CH)
		updateGUI($hpProgress, Floor(($HP / $HPCAP) * 100))
		updateGUI($mpProgress, Floor(($MP / $MPCAP) * 100))
	EndIf
EndFunc

Func updateGUI($ctrl, $val)
	If GUICtrlRead($ctrl) <> $val Then
		GUICtrlSetData($ctrl, $val)
	EndIf
EndFunc

Func breakGambits()
	Dim $gambits = $config.Item("Gambits").Keys
	For $g In $gambits
		If StringInStr($config.Item("Gambits").Item($g), "$Break") > 0 Then Return True
	Next
	Return False
EndFunc

Dim $mapNegCoords = 4294967294

Func updateMapCoords()
	$mapX = Eval("_mapX")
	$mapY = Eval("_mapY")
	If $mapX > $mapNegCoords - 800 Then $mapX += $mapNegCoords * -1
	If $mapY > $mapNegCoords - 600 Then $mapY += $mapNegCoords * -1
EndFunc

Func mapToggle($open = 1)
	While loadMem("map") <> $open
		Send($mapShortcut)
		Sleep(200)
	WEnd
EndFunc

Func mapAlign()
	If Not IsDeclared("_mapX") Then Return
	Dim $x = loadMem("mapX"), $y = loadMem("mapY"), $mX, $mY
	If $x > $mapNegCoords - 800 Then $x += $mapNegCoords * -1
	If $y > $mapNegCoords - 600 Then $y += $mapNegCoords * -1
	If getDistance($x, $y, $mapX, $mapY) > 1 Then
		If $x > 0 Then
			$mX = $x + 10
		ElseIf $x < 0 Then
			$mX = $x + 790
		EndIf
		If $y > 0 Then
			$mY = $y + 10
		ElseIf $y < 0 Then
			$mY = $y + 550
		EndIf
		$t = _Atan2($mapY - $y, $mapX - $x)
		$d = getDistance($x,$y,$mapX,$mapY)
		$dx = Cos($t) * $d + $mX
		$dy = Sin($t) * $d + $mY
		MouseUp("left")
		Sleep(50)
		MouseMove($mX, $mY, 10)
		MouseDown("left")
		Sleep(50)
		MouseMove($dx, $dy, 50)
		MouseUp("left")
		Sleep(50)
	EndIf
EndFunc

Func processChatActions()
	Dim $chats = chatLog()
	For $i = UBound($chats) - 1 To 0
		If StringInStr($lootMessage, $chats[$i]) > 0 Then
			$allowLoot = False
			setStatus("System no loot detected")
			If $targetState = 0 Then clickMapPoint(False)
		ElseIf StringInStr($backpackFull, $chats[$i]) > 0 Then
			$allowLoot = False
			setStatus("System backpack full detected")
			$inventoryFull = True
			If $targetState = 0 Then clickMapPoint(False)
		Else
			processChatGambits($chats[$i])
		EndIf
	Next
EndFunc

Func chatAction($g, $c = "")
	If $g[3] == "SAFESIT" Then
		If $oldSafeCond = "" Then
			$oldSafeCond = $safeCond
			$safeCond = "1=1"
			$safeStatus = ", " & setStatus("Chat safesit action activated")
		Else
			$safeCond = $oldSafeCond
			$oldSafeCond = ""
			$safeStatus = ", " & setStatus("Chat safesit action expired")
		EndIf
	ElseIf $g[3] == "NOTIFY" And $c <> "" Then
		sendMail($c, 1)
		setStatus("Chat NOTIFY activated")
	ElseIf $g[3] == "QUIT" And $c <> "" Then
		$oldSafeCond = $safeCond
		$safeCond = "1=1"
		$exitBot = True
		$safeStatus = ", " & setStatus("Chat quit action activated")
	EndIf
EndFunc

Func processChatGambits($chat = "")
	Dim $actions = $config.Item("ChatGambits").Keys, $gambit, $tmp, $aKey, $cond2 = False, $cond1 = False
	For $a In $actions
		$aKey = "chat_" & $a
		$gambit = $config.Item("ChatGambits").Item($a)
		$g = StringSplit($gambit[1], "-")
		If $timers.Exists($aKey) And TimerDiff($timers.Item($aKey)) >= $gambit[4] Then
			$timers.Remove($aKey)
			If _ArraySearch($chatCommands, $gambit[3]) <> -1 Then chatAction($gambit)
		EndIf
		If $gambit[2] = "" Then
			$cond2 = True
		Else
			$cond2 = StringInStr(StringMid($chat, StringInStr($chat, ":") + 1), $gambit[2]) > 0
		EndIf
		If $gambit[1] = "" Then
			$cond1 = True
		Else
			$cond1 = StringInStr($chat, "[" & $g[1] & "]") = 1
			If $cond1 And $g[0] = 2 Then $cond1 = StringInstr(StringMid($chat, StringInStr($chat, "]") + 1, StringInStr($chat, ":") - 1), $g[2])
		EndIf
		If $chat <> "" And $cond1 And $cond2 And Not $timers.Exists($aKey) Then
			If StringRegExp($gambit[3], "[A-Za-z0-9_]{1,}") And $config.Item("Shortcut").Exists($gambit[3]) Then
				Send($config.Item("Shortcut").Item($gambit[3]))
				If $config.Item("ActionDelay").Exists($gambit[3]) Then
					Sleep($config.Item("ActionDelay").Item($gambit[3]))
				Else
					Sleep(200)
				EndIf
			ElseIf _ArraySearch($chatCommands, $gambit[3]) = -1 Then
				setStatus("ChatGambits " & $chat & " - " & $a)
				If $g[0] > 0 And $g[1] = "Whisper" Then
					Send("^r")
				Else
					Send("^s")
				EndIf
				Sleep(200)
				Send($gambit[3], 1)
				Sleep((Ubound(StringSplit($gambit[3], " ")) / $wpm) * 60 * 1000)
				Send("^s")
				Sleep(200)
				Send("{ENTER}")
			Else
				chatAction($gambit, $chat)
			EndIf
			$timers.Add($aKey, TimerInit())
			sysLog("Chat - " & $a & " - " & $chat)
			Return
		ElseIf StringInStr($chat, "[Say]") = 1 Or StringInStr($chat, "[Whisper]") = 1 Then
			sysLog("Chat - " & $chat)
		EndIf
	Next
EndFunc

Func chatLog()
	If $chatSys = 1 Then
		Return chatLogRead()
	Else
		Return chatLogWrite()
	EndIf
EndFunc

Func chatLogWrite()
	Dim $off1 = Dec("4"), $off2 = Dec("22"), $chatPointer, $tmpLog, $chat, $pattern = "^[A\[ ]{1,}[A-Za-z0-9]{1,}.*", $tmp, $chatStr, $chatLogs[10], $newChats[1], $chatIndex = $lastChatIndex
	If Not $configMem.Exists("Chat") Then Return
	$chatPointer = $configMem.Item("Chat")
	If $lastChatIndex > 10 Then
		$startIndex = $lastChatIndex - 10
	Else
		$startIndex = 0
	EndIf
	For $i = $startIndex To 77
		$chatPointer[4] = Hex(Dec("0") + ($off1 * $i))
		$tmp = ""
		$chatStr = ""
		$chat = ReadMemoryOffset($chatPointer, 0, "char[50]")
		If StringLeft($chat, 1) = "|" Then ContinueLoop
		If StringRegExp($chat, $pattern) Then
			$tmpChatPointer = $chatPointer
			If StringLeft($chat,1) = " " And Ubound($chatLogs) > 1 Then
				$chatStr = _ArrayPop($chatLogs) & $chat
			Else
				$chatStr = $chat
			EndIf
		Else
			$tmpLog = $chatPointer
			ReDim $tmpLog[7]
			$tmpLog[6] = "0"
			$tmpChatPointer = $tmpLog
			$chat = ReadMemoryOffset($tmpLog, 0, "char[50]")
			If StringLeft($chat, 1) = "|" Then ContinueLoop
			If StringRegExp($chat, $pattern) Then
				$tmpLog[6] = Hex(Dec($tmpLog[6]) + $off2)
				$tmp = ReadMemoryOffset($tmpLog, 0, "char[50]")
				If StringLeft($chat,1) = " " And Ubound($chatLogs) > 1 Then
					$chatStr = _ArrayPop($chatLogs) & $chat
				Else
					$chatStr = $chat
				EndIf
				If StringRegExp($tmp, $pattern) And Not StringInStr($chatStr, $tmp) Then $chatStr &= $tmp
			EndIf
		EndIf
		If $chatStr <> "" And Not StringInStr($chatStr, "You whisper to") And Not StringInStr($chatStr, "]" & Eval("_Name") & ":") Then
			If Not IsArray($chatLogs) Then ReDim $chatLogs[10]
			_ArrayPush($chatLogs, $chatStr)
			$lastChatIndex = $i
			WriteMemoryOffset("|" & StringRight($chat, StringLen($chat) - 1), $tmpChatPointer, 0, "char[" & StringLen($chat) & "]")
		EndIf
	Next
	For $i = 0 To Ubound($chatLogs) - 1
		$chat = _ArrayPop($chatLogs)
		If "" == $chat Then ExitLoop
		$newChats[UBound($newChats) - 1] = $chat
		ReDim $newChats[Ubound($newChats) + 1]
	Next
	If UBound($newChats) > 1 Then
		ReDim $newChats[UBound($newChats) - 1]
		$lastChat = $newChats[0]
	EndIf
	Return $newChats
EndFunc

Func chatLogRead()
	Dim $off1 = Dec("4"), $off2 = Dec("22"), $chatPointer, $tmpLog, $chat, $pattern = "^[A\[ ]{1,}[A-Za-z0-9]{1,}.*", $tmp, $chatStr, $chatLogs[10], $newChats[1], $chatIndex = $lastChatIndex, $lastTmp = ""
	If Not $configMem.Exists("Chat") Then Return
	$chatPointer = $configMem.Item("Chat")
	If $lastChatIndex > 10 Then
		$startIndex = $lastChatIndex - 10
	Else
		$startIndex = 0
	EndIf
	For $i = $startIndex To 77
		$chatPointer[4] = Hex(Dec("0") + ($off1 * $i))
		$tmp = ""
		$chatStr = ""
		$chat = ReadMemoryOffset($chatPointer, 0, "char[50]")
		If StringRegExp($chat, $pattern) Then
			If StringLeft($chat,1) = " " And Ubound($chatLogs) > 1 Then
				$chatStr = _ArrayPop($chatLogs) & $chat
			Else
				$chatStr = $chat
			EndIf
			;_ArrayPush($chatLogs, $tmp & $chat)
		Else
			$tmpLog = $chatPointer
			ReDim $tmpLog[7]
			$tmpLog[6] = "0"
			$chat = ReadMemoryOffset($tmpLog, 0, "char[50]")
			If StringRegExp($chat, $pattern) Then
				$tmpLog[6] = Hex(Dec($tmpLog[6]) + $off2)
				$tmp = ReadMemoryOffset($tmpLog, 0, "char[50]")
				If StringLeft($chat,1) = " " And Ubound($chatLogs) > 1 Then
					$chatStr = _ArrayPop($chatLogs) & $chat
				Else
					$chatStr = $chat
				EndIf
				If StringRegExp($tmp, $pattern) And Not StringInStr($chatStr, $tmp) Then $chatStr &= $tmp
				;_ArrayPush($chatLogs, $tmp & $chat)
			EndIf
		EndIf
		If $chatStr <> "" And Not StringInStr($chatStr, "You whisper to") And Not StringInStr($chatStr, "]" & Eval("_Name") & ":") Then
			If Not IsArray($chatLogs) Then ReDim $chatLogs[10]
			If $lastTmp <> $chatStr Then _ArrayPush($chatLogs, $chatStr)
			$lastChatIndex = $i
			$lastTmp = $chatStr
		EndIf
	Next
	If $lastChat = "" Then $lastChat = $chatLogs[UBound($chatLogs) - 1]
	For $i = 0 To UBound($chatLogs) - 1
		$chat = _ArrayPop($chatLogs)
		If $lastChat == $chat Then ExitLoop
		$newChats[UBound($newChats) - 1] = $chat
		ReDim $newChats[Ubound($newChats) + 1]
	Next
	If UBound($newChats) > 1 Then ReDim $newChats[UBound($newChats) - 1]
	If $newChats[0] <> "" Then $lastChat = $newChats[0]
	Return $newChats
EndFunc

Func playerAlert()
	If $zoneWaypoints[0][0] = 0 Then Return
	Dim $nOff = Dec("4"), $listPointer = $configMem.Item("ListStart"), $player = "", $pattern = "^[A-Za-z0-9_\-]{1,}$", $tmpPointer
	For $i = 1 To 14
		$listPointer[2] = Hex($i * $nOff)
		$player = ReadMemoryOffset($listPointer, 0, "char[50]")
		If Not StringRegExp($player, $pattern) Then
			$tmpPointer = $listPointer
			ReDim $tmpPointer[UBound($tmpPointer) + 1]
			$tmpPointer[UBound($tmpPointer) - 1] = "0"
			$player = ReadMemoryOffset($tmpPointer, 0, "char[50]")
			If Not StringRegExp($player, $pattern) Then ContinueLoop
		EndIf
		If $player <> "" And $player <> Eval("_Name") And (StringInStr($player, "GS") = 1 Or _ArraySearch($playerAlert, $player) <> -1) Then
			If $oldSafeCond = "" And Not $timers.Exists("playeralert") Then
				$oldSafeCond = $safeCond
				$safeCond = "2=2"
				$safeStatus = ", " & setStatus("Player alert! " & $player)
				sysLog("Player alert - " & $player)
				$timers.Add("playeralert", TimerInit())
				Return
			EndIf
		EndIf
	Next
EndFunc

Func checkList()
	If Not IsArray($playerAlert) Or $zoneWaypoints[0][0] = 0 Then Return
	Dim $nOff = Dec("a8"), $lOff = Dec("1F8"), $lStart = Dec("930"), $currentChar[2], $listPointer, $locPointer, $hasAlert = False
	$listPointer = $configMem.Item("ListStart")
	$locPointer = $listPointer
	$locPointer[UBound($locPointer) - 1] =  Hex(Dec($locPointer[UBound($locPointer) - 1]) + $lStart)
	Do
		$currentChar[0] = ReadMemoryOffset($listPointer, 0, "char[50]")
		$currentChar[1] = ReadMemoryOffset($locPointer, 0, "char[50]")
		;MsgBox(0,"ASD", loadMem("CurrentLoc") & "-" & $currentChar[0] & "-"& $currentChar[1])
		If loadMem("CurrentLoc") == $currentChar[1] And ($playerAlert[0] == "all" Or _ArraySearch($playerAlert, $currentChar[0]) <> -1) Then
			$hasAlert = True
			If $oldSafeCond == "" Then
				$oldSafeCond = $safeCond
				$safeCond = "3=3"
				$safeStatus = ", " & setStatus("Player alert! " & $currentChar[0])
			EndIf
		EndIf
		$listPointer[UBound($locPointer) - 1] =  Hex(Dec($listPointer[UBound($listPointer) - 1]) + $nOff)
		$locPointer[UBound($locPointer) - 1] =  Hex(Dec($locPointer[UBound($locPointer) - 1]) + $lOff)
	Until $currentChar[1] == "Offline" Or $currentChar[1] == ""
	If Not $hasAlert And $oldSafeCond = "3=3" Then
		$safeCond = $oldSafeCond
		$oldSafeCond = ""
		$safeStatus = ", " & setStatus("Player alert expired")
	EndIf
EndFunc

Func sit($sit = 1)
	While loadMem("Sit") <> $sit
		Send($sitShortcut)
		Sleep(200)
	WEnd
EndFunc

Func getDistance($x1, $y1, $x2, $y2)
   return Sqrt((Abs($x1-$x2))^2 + (Abs($y1-$y2))^2)
EndFunc

Func arrivedBot()
	Dim $x, $y, $i = - 1, $r = $radius
	$coord = getPosition()
	If Not IsArray($coord) Then Return False
	If $gotoStore Then
		$i = 1
	ElseIf $gotoSafe Then
		$i = 0
	EndIf
	If $i >= 0 Then
		$x = $zoneCoords[$i][0]
		$y = $zoneCoords[$i][1]
		$m = $zoneWaypoints[$i][2]
	Else
		$x = $waypointCoord[$lastIndex][0]
		$y = $waypointCoord[$lastIndex][1]
		$m = $WayPoints[$lastIndex][2]
	EndIf
	;If $m = 0 Then $r = 3
	If getDistance($x, $y, $coord[0], $coord[1]) <= $r Then
		;setCurrentWaypoint()
		Return True
	Else
		Return False
	EndIf
EndFunc

Func clickMapPoint($next = True)
	Dim $x, $y, $m
	If Not $next Then
		$WayPointIndex = $lastIndex
	EndIf
	If $WayPointCount = 0 Then
		Return
	EndIf
	If $WayPointCount = $WayPointIndex Then
		$WayPointIndex = 0
	EndIf
	If Not WinActive($processName) Then
		WinActivate($processName)
		Sleep(100)
	EndIf
	If $gotoStore Then
		$x = $zoneWaypoints[1][0]
		$y = $zoneWaypoints[1][1]
		$m = $zoneWaypoints[1][2]
	ElseIf $gotoSafe Then
		$x = $zoneWaypoints[0][0]
		$y = $zoneWaypoints[0][1]
		$m = $zoneWaypoints[0][2]
	Else
		$lastIndex = $WayPointIndex
		updateGUI($waypointLabel, ($WayPointIndex + 1) & "/" & $WayPointCount)
		$x = $WayPoints[$WayPointIndex][0]
		$y = $WayPoints[$WayPointIndex][1]
		$m = $WayPoints[$WayPointIndex][2]
		$WayPointIndex += 1
	EndIf
	mapToggle($m)
	MouseUp("left")
	Sleep(100)
	If $m = 0 Then
		;If $timers.Exists($freezeDelay) Then $timers.remove($freezeDelay)
		moveMouse($x, $y)
		MouseDown("left")
		Sleep(100)
		MouseUp("left")
		Sleep(50)
		writeDestination($x, $y)
	Else
		mapAlign()
		MouseMove($x, $y, 0)
		Sleep(100)
		MouseDown("left")
		Sleep(100)
		MouseUp("left")
		Sleep(50)
	EndIf
EndFunc

Func writeDestination($x, $y)
	writeMem("mX", $x)
	writeMem("mY", $y)
EndFunc

Func moveMouse($x2, $y2)
	Dim $x1 = Eval("_pX"), $y1 = Eval("_pY")
	Dim $angle = (_ATan2($y2 - $y1, $x2 - $x1) / $PI) * 180, $currentAngle = Eval("_Direction"), $radianDeg = 57.2957795, $t, $dx, $dy, $direction = 0
	Dim $centerX = $clientSize[0]/2, $centerY = $clientSize[1]/2, $dist = $cursorDistance, $x , $y, $rotateAngle = 0
	If $currentAngle > 0 Then
		$currentAngle = ($PI * 2) - $currentAngle
	Else
		$currentAngle = Abs($currentAngle)
	EndIf
	$currentAngle *= $radianDeg
	$currentAngle = $currentAngle - 90
	If $currentAngle < 0 Then $currentAngle += 360
	$screenAngle = $angle + 180
	$t = $screenAngle * $PI / 180
	$dx = -Cos($t) * $dist
	$dy = Sin($t) * $dist
	If $currentAngle < 90 Then
		$t = (Abs(90 - $currentAngle) * $PI / 180) * - 1
	Else
		$t = Abs($currentAngle - 90) * $PI / 180
	EndIf
	$x = ($dx * Cos($t)) - ($dy * Sin($t))
	$y = ($dy * Cos($t)) + ($dx * Sin($t))

	$x += $centerX
	$y += $centerY
	MouseMove($x, $y, 0)
	$rotateAngle = $currentAngle - 180
	If loadMem("Cursor") = 1 Then
		$doAntiStuck = True
		$t = $screenAngle * $PI / 180
		$dx = -Cos($t) * ($dist * 2)
		$dy = Sin($t) * ($dist * 2)
		While loadMem("Cursor") = 1
			If $rotateAngle < 0 Then $rotateAngle += 360
			$rotateAngle += 10
			If $rotateAngle < 90 Then
				$t = (Abs(90 - $rotateAngle) * $PI / 180) * - 1
			Else
				$t = Abs($rotateAngle - 90) * $PI / 180
			EndIf
			$x = (($dx * Cos($t)) - ($dy * Sin($t))) + $centerX
			$y = (($dy * Cos($t)) + ($dx * Sin($t))) + $centerY
			MouseMove($x, $y, 0)
			Sleep(10)
		WEnd
	EndIf
EndFunc

Func removeTarget()
;	MouseUp("left")
;	Sleep(100)
;	MouseMove($antiStuckCoords[0][0], $antiStuckCoords[0][1], 0)
;	Sleep(100)
;	MouseClick("right",$antiStuckCoords[0][0], $antiStuckCoords[0][1], 2, 100)
;	Sleep(100)
	writeMem("Target", 0)
EndFunc

Func getWayPoint($which = "next")
	Dim $nWP
	If $which == "next" Then
		$nWP = $WayPointIndex + 1
	Else
		$nWP = $lastIndex + 1
	EndIf
	If $WayPointCount = $nWP - 1 Then
		$nWP = 1
	EndIf
	Return $nWP
EndFunc

Func getPosition() ;$inGame = False, $who = "player"
	Dim $pos[2] ;, $position
	;If $WayPoints[$lastIndex][2] = 0 Or $inGame And IsDeclared("_pX") Then
		$pos[0] = loadMem("pX")
		$pos[1] = loadMem("pY")
		Return $pos
	;Else
	;	$position = PixelSearch(0,0, $clientSize[0] - $miniMapWidth, $clientSize[1], $arrowHex, 5, 1)
	;EndIf
	;If IsArray($position) Then
	;	Return $position
	;Else
	;	Return 0
	;EndIf
EndFunc

Func checkDestRange()
	Dim $pos, $destR
	$pos = getPosition()
	$destR = getDistance($pos[0], $pos[1], $WayPoints[$lastIndex][0],$WayPoints[$lastIndex][1])
	If $destR > $destRange Then
		clickMapPoint(False)
		$destRange = $destR
	EndIf
EndFunc

Func setCurrentWaypoint()
	$coord = getPosition()
	If $gotoStore Then
		$zoneCoords[1][0] = $coord[0]
		$zoneCoords[1][1] = $coord[1]
	ElseIf $gotoSafe Then
		$zoneCoords[0][0] = $coord[0]
		$zoneCoords[0][1] = $coord[1]
	Else
		$waypointCoord[$lastIndex][0] = $coord[0]
		$waypointCoord[$lastIndex][1] = $coord[1]
	EndIf
EndFunc

Func moveBot()
	Dim $useStuckDelay, $scanTop
	$delayName = "moveDelay"
	$delayMove  = "MovingTime"
	If ($targetState = 0 And Not $camperMode And $WayPointCount > 0) Or ($gotoSafe And Not $safeRecover) Then
		If Not $timers.Exists($freezeDelay) Then
			$lastCoords = getPosition()
			;If $WayPoints[$lastIndex][2] = 0 And $stuckDelay = 200 Then $stuckDelay = 1000
			If IsArray($lastCoords) Then
				$timers.add($freezeDelay, TimerInit())
				$scanTop = 0
			EndIf
		ElseIf TimerDiff($timers.Item($freezeDelay)) > 100 Then
			$currentCoords = getPosition()
			;MsgBox(0,"ASD", $currentCoords[0] &"x" & $currentCoords[1] &"="& $lastCoords[0]&"x"& $lastCoords[1])
			If Floor(getDistance($currentCoords[0], $currentCoords[1], $lastCoords[0], $lastCoords[1])) <= 0 Then
				If loadMem("map") = 0 And Not $doAntiStuck Then
					clickMapPoint(False)
				Else
					Do
						$findEscape = PixelSearch($clientSize[0] - 125, 54 + $scanTop, $clientSize[0] - 45, 114, $escapeHex, 5, Random(30,50))
						$scanTop += 10
						If $scanTop + 54 > 114 Then
							$scanTop = 0
						EndIf
					Until IsArray($findEscape)
					If IsArray($findEscape) Then
						MouseUp("left")
						Sleep(100)
						MouseMove($findEscape[0], $findEscape[1], 0)
						Sleep(100)
						MouseDown("left")
						Sleep(100)
						MouseUp("left")
						If Eval("_map") = 0 Then
							Sleep($maplessAntiSleep)
						Else
							Sleep(700)
						EndIf
						clickMapPoint(False)
						Sleep(500)
						If $gotoSafe Then
							setStatus("Stuck, rerouting to " & $dest)
						Else
							setStatus("Stuck, rerouting to waypoint " & getWayPoint("last"))
						EndIf
					EndIf
					$antiStuck = True
					$doAntiStuck = False
				EndIf
			EndIf
			If $timers.Exists($freezeDelay) Then $timers.remove($freezeDelay)
		EndIf
	ElseIf $targetState = 1 And $timers.Exists($freezeDelay) Then
		$timers.remove($freezeDelay)
	EndIf
	If $gotoSafe Then
		If Not arrivedBot() Then
			clickMapPoint()
		EndIf
		Return
	ElseIf $WayPointCount == 0 Then
		Return
	EndIf
	If $antiStuck Or ($targetState = 0 And $WayPoints[$lastIndex][2] = 1) Then ; And $moving == True
		setStatus("Continue to waypoint " & getWayPoint("last"))
		clickMapPoint(False)
		$antiStuck = False
	EndIf
	If arrivedBot() And Not $gotoSafe Then ;$moving == true AND
		Dim $status = "Arrived at waypoint " & getWayPoint("last")
		If $WayPointCount > 1 Then
			$status &= " moving to next waypoint " & getWayPoint()
		EndIf
		setStatus($status)
		;setCurrentWaypoint()
		;$moving = false
		$lostTimes = 0
		If $escapeFromSafe Then
			$escapeFromSafe = False
			$escapeFight = $lastEscapeFight
		EndIf
		clickMapPoint()
		;setCurrentWaypoint(False)
		;$moving = true
		If $timers.Exists($delayMove) Then
			$timers.remove($delayMove)
		EndIf
		$timers.add($delayMove, TimerInit())
	ElseIf $timers.Exists("MovingTime") Then
		If $lostDelay < TimerDiff($timers.Item($delayMove)) Then
			$timers.remove($delayMove)
			;$moving = false
			$lostTimes += 1
			If $lostTimes <= $waypointRetry Then
				$WayPointIndex = $lastIndex
				setStatus("Can't find waypoint, retry("& $lostTimes &") moving " & getWayPoint("last"))
			Else
				setStatus("Can't find waypoint, moving to next waypoint " & getWayPoint())
				$lostTimes = 0
			EndIf
			clickMapPoint()
		EndIf
	EndIf
EndFunc

Func ClearWayPoints()
	$lastIndex = 0
	$WayPointIndex = 0
	$WayPointCount = 0
	$mapX = 0
	$mapY = 0
	ReDim $WayPoints[1][3]
	ReDim $waypointCoord[1][2]
	updateGUI($waypointLabel, $WayPointCount)
	setStatus("Waypoints cleared")
EndFunc

Func ClearLastWayPoints()
	If $WayPointCount <= 0 Then Return
	$lastIndex = 0
	$WayPointIndex = 0
	$WayPointCount -= 1
	ReDim $WayPoints[$WayPointCount][3]
	ReDim $waypointCoord[$WayPointCount][2]
	updateGUI($waypointLabel, $WayPointCount)
	setStatus("Last waypoint deleted")
EndFunc

Func getWaypointPos()
	Dim $coords[3]
	If loadMem("map") = 0 Then
		$coords[0] = Round(loadMem("pX"))
		$coords[1] = Round(loadMem("pY"))
	Else
		$coords = MouseGetPos()
		ReDim $coords[3]
	EndIf
	$coords[2] = loadMem("map")
	Return $coords
EndFunc

Func InsertWayPoint($t = -1, $type = "")
	If Not WinActive($processName) Then
		WinActivate($processName)
	EndIf
	updateValues()
	If $t <> -1 Then
		$coords = getWaypointPos()
		$zoneWaypoints[$t][0] = $coords[0]
		$zoneWaypoints[$t][1] = $coords[1]
		$zoneWaypoints[$t][2] = $coords[2]
		If $coords[2] = 0 Then
			$zoneCoords[$t][0] = $coords[0]
			$zoneCoords[$t][1] = $coords[1]
		Else
			$zoneCoords[$t][0] = Number(loadMem("mapdX"))
			$zoneCoords[$t][1] = Number(loadMem("mapdY"))
		EndIf
		updateZone()
		setStatus($type & " waypoint added")
	Else
		If $WayPointCount = 0 Then
			$WayPointIndex = 0
		EndIf
		$WayPointCount = $WayPointCount + 1
		ReDim $WayPoints[$WayPointCount][3]
		ReDim $waypointCoord[$WayPointCount][2]
		$coords = getWaypointPos()
		$WayPoints[$WayPointCount-1][0] = $coords[0]
		$WayPoints[$WayPointCount-1][1] = $coords[1]
		$WayPoints[$WayPointCount-1][2] = loadMem("map")
		If $WayPoints[$WayPointCount-1][2] = 0 Then
			$waypointCoord[$WayPointCount-1][0] = $coords[0]
			$waypointCoord[$WayPointCount-1][1] = $coords[1]
		Else
			$waypointCoord[$WayPointCount-1][0] = Number(loadMem("mapdX"))
			$waypointCoord[$WayPointCount-1][1] = Number(loadMem("mapdY"))
		EndIf
		updateGUI($waypointLabel, $WayPointCount)
		setStatus("Waypoint " & $WayPointCount & " added")
	EndIf
EndFunc

Func getTargetRange()
	Dim $distance = getDistance(loadMem("pX"), loadMem("pY"), loadMem("tX"), loadMem("tY"))
	$RANGE = Round($distance,1)
	updateGUI($rangeLabel, $RANGE)
	Return $distance
EndFunc

Func monsterDetect()
	If $killWait And $timers.Exists("FightStuck") Then
		If TimerDiff($timers.Item("FightStuck")) > $fightStuckDelay And ($THP = $THPCAP Or $THP = $lastTargetHP) Then
			$killWait = False
			$timers.remove("FightStuck")
			$targetState = 0
			removeTarget()
			setStatus("Ignored " & Eval("_TargetName") & ", can't reach")
			clickMapPoint()
		EndIf
	ElseIf $targetState = 1 And IsDeclared("_TargetName") Then
		Sleep(100)
		$targetDistance = getTargetRange()
		If IsArray($attackMonsters) And _ArraySearch($attackMonsters, Eval("_TargetName")) = -1 And $targetDistance > $targetIgnoreDistance Then
			$targetState = 0
			setStatus("Ignored " & Eval("_TargetName") & ", not in attack list")
		ElseIf IsArray($ignoreMonsters) And _ArraySearch($ignoreMonsters, Eval("_TargetName")) <> -1 And $targetDistance > $targetIgnoreDistance Then
			$targetState = 0
			setStatus("Ignored " & Eval("_TargetName") & ", ignored list")
		EndIf
		If $targetState = 1 Then
			If $targetAttackDistance > 0 And $targetDistance > $targetAttackDistance Then
				$targetState = 0
				setStatus("Ignored " & Eval("_TargetName") & ", too far")
			ElseIf $waypointRadius > 0 Then
				Dim $tooFar = False
				For $i = 0 To $WayPointCount - 1
					If IsNumber($waypointCoord[$i][0]) And IsNumber($waypointCoord[$i][1]) And $targetDistance > $targetIgnoreDistance And $waypointRadius < getDistance($waypointCoord[$i][0], $waypointCoord[$i][1], Eval("_tX"), Eval("_tY")) Then
						$tooFar = True
					EndIf
				Next
				If $tooFar Then
					$targetState = 0
					setStatus("Ignored " & Eval("_TargetName") & ", outside waypoint radius")
				EndIf
			EndIf
		EndIf
		If IsDeclared("_TargetHP") And $targetState = 1 Then
			If Eval("_TargetHP") < Eval("_TargetHPCap") And $targetDistance > $targetIgnoreDistance And Not $ignoreAntiKs Then
				$targetState = 0
				setStatus("Ignored " & Eval("_TargetName") & ", Anti-KS")
			EndIf
		EndIf
	EndIf
	If Not $killWait And $targetState = 1 Then
		$killWait = True
		$maxUsage.RemoveAll()
		If $timers.Exists("FightStuck") Then
			$timers.remove("FightStuck")
		EndIf
		$timers.add("FightStuck", TimerInit())
		setStatus("Fighting " & Eval("_TargetName"))
	EndIf
	$T = $targetState
EndFunc

Func closeAndExit()
	sendMail(logToFile(IniRead($settingsFile,"Settings","logcount", 5)))
	Sleep(1000)
	WinClose($processName)
	Sleep(1000)
	If IniRead($settingsFile,"Settings","shutdown", 0) > 0 Then
		Shutdown(5)
	EndIf
	Exit
EndFunc

Func reviveBot()
	Sleep(50)
	MouseMove($clientSize[0] / 2, $clientSize[1] / 2 - 105, 10)
	MouseClick("left")
	;MouseMove($clientSize[0] / 2, $clientSize[1] / 2 - 75, 10)
	$camperMode = True
	$gotoSafe = True
	$safeRecover = True
EndFunc

Func shortcutCommand($cmd)
	If $cmd = "REVIVE" Then
		reviveBot()
	ElseIf StringInStr($cmd, "SUMMON_SPR") <> -1 Then
		summonSprite(Number(StringRight($cmd, 1)))
	EndIf
EndFunc

Func processBot()
	updateValues()
	If $exitTimer > 0 Then
		If TimerDiff($killTimer) > $exitTimer Then
			$safeCond = "1=1"
			$exitBot = True
			$safeStatus = ", " & setStatus("Exit timer activated")
		EndIf
	EndIf
	If $CURSED = 0 Then
		$execSafeCond = Execute($safeCond)
		If $execSafeCond And Not $gotoSafe And $zoneWaypoints[0][0] > 0 Then
			If $safeRecover And $SIT = 1 Then sit(0)
			$safeRecover = False
			$gotoSafe = True
			If $timers.Exists($freezeDelay) Then $timers.remove($freezeDelay)
			If $timers.Exists("SafeZone") Then $timers.remove("SafeZone")
			$timers.add("SafeZone", TimerInit())
			setStatus("Running to " & $dest & $safeStatus)
			clickMapPoint()
		ElseIf Not $camperMode And Not $safeRecover And Execute($sitCond) And Not $execSafeCond Then
			$safeRecover = True
			$camperMode = True
			setStatus("Camper mode... need to recover.");
		ElseIf $execSafeCond And Not $gotoSafe And $zoneWaypoints[0][0] > 0 Then
			$safeRecover = False
			$camperMode = False
			Return
		EndIf
	EndIf
	If $gotoSafe And Not $safeRecover Then
		$safeDelay = TimerDiff($timers.Item("SafeZone")) > $safeSitDelay
		If arrivedBot() Or $safeDelay Then
			If Not $gotoStore Then sit(1)
			$safeRecover = True
			$camperMode = True
			If $timers.Exists("SafeZone") Then
				$timers.remove("SafeZone")
			EndIf
			If $safeDelay And Not $gotoStore Then
				setStatus("Can't find " & $dest & ", recovering here.")
			ElseIf $safeDelay And $gotoStore Then
				setStatus("Can't find " & $dest & ", canceling store.")
				cancelStoreAction()
			Else
				setStatus("Arrived at " & $dest)
				If $gotoStore Then storeProcess()
			EndIf
			removeTarget()
			If $exitBot Then
				closeAndExit()
			EndIf
		EndIf
	EndIf
	If $safeRecover Or $gotoSafe Then
		If $safeCond = "2=2" And $timers.Exists("playeralert") And TimerDiff($timers.Item("playeralert")) > $playerAlertDelay Then
			$safeCond = $oldSafeCond
			$oldSafeCond = ""
			$safeStatus = ", Player alert has expired"
			$timers.remove("playeralert")
		EndIf
		If Execute($safeRecoverCond) And Not Execute($safeCond) Then
			If $gotoSafe Then
				$escapeFromSafe = True
				$lastEscapeFight = $escapeFight
				$escapeFight = 1
			EndIf
			$safeRecover = False
			$gotoSafe = False
			$camperMode = False
			setStatus("Recovered" & $safeStatus)
			$safeStatus = ""
		EndIf
	EndIf
	If Not $gotoSafe Then
		monsterDetect()
	EndIf
	If $gotoSafe And Not $camperMode Then
		$actions = $safeRunActions
	Else
		$actions = $config.Item("Shortcut").Keys
	EndIf
	If IsArray($actions) Then
		If $partyMembers > 0 Then processPartyActions($actions)
		If $oldSafeCond = "" And IsArray($playerAlert) Then playerAlert()
		processChatActions()
		If $targetState = 0 And $zoneWaypoints[1][0] > 0 Then processStoreActions()
		For $a in $actions
			$delayExists = $config.Item("Delay").Exists($a)
			If $config.Item("Gambits").Exists($a) Then
				If Not $allowLoot And StringInStr($a, "loot") Then
					$meetCondition = False
				Else
					$meetCondition = Execute($config.Item("Gambits").Item($a))
				EndIf
				If $meetCondition Then
					If $delayExists AND $timers.Exists($a) Then
						$timeDiff = TimerDiff($timers.Item($a))
						If $timeDiff >= $config.Item("Delay").Item($a) Then
							$timers.remove($a)
						EndIf
					EndIf
				EndIf
			EndIf
			If $maxUsage.Exists($a) And $maxUsage.Item($a) >= $config.Item("MaxUsage").Item($a) Then $meetCondition = False
			If Not $timers.Exists($a) And $meetCondition Then
				$key = $config.Item("Shortcut").Item($a)
				;Exception for monster selection And Camper Mode
				If $key <> "{TAB}" Or ($key == "{TAB}" And $targetState = 0 And Not $camperMode) Then
					If $key <> "{TAB}" And $targetState = 0 And $camperMode And _ArraySearch($sitActions, $a) = -1 Then
						;Ignore any shortcut with camper mode and no target(assumes everything is buff)
					ElseIf $key == "{TAB}" And $escapeFight = 1 And $targetState = 0 Then ;And $moving == True
						;Ignore fights while moving to waypoint
					ElseIf $key == "{TAB}" And loadMem("Target") = 1 And $RANGE <= $targetIgnoreDistance And $targetState = 0 Then
						;updates target if needs to still tab
					ElseIf _ArraySearch($shortcutCommands, $key) <> -1 Then
						shortcutCommand($key)
					Else
						Send($key)
						Sleep(200)
						If $config.Item("MaxUsage").Exists($a) Then
							If Not $maxUsage.Exists($a) Then $maxUsage.Add($a, 0)
							$tmp = $maxUsage.Item($a) + 1
							$maxUsage.remove($a)
							$maxUsage.Add($a, $tmp)
						EndIf
						If $config.Item("ActionDelay").Exists($a) Then
							Sleep($config.Item("ActionDelay").Item($a))
						ElseIf $camperMode And _ArraySearch($sitActions, $a) <> -1 Then
							If loadMem("Sit") = 1 Then
								Sleep(1000)
							EndIf
						EndIf
						If $delayExists Then $timers.add($a, TimerInit())
						If _ArraySearch($waitActions, $a) <> -1 And $targetState = 0 And $timers.Exists($freezeDelay) Then $timers.remove($freezeDelay)
					EndIf
				EndIf
			EndIf
		Next
	EndIf
	processSpriteActions()
	If $camperMode Then
		If $SIT = 0 And $targetState = 0 Then
			If $gotoSafe And $safeStatus <> "" Then
				setStatus("Waiting" & $safeStatus)
				$safeStatus = ""
			Else
				setStatus("Recovering")
			EndIf
			If Not $gotoStore Then sit(1)
		EndIF
	ElseIf Not $killWait Or $gotoSafe Then
		moveBot()
	EndIf
EndFunc

Func processPartyActions($actions)
	Dim $nOff = Dec("1c"), $capOff = Dec("8"), $listCtr = 0, $tmp
	If Not IsArray($partyListPointer) Then
		Return
	EndIf
	For $i = 1 To $partyMembers
		$tmp = $partyListPointer
		$tmp[UBound($tmp) - 2] = Hex(Dec($tmp[UBound($tmp) - 2]) + $listCtr)
		$PHP = ReadMemoryOffset($tmp)
		$tmp[UBound($tmp) - 1] = Hex(Dec($tmp[UBound($tmp) - 1]) - $capOff)
		$PHPCAP = ReadMemoryOffset($tmp)
		GlobalAssign("P" & $i, True, "")
		For $a in $actions
			If $config.Item("PartyGambits").Exists($a) Then
				processPlayerAction($i, $a)
			EndIf
		Next
		If $partyIndex > 0 And $i = Eval("_PartyMembers") Then
			selectParty(1)
		EndIf
		$partyIndex = 0
		GlobalAssign("P" & $i, False, "")
		$listCtr += $nOff
	Next
	removeTarget()
EndFunc

Func selectParty($n)
	removeTarget()
	while loadMem("Target") = 0
		Send("{F" & $n &"}")
		Sleep(200)
	WEnd
	$partyIndex = $n
	Dim $playerRange = getTargetRange()
	If $playerRange <= $targetIgnoreDistance Then
		$ignoreAntiKs = True
	EndIf
EndFunc

Func processPlayerAction($n, $a)
	Dim $aKey = "P" & $n & $a, $gambit = $config.Item("PartyGambits").Item($a)
	;Detects target selected
	If ((StringInStr($gambit, "T=1") > 0 Or StringInStr($gambit, "T = 1") > 0) And $targetState = 0) Or ((StringInStr($gambit, "T=0") > 0 Or StringInStr($gambit, "T = 0") > 0) And $targetState = 1) Then
		Return
	EndIf
	If $partyIndex = 0 And StringInStr($gambit, "RANGE") > 0 Then
		selectParty($n + 1)
	EndIf
	$meetCondition = Execute($gambit)
	$delayExists = $config.Item("Delay").Exists($a)
	If $meetCondition Then
		If $delayExists AND $timers.Exists($aKey) Then
			$timeDiff = TimerDiff($timers.Item($aKey))
			If $timeDiff >= $config.Item("Delay").Item($a) Then
				$timers.remove($aKey)
			EndIf
		EndIf
	EndIf
	If Not $timers.Exists($aKey) And $meetCondition Then
		If $partyIndex = 0 And StringInStr($gambit, "RANGE") = 0 Then
			selectParty($n + 1)
		EndIf
		$key = $config.Item("Shortcut").Item($a)
		If Not $camperMode Then
			Send($key)
			Sleep(200)
			If $config.Item("ActionDelay").Exists($a) Then Sleep($config.Item("ActionDelay").Item($a))
			If $delayExists Then $timers.add($aKey, TimerInit())
			If _ArraySearch($waitActions, $a) <> -1 And $timers.Exists($freezeDelay) Then $timers.remove($freezeDelay)
		EndIf
	EndIf
EndFunc

Dim $cancelStore = False
Func cancelStoreAction($cancel = False)
	$safeCond = $oldSafeCond
	$oldSafeCond = ""
	$dest = "safe zone"
	$gotoStore = False
	$cancelStore = $cancel
EndFunc

Func processStoreActions()
	Dim $actions = $config.Item("StoreGambits").Keys, $tmp
	For $a In $actions
		$aKey = "_" & $a
		$g = $config.Item("StoreGambits").Item($a)
		If ($inventoryFull Or ((IsDeclared($aKey) And Eval($aKey) <= $g[1]) Or ($g[3] = 0 And Eval($aKey) > $g[1]))) And Not $gotoStore And Not $cancelStore Then
			If Not $inventoryFull Then
				$tmp = setStatus("StoreGambits " & $a & ", going to store")
			Else
				$tmp = setStatus("Inventory full, going to store")
			EndIf
			sysLog($tmp)
			$oldSafeCond = $safeCond
			$safeCond = "1=1"
			$dest = "store"
			$gotoStore = True
		EndIf
	Next
EndFunc

Func storeProcess()
	Dim $lastZoom = loadMem("Zoom")
	writeMem("Zoom", 7.5)
	mapToggle(0)
	searchNPC()
	storeAction("SellOrdinary")
	$storePage = 1
	Dim $actions = $config.Item("StoreGambits").Keys, $minGold
	For $a In $actions
		$aKey = "_" & $a
		$g = $config.Item("StoreGambits").Item($a)
		If IsDeclared($aKey) And Eval($aKey) < $g[2] And Not $cancelStore Then
			If $g[0] = 4 Then
				$minGold = money($g[4])
			Else
				$minGold = 10000
			EndIf
			setStatus("Restocking " & $a)
			While loadMem($a) < $g[2] And loadMem("Gold") > $minGold
				storeAction($g[3])
			WEnd
		EndIf
	Next
	While loadMem("OpenWin") > 1
		Send("b")
		Sleep(200)
	WEnd
	$safeStatus = ", Finished restocking"
	cancelStoreAction()
	writeMem("Zoom", $lastZoom)
EndFunc

Func searchNPC()
	Dim $searchY = 0
	While loadMem("Cursor") <> 5
		$coords = searchHex($configSetting.Item("NPCHex"), 400, 300, 400, 400)
		MouseMove($coords[0] + 10, $coords[1] + $searchY, 0)
		$searchY += 1
		If $searchY > 30 Then $searchY = 0
	WEnd
	While loadMem("OpenWin") < 1
		MouseClick("right")
		Sleep(200)
		If loadMem("Cursor") <> 5 Then
			searchNPC()
			Return
		EndIf
	WEnd
	$coords = searchHex($configSetting.Item("StoreHex"))
	MouseMove($coords[0] + 100, $coords[1], 10)
	MouseClick("left")
	Sleep(150)
EndFunc

Dim $sellNormalOff[2] = [210,302], $pageOff[2][2] = [[120,263],[174,263]], $blockOff[2] = [7,47], $storePage = 1

Func storeAction($action, $clicks = 1, $delay = 50)
	Dim $button = "left", $step = "Next", $addBlock
	Sleep(200)
	$coords = searchHex($configSetting.Item("WinTitleHex"), 500, 500, 50,50)
	If $action = "SellOrdinary" Then
		$coords[0] += $sellNormalOff[0]
		$coords[1] += $sellNormalOff[1]
		$inventoryFull = False
	ElseIf $action = "Next" Then
		$coords[0] += $pageOff[1][0]
		$coords[1] += $pageOff[1][1]
	ElseIf $action = "Prev" Then
		$coords[0] += $pageOff[0][0]
		$coords[1] += $pageOff[0][1]
	Else
		If $action/10 > 1 Then
			$page = Ceiling($action/10)
			$action = Mod($action, 10)
		Else
			$page = 1
		EndIf
		If $page > $storePage Then
			$step = "Next"
		ElseIf $page < $storePage Then
			$step = "Prev"
		EndIf
		For $i = 1 To Abs($page - $storePage)
			storeAction($step)
		Next
		$storePage = $page
		If $action > 5 Then
			$addBlock = 156
			$action -= 5
		Else
			$addBlock = 0
		EndIf
		$coords[0] += $blockOff[0] + $addBlock
		$coords[1] += $blockOff[1] * $action
		$button = "right"
	EndIf
	MouseMove($coords[0], $coords[1], 10)
	MouseClick($button, $coords[0], $coords[1], $clicks, $delay)
	Sleep(200)
EndFunc

Func searchHex($color, $offL = 200, $offT = 200, $offR = 200, $offB = 200)
	Dim $coords
	While Not IsArray($coords)
		$coords = PixelSearch($clientSize[0]/2 - $offL, $clientSize[1]/2 - $offT, $clientSize[0]/2 + $offR, $clientSize[1]/2 + $offB,$color, 5, 1)
	WEnd
	Return $coords
EndFunc

Dim $posPointerX[5] = [5, "", "4", "8", "C"], $posPointerY[5] = [5, "", "4", "8", "10"]

Func spriteInfo($spr, $type = "status")
	Dim $tmp, $tmp2[2], $offset
	If $type = "status" Then
		If Not $configMem.Exists("SpriteState") Then Return 1
		Dim $pointer = $configMem.Item("SpriteState")
		$pointer[3] = Hex(($spr - 1) * Dec("4"))
		Return ReadMemoryOffset($pointer)
	ElseIf $type = "SpritePos" Then
		$posPointerX[1] = "0x" & Hex($configMem.Item("SpriteBase") + (($spr-1) * Dec("4")))
		$posPointerY[1] = $posPointerX[1]
		$tmp2[0] = ReadMemoryOffset($posPointerX)
		$tmp2[1] = ReadMemoryOffset($posPointerY)
		Return $tmp2
	ElseIf $type = "TrainPos" Or $type = "CollectPos" Then
		If $type = "TrainPos" Then
			$offset = $trainOffset
		Else
			$offset = $collectOffset
		EndIf
		$offset += ($spr - 1) * Dec("4")
		$posPointerX[1] = "0x" & Hex($configMem.Item("SpriteBase") + $offset)
		$posPointerY[1] = $posPointerX[1]
		$tmp2[0] = ReadMemoryOffset($posPointerX)
		$tmp2[1] = ReadMemoryOffset($posPointerY)
		Return $tmp2
	EndIf
EndFunc

Func processSpriteActions()
	Dim $actions = $config.Item("SpriteGambits").Keys, $tmp, $status
	For $a In $actions
		$tmp = $config.Item("SpriteGambits").Item($a)
		$status = spriteInfo($tmp[1])
		If $status = 0 And $configMem.Exists("SprStamina" & $tmp[1]) And loadMem("SprStamina" & $tmp[1]) <= $minSprStamina Then ContinueLoop
		If $status <> 1 And $tmp[0] = 4 And loadMem($tmp[4]) < $tmp[2] Then
			spriteAction($tmp[1], $tmp[2], $tmp[3], $status, "autocollect")
			Return
		ElseIf $status <> 1 And $tmp[0] = 3 Then
			spriteAction($tmp[1], $tmp[2], $tmp[3], $status)
			Return
		EndIf
	Next
EndFunc

Dim $trainOff[2] = [50,350], $collectOff[2] = [120,330], $trainBlockOff[2] = [50, 86], $trainOkOff[2] = [335,323], $trainCancelOff[2] = [400,323], $spriteOkOff[2] = [180,210], $spriteChatOff[2] = [50,330]

Func closeAllWin()
	While loadMem("OpenWin") <> 0
		Send("{Esc}")
		Sleep(200)
	WEnd
EndFunc

Func spriteAction($sprite, $train, $collect, $status, $action = "train")
	If $status = 1 Then Return
	If $action <> "collect" Then closeAllWin()
	Dim $fKey = "{F" & ($sprite+5) & "}", $useBlock
	If $status <> 1 And ($action = "train" Or $action = "autocollect") Then
		While loadMem("OpenWin") <> 1
			Send($fKey)
			Sleep(200)
		WEnd
	EndIf
	$pos = spriteInfo($sprite, "SpritePos")
	If $status = 0 Then
		setStatus("Sprite[" & $sprite & "] Action[" & $action & "]")
		If $action = "train" Or $action = "autocollect" Then
			MouseMove($pos[0] + $spriteChatOff[0], $pos[1] + $spriteChatOff[1], 5)
			For $i = 0 To $spriteChat
				MouseClick("left")
				Sleep(100)
			Next
		EndIf
		If $action = "train" Then
			MouseMove($pos[0] + $trainOff[0], $pos[1] + $trainOff[1], 5)
			$useBlock = $train
		Else
			MouseMove($pos[0] + $collectOff[0], $pos[1] + $collectOff[1], 5)
			$useBlock = $collect
		EndIf
		While loadMem("OpenWin") <> 2
			MouseClick("left")
			Sleep(200)
		WEnd
		If $action = "train" Then
			$pos = spriteInfo($sprite, "TrainPos")
		Else
			$pos = spriteInfo($sprite, "CollectPos")
		EndIf
		MouseMove($pos[0] + $trainBlockOff[0], $pos[1] + $trainBlockOff[1] + ($useBlock * 14.2), 5)
		Sleep(150)
		MouseClick("left")
		Sleep(200)
		MouseMove($pos[0] + $trainOkOff[0], $pos[1] + $trainOkOff[1], 5)
		Sleep(150)
		MouseClick("left")
		Sleep(200)
		If 2 = loadMem("OpenWin") And $action <> "collect" Then
			MouseMove($pos[0] + $trainCancelOff[0], $pos[1] + $trainCancelOff[1], 5)
			Sleep(200)
			MouseClick("left")
			Sleep(150)
			spriteAction($sprite, $train, $collect, $status, "collect")
		Else
			closeAllWin()
		EndIf
	ElseIf $status >=5 Then
		setStatus("Sprite[" & $sprite & "] Action[Finished]")
		MouseMove($pos[0] + $spriteOkOff[0], $pos[1] + $spriteOkOff[1], 5)
		While spriteInfo($sprite) >= 5
			MouseClick("left")
			Sleep(200)
		WEnd
		closeAllWin()
	EndIf
EndFunc

Func summonSprite($spr)
	Dim $spriteLeft = (($clientSize[0] - 800) / 2) + 685
	Dim $spriteTop = $clientSize[1] - 23, $addX = 0
	$spriteLeft += (($spr - 1) * 40)
	MouseMove($spriteLeft, $spriteTop, 2)
	MouseClick("right")
	Sleep(200)
	If $clientSize[0] > 800 Or ($clientSize[0] = 800 And $spr = 1) Then $addX = 50
	MouseMove($spriteLeft + $addX, $spriteTop, 10)
	MouseDown("left")
	Sleep(50)
	MouseUp("left")
	Sleep(150)
EndFunc