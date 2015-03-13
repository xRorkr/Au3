For more informations visit us at:
http://gfbot.altlimit.org/

changelogs:
v1.1.1.9 - 1/27/2011 - STABLE
-Bugfix reply chat gambits
-Updated pointers

v1.1.1.8 - 1/2/2011
-Bugfix sprite train/collect window offsets

v1.1.1.7 - 10/6/2010
-Bugfix sprite stamina < 100 not completing

v1.1.1.6 - 10/4/2010
-Fixed sprite window offsets
-Updated charbase pointer for playeralert

v1.1.1.5 - 9/24/2010
-Updated sprite pointers(Causing sprite trainer to fail)
-Updated ES pointers
-Added __Map__ variable for ConfigFile

v1.1.1.4 - 8/17/2010
-Bugfix sprite gambits
-Updated pointers
-Added stamina requirements for sprite trainer

v1.1.1.3 - 6/6/2010
-Improved client detection

v1.1.1.2 - 6/1/2010
-Bugfix Sprite trainer

v1.1.1.1 - 5/31/2010
-Bugfix file log creation

v1.1.1.0 - 5/30/2010
-Added SUMMON_SPR_1/2/3 shortcut commands
-Bugfix sprite trainer
-Added logging for chats/sprites
-Improved logging/auto log if unlogged

v1.1.0.2 - 5/27/2010
-Bugfix choosing wrong sprite collect/train
-Moved spritegambits actions after normal gambits
-Updated pointers

v1.1.0.0 - 5/27/2010
-SpriteGambits added

v1.0.0.8 - 5/25/2010
-Added login module

v1.0.0.7 - 5/20/2010
-Changed chatsystem default to read
-Added logs for chat/store gambits

v1.0.0.6 - 5/15/2010
-Improved mapless anti-stuck
-Improved mapped waypoint check
-Improved waypoint radius

v1.0.0.5 - 5/13/2010
-Improved fightstuckdelay
-Improved players detection

v1.0.0.4 - 5/12/2010
-Change adding of safe/store waypoints
-Improved playeralert

v1.0.0.3 - 5/11/2010
-Added notifyalert(accepts a path to execute)
-Improved anti-stuck for mapless waypoint
-Added ChatGambits execute Shortcut and QUIT

v1.0.0.2 - 5/11/2010
-Improved map/mapless waypoint system
-Improved Auto-Buy/Sell

v1.0.0.1 - 5/11/2010
-Removed debug msgbox in storegambits

v1.0.0.0 - 5/10/2010
-Added REVIVE action(exitdie must be 0)
-Added equipment breaking gambits (BreakArmor,BreakWeapon)
-Added delay settings(3s,5m,1h default s)
-Added last damage gambits (DMG)
-Added client pointer detection
-Added Auto save waypoints
-Added auto align mapped waypoint system
-Added mapless waypoint system
-Added MaxUsage
-Added ChatGambits
-Added PartyGambits
-Added StoreGambits

v0.9.8.4 - 5/2/2010
-Works without waypoint added
-Improved waypointradius(moved to Misc)

v0.9.8.3 - 4/30/2010
-Bugfix kill increment on ignored monsters

v0.9.8.2 - 4/28/2010
-Bugfix MemoryRead from 0.9.8.1

v0.9.8.1 - 4/27/2010
-Updated Pointers
-Added playeralert
-Added support for >=, <=, != in gambits

v0.9.8.0 - 4/22/2010
-Too far bugfix
-Made exittimer accept (YYYY-MM-DD HH:MM)
-Added untested feature

v0.9.7.2 - 4/19/2010 - STABLE
-Bugfix log email
-Auto shutdown

v0.9.7.1 - 4/18/2010
-Changed deathmail to notifyemail
-Added logcount (default 5)
-Bugfix running to safe zone
-Moved version in window

v0.9.7.0 - 4/18/2010
-Removed waypointdelay
-Update player coords pointer (Causing range errors)
-Improved AI

v0.9.6.0 - 4/17/2010
-Added deathmail

v0.9.5.4 - 4/17/2010
-Added ability to change WindowTitle and VERSION from GFBot.ini
-Target bugfix - bugfix
-Added auto renaming

v0.9.5.0 - 4/17/2010
-changed shortcuts, please refer to the guide
-Added fightstuckdelay
-Removed stuckdelay
-Removed stuckescape
-Improved stuff

v0.9.4.1 - 4/16/2010
-Bugfix charactername.ini loading

v0.9.4.0 - 4/15/2010
-Added SHP(Summon HP),THP(Target HP),RANGE(Target distance) in gambits
-Used CharacterName.ini for config if not set
-Added more logs

v0.9.3.0 - 4/14/2010
-Added memory write in config
-Added Zoom out after kill

v0.9.2.0 - 4/14/2010
-Added check if equipment broken quit bot
-Bugfix anti-stuck
-Added saferunactions

v0.9.1.0 - 4/13/2010
-Recoded Anti-Stuck improved
-Added alt+r reload config

v0.9.0.0 - 4/13/2010
-Added anti-ks
-Added attak and ignore distance
-Added ignoremonsters and attackmonsters

v0.8.3.0 - 4/11/2010
-Bugfix safezone run
-Added escape fight when coming from safe zone

v0.8.2.0 - 4/11/2010
-Improved sitting and camper mode

v0.8.1.0 - 4/11/2010
-Bugfix sitactions lag

v0.8.0.0 - 4/10/2010
-Bugfix safezone run
-Added [Misc] section in config
-Added sitactions for allowed actions while sitting
-Added skillset to use when starting to bot
-Added exitlevel to close client when reach certian level
-Added exittimer to close client (in hours)

v0.7.2.0 - 4/9/2010
-Bugfix error in anti-stuck
-Improved anti-stuck

v0.7.1.0 - 4/8/2010
-Bugfix anti-stuck
-More accurate player position

v0.7.0 - 4/8/2010
-Added Safe Zone notice
-Code cleanup

v0.6.1 - 4/8/2010
-Bugfix TTL forula
-Bugfix recoversit/safesit conflict

v0.6 - 4/7/2010
-Changed GFBot.ini format
-Added ability to add gambits variable
-Added waypointradius
-Added escapefight
-Fixed cursed heal before safezone

v0.5.1 - 4/6/2010
-Added recoversit (recoversit=HP < 50%)

v0.5 - 4/5/2010
-Target bugfix
-Safe zone always camper mode

v0.4 - 4/4/2010 - Stable

-New improved GUI
-Bug Fixes


v0.3 - 4/4/2010

-Map bug fix
-Added some stats


v0.2 - 4/3/2010

-Improved safepoint processing
-Some bug fixes

v0.1 - 4/2/2010

-Waypoints
-Gambits
-Anti-Stuck
