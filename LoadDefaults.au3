
Func defaultSettings()
	$memRealTime = StringSplit($configSetting.Item("MemRealTime"), ",")
	$memPerLevel = StringSplit($configSetting.Item("MemPerLevel"), ",")
	$memPerKill = StringSplit($configSetting.Item("MemPerKill"), ",")
	$Zoom = $configSetting.Item("Zoom")
	$escapeHex = $configSetting.Item("EscapeColor")
	$radius = $configSetting.Item("radius")
	$waypointRetry = $configSetting.Item("waypointretry")
	$cursorDistance = $configSetting.Item("cursordistance")
	$spriteChat = $configSetting.Item("spritechat")
	$arrowHex = $configSetting.Item("ArrowColor")
	$targetIgnoreDistance = $configSetting.Item("monsterignoredistance")
	$targetAttackDistance = $configSetting.Item("monsterattackdistance")
	If $configSetting.Item("chatsystem") = "read" Then
		$chatSys = 1
	Else
		$chatSys = 2
	EndIf
	If $configSetting.Exists("escapefight") Then $escapeFight = $configSetting.Item("escapefight")
	If $configMem.Exists("PartyListStart") Then $partyListPointer = $configMem.Item("PartyListStart")
	If $configSetting.Exists("SprWinOffset") Then
		$tmp = StringSplit($configSetting.Item("SprWinOffset"), ",")
		$trainOffset = Dec($tmp[1])
		$collectOffset = Dec($tmp[2])
	EndIf
EndFunc

Func defaultConfig()
	If $config.Item("Misc").Exists("minsprstamina") Then $minSprStamina = $config.Item("Misc").Item("minsprstamina")
	If $config.Item("Misc").Exists("autoroute") Then $autoRoute = $config.Item("Misc").Item("autoroute")
	If $config.Item("Misc").Exists("exitdie") Then $exitDie = $config.Item("Misc").Item("exitdie")
	If $config.Item("Misc").Exists("wpm") Then $wpm = $config.Item("Misc").Item("wpm")
	If $config.Item("Misc").Exists("partymembers") Then $partyMembers = $config.Item("Misc").Item("partymembers")
	If $config.Item("Misc").Exists("waypointradius") Then $waypointRadius = $config.Item("Misc").Item("waypointradius")
	If $config.Item("Misc").Exists("playeralert") Then $playerAlert = StringSplit($config.Item("Misc").Item("playeralert"), ",", 2)
	If $config.Item("Misc").Exists("sitactions") Then $sitActions = StringSplit($config.Item("Misc").Item("sitactions"), ",", 2)
	If $config.Item("Misc").Exists("saferunactions") Then $safeRunActions = StringSplit($config.Item("Misc").Item("saferunactions"), ",", 2)
	If $config.Item("Misc").Exists("waitactions") Then $waitActions = StringSplit($config.Item("Misc").Item("waitactions"), ",", 2)
	If $config.Item("Misc").Exists("attackmonsters") Then $attackMonsters = StringSplit($config.Item("Misc").Item("attackmonsters"), ",")
	If $config.Item("Misc").Exists("ignoremonsters") Then $ignoreMonsters = StringSplit($config.Item("Misc").Item("ignoremonsters"), ",")
	If $config.Item("Misc").Exists("exitlevel") Then $exitLevel = $config.Item("Misc").Item("exitlevel")
	If $config.Item("Misc").Exists("exittimer") Then
		Dim $tmp = $config.Item("Misc").Item("exittimer")
		If IsNumber($tmp) Then
			$exitTimer = $tmp  * 60 * 60 * 1000
		ElseIf IsString($tmp) Then
			$exitTimer = _DateDiff("s", _NowCalc(), $tmp) * 1000
		EndIf
	EndIf
	If $config.Item("Gambits").Exists("recovered") Then $safeRecoverCond = $config.Item("Gambits").Item("recovered")
	If $config.Item("Delay").Exists("fightstuckdelay") Then $fightStuckDelay = $config.Item("Delay").Item("fightstuckdelay")
	If $config.Item("Delay").Exists("playeralert") Then $playerAlertDelay = $config.Item("Delay").Item("playeralert")
	If $config.Item("Delay").Exists("stuckdelay") Then $stuckDelay = $config.Item("Delay").Item("stuckdelay")
	If $config.Item("Delay").Exists("waypointdelay") Then $waypointDelay = $config.Item("Delay").Item("waypointdelay")
	If $config.Item("Delay").Exists("lostdelay") Then $lostDelay = $config.Item("Delay").Item("lostdelay")
	If $config.Item("Delay").Exists("antistuck") Then $maplessAntiSleep = $config.Item("Delay").Item("antistuck")
	If $config.Item("Delay").Exists("safesit") Then $safeSitDelay = $config.Item("Delay").Item("safesit")
	If $config.Item("Gambits").Exists("safesit") Then $safeCond = $config.Item("Gambits").Item("safesit")
	If $config.Item("Gambits").Exists("recoversit") Then $sitCond = $config.Item("Gambits").Item("recoversit")
	loadWaypoints()
EndFunc

Func loadWaypoints()
	If Not $config.Exists("Waypoint") Then Return
	If $config.Item("Waypoint").Exists("waypoints") Then
		Dim $wps = StringSplit($config.Item("Waypoint").Item("waypoints"), "|"), $wpmodes
		Dim $wpsc = StringSplit($config.Item("Waypoint").Item("waypointcoords"), "|")
		$WayPointCount = 0
		$WayPointIndex = 0
		For $i = 1 To UBound($wps) - 1
			$WayPointCount = $WayPointCount + 1
			ReDim $WayPoints[$WayPointCount][3]
			ReDim $waypointCoord[$WayPointCount][2]
			$coords = StringSplit($wps[$i], ",", 2)
			$WayPoints[$WayPointCount-1][0] = $coords[0]
			$WayPoints[$WayPointCount-1][1] = $coords[1]
			$WayPoints[$WayPointCount-1][2] = $coords[2]
			;If $WayPoints[$WayPointCount-1][2] = 0 Then
				$coords = StringSplit($wpsc[$i], ",", 2)
				$waypointCoord[$WayPointCount-1][0] = $coords[0]
				$waypointCoord[$WayPointCount-1][1] = $coords[1]
			;EndIf
		Next
		updateGUI($waypointLabel, $WayPointCount)
	EndIf
	For $i = 0 To UBound($zones) - 1
		If $config.Item("Waypoint").Exists($zones[$i]) Then
			$coords = StringSplit($config.Item("Waypoint").Item($zones[$i]), ",", 2)
			$zoneWaypoints[$i][0] = $coords[0]
			$zoneWaypoints[$i][1] = $coords[1]
			$zoneWaypoints[$i][2] = $coords[2]
			$coords = StringSplit($config.Item("Waypoint").Item($zones[$i] & "coords"), ",", 2)
			$zoneCoords[$i][0] = $coords[0]
			$zoneCoords[$i][1] = $coords[1]
		EndIf
	Next
	updateZone()
	If $config.Item("Waypoint").Exists("map") Then
		$coords = StringSplit($config.Item("Waypoint").Item("map"), ",", 2)
		$mapX = Number($coords[0])
		$mapY = Number($coords[1])
	EndIf
EndFunc