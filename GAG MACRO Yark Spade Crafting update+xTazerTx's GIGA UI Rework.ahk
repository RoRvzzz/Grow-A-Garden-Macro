;   GAG MACRO Yark Spade Crafting update +xTazerTx's GIGA UI Rework

#SingleInstance, Force
#NoEnv
SetWorkingDir %A_ScriptDir%
#WinActivateForce
SetMouseDelay, -1 
SetWinDelay, -1
SetControlDelay, -1
SetBatchLines, -1   

; globals

global webhookURL
global privateServerLink
global discordUserID
global PingSelected
global reconnectingProcess
global AutoHoney

global windowIDS := []
global currentWindow := ""
global firstWindow := ""
global instanceNumber
global idDisplay := ""
global started := 0

global cycleCount := 0
global cycleFinished := 0
global toolTipText := ""

global currentItem := ""
global currentArray := ""
global currentSelectedArray := ""
global indexItem := ""
global indexArray := []

global currentHour
global currentMinute
global currentSecond

global midX
global midY

global msgBoxCooldown := 0

global gearAutoActive := 0
global seedAutoActive := 0
global eggAutoActive  := 0
global honeyAutoActive := 0
global autoHoneyActive := 0
global seedCraftingAutoActive := 0
global bearCraftingAutoActive := 0
global cosmeticAutoActive := 0
global lastHoneyHour := -1
global lastHoneyShopMinute := -1

global bearCraftingLocked := 0
global seedCraftingLocked := 0

global honeyShopFailed := false

global actionQueue := []

settingsFile := A_ScriptDir "\settings.ini"
mainDir := A_ScriptDir . "\Images\"
subTabHoneyPath := mainDir . "rbx background honey tab.PNG"
subTabSeedPath  := mainDir . "background seedcaft subtab.PNG"
subTabBearPath  := mainDir . "background bearcraft subtab.PNG"
debugBoxPngPath := mainDir . "debugbox.png"

honeyItems := ["A", "B", "C"]
seedCraftingItems := ["X", "Y"]
bearCraftingItems := ["L", "M"]


HideAllCheckboxSets() {
    global honeyItems, seedCraftingItems, bearCraftingItems


    GuiControl, Hide, AutoHoney
    GuiControl, Hide, SelectAllHoney

    Loop, % honeyItems.Length()
        GuiControl, Hide, % "HoneyItem" A_Index

    Loop, % seedCraftingItems.Length()
        GuiControl, Hide, % "SeedCraftingItem" A_Index
            GuiControl, Hide, SeedCraftLockLabel
        GuiControl, Hide, ManualSeedCraftLock

    Loop, % bearCraftingItems.Length()
        GuiControl, Hide, % "BearCraftingItem" A_Index
        GuiControl, Hide, BearCraftLockLabel
        GuiControl, Hide, ManualBearCraftLock

}






global currentShop := ""

global selectedResolution

global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
scrollCounts_1080p :=       [2, 4, 6, 8, 9, 11, 13, 14, 16, 18, 20, 21, 23, 25, 26, 28, 29, 31]
scrollCounts_1440p_100 :=   [3, 5, 8, 10, 13, 15, 17, 20, 22, 24, 27, 30, 31, 34, 36, 38, 40, 42]
scrollCounts_1440p_125 :=   [3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 25, 27, 29, 30, 31, 32]

global gearScroll_1080p, toolScroll_1440p_100, toolScroll_1440p_125
gearScroll_1080p     := [1, 2, 4, 6, 8, 9, 11, 13]
gearScroll_1440p_100 := [2, 3, 6, 8, 10, 13, 15, 17]
gearScroll_1440p_125 := [1, 3, 4, 6, 8, 9, 12, 12]

; http functions

SendDiscordMessage(webhookURL, message) {

    FormatTime, messageTime, , hh:mm:ss tt
    fullMessage := "[" . messageTime . "] " . message

    json := "{""content"": """ . fullMessage . """}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

    try {
        whr.Open("POST", webhookURL, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(json)
        whr.WaitForResponse()
        status := whr.Status

        if (status != 200 && status != 204) {
            return
        }
    } catch {
        return
    }

}

checkValidity(url, msg := 0, mode := "nil") {

    global webhookURL
    global privateServerLink
    global settingsFile

    isValid := 0

    if (mode = "webhook" && (url = "" || !(InStr(url, "discord.com/api") || InStr(url, "discordapp.com/api")))) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Webhook
            IniRead, savedWebhook, %settingsFile%, Main, UserWebhook,
            GuiControl,, webhookURL, %savedWebhook%
        }
        return false
    }

    if (mode = "privateserver" && (url = "" || !InStr(url, "roblox.com/share"))) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Private Server Link
            IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink,
            GuiControl,, privateServerLink, %savedServerLink%
        }
        return false
    }

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        whr.WaitForResponse()
        status := whr.Status

        if (mode = "webhook" && (status = 200 || status = 204)) {
            isValid := 1
        } else if (mode = "privateserver" && (status >= 200 && status < 400)) {
            isValid := 1
        }
    } catch {
        isValid := 0
    }

    if (msg) {
        if (mode = "webhook") {
            if (isValid && webhookURL != "") {
                IniWrite, %webhookURL%, %settingsFile%, Main, UserWebhook
                MsgBox, 0, Message, Webhook Saved Successfully
            }
            else if (!isValid && webhookURL != "") {
                MsgBox, 0, Message, Invalid Webhook
                IniRead, savedWebhook, %settingsFile%, Main, UserWebhook,
                GuiControl,, webhookURL, %savedWebhook%
            }
        } else if (mode = "privateserver") {
            if (isValid && privateServerLink != "") {
                IniWrite, %privateServerLink%, %settingsFile%, Main, PrivateServerLink
                MsgBox, 0, Message, Private Server Link Saved Successfully
            }
            else if (!isValid && privateServerLink != "") {
                MsgBox, 0, Message, Invalid Private Server Link
                IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink,
                GuiControl,, privateServerLink, %savedServerLink%
            }
        }
    }

    return isValid

}


showPopupMessage(msgText := "nil", duration := 2000) {

    static popupID := 99

    ; get main GUI position and size
    WinGetPos, guiX, guiY, guiW, guiH, A

    innerX := 20
    innerY := 35
    innerW := 200
    innerH := 50
    winW := 200
    winH := 50
    x := guiX + (guiW - winW) // 2 - 40
    y := guiY + (guiH - winH) // 2

    if (!msgBoxCooldown) {
        msgBoxCooldown = 1
        Gui, %popupID%:Destroy
        Gui, %popupID%:+AlwaysOnTop -Caption +ToolWindow +Border
        Gui, %popupID%:Color, FFFFFF
        Gui, %popupID%:Font, s10 cBlack, Segoe UI
        Gui, %popupID%:Add, Text, x%innerX% y%innerY% w%innerW% h%innerH% BackgroundWhite Center cBlack, %msgText%
        Gui, %popupID%:Show, x%x% y%y% NoActivate
        SetTimer, HidePopupMessage, -%duration%
        Sleep, 2200
        msgBoxCooldown = 0
    }

}

DonateResponder(ctrlName) {

    MsgBox, 1, Disclaimer, 
    (
    Your browser will open with a link to a roblox gamepass once you press OK.
    - Feel free to check the code, there are no malicious links.
    )

    IfMsgBox, OK
        if (ctrlName = "Donate100")
            Run, https://www.roblox.com/game-pass/1197306369/100-Donation
        else if (ctrlName = "Donate500")
            Run, https://www.roblox.com/game-pass/1222540123/500-Donation
        else if (ctrlName = "Donate1000")
            Run, https://www.roblox.com/game-pass/1222262383/1000-Donation
        else if (ctrlName = "Donate2500")
            Run, https://www.roblox.com/game-pass/1222306189/2500-Donation
        else if (ctrlName = "Donate10000")
            Run, https://www.roblox.com/game-pass/1220930414/10-000-Donation
        else
            return

}

; mouse functions

SafeMoveRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        moveX := winX + Round(xRatio * winW)
        moveY := winY + Round(yRatio * winH)
        MouseMove, %moveX%, %moveY%
    }

}

SafeClickRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        clickX := winX + Round(xRatio * winW)
        clickY := winY + Round(yRatio * winH)
        Click, %clickX%, %clickY%
    }

}

getMouseCoord(axis) {

    WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY

        relX := (mouseX - winX) / winW
        relY := (mouseY - winY) / winH

        if (axis = "x")
            return relX
        else if (axis = "y")
            return relY

    return ""  ; error

}

; directional sequence encoder/executor
; if you're going to modify the calls to this make sure you know what you're doing (ui navigation has some odd behaviours)

uiUniversal(order := 0, exitUi := 1, continuous := 0, spam := 0, spamCount := 30, delayTime := 50, mode := "universal", index := 0, dir := "nil", itemType := "nil") {

    global SavedSpeed
    global SavedKeybind
    global UINavigationFix

    global indexItem
    global currentArray

    If (!order && mode = "universal") {
        return
    }

    if (!continuous) {
        sendKeybind(SavedKeybind)
        Sleep, 50
        if (UINavigationFix) {
            repeatKey("Up", 5, 50)
            Sleep, 50
            repeatKey("Left", 3, 50)
            Sleep, 50
            repeatKey("up", 5, 50)
            Sleep, 50
            repeatKey("Left", 3, 50)
            Sleep, 50
        }   
    }  

    ; right = 1, left = 2, up = 3, down = 4, enter = 0, manual delay = 5
    if (mode = "universal") {

        Loop, Parse, order 
        {
            if (A_LoopField = "1") {
                repeatKey("Right", 1)
            }
            else if (A_LoopField = "2") {
                repeatKey("Left", 1)
            }
            else if (A_LoopField = "3") {
                repeatKey("Up", 1)
            }        
            else if (A_LoopField = "4") {
                repeatKey("Down", 1)
            }  
            else if (A_LoopField = "0") {
                repeatKey("Enter", spam ? spamCount : 1, spam ? 10 : 0)
            }       
            else if (A_LoopField = "5") {
                Sleep, 100
            } 
            if (SavedSpeed = "Stable" && A_LoopField != "5") {
                Sleep, %delayTime%
            }
        }

    }
    else if (mode = "calculate") {

        previousIndex := findIndex(currentArray, indexItem)
        sendCount := index - previousIndex

        FileAppend, % "index: " . index . "`n", debug.txt
        FileAppend, % "previusIndex: " . previousIndex . "`n", debug.txt
        FileAppend, % "currentarray: " . currentArray.Name . "`n", debug.txt

        if (dir = "up") {
            repeatKey(dir)
            repeatKey("Enter")
            repeatKey(dir, sendCount)
        }
        else if (dir = "down") {
            FileAppend, % "sendCount: " . sendCount . "`n", debug.txt
            repeatKey(dir, sendCount)
            repeatKey("Enter")
            repeatKey(dir)
            if ((currentArray.Name = "gearItems") && (index != 2) && (UINavigationFix)) {
                repeatKey("Left")
                }
            else if ((currentArray.Name = "seedItems") && (UINavigationFix)) {
                repeatKey("Left")
            }
        }

    }
    else if (mode = "close") {

        if (dir = "up") {
            repeatKey(dir)
            repeatKey("Enter")
            repeatKey(dir, index)
        }
        else if (dir = "down") {
            repeatKey(dir, index)
            repeatKey("Enter")
            repeatKey(dir)
        }

    }

    if (exitUi) {
        Sleep, 50
        sendKeybind(SavedKeybind)
    }

    return

}

; universal shop buyer

buyUniversal(itemType) {

    global currentArray
    global currentSelectedArray
    global indexItem := ""
    global indexArray := []
    global UINavigationFix

    indexArray := []
    lastIndex := 0
    
    ; name array
    arrayName := itemType . "Items"
    currentArray := %arrayName%
    currentArray.Name := arrayName

    ; get arrays
    StringUpper, itemType, itemType, T

    selectedArrayName := "selected" . itemtype . "Items"
    currentSelectedArray := %selectedArrayName%

    ; get item indexes
    for i, selectedItem in currentSelectedArray {
        indexArray.Push(findIndex(currentArray, selectedItem))
    }

    ; buy items
    for i, index in indexArray {
        currentItem := currentSelectedArray[i]
        Sleep, 50
        uiUniversal(, 0, 1, , , , "calculate", index, "down", itemType)
        indexItem := currentSelectedArray[i]
        sleepAmount(100, 200)
        quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8508)
        Sleep, 50
        lastIndex := index - 1
    }

    ; end
    Sleep, 100
    uiUniversal(, 0, 1,,,, "close", lastIndex, "up", itemType)
    Sleep, 100

}

; helper functions

repeatKey(key := "nil", count := 1, delay := 30) {

    global SavedSpeed

    if (key = "nil") {
        return
    }

    Loop, %count% {
        Send {%key%}
        Sleep, % (SavedSpeed = "Ultra" ? (delay - 25) : SavedSpeed = "Max" ? (delay - 30) : delay)
    }

}

sendKeybind(keybind) {

    if (keybind = "\") {
        Send, \
    }
    else {
        Send, {%keybind%}
    }

}

sleepAmount(fastTime, slowTime) {

    global SavedSpeed

    Sleep, % (SavedSpeed != "Stable") ? fastTime : slowTime

}

findIndex(array := "", value := "", returnValue := "int") {
    
    FileAppend, % "Searching " . array.Name . " for " . value . "`n", debug.txt

    for index, item in array {
        if (value = item) {
            FileAppend, % "found " . value . " at index " . index "`n", debug.txt
            if (returnValue = "int") {
                return index
            }
            else if (returnValue = "bool") {
                return true
            }
        }
    }

    if (returnValue = "int") {
        return 1
    }
    else if (returnValue = "bool") {
        return false
    }

}

searchItem(search := "nil") {

    global UINavigationFix

    if(search = "nil") {
        Return
    }
    
    ;with UINavigationFix
    if (UINavigationFix) {
        uiUniversal("150524150505305", 0) 
        typeString(search)
        Sleep, 50

        if (search = "recall") {
            uiUniversal("4335505541555055", 1, 1)
        }

        uiUniversal(10)
    }
    else { ;without UINavigationFix
        uiUniversal("1011143333333333333333333311440", 0)
        Sleep, 50      
        typeString(search)
        Sleep, 50

        if (search = "recall") {
            uiUniversal("2211550554155055", 1, 1)
        }

        uiUniversal(10)
    }

}

typeString(string, enter := 1, clean := 1) {

    if (string = "") {
        Return
    }

    if (clean) {
        Send {BackSpace 20}
        Sleep, 100
    }

    Loop, Parse, string
    {
        Send, {%A_LoopField%}
        Sleep, 100
    }

    if (enter) {
        Send, {Enter}
    }

    Return

}

dialogueClick(shop) {

    Loop, 10 {
        Send, {WheelUp}
        Sleep, 20
    }

    sleepAmount(500, 1500)

    Loop, 1 {
        Send, {WheelDown}
        Sleep, 20
    }

    sleepAmount(500, 1500)

    if (shop = "gear") {
        SafeClickRelative(midX + 0.4, midY - 0.1)
    }

    Sleep, 500

    SafeMoveRelative(midX, midY)

}

hotbarController(select := 0, unselect := 0, key := "nil") {

    if ((select = 1 && unselect = 1) || (select = 0 && unselect = 0) || key = "nil") {
        Return
    }

    if (unselect) {
        Send, {%key%}
        Sleep, 200
        Send, {%key%}
    }
    else if (select) {
        Send, {%key%}
    }

}

closeRobuxPrompt() {

    Loop, 4 {
        Send {Escape}
        Sleep, 100
    }

}

getWindowIDS(returnIndex := 0) {

    global windowIDS
    global idDisplay
    global firstWindow

    windowIDS := []
    idDisplay := ""
    firstWindow := ""

    WinGet, robloxWindows, List, ahk_exe RobloxPlayerBeta.exe

    Loop, %robloxWindows% {
        windowIDS.Push(robloxWindows%A_Index%)
        idDisplay .= windowIDS[A_Index] . ", "
    }

    firstWindow := % windowIDS[1]

    StringTrimRight, idDisplay, idDisplay, 2

    if (returnIndex) {
        Return windowIDS[returnIndex]
    }
    
}

closeShop(shop, success) {

    StringUpper, shop, shop, T

    if (success) {

        Sleep, 500
        uiUniversal("4330320", 1, 1)

    }
    else {

        ToolTip, % "Error In Detecting " . shop
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Failed To Detect " . shop . " Shop Opening [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
        ; failsafe
        uiUniversal("3332223111133322231111054105")

    }

}

walkDistance(order := 0, multiplier := 1) {

    ; later

}

sendMessages() {

    ; later

}

; color detectors

quickDetectEgg(buyColor, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    global UINavigationFix
    global selectedEggItems
    global currentItem

    eggsCompleted := 0
    isSelected := 0

    eggColorMap := Object()
    eggColorMap["Common Egg"]    := "0xFFFFFF"
    eggColorMap["Uncommon Egg"]  := "0x81A7D3"
    eggColorMap["Rare Egg"]      := "0xBB5421"
    eggColorMap["Legendary Egg"] := "0x2D78A3"
    eggColorMap["Mythical Egg"]  := "0x00CCFF"
    eggColorMap["Bug Egg"]       := "0x86FFD5"

    Loop, 5 {
        for rarity, color in eggColorMap {
            currentItem := rarity
            isSelected := 0

            for i, selected in selectedEggItems {
                if (selected = rarity) {
                    isSelected := 1
                    break
                }
            }

            ; check for the egg on screen, if its selected it gets bought
            if (simpleDetect(color, variation, 0.41, 0.32, 0.54, 0.38)) {
                if (isSelected) {
                    quickDetect(buyColor, 0, 5, 0.4, 0.60, 0.65, 0.70, 0, 1)
                    eggsCompleted = 1
                    break
                } else {
                    if (simpleDetect(buyColor, variation, 0.40, 0.60, 0.65, 0.70)) {
                        ToolTip, % currentItem . "`nIn Stock, Not Selected"
                        SetTimer, HideTooltip, -1500
                        SendDiscordMessage(webhookURL, currentItem . " In Stock, Not Selected")
                    }
                    else {
                        ToolTip, % currentItem . "`nNot In Stock, Not Selected"
                        SetTimer, HideTooltip, -1500
                        SendDiscordMessage(webhookURL, currentItem . " Not In Stock, Not Selected")
                    }
                    if (UINavigationFix) {
                        uiUniversal(3140, 1, 1)
                    }
                    else {
                        uiUniversal(1105, 1, 1)
                    }
                    eggsCompleted = 1
                    break
                }
            }    
        }
        ; failsafe
        if (eggsCompleted) {
            return
        }
        Sleep, 1500
    }
    
    if (!eggsCompleted) {
        uiUniversal(5, 1, 1)
        ToolTip, Error In Detection
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Failed To Detect Any Egg [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
    }

}

simpleDetect(colorInBGR, variation, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    DrawDebugBox(x1, y1, x2, y2)

    PixelSearch, FoundX, FoundY, x1, y1, x2, y2, colorInBGR, variation, Fast
    if (ErrorLevel = 0) {
        return true
    }

}

quickDetect(color1, color2, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0, item := 1, egg := 0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    stock := 0
    eggDetected := 0

    global currentItem
    global UINavigationFix
    
    ; change to whatever you want to be pinged for
    pingItems := []

	ping := false

    if (PingSelected) {
        for i, pingitem in pingItems {
            if (pingitem = currentItem) {
                ping := true
                break
            }
        }
    }

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    ; for seeds/gears checks if either color is there (buy button)
    if (item) {
        for index, color in [color1, color2] {
            PixelSearch, FoundX, FoundY, x1, y1, x2, y2, %color%, variation, Fast RGB
            if (ErrorLevel = 0) {
                stock := 1
                ToolTip, %currentItem% `nIn Stock
                SetTimer, HideTooltip, -1500  
                uiUniversal(50, 0, 1, 1)
                Sleep, 50
                if (ping)
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
                else
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
            }
        }
    }

    ; for eggs
    if (egg) {
        PixelSearch, FoundX, FoundY, x1, y1, x2, y2, color1, variation, Fast RGB
        if (ErrorLevel = 0) {
            stock := 1
            ToolTip, %currentItem% `nIn Stock
            SetTimer, HideTooltip, -1500  
            uiUniversal(500, 1, 1)
            Sleep, 50
            if (ping)
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
            else
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
        }
        if (!stock) {
            if (UINavigationFix) {
                uiUniversal(3140, 1, 1)
            }
            else {
                uiUniversal(1105, 1, 1)
            }
            SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
        }
    }

    Sleep, 100

    if (!stock) {
        ToolTip, %currentItem% `nNot In Stock
        SetTimer, HideTooltip, -1500
        ; SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
    }

}

; item arrays

seedItems := ["Carrot Seed", "Strawberry Seed", "Blueberry Seed", "Orange Tulip"
             , "Tomato Seed", "Corn Seed", "Daffodil Seed", "Watermelon Seed"
             , "Pumpkin Seed", "Apple Seed", "Bamboo Seed", "Coconut Seed"
             , "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed"
             , "Mushroom Seed", "Pepper Seed", "Cacao Seed", "Beanstalk Seed", "Ember Lily Seed", "Sugar Apple Seed"] ;

gearItems := ["Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler"
             , "Godly Sprinkler", "Lightning Rod", "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot"]

eggItems := ["Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg"
             , "Bug Egg"]

cosmeticItems := ["Cosmetic 1", "Cosmetic 2", "Cosmetic 3", "Cosmetic 4", "Cosmetic 5"
             , "Cosmetic 6",  "Cosmetic 7", "Cosmetic 8", "Cosmetic 9"]

honeyItems := ["Flower Seed Pack", "Lavender Seed", "Nectarshade Seed", "Nectarine Seed", "Hive Fruit Seed"
	   , "Pollen Radar", "Nectar Staff", "Honey Sprinkler", "Bee Egg", "Bee Crate", "Honey Comb"
             , "Bee Chair", "Honey Torch", "Honey Walkway"]

bearCraftingItems := ["Tropical Mist Sprinkler", "Berry Blusher Sprinkler", "Spice Spritzer Sprinkler", "Sweet Soaker Sprinkler"
	  , "Flower Froster Sprinkler", "Stalk Sprout Sprinkler", "Mutation Spray Choc", "Mutation Spray Pollinated", "Mutation Spray Shocked"
	  , "Honey Crafters Crate", "Anti Bee Egg", "Pack Bee"]

seedCraftingItems := ["Crafters Seed Pack", "Manuka Flower", "Dandelion", "Lumira", "Honeysuckle", "Bee Balm", "Nectar Thorn", "Suncoil"]
	

settingsFile := A_ScriptDir "\settings.ini"

Gosub, ShowGui
Return

; main ui

ShowGui:
    Gui, Destroy
    Gui, -MinimizeBox -Caption
    Gui, Color, 0x202020  ; Needed for transparency to work properly
    WinSet, TransColor, 0x202020  ; Make black fully transparent
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx window background .PNG"
    
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background minimize button.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background close button.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background settings rbx macro Tabsfixed.PNG" 

    Gui, Add, Text, x496 y0 w24 h24 BackgroundTrans gCloseApp
    Gui, Add, Text, x0 y0 w24 h24 BackgroundTrans gMinimizeApp
    Gui, Add, Text, x0 y0 w472 h15 BackgroundTrans gDragWindow







    Gui, Font, s9 cWhite, Segoe UI
    Gui, Add, Tab , x0 y24 w540 h24 vMyTab,`n    Seeds    |    Gears    |    Eggs    |   Cosmetics   |    Honey    |     Settings     |   Credits`n    |
    guicontrol, choose, mytab, 6

    Gui, Tab, 1
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx background Seed tab.PNG"
    IniRead, SelectAllSeeds, %settingsFile%, Seed, SelectAllSeeds, 0
    Gui, Add, CheckBox, % "x391 y135 w12 h12 vSelectAllSeeds gHandleSelectAll -Theme Background3C3C3C " . (SelectAllSeeds ? "Checked" : "")
    

    Loop, % seedItems.Length() {
        IniRead, sVal, %settingsFile%, Seed, Item%A_Index%, 0
        if (A_Index > 18) {
            col := 373
            idx := A_Index - 19
            yBase := 183
        }
        else if (A_Index > 9) {
            col := 198
            idx := A_Index - 10
            yBase := 183
        
        }
        else {
            col := 23
            idx := A_Index
            yBase := 158
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " w12 h12 vSeedItem" A_Index " gHandleSelectAll cD3D3D3 " . (sVal ? "Checked" : ""), 

    }

    Gui, Tab, 2
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx background Gears tab.PNG"

    IniRead, SelectAllGears, %settingsFile%, Gear, SelectAllGears, 0
    Gui, Add, Checkbox, % "x391 y135 w12 h12 vSelectAllGears gHandleSelectAll c87CEEB " . (SelectAllGears ? "Checked" : ""), Select All Gears 


    Loop, % gearItems.Length() {
        IniRead, gVal, %settingsFile%, Gear, Item%A_Index%, 0
        if (A_Index > 8) {
            col := 373
            idx := A_Index - 9
            yBase := 192
        }
        else if (A_Index > 3) {
            col := 200
            idx := A_Index - 4
            yBase := 192
        
        }
        else {
            col := 28
            idx := A_Index
            yBase := 160
        }
        y := yBase + (idx * 31)
        Gui, Add, Checkbox, % "x" col " y" y " w12 h12 vGearItem" A_Index " gHandleSelectAll cD3D3D3 " . (gVal ? "Checked" : ""), 

    }

    Gui, Tab, 3
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx background egg tab.PNG"
    IniRead, SelectAllEggs, %settingsFile%, Egg, SelectAllEggs, 0
    Gui, Add, CheckBox, % "x391 y135 w12 h12 vSelectAllEggs gHandleSelectAll -Theme BackgroundTrans ce87b07 " . (SelectAllEggs ? "Checked" : "")

    Loop, % eggItems.Length() {
        IniRead, eVal, %settingsFile%, Egg, Item%A_Index%, 0
        if (A_Index > 4) {
            col := 375
            idx := A_Index - 5
            yBase := 265
        }
        else if (A_Index > 2) {
            col := 205
            idx := A_Index - 3
            yBase := 265
        
        }
        else {
            col := 23
            idx := A_Index
            yBase := 155
        }
        y := yBase + (idx * 109)
        Gui, Add, Checkbox, % "x" col " y" y " w12 h12 vEggItem" A_Index " gHandleSelectAll cD3D3D3 " . (eVal ? "Checked" : ""), % eggItems[A_Index]


    }

    Gui, Tab, 4
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx background CosmeticShop.PNG"
    IniRead, BuyAllCosmetics, %settingsFile%, Cosmetic, BuyAllCosmetics, 0
    Gui, Add, CheckBox, % "x61 y118 w12 h12 vBuyAllCosmetics gHandleSelectAll -Theme BackgroundTrans cD41551 " . (BuyAllCosmetics ? "Checked" : "")


    

    Gui, Tab, 5
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background honeytabmashup.PNG"
; ----- GUI Layout -----

Gui, Add, Picture, x0 y0 w520 h425 vSubTabImage BackgroundTrans, % subTabHoneyPath

;Gui, Add, Picture, x0 y0 w520 h425 vSubTabImage BackgroundTrans, % subTabHoneyPath


; Text "buttons" to switch tabs - must contain text to be clickable
Gui, Add, Text, x12  y80 w120 h40 gShowHoneySubTab BackgroundTrans,
Gui, Add, Text, x152 y80 w120 h40 gShowSeedSubTab  BackgroundTrans,
Gui, Add, Text, x293 y80 w120 h40 gShowBearSubTab  BackgroundTrans,
;just saving stuff dont ask    color 32CD32                             background seedcaft subtab.PNG          background bearcraft subtab.PNG
;Gui, Add, Text, x152 y80 w120 h40 gShowSeedSubTab  BackgroundTrans,seed  
;Gui, Add, Text, x293 y80 w120 h40 gShowBearSubTab  BackgroundTrans,bear

; ----- Honey Set -----
IniRead, AutoHoneySetting, %settingsFile%, AutoHoney, AutoHoneySetting, 0
Gui, Add, CheckBox, % "x119 y135 w12 h12 vAutoHoney gSaveAutoHoney BackgroundTrans c00FF00 " . (AutoHoneySetting ? "Checked" : "")

IniRead, SelectAllHoney, %settingsFile%, Honey, SelectAll, 0
Gui, Add, CheckBox, % "x391 y135 w12 h12 vSelectAllHoney gHandleSelectAll BackgroundTrans cFFD700 " . (SelectAllHoney ? "Checked" : "")

Loop, % honeyItems.Length() {
    IniRead, hVal, %settingsFile%, Honey, Item%A_Index%, 0
    if (A_Index > 9) {
        col := 369, idx := A_Index - 10, yBase := 193
    } else if (A_Index > 7) {
        col := 194, idx := A_Index - 8, yBase := 193
    } else {
        col := 20, idx := A_Index, yBase := 163
    }
    y := yBase + (idx * 30)
    Gui, Add, Checkbox, % "x" col " y" y " w12 h12 vHoneyItem" A_Index " gHandleSelectAll cWhite BackgroundTrans " . (hVal ? "Checked" : "")
}

; ----- SeedCrafting Set -----
Loop, % seedCraftingItems.Length() {
    IniRead, sVal, %settingsFile%, SeedCrafting, Item%A_Index%, 0
    if (A_Index > 6) {
        col := 374, idx := A_Index - 7, yBase := 213
    } else if (A_Index > 3) {
        col := 199, idx := A_Index - 4, yBase := 213
    } else {
        col := 25, idx := A_Index, yBase := 143
    }
    y := yBase + (idx * 70)
    Gui, Add, Checkbox, % "x" col " y" y " w12 h12 vSeedCraftingItem" A_Index " gHandleSelectAll cWhite BackgroundTrans " . (sVal ? "Checked" : ""), % seedCraftingItems[A_Index]
}

; === Seed Craft Lock ===
IniRead, ManualSeedCraftLock, %settingsFile%, Main, ManualSeedCraftLock, 0
Gui, Add, Edit, x369 y132 w36 h18 vManualSeedCraftLock gUpdateCraftLock -Theme cBlack, %ManualSeedCraftLock%

; ----- BearCrafting Set -----
Loop, % bearCraftingItems.Length() {
    IniRead, bVal, %settingsFile%, BearCrafting, Item%A_Index%, 0
    if (A_Index > 8) {
        col := 374, idx := A_Index - 9, yBase := 183
    } else if (A_Index > 4) {
        col := 199, idx := A_Index - 5, yBase := 183
    } else {
        col := 25, idx := A_Index, yBase := 133
    }
    y := yBase + (idx * 50)
    Gui, Add, Checkbox, % "x" col " y" y " w13 h13 vBearCraftingItem" A_Index " gHandleSelectAll cWhite BackgroundTrans " . (bVal ? "Checked" : ""), % bearCraftingItems[A_Index]
}
; === Bear Craft Lock ===
IniRead, ManualBearCraftLock, %settingsFile%, Main, ManualBearCraftLock, 0
Gui, Add, Edit, x369 y132 w36 h18 vManualBearCraftLock gUpdateCraftLock -Theme cBlack, %ManualBearCraftLock%


   
    
    Gui, Tab, 6
    
    ; Invisible hotspots (replacing buttons)
    Gui, Add, Text, x390 y86  w100 h16 gDisplayWebhookValidity BackgroundTrans 0x4
    Gui, Add, Text, x390 y111 w100 h16 gUpdateUserID          BackgroundTrans 0x4
    Gui, Add, Text, x390 y135 w100 h16 gDisplayServerValidity BackgroundTrans 0x4
    Gui, Add, Text, x217 y164 w85  h18 gClearSaves            BackgroundTrans 0x4
    Gui, Add, Text, x15  y370 w105 h40 gStartScanMultiInstance BackgroundTrans 0x4
    Gui, Add, Text, x405 y370 w105 h40 gQuit                  BackgroundTrans 0x4
    Gui, Add, Text, x240 y385 w40  h25 gGui2                  BackgroundTrans 0x4
    Gui, Add, Text, x414 y251 w84  h20 gGui4                  BackgroundTrans 0x4
    Gui, Add, Text, x414 y218 w84  h20 gGui5                  BackgroundTrans 0x4

    
  
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab backgroundfixed.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background settings rbx button help.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background settings rbx button start.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "background settings rbx button stop.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab Save Webhook button.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab clear save button.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab Save PS Link button.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab Save User ID button.PNG"
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab Eggs button1.PNG"
    Gui, Add, Picture, x0 y-3 w520 h425 BackgroundTrans, % mainDir "rbx macro setting  tab Pets button.PNG" 


    ; opt1 := (selectedResolution = 1 ? "Checked" : "")
    ; opt2 := (selectedResolution = 2 ? "Checked" : "")
    ; opt3 := (selectedResolution = 3 ? "Checked" : "")
    ; opt4 := (selectedResolution = 4 ? "Checked" : "")
    
    ;Gui, Add, GroupBox, x30 y200 w260 h110, Resolution
    ; Gui, Add, Text, x35 y220, Resolutions:
    ; IniRead, selectedResolution, %settingsFile%, Main, Resolution, 1
    ; Gui, Add, Radio, x35 y240 vselectedResolution gUpdateResolution c708090 %opt1%, 2560x1440 125`%
    ; Gui, Add, Radio, x35 y260 gUpdateResolution c708090 %opt2%, 2560x1440 100`%
    ; Gui, Add, Radio, x35 y280 gUpdateResolution c708090 %opt3%, 1920x1080 100`%
    ; Gui, Add, Radio, x35 y300 gUpdateResolution c708090 %opt4%, 1280x720 100`%







        IniRead, PingSelected, %settingsFile%, Main, PingSelected, 0
    pingColor := PingSelected ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x140 y246 w12 h12 vPingSelected gUpdateSettingColor " . pingColor . (PingSelected ? " Checked" : ""), Discord Item Pings
    
    IniRead, AutoAlign, %settingsFile%, Main, AutoAlign, 0
    autoColor := AutoAlign ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x105 y272 w12 h12 vAutoAlign gUpdateSettingColor " . autoColor . (AutoAlign ? " Checked" : ""), Auto-Align


    IniRead, MultiInstanceMode, %settingsFile%, Main, MultiInstanceMode, 0
    multiInstanceColor := MultiInstanceMode ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x160 y299 w12 h12 vMultiInstanceMode gUpdateSettingColor " . multiInstanceColor . (MultiInstanceMode ? " Checked" : ""), Multi-Instance Mode

    IniRead, UINavigationFix, %settingsFile%, Main, UINavigationFix, 0
    uiNavigationFixColor := UINavigationFix ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x140 y324 w12 h12 vUINavigationFix gUpdateSettingColor " . uiNavigationFixColor . (UINavigationFix ? " Checked" : ""), UI Navigation Fix


    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedWebhook, %settingsFile%, Main, UserWebhook
    if (savedWebhook = "ERROR") {
        savedWebhook := ""
    }
    Gui, Add, Edit, x125 y87 w255 h15 vwebhookURL hwndhWebhookURL +E0x200 +E0x800 -Theme cBlack, %savedWebhook%


    ;WinSet, Transparent, 1, ahk_id %hWebhookURL%


    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID
    if (savedUserID = "ERROR") {
        savedUserID := ""
    }
    
    Gui, Add, Edit, x135 y111 w245 h15 vdiscordUserID +E0x200 +E0x800 -Theme cBlack Background2C2F33, %savedUserID%


    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID


    IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink
    if (savedServerLink = "ERROR") {
        savedServerLink := ""
    }
    Gui, Add, Edit, x125 y136 w255 h15 vprivateServerLink -Theme cBlack BackgroundFFFFFF, %savedServerLink%

    
    IniRead, SavedKeybind, %settingsFile%, Main, UINavigationKeybind, \
    if (SavedKeybind = "") {
        SavedKeybind := "\"
    }
    Gui, Add, Edit, x169 y220 w20 h16 vSavedKeybind gUpdateKeybind -Theme +E0x200 +E0x800 cBlack Background2E2E2E, %savedKeybind%


    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, SavedSpeed, %settingsFile%, Main, MacroSpeed, Stable
    Gui, Add, DropDownList, vSavedSpeed gUpdateSpeed x115 y191 w50 , Stable|Fast|Ultra|Max
    GuiControl, ChooseString, SavedSpeed, %SavedSpeed%
    
    HideAllCheckboxSets()
Gosub, ShowHoneySubTab


    Gui, Tab, 7
    Gui, Add, Picture, x0 y0 w520 h425 BackgroundTrans, % mainDir "rbx macro background credit.png"
    ; Set the font to blue, underlined
    Gui, Font, cBlue underline

    ; Add the text as a clickable link with transparent background
    Gui, Add, Text, x355 y345 w150 BackgroundTrans gOpenLink, GAG MODED MACROS DISCORD `njoin for update and bugreport

    ; Reset the font so other text isn't underlined
    Gui, Font, norm



    Gui, Show, w520 h425, GAG MACRO Yark Spade Crafting update +xTazerTx's GIGA UI Rework

   

Return

OpenLink:
    Run, https://discord.gg/gagmacros  ; <-- replace with your actual link
return


    MinimizeApp:
    Gui, Minimize
    return

    CloseApp:
        ExitApp
    return

    DragWindow:
        PostMessage, 0xA1, 2  ; WM_NCLBUTTONDOWN, HTCAPTION
    return


    
; ----- Tab Switch Labels -----

ShowHoneySubTab:
    HideAllCheckboxSets()
    GuiControl,, SubTabImage, % subTabHoneyPath
    GuiControl, Show, AutoHoney
    GuiControl, Show, SelectAllHoney
    Loop, % honeyItems.Length() {
        GuiControl, Show, % "HoneyItem" A_Index
    }
return



ShowSeedSubTab:
    HideAllCheckboxSets()
    GuiControl,, SubTabImage, % subTabSeedPath
    Loop, % seedCraftingItems.Length() {
        GuiControl, Show, % "SeedCraftingItem" A_Index  
        GuiControl, Show, SeedCraftLockLabel
        GuiControl, Show, ManualSeedCraftLock

    }
return




ShowBearSubTab:
    HideAllCheckboxSets()
    GuiControl,, SubTabImage, % subTabBearPath
    Loop, % bearCraftingItems.Length() {
        GuiControl, Show, % "BearCraftingItem" A_Index
        GuiControl, Show, BearCraftLockLabel
        GuiControl, Show, ManualBearCraftLock

    }
return

    





return

Gui2:
	Gui, 2:Show, x200 y200 w520 h425
		Gui, 2:+Resize +MinimizeBox +SysMenu
		Gui, 2:Margin, 10, 10
		Gui, 2:Color, 0x202020
		Gui, 2:Font, s9 cWhite, Segoe UI
		Gui, 2:Add, Tab, x10 y10 w495 h400 , Help Window|How to set up|Common issues|Manual Alignment|multi instance
	
	Gui, 2: Tab, 1
	Gui, 2: Font, s9 cWhite norm, Segoe UI
	Gui, 2: Add, GroupBox, x20 y50 w475 h350 cD3D3D3,
	Gui, 2: Add, Text, x35 y75 w450 h300,
(
Welcomed  to the help tab

This window is  intended for helpping trouble shoot and setting up the macro without the help of anyone please check the other tabs



First and foremost if its your fist time using the macro and  downloading ahk 1.1 please restart your computer because ahk did not boot properlly

Also extract the  entire file and dont have them spread around it will lead to the macro failing to run properly



Newest known bug and fix:
The shovel bugg where your navigation key start on the toolbar and the fix for that is just rejoining till you dont have it

)
	
		Gui, 2: Tab, 2
		Gui, 2: Font, s9 cWhite norm, Segoe UI
		Gui, 2: Add, GroupBox, x23 y50 w475 h350 cD3D3D3,
		
		Gui, 2: Add, Text, x35 y75 w450 h300,

		(
This is what you should do to run the macro


In roblox setting disable shiftlock, put the camera mode in default and enable ui navigation

Turn on auto-align

Disable fastmode

Input your navigation key and forward movement key in the macro settings
Place the recall wrench is you 2nd toolbar slot and fill the rest of the slot with anything else

Do not start the macro with ui navigation on



And start the macro with f5 and stop it with f7 (fn+f5 and fn+f7 for small keyboard)
Also you can force shutdown the macro with Rshift.
)
		Gui, 2: Tab, 3
		Gui, 2: Font, s9 cWhite norm, Segoe UI
		Gui, 2:Add, GroupBox, x23 y50 w475 h350 cD3D3D3,
		
		Gui, 2:Add, Text, x35 y75 w450 h300,
(
The macro isnt clicking where it should  to open the shops? 

Make sure to run the macro in 1920x1080 100 or 2560x1440 150 or any 16:9 resolustion
Also disable hdr or any  colour altering display settings 

Rhe macro is missing the eggs ?

Remove or pet grey mouse or any movement speed pets


)
		Gui, 2: Tab, 4
		Gui, 2: Font, s9 cWhite norm, Segoe UI
		Gui, 2: Add, GroupBox, x23 y50 w475 h350 cD6D6D6, !!! do not do this if you use auto-align!!!
		
		Gui, 2:Add, Text, x35 y69 w450 h300,
(
You must be in that exact camera position for manual alignment to work and same for the zoom level.

Failling to align correctly will lead to drifting wich will break some of the shops
)
Gui, 2:Add, Picture, x35 y145 w450 h250, % mainDir "camalign.png"

		Gui, 2: Tab, 5
		Gui, 2: Font, s9 cWhite norm, Segoe UI
		Gui, 2: Add, GroupBox, x23 y50 w475 h350 cD6D6D6, 
		
		Gui, 2:Add, Text, x35 y69 w450 h300,
		(
Using multy instance mode is very simple just get yourself multiple roblox window and the macro will do all the works itself.


this can be donr by using bloxstarp or any other means of generating orther roblox instance.


but be carefull depending on wich client you use you might get banned from roblox beacause of the recent modified client ban that roblox implemented.
)
Return

Gui3:
    Gui, 3:Show, x169 y40 w440 h969 
    Gui, 3:+Resize +MinimizeBox +SysMenu 
    Gui, 3:Margin, 10, 10
    Gui, 3:Color, c244f29
    Gui, 3:Add, Text, x100 y98 BackgroundTrans,...........................................................
    Gui, 3:Add, Picture, x-21 y-10 w478 h1001, % mainDir "beequest.png"
    
    

    Gui, 3:Add, Checkbox, cYellow x340 y3 gSwitch, Always on top
Return
Switch:
	if(Always:=!Always)
		Gui,+AlwaysOnTop
	else
		Gui,-AlwaysOnTop
	return
Gui4:
    Gui, 4:Show, x169 y20 w574 h938
    Gui, 4:+Resize +MinimizeBox +SysMenu 
    Gui, 4:Margin, 10, 10
    Gui, 4:Color, c244f29
    Gui, 4:Add, Picture, x-25 y-9 w619 h969, % mainDir "eggs.png"

    Gui, 4:Add, Checkbox, cYellow x480 y3 gSwitch1, Always on top
Return
Switch1:
	if(Always:=!Always)
		Gui,-AlwaysOnTop
	else
		Gui,+AlwaysOnTop
	return


Gui5:
    Gui, 5:Show, x169 y0 w626 h1000
    Gui, 5:+Resize +MinimizeBox +SysMenu 
    Gui, 5:Margin, 10, 10
    Gui, 5:Color, c244f29
    Gui, 5:Add, Picture, x-7 y13 w724 h986, % mainDir "pets.png"

    Gui, 5:Add, Checkbox, cYellow x530 y3 gSwitch2, Always on top
Return
Switch2:
	if(Always:=!Always)
		Gui,+AlwaysOnTop
	else
		Gui,-AlwaysOnTop
	return





Return

; ui handlers

DisplayWebhookValidity:
    
    Gui, Submit, NoHide

    checkValidity(webhookURL, 1, "webhook")

Return

UpdateUserID:

    Gui, Submit, NoHide

    if (discordUserID != "") {
        IniWrite, %discordUserID%, %settingsFile%, Main, DiscordUserID
        MsgBox, 0, Message, Discord UserID Saved
    }

Return

DisplayServerValidity:

    Gui, Submit, NoHide

    checkValidity(privateServerLink, 1, "privateserver")

Return

ClearSaves:

    IniWrite, %A_Space%, %settingsFile%, Main, UserWebhook
    IniWrite, %A_Space%, %settingsFile%, Main, DiscordUserID
    IniWrite, %A_Space%, %settingsFile%, Main, PrivateServerLink

    IniRead, savedWebhook, %settingsFile%, Main, UserWebhook
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID
    IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink

    GuiControl,, webhookURL, %savedWebhook% 
    GuiControl,, discordUserID, %savedUserID% 
    GuiControl,, privateServerLink, %savedServerLink% 

    MsgBox, 0, Message, Webhook, User Id, and Private Server Link Cleared

Return

UpdateKeybind:

    Gui, Submit, NoHide

    if (StrLen(SavedKeybind) > 1) {
        MsgBox, 0, Error, % "Keybind must be a single key, please type a valid keybind."
        SavedKeybind := "\"
        GuiControl,, SavedKeybind, %SavedKeybind%
        Return
    }
    else {
        IniWrite, %SavedKeybind%, %settingsFile%, Main, UINavigationKeybind
    }

    Return

UpdateCraftLock:

    Gui, Submit, NoHide
    IniWrite, %ManualSeedCraftLock%, %settingsFile%, Main, ManualSeedCraftLock
    IniWrite, %ManualBearCraftLock%, %settingsFile%, Main, ManualBearCraftLock
    Return
    
UpdateSpeed:

    Gui, Submit, NoHide

    IniWrite, %SavedSpeed%, %settingsFile%, Main, MacroSpeed
    GuiControl, ChooseString, SavedSpeed, %SavedSpeed%
    if (SavedSpeed = "Fast") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Use with caution (Requires a stable FPS rate)."
    }
    else if (SavedSpeed = "Ultra") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Use at your own risk, high chance of erroring/breaking (Requires a very stable and high FPS rate)."
    }
    else if (SavedSpeed = "Max") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Zero delay on UI Navigation inputs, I wouldn't recommend actually using this it's mostly here for fun."
    }
    else {
        MsgBox, 0, Message, % "Macro speed set to " . SavedSpeed . ". Recommended for lower end devices."
    }

Return

UpdateResolution:

    Gui, Submit, NoHide

    IniWrite, %selectedResolution%, %settingsFile%, Main, Resolution

return

HandleSelectAll:

    Gui, Submit, NoHide

    if (SubStr(A_GuiControl, 1, 9) = "SelectAll") {
        group := SubStr(A_GuiControl, 10)  ; seeds, gears, eggs
        controlVar := A_GuiControl
        Loop {
            item := group . "Item" . A_Index
            if (!IsSet(%item%))
                break
            GuiControl,, %item%, % %controlVar%
        }
    }
    else if (RegExMatch(A_GuiControl, "^(Seed|Gear|Egg)Item\d+$", m)) {
        group := m1  ; seed, gear, egg
        
        assign := (group = "Seed" || group = "Gear" || group = "Egg") ? "SelectAll" . group . "s" : "SelectAll" . group

        if (!%A_GuiControl%)
            GuiControl,, %assign%, 0
    }

    if (A_GuiControl = "SelectAllSeeds") {
        Loop, % seedItems.Length()
            GuiControl,, SeedItem%A_Index%, % SelectAllSeeds
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllEggs") {
        Loop, % eggItems.Length()
            GuiControl,, EggItem%A_Index%, % SelectAllEggs
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllGears") {
        Loop, % gearItems.Length()
            GuiControl,, GearItem%A_Index%, % SelectAllGears
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllHoney") {
        Loop, % honeyItems.Length()
            GuiControl,, GearItem%A_Index%, % SelectAllHoney
            Gosub, SaveSettings
    }

return

UpdateSettingColor:

    Gui, Submit, NoHide

    ; color values
    autoColor := "+c" . (AutoAlign ? "90EE90" : "D3D3D3")
    pingColor := "+c" . (PingSelected ? "90EE90" : "D3D3D3")
    multiInstanceColor := "+c" . (MultiInstanceMode ? "90EE90" : "D3D3D3")
    uiNavigationFixColor := "+c" . (UINavigationFix ? "90EE90" : "D3D3D3")

    ; apply colors
    GuiControl, %autoColor%, AutoAlign
    GuiControl, +Redraw, AutoAlign

    GuiControl, %pingColor%, PingSelected
    GuiControl, +Redraw, PingSelected

    GuiControl, %multiInstanceColor%, MultiInstanceMode
    GuiControl, +Redraw, MultiInstanceMode

    GuiControl, %uiNavigationFixColor%, UINavigationFix
    GuiControl, +Redraw, UINavigationFix
    
return

Donate:

    DonateResponder(A_GuiControl)
    
Return

HideTooltip:

    ToolTip

return

HidePopupMessage:

    Gui, 99:Destroy

Return

GetScrollCountRes(index, mode := "seed") {

    global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
    global gearScroll_1080p, gearScroll_1440p_100, gearScroll_1440p_125

    if (mode = "seed") {
        arr1 := scrollCounts_1080p
        arr2 := scrollCounts_1440p_100
        arr3 := scrollCounts_1440p_125
    } else if (mode = "gear") {
        arr1 := gearScroll_1080p
        arr2 := gearScroll_1440p_100
        arr3 := gearScroll_1440p_125
    }

    arr := (selectedResolution = 1) ? arr1
        : (selectedResolution = 2) ? arr2
        : (selectedResolution = 3) ? arr3
        : []

    loopCount := arr.HasKey(index) ? arr[index] : 0

    return loopCount
}

; item selection

UpdateSelectedItems:

    Gui, Submit, NoHide
    
    selectedSeedItems := []

    Loop, % seedItems.Length() {
        if (SeedItem%A_Index%)
            selectedSeedItems.Push(seedItems[A_Index])
    }

    selectedGearItems := []

    Loop, % gearItems.Length() {
        if (GearItem%A_Index%)
            selectedGearItems.Push(gearItems[A_Index])
    }

    selectedEggItems := []

    Loop, % eggItems.Length() {
        if (eggItem%A_Index%)
            selectedEggItems.Push(eggItems[A_Index])
    }

    selectedHoneyItems := []

    Loop, % honeyItems.Length() {
        if (HoneyItem%A_Index%)
            selectedHoneyItems.Push(honeyItems[A_Index])
    }

    selectedSeedCraftingItems := []

    Loop, % seedCraftingItems.Length() {
        if (SeedCraftingItem%A_Index%)
            selectedSeedCraftingItems.Push(SeedCraftingItems[A_Index])
    }

    selectedBearCraftingItems := []

    Loop, % bearCraftingItems.Length() {
        if (BearCraftingItem%A_Index%)
            selectedBearCraftingItems.Push(BearCraftingItems[A_Index])
    }

Return

GetSelectedItems() {

    result := ""
    if (selectedSeedItems.Length()) {
        result .= "Seed Items:`n"
        for _, name in selectedSeedItems
            result .= "  - " name "`n"
    }
    if (selectedGearItems.Length()) {
        result .= "Gear Items:`n"
        for _, name in selectedGearItems
            result .= "  - " name "`n"
    }
    if (selectedEggItems.Length()) {
        result .= "Egg Items:`n"
        for _, name in selectedEggItems
            result .= "  - " name "`n"
    }

    return result
    
}

DrawDebugBox(x1, y1, x2, y2, debugBoxPngPath := "") {
    Gui, DebugBox:Destroy
    Gui, DebugBox:+AlwaysOnTop +ToolWindow -Caption +LastFound +E0x20 +Owner ; E0x20 = click-through
    WinSet, TransColor, EEAA99, A
    width := x2 - x1
    height := y2 - y1
    if (debugBoxPngPath = "") {
        debugBoxPngPath := A_ScriptDir . "\Images\debugbox.png"
    }
    Gui, DebugBox:Add, Picture, x0 y0 +BackgroundTrans, %debugBoxPngPath%
    Gui, DebugBox:Show, x%x1% y100 NoActivate
    SetTimer, RemoveDebugBox, -1000  ; Auto remove after 1 second
}

RemoveDebugBox:
    Gui, DebugBox:Destroy
Return

SaveAutoHoney:
    Gui, Submit, NoHide
    IniWrite, %AutoHoney%, %settingsFile%, AutoHoney, AutoHoneySetting
Return

; macro starts

StartScanMultiInstance:
    
    Gui, Submit, NoHide

    global cycleCount
    global cycleFinished

    global lastGearMinute := -1
    global lastSeedMinute := -1
    global lastEggShopMinute := -1
    global lastCosmeticShopHour := -1
    global lastAutoHoneyMinute := -1
    global lastHoneyShopMinute := -1
    global lastHoneyRetryMinute := -1
    global lastSeedCraftMinute := -1
    global lastBearCraftMinute := -1

    started := 1
    cycleFinished := 1

    currentSection := "StartScanMultiInstance"

    SetTimer, AutoReconnect, Off
    SetTimer, CheckLoadingScreen, Off

    getWindowIDS()

    if InStr(A_ScriptDir, A_Temp) {
        MsgBox, 16, Error, Please, extract the file before running the macro.
        ExitApp
    }

    if(!windowIDS.MaxIndex()) {
        MsgBox, 1, Message, No roblox window found, if this is a false flag press OK to continue.
        IfMsgBox, Cancel
        Return
    }

    SendDiscordMessage(webhookURL, "Macro started.")

    if (MultiInstanceMode) {
        MsgBox, 1, Multi-Instance Mode, % "You have " . windowIDS.MaxIndex() . " instances open. (Instance ID's: " . idDisplay . ")`nPress OK to start the macro."
        IfMsgBox, Cancel
            Return
    }

    if WinExist("ahk_id " . firstWindow) {
        WinActivate
        WinWaitActive, , , 2
    }

    if (MultiInstanceMode) {
        for window in windowIDS {

            currentWindow := % windowIDS[window]

            ToolTip, % "Aligning Instance " . window . " (" . currentWindow . ")"
            SetTimer, HideTooltip, -5000

            WinActivate, % "ahk_id " . currentWindow

            Sleep, 500
            SafeClickRelative(0.5, 0.5)
            Sleep, 100
            Gosub, alignment
            Sleep, 100

        }
    }
    else {

        Sleep, 500
        Gosub, alignment
        Sleep, 100

    }

    WinActivate, % "ahk_id " . firstWindow

    Gui, Submit, NoHide
        
    Gosub, UpdateSelectedItems  
    itemsText := GetSelectedItems()

    Sleep, 500

    Gosub, SetTimers

    while (started) {
        if (actionQueue.Length()) {
            SetTimer, AutoReconnect, Off
            ToolTip  
            next := actionQueue.RemoveAt(1)
            if (MultiInstanceMode) {
                for window in windowIDS {
                    currentWindow := % windowIDS[window]
                    instanceNumber := window
                    ToolTip, % "Running Cycle On Instance " . window
                    SetTimer, HideTooltip, -1500
                    SendDiscordMessage(webhookURL, "***Instance " . instanceNumber . "***")
                    WinActivate, % "ahk_id " . currentWindow
                    Sleep, 200
                    SafeClickRelative(midX, midY)
                    Sleep, 200
                    Gosub, % next
                }
            }
            else {
                WinActivate, % "ahk_id " . firstWindow
                Gosub, % next
            }
            if (!actionQueue.MaxIndex()) {
                cycleFinished := 1
            }
            Sleep, 500
        } else {
            Gosub, SetToolTip
            if (cycleFinished) {
                WinActivate, % "ahk_id " . firstWindow
                cycleCount++
                SendDiscordMessage(webhookURL, "[**CYCLE " . cycleCount . " COMPLETED**]")
                cycleFinished := 0
                if (!MultiInstanceMode) {
                    SetTimer, AutoReconnect, 5000
                }
            }
            Sleep, 1000
        }
    }
		

Return

; actions

AutoBuySeed:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastSeedMinute) {
        lastSeedMinute := currentMinute
        SetTimer, PushBuySeed, -8000
    }

Return

PushBuySeed: 

    actionQueue.Push("BuySeed")

Return

BuySeed:

    currentSection := "BuySeed"
    if (selectedSeedItems.Length())
        Gosub, SeedShopPath

Return

AutoBuyGear:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastGearMinute) {
        lastGearMinute := currentMinute
        SetTimer, PushBuyGear, -8000
    }

Return

PushBuyGear: 

    actionQueue.Push("BuyGear")

Return

BuyGear:

    currentSection := "BuyGear"
    if (selectedGearItems.Length())
        Gosub, GearShopPath

Return

AutoBuyEggShop:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastEggShopMinute) {
        lastEggShopMinute := currentMinute
        SetTimer, PushBuyEggShop, -8000
    }

Return

PushBuyEggShop: 

    actionQueue.Push("BuyEggShop")

Return

BuyEggShop:

    currentSection := "BuyEggShop"
    if (selectedEggItems.Length()) {
        Gosub, EggShopPath
    } 

Return

AutoBuyCosmeticShop:

    ; queues if its not the first cycle, the minute is 0, and the current hour is an even number (every 2 hours)
    if (cycleCount > 0 && currentMinute = 0 && Mod(currentHour, 2) = 0 && currentHour != lastCosmeticShopHour) {
        lastCosmeticShopHour := currentHour
        SetTimer, PushBuyCosmeticShop, -8000
    }

Return

PushBuyCosmeticShop: 

    actionQueue.Push("BuyCosmeticShop")

Return

BuyCosmeticShop:

    currentSection := "BuyCosmeticShop"
    if (BuyAllCosmetics) {
        Gosub, CosmeticShopPath
    } 

Return

AutoBuyHoney:
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastHoneyShopMinute) {
        lastHoneyShopMinute := currentMinute
        SetTimer, PushBuyHoney, -8000
    }
        if (honeyShopFailed && Mod(currentMinute, 5) = 0 && currentMinute != lastHoneyRetryMinute) {
            lastHoneyRetryMinute := currentMinute
            SendDiscordMessage(webhookURL, "**[HONEY RETRY]**")
            SetTimer, PushBuyHoney, -8000
        }
Return


PushBuyHoney: 
    actionQueue.Push("BuyHoney")
Return

BuyHoney:
    currentSection := "BuyHoney"

    if (selectedHoneyItems.Length()) {
        if (UseAlts) {
            for index, winID in windowIDs {
                WinActivate, ahk_id %winID%
                WinWaitActive, ahk_id %winID%,, 2
                Gosub, HoneyShopPath
            }
        }
        else {
            Gosub, HoneyShopPath
        } 
    } 
Return


AutoHoney:
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastAutoHoneyMinute) {
        lastAutoHoneyMinute := currentMinute
        SetTimer, PushAutoHoney, -8000
    }
Return

PushAutoHoney:
    actionQueue.Push("RunAutoHoney")
Return

RunAutoHoney:
    currentSection := "RunAutoHoney"

 if (AutoHoney) {
    if (UseAlts) {
        for index, winID in windowIDs {
            WinActivate, ahk_id %winID%
            WinWaitActive, ahk_id %winID%,, 2
            Gosub, AutoHoneyPath
        }
    } else {
        Gosub, AutoHoneyPath
    }
}
Return

AutoSeedCraft:
if (seedCraftingLocked = 1)
	return

    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastSeedCraftMinute) {
        lastSeedCraftMinute := currentMinute
        SetTimer, PushSeedCraft, -8000
    }
Return

PushSeedCraft:
    actionQueue.Push("RunAutoSeedCraft")
Return

RunAutoSeedCraft:
    currentSection := "RunAutoSeedCraft"

 if (selectedSeedCraftingItems.Length()) {
    if (UseAlts) {
        for index, winID in windowIDs {
            WinActivate, ahk_id %winID%
            WinWaitActive, ahk_id %winID%,, 2
            Gosub, AutoSeedCraftPath
        }
    } else {
        Gosub, AutoSeedCraftPath
    }
}
Return

AutoBearCraft:
if (bearCraftingLocked = 1)
	return

    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastBearCraftMinute) {
        lastBearCraftMinute := currentMinute
        bearCraftQueued := true
        SetTimer, PushBearCraft, -8000
    }
Return

PushBearCraft:
    actionQueue.Push("RunAutoBearCraft")
    bearCraftQueued := false
Return

RunAutoBearCraft:
    currentSection := "RunAutoBearCraft"

 if (selectedBearCraftingItems.Length()) {
    if (UseAlts) {
        for index, winID in windowIDs {
            WinActivate, ahk_id %winID%
            WinWaitActive, ahk_id %winID%,, 2
            Gosub, AutoBearCraftPath
        }
    } else {
        Gosub, AutoBearCraftPath
    }
}
Return

; helper labels

SetToolTip:

    mod5 := Mod(currentMinute, 5)
    rem5min := (mod5 = 0) ? 5 : 5 - mod5
    rem5sec := rem5min * 60 - currentSecond
    if (rem5sec < 0)
        rem5sec := 0
    seedMin := rem5sec // 60
    seedSec := Mod(rem5sec, 60)
    seedText := (seedSec < 10) ? seedMin . ":0" . seedSec : seedMin . ":" . seedSec
    gearMin := rem5sec // 60
    gearSec := Mod(rem5sec, 60)
    gearText := (gearSec < 10) ? gearMin . ":0" . gearSec : gearMin . ":" . gearSec

    mod30 := Mod(currentMinute, 30)
    rem30min := (mod30 = 0) ? 30 : 30 - mod30
    rem30sec := rem30min * 60 - currentSecond
    if (rem30sec < 0)
        rem30sec := 0
    eggMin := rem30sec // 60
    eggSec := Mod(rem30sec, 60)
    eggText := (eggSec < 10) ? eggMin . ":0" . eggSec : eggMin . ":" . eggSec

    mod60 := Mod(currentMinute, 60)
    rem60min := (mod60 = 0) ? 60 : 60 - mod60
    rem60sec := rem60min * 60 - currentSecond
    if (rem60sec < 0)
        rem60sec := 0
    honeyMin := rem60sec // 60
    honeySec := Mod(rem60sec, 60)
    honeyText := (honeySec < 10) ? honeyMin . ":0" . honeySec : honeyMin . ":" . honeySec

    totalSecNow := currentHour * 3600 + currentMinute * 60 + currentSecond
    nextCosHour := (Floor(currentHour/2) + 1) * 2
    nextCosTotal := nextCosHour * 3600
    remCossec := nextCosTotal - totalSecNow
    if (remCossec < 0)
        remCossec := 0
    cosH := remCossec // 3600
    cosM := (remCossec - cosH*3600) // 60
    cosS := Mod(remCossec, 60)
    if (cosH > 0)
        cosText := cosH . ":" . (cosM < 10 ? "0" . cosM : cosM) . ":" . (cosS < 10 ? "0" . cosS : cosS)
    else
        cosText := cosM . ":" . (cosS < 10 ? "0" . cosS : cosS)


    tooltipText := ""
    if (selectedSeedItems.Length()) {
        tooltipText .= "Seed Shop: " . seedText . "`n"
    }
    if (selectedGearItems.Length()) {
        tooltipText .= "Gear Shop: " . gearText . "`n"
    }
    if (selectedEggItems.Length()) {
        tooltipText .= "Egg Shop : " . eggText . "`n"
    }
    if (BuyAllCosmetics) {
        tooltipText .= "Cosmetic Shop: " . cosText . "`n"
    }
    if (selectedHoneyItems.Length()) {
        tooltipText .= "Honey Shop: " . eggText . "`n"
    }
    if (AutoHoney) {
    	tooltipText .= "Turn in Pollinated: " . seedText . "`n"
    }

    if (tooltipText != "") {
        CoordMode, Mouse, Screen
        MouseGetPos, mX, mY
        offsetX := 10
        offsetY := 10
        ToolTip, % tooltipText, % (mX + offsetX), % (mY + offsetY)
    } else {
        ToolTip  ; clears any existing tooltip
    }

Return

SetTimers:

    SetTimer, UpdateTime, 1000

    if (selectedSeedItems.Length()) {
        actionQueue.Push("BuySeed")
    }
    seedAutoActive := 1
    SetTimer, AutoBuySeed, 1000 ; checks every second if it should queue

    if (selectedGearItems.Length()) {
        actionQueue.Push("BuyGear")
    }
    gearAutoActive := 1
    SetTimer, AutoBuyGear, 1000 ; checks every second if it should queue

    if (selectedEggItems.Length()) {
        actionQueue.Push("BuyEggShop")
    }
    eggAutoActive := 1
    SetTimer, AutoBuyEggShop, 1000 ; checks every second if it should queue

    if (BuyAllCosmetics) {
        actionQueue.Push("BuyCosmeticShop")
    }
    cosmeticAutoActive := 1
    SetTimer, AutoBuyCosmeticShop, 1000 ; checks every second if it should queue

    if (selectedHoneyItems.Length()) {
        actionQueue.Push("BuyHoney")
    }
    honeyAutoActive := 1
    SetTimer, AutoBuyHoney, 1000 ; checks every second if it should queue

    if (AutoHoney) {
        actionQueue.Push("RunAutoHoney")
    }
    autoHoneyActive := 1
    SetTimer, AutoHoney, 1000 ; checks every second if it should queue

    if (selectedSeedCraftingItems.Length()) {
        actionQueue.Push("RunAutoSeedCraft")
    }
    seedCraftingAutoActive := 1
    SetTimer, AutoSeedCraft, 1000 ; checks every second if it should queue

    if (selectedBearCraftingItems.Length()) {
        actionQueue.Push("RunAutoBearCraft")
    }
    bearCraftingAutoActive := 1
    SetTimer, AutoBearCraft, 1000 ; checks every second if it should queue
    
Return

UpdateTime:

    FormatTime, currentHour,, hh
    FormatTime, currentMinute,, mm
    FormatTime, currentSecond,, ss

    currentHour := currentHour + 0
    currentMinute := currentMinute + 0
    currentSecond := currentSecond + 0

Return

AutoReconnect:

    global actionQueue

    if ((simpleDetect(0x302927, 0, 0.3988, 0.3548, 0.6047, 0.6674) || simpleDetect(0x3D3B39, 0, 0.3988, 0.3548, 0.6047, 0.6674)) && simpleDetect(0xFFFFFF, 0, 0.3988, 0.3548, 0.6047, 0.6674) && privateServerLink != "") {
        started := 0
        actionQueue := []
        SetTimer, AutoReconnect, Off
        Sleep, 500
        WinClose, % "ahk_id" . firstWindow
        Sleep, 1000
        WinClose, % "ahk_id" . firstWindow
        Sleep, 500
        Run, % privateServerLink
        ToolTip, Attempting To Reconnect
        SetTimer, HideTooltip, -5000
        SendDiscordMessage(webhookURL, "Lost connection or macro errored, attempting to reconnect..." . (PingSelected ? " <@" . discordUserID . ">" : ""))
        sleepAmount(15000, 30000)
        SetTimer, CheckLoadingScreen, 5000
    }

Return

CheckLoadingScreen:

    ToolTip, Detecting Rejoin

    getWindowIDS()

    WinActivate, % "ahk_id" . firstWindow

    if (simpleDetect(0x000000, 0, 0.75, 0.75, 0.9, 0.9)) {
        SafeClickRelative(midX, midY)
    }
    else {
        ToolTip, Rejoined Successfully
        sleepAmount(5000, 10000)
        SendDiscordMessage(webhookURL, "Successfully reconnected to server." . (PingSelected ? " <@" . discordUserID . ">" : ""))
        Sleep, 200
        Gosub, StartScanMultiInstance
    }

Return

; set up labels

alignment:

    ToolTip, Beginning Alignment
    SetTimer, HideTooltip, -5000

    SafeClickRelative(0.5, 0.5)
    Sleep, 100

    searchitem("recall")

    Sleep, 200

    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
        Sleep, 100
        }
    else {
        Gosub, zoomAlignment
        Sleep, 100
    }

    Sleep, 1000
    uiUniversal(11110)
    Sleep, 100

    ToolTip, Alignment Complete
    SetTimer, HideTooltip, -1000

Return

cameraChange:

    ; changes camera mode to follow and can be called again to reverse it (0123, 0->3, 3->0)
    Send, {Escape}
    Sleep, 500
    Send, {Tab}
    Sleep, 400
    Send {Down}
    Sleep, 100
    repeatKey("Right", 2, (SavedSpeed = "Ultra") ? 55 : (SavedSpeed = "Max") ? 60 : 30)
    Sleep, 100
    Send {Escape}

Return

cameraAlignment:

    ; puts character in overhead view
    Click, Right, Down
    Sleep, 200
    SafeMoveRelative(0.5, 0.5)
    Sleep, 200
    MouseMove, 0, 800, R
    Sleep, 200
    Click, Right, Up

Return

zoomAlignment:

    ; sets correct player zoom
    SafeMoveRelative(0.5, 0.5)
    Sleep, 100

    Loop, 40 {
        Send, {WheelUp}
        Sleep, 20
    }

    Sleep, 200

    Loop, 6 {
        Send, {WheelDown}
        Sleep, 20
    }

    midX := getMouseCoord("x")
    midY := getMouseCoord("y")

Return

characterAlignment:

    ; aligns character through spam tping and using the follow camera mode

    sendKeybind(SavedKeybind)
    Sleep, 10

    if (UINavigationFix) {
        repeatKey("Left", 5)
        Sleep, 10
        repeatKey("Up", 5)
        Sleep, 10
    }

    repeatKey("Right", 3)
    Loop, % ((SavedSpeed = "Ultra") ? 12 : (SavedSpeed = "Max") ? 18 : 8) {
    Send, {Enter}
    Sleep, 10
    repeatKey("Right", 2)
    Sleep, 10
    Send, {Enter}
    Sleep, 10
    repeatKey("Left", 2)
    }
    Sleep, 10
    sendKeybind(SavedKeybind)

Return

; buying paths

EggShopPath:

    Sleep, 100
    uiUniversal("11110")
    Sleep, 100
    hotbarController(1, 0, "2")
    sleepAmount(100, 1000)
    SafeClickRelative(midX, midY)
    SendDiscordMessage(webhookURL, "**[Egg Cycle]**")
    Sleep, 800

    ; egg 1 sequence
    Send, {Up Down}
    Sleep, 1800
    Send {Up Up}
    sleepAmount(500, 1000)
    Send {e}
    Sleep, 100
    uiUniversal("11114", 0, 0)
    Sleep, 100
    quickDetectEgg(0x26EE26, 15, 0.41, 0.65, 0.52, 0.70)
    Sleep, 800
    ; egg 2 sequence
    Send, {Up down}
    Sleep, 200
    Send, {Up up}
    sleepAmount(100, 1000)
    Send {e}
    Sleep, 100
    uiUniversal("11114", 0, 0)
    Sleep, 100
    quickDetectEgg(0x26EE26, 15, 0.41, 0.65, 0.52, 0.70)
    Sleep, 800
    ; egg 3 sequence
    Send, {Up down}
    Sleep, 200
    Send, {Up up}
    sleepAmount(100, 1000)
    Send, {e}
    Sleep, 200
    uiUniversal("11114", 0, 0)
    Sleep, 100
    quickDetectEgg(0x26EE26, 15, 0.41, 0.65, 0.52, 0.70)
    Sleep, 300

    closeRobuxPrompt()
    sleepAmount(1250, 2500)
    uiUniversal("11110")
    Sleep, 100
    SendDiscordMessage(webhookURL, "**[Eggs Completed]**")

    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
    else {
        Gosub, zoomAlignment
    }

Return

SeedShopPath:

    seedsCompleted := 0

    uiUniversal("1111020")
    sleepAmount(100, 1000)
    Send, {e}
    SendDiscordMessage(webhookURL, "**[Seed Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Seed Shop Opened.")
            Sleep, 200
            uiUniversal("3331114433331114405550555", 0)
            Sleep, 100
            buyUniversal("seed")
            SendDiscordMessage(webhookURL, "Seed Shop Closed.")
            seedsCompleted = 1
        }
        if (seedsCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("seed", seedsCompleted)

    SendDiscordMessage(webhookURL, "**[Seeds Completed]**")

Return

GearShopPath:

    gearsCompleted := 0

    hotbarController(0, 1, "0")
    uiUniversal("11110")
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(1200, 2500)
    Send, {e}
    sleepAmount(1500, 5000)
    dialogueClick("gear")
    SendDiscordMessage(webhookURL, "**[Gear Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Gear Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Gear Shop Opened.")
            Sleep, 200
            uiUniversal("3331114433331114405550555", 0)
            Sleep, 100
            buyUniversal("gear")
            SendDiscordMessage(webhookURL, "Gear Shop Closed.")
            gearsCompleted = 1
        }
        if (gearsCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("gear", gearsCompleted)
    
    Sleep, 1000

    Gosub, zoomAlignment

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Gears Completed]**")

Return

CosmeticShopPath:

    ; if you are reading this please forgive this absolute garbage label
    cosmeticsCompleted := 0

    hotbarController(0, 1, "0")
    uiUniversal("11110")
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(800, 1000)
    Send, {Up Down}
    Sleep, 900
    Send, {Up Up}
    sleepAmount(100, 1000)
    Send, {e}
    sleepAmount(2500, 5000)
    SendDiscordMessage(webhookURL, "**[Cosmetic Cycle]**")
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.61, 0.182, 0.764, 0.259)) {
            ToolTip, Cosmetic Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Cosmetic Shop Opened.")
            Sleep, 200
            for index, item in cosmeticItems {
                label := StrReplace(item, " ", "")
                currentItem := cosmeticItems[A_Index]
                Gosub, %label%
                SendDiscordMessage(webhookURL, "Bought " . currentItem . )
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Cosmetic Shop Closed.")
            cosmeticsCompleted = 1
        }
        if (cosmeticsCompleted) {
            break
        }
        Sleep, 2000
    }

    if (cosmeticsCompleted) {
        Sleep, 500
        uiUniversal("111114150320")
    }
    else {
        SendDiscordMessage(webhookURL, "Failed To Detect Cosmetic Shop Opening [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
        ; failsafe
        uiUniversal("11114111350")
        Sleep, 50
        uiUniversal("11110")
    }

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Cosmetics Completed]**")

Return

HoneyShopPath:

    honeyCompleted := false
    shopOpened := false
    honeyShopFailed := false

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    uiUniversal("616161616062606")
    Sleep, % FastMode ? 500 : 2500
    Send, {d down}
    Sleep, 9350
    Send, {d up}
    Sleep, % FastMode ? 300 : 300
    Send, {Up Down}
    Sleep, 300
    Send, {Up Up}
    Sleep, % FastMode ? 100 : 300
    Loop, 4 {
             Send, {WheelDown}
             Sleep, 20
             }
    Sleep, % FastMode ? 100 : 1200
    Send, {e}
    Sleep, 2500
    SafeClickRelative(0.64, 0.50)
    Sleep, 200
    SendDiscordMessage(webhookURL, "**[HONEY CYCLE]**")
    Sleep, % FastMode ? 2500 : 5000

     ; detect shop open (up to 5 tries)
    Loop, 5 {
        if ( simpleDetect(0x03FADC, 10, 0.54, 0.20, 0.65, 0.325) ) {
            shopOpened := true
            ToolTip, Honey Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Honey Shop Opened.")
            Break
        }
        Sleep, 2000
    }

    if (!shopOpened) {
        SendDiscordMessage(webhookURL, "Failed To Detect Honey Shop Opening [Error]" (PingSelected ? " <@" . discordUserID . ">" : "") )
        uiUniversal("63636362626263616161616363636262626361616161606561646056")
	honeyShopFailed := true
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
        Return
    }

    SendRaw, %UINavToggle%
    Sleep, 200
    SendRaw, %UINavToggle%
    Sleep, 200
    uiUniversal("61616161616161616161626060656", 0)
    Sleep, 100
    positions := []
    Loop, % honeyItems.Length() {
        if (HoneyItem%A_Index%)
            positions.Push(A_Index)
    }
    positions.Sort()
    currentPos := 1
    demonicQuestionMark := {1: true, 9: true, 10: true}
    for _, targetPos in positions {
        delta := targetPos - currentPos
        if (delta > 0){
            Loop, % delta{
                step := currentPos + A_Index ; Index for current loop #
                if (demonicQuestionMark.HasKey(step) && targetPos > 9){
                    uiUniversal("46", 0, 1)
                }
                else if(demonicQuestionMark.HasKey(step) && delta != 1){
                    uiUniversal("46", 0, 1)
                }
                uiUniversal("4", 0, 1)
            }
        }
        currentItem := honeyItems[targetPos]
        if(currentPos == 1 && targetPos != 1 && targetPos < 9){
            uiUniversal("46", 0, 1)
        }
        if(targetPos > 10 && currentPos < 9){
            uiUniversal("46", 0, 1)
        }
        if(currentPos == 10 && targetPos > 10 && delta == 1){
            uiUniversal("46", 0, 1)
        }
        if (demonicQuestionMark.HasKey(targetPos)) {
            uiUniversal("064646", 0, 1)
        } else {
            uiUniversal("0646", 0, 1)
        }

        Sleep, % FastMode ? 60 : 200
        quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
        Sleep, 60
        uiUniversal("3606", 0, 1)
        Sleep, % FastMode ? 60 : 200
        currentPos := targetPos
        Sleep, 100
    }

    SendDiscordMessage(webhookURL, "Honey Shop Closed.")

    honeyCompleted := true

    if (honeyCompleted) {
        Sleep, 500
        uiUniversal("52525252525252525055555506", 1, 1)
        Sleep, 120          ; in case a robux prompt
        Send, {Escape}
        Sleep, 80
        Send, {Escape}
        Sleep, 50
        SendDiscordMessage(webhookURL, "**[HONEY COMPLETED]**")
    }
			Sleep, % FastMode ? 150 : 1500
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
    else {
        Gosub, zoomAlignment
    }
Return


ClickFirstFour() {
        SafeClickRelative(0.35, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.38, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.415, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.45, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
}

ClickFirstEight() {
        SafeClickRelative(0.35, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.38, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.415, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.45, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.485, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.52, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.555, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
        Sleep, % FastMode ? 400 : 200
        SafeClickRelative(0.59, 0.70)
        Sleep, % FastMode ? 50 : 200
        Send, {e}
}


AutoHoneyPath:

    autoHoneyCompleted := false

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    SendDiscordMessage(webhookURL, "**[HONEY COMPRESS CYCLE]**")
    uiUniversal("616161616062606")
    Sleep, % FastMode ? 500 : 2500
    Send, {d down}
    Sleep, 9150
    Send, {d up}
    Sleep, % FastMode ? 300 : 300
    Send, {Up Down}
    Sleep, 620
    Send, {Up Up}
    Sleep, % FastMode ? 100 : 300
    Send, {d down}
    Sleep, 600
    Send, {d up}
    Sleep, % FastMode ? 100 : 300
    Send, {e}
    Sleep, % FastMode ? 100 : 300
    uiUniversal("63636363616066664646460")
    Sleep, % FastMode ? 100 : 300
    SendInput, ^{Backspace 5}
    Sleep, % FastMode ? 100 : 300
    Send, pollinated

    Loop, 3
    {
	ClickFirstFour()
    }
    Send, 2
    Sleep, 100
    Send, 2
    Sleep, 100
    Sleep, 30000
    Send, {e}
    Sleep, 100
    Loop, 3
    {
	ClickFirstFour()
    }
    Send, 2
    Sleep, 100
    Send, 2
    Sleep, 100
    Sleep, 30000
    Send, {e}
    Sleep, 100
    Loop, 3
    {
	ClickFirstFour()
    }

    Sleep, % FastMode ? 150 : 300
    SafeClickRelative(0.64, 0.51)
    Sleep, % FastMode ? 100 : 200
    Send, {2}
    Send, {2}
    Sleep, % FastMode ? 100 : 200
    uiUniversal("63636363636161616160")
    SendDiscordMessage(webhookURL, "**[HONEY COMPRESS COMPLETE]**")
    autoHoneyCompleted := true

    TrackHoneyCycle()

TrackHoneyCycle()
{
    global honeyCount, webhookURL

    honeyCount += 30

    SendDiscordMessage(webhookURL, "**[Honey Compress]** +30 honey collected")
    SendDiscordMessage(webhookURL, "**[Honey Compress]** Total honey collected: " . honeyCount)
}

        Sleep, 120          ; in case a robux prompt
        Send, {Escape}
        Sleep, 80
        Send, {Escape}
        Sleep, 50
Return


ClickSeedFilter() {
        SafeClickRelative(0.31, 0.72)
}
ClickFruitFilter() {
        SafeClickRelative(0.31, 0.78)
}
	

AutoSeedCraftPath:

if (cycleCount = 0 && ManualSeedCraftLock > 0) {
	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -%ManualSeedCraftLock%
Return
}

    seedCraftCompleted := false
    seedCraftShopOpened := false
    seedCraftShopFailed := false

CraftShopUiFix() {
    uiUniversal("33333333")
    Sleep, % FastMode ? 100 : 300
    uiUniversal("515151545454545450505333333")
    Sleep, % FastMode ? 100 : 300
    uiUniversal("3333333545450505")
}

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    SendDiscordMessage(webhookURL, "**[SEED CRAFTING CYCLE]**.")
    Sleep, 100
    uiUniversal("1111020")
    Sleep, % FastMode ? 500 : 2500
    Send, {d down}
    Sleep, 7000
    Send, {d up}
    Sleep, % FastMode ? 300 : 300
    Send, {Up Down}
    Sleep, 820
    Send, {Up Up}
    Sleep, % FastMode ? 100 : 300
    Send, {c}
    Sleep, % FastMode ? 100 : 300
    Send, {e}
    Sleep, % FastMode ? 100 : 300
    Send, {e}
    Sleep, % FastMode ? 100 : 300
Loop, 5 {
        if (simpleDetect(0xA0014C, 15, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Crafter Opened
            SetTimer, HideTooltip, -1500
            seedCraftShopOpened := true
            SendDiscordMessage(webhookURL, "Seed Crafter Opened.")
	    break
	}
        else if (simpleDetect(0xA3014D, 15, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Crafter Opened
            SetTimer, HideTooltip, -1500
            seedCraftShopOpened := true
            SendDiscordMessage(webhookURL, "Seed Crafter Opened.")
	    break
	}
}

    if (!seedCraftShopOpened) {
        SendDiscordMessage(webhookURL, "Failed To Detect Seed Crafter Opening [Error]" (PingSelected ? " <@" . discordUserID . ">" : "") )
        uiUniversal("63636362626263616161616363636262626361616161606561646056")
	seedCraftShopFailed := true
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
        Return
    }

selectedSeedCraftItems := []
Loop, 12 {
    lastRanItem := currentItem 
    IniRead, value, %A_ScriptDir%\settings.ini, SeedCrafting, Item%A_Index%, 0
    if (value = 1)
        selectedSeedCraftItems.Push(A_Index)
}

For index, item in selectedSeedCraftItems {
    if (item = 1) {
	CraftShopUiFix()
	currentItem := "Crafters Seed Pack"
        uiUniversal("333333354545054545505")

	Sleep, 100
	searchItem("pack")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -1200000 
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 2) {
	CraftShopUiFix()
	currentItem := "Manuka Flower"
        uiUniversal("33333333335454545450545505")

	Sleep, 100
	searchItem("daffodil")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("orange")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 3) {
	CraftShopUiFix()
	currentItem := "Dandelion"
        uiUniversal("3333333333545454545450545505")

	Sleep, 100
	searchItem("bamboo")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("manuka")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -960000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 4) {

        uiUniversal("33333333")
        Sleep, % FastMode ? 100 : 300
        uiUniversal("5151515454545454545450505333333")
        Sleep, % FastMode ? 100 : 300
        uiUniversal("3333333545450505")

	currentItem := "Lumira"
        uiUniversal("333333333354545454545450545505")

	Sleep, 100
	searchItem("pumpkin")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("dandelion")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("pack")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -1200000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 5) {
	CraftShopUiFix()
	currentItem := "Honeysuckle"
        uiUniversal("33333333335454545454545450545505")

	Sleep, 100
	searchItem("pink")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("dahlia")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -1500000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 6) {
	CraftShopUiFix()
	currentItem := "Bee Balm"
        uiUniversal("3333333333545454545454545450545505")

	Sleep, 100
	searchItem("crocus")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("lavender")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -900000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 7) {
	CraftShopUiFix()
	currentItem := "Nectar Thorn"
        uiUniversal("333333333354545454545454545450545505")

	Sleep, 100
	searchItem("cactus")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("cactus")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("nectarshade")
	Sleep, 100
	ClickSeedFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -1800000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 8) {
	CraftShopUiFix()
	currentItem := "Suncoil"
        uiUniversal("33333333335454545454545454545450545505")

	Sleep, 100
	searchItem("crocus")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("daffodil")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("dandelion")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("pink")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 500
	closeRobuxPrompt()

	seedCraftingLocked := 1
	SetTimer, UnlockSeedCraft, -2700000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
}
    seedCraftCompleted := true
    Sleep, % FastMode ? 100 : 200
	Send, {2}
	Send, {2}
    Sleep, % FastMode ? 100 : 200
    uiUniversal("63636363636161616160")
    SendDiscordMessage(webhookURL, "**[SEED CRAFTING COMPLETE]**")
    Sleep, % FastMode ? 100 : 200
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
Return

AutoBearCraftPath:

if (cycleCount = 0 && ManualBearCraftLock > 0) {
	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -%ManualBearCraftLock%
Return
}

    bearCraftCompleted := false
    bearCraftShopOpened := false
    bearCraftShopFailed := false

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    SendDiscordMessage(webhookURL, "**[BEAR CRAFTING CYCLE]**")
    Sleep, 100
    uiUniversal("1111020")
    Sleep, % FastMode ? 500 : 2500
    Send, {d down}
    Sleep, 7000
    Send, {d up}
    Sleep, % FastMode ? 300 : 300
    Send, {Up Down}
    Sleep, 600
    Send, {Up Up}
    Sleep, % FastMode ? 100 : 300
    Send, {d down}
    Sleep, 600
    Send, {d up}
    Sleep, % FastMode ? 100 : 300
    Send, {c}
    Sleep, % FastMode ? 100 : 300
    Send, {e}
    Sleep, % FastMode ? 100 : 300
    Send, {e}
    Sleep, % FastMode ? 100 : 300
Loop, 5 {
        if (simpleDetect(0xA0014C, 15, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Crafter Opened
            SetTimer, HideTooltip, -1500
            bearCraftShopOpened := true
            SendDiscordMessage(webhookURL, "Seed Crafter Opened.")
	    break
	}
        else if (simpleDetect(0xA3014D, 15, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Crafter Opened
            SetTimer, HideTooltip, -1500
            bearCraftShopOpened := true
            SendDiscordMessage(webhookURL, "Seed Crafter Opened.")
	    break
	}
}

    if (!bearCraftShopOpened) {
        SendDiscordMessage(webhookURL, "Failed To Detect Bear Crafter Opening [Error]" (PingSelected ? " <@" . discordUserID . ">" : "") )
        uiUniversal("63636362626263616161616363636262626361616161606561646056")
	bearCraftShopFailed := true
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
        Return
    }

selectedBearCraftItems := []
Loop, 12 {
    IniRead, value, %A_ScriptDir%\settings.ini, BearCrafting, Item%A_Index%, 0
    if (value = 1)
        selectedBearCraftItems.Push(A_Index)
}

For index, item in selectedBearCraftItems {
    if (item = 1) {
	CraftShopUiFix()
	currentItem := "Tropical Mist Sprinkler"
        uiUniversal("3333333545450545505")

	Sleep, 100
	searchItem("coconut")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("dragon")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("mango")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("godly")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -3600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 2) {
	CraftShopUiFix()
	currentItem := "Berry Blusher Sprinkler"
        uiUniversal("333333354545450545505")

	Sleep, 100
	searchItem("grape")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("blueberry")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("strawberry")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("godly")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -3600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 3) {
	CraftShopUiFix()
	currentItem := "Spice Spritzer Sprinkler"
        uiUniversal("33333335454545450545505")

	Sleep, 100
	searchItem("pepper")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("ember")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("cacao")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("master")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -3600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 4) {

        uiUniversal("33333333")
        Sleep, % FastMode ? 100 : 300
        uiUniversal("5151515454545454545450505333333")
        Sleep, % FastMode ? 100 : 300
        uiUniversal("3333333545450505")

	currentItem := "Sweet Soaker Sprinkler"
        uiUniversal("3333333545454545450545505")

	Sleep, 100
	searchItem("watermelon")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -3600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 5) {
	CraftShopUiFix()
	currentItem := "Flower Froster Sprinkler"
        uiUniversal("333333354545454545450545505")

	Sleep, 100
	searchItem("orange")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("daffodil")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("advanced")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("basic")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -3600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 6) {
	CraftShopUiFix()
	currentItem := "Stalk Sprout Sprinkler"
        uiUniversal("33333335454545454545450545505")

	Sleep, 100
	searchItem("bamboo")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("beanstalk")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("mushroom")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("advanced")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -3600000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 7) {
	CraftShopUiFix()
	currentItem := "Mutation Spray Choc"
        uiUniversal("3333333545454545454545450545505")

	Sleep, 100
	searchItem("cacao")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("cleaning")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -900000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 8) {
	CraftShopUiFix()
	currentItem := "Mutation Spray Pollinated"
        uiUniversal("333333354545454545454545450545505")

	Sleep, 100
	searchItem("balm")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("cleaning")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -300000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 9) {
	CraftShopUiFix()
	currentItem := "Mutation Spray Shocked"
        uiUniversal("33333335454545454545454545450545505")

	Sleep, 100
	searchItem("lightning")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("cleaning")
	Sleep, 100
	ClickFirstFour()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -1800000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 10) {
	CraftShopUiFix()
	currentItem := "Honey Crafters Crate"
        uiUniversal("333333354545454545454545454545054545505")

	Sleep, 100
	searchItem("crate")
	Sleep, 100
	ClickFirstEight()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -1800000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 11) {
	CraftShopUiFix()
	currentItem := "Anti Bee Egg"
        uiUniversal("3333333545454545454545454545454545054545505")

	Sleep, 100
	searchItem("egg")
	Sleep, 100
	ClickFirstEight()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -7200000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
    if (item = 12) {
	CraftShopUiFix()
	currentItem := "Pack Bee"
        uiUniversal("333333354545454545454545454545454545450545505")

	Sleep, 100
	searchItem("sunflower")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("dahlia")
	Sleep, 100
	ClickFruitFilter()
	Sleep, 100
	ClickFirstFour()
	Sleep, 100
        Send, {vkC0sc029}
	Sleep, 100
	searchItem("egg")
	Sleep, 100
	ClickFirstEight()
	Sleep, 500
	closeRobuxPrompt()
	Sleep, 100

	bearCraftingLocked := 1
	SetTimer, UnlockBearCraft, -14400000
	SendDiscordMessage(webhookURL, "Attempted to craft " . currentItem . ".")
        Sleep, 50
	Break
    }
}

    bearCraftCompleted := true
    Sleep, % FastMode ? 100 : 200
	Send, {2}
	Send, {2}
    Sleep, % FastMode ? 100 : 200
    uiUniversal("63636363636161616160")
    SendDiscordMessage(webhookURL, "**[BEAR CRAFTING COMPLETED]**")
    Sleep, % FastMode ? 100 : 200
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
Return

UnlockSeedCraft:
    seedCraftingLocked := 0
Return

UnlockBearCraft:
    bearCraftingLocked := 0
Return

; cosmetic labels

Cosmetic1:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111445000000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic2:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442250000000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic3:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442222500000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic4:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224500000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic5:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224150000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic6:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224115000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic7:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222241115000000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic8:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222241111500000000")
        sleepAmount(50, 200)
    }

Return

Cosmetic9:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442222411111500000000")
        sleepAmount(50, 200)
    }

Return

; save settings and start/exit

SaveSettings:

    Gui, Submit, NoHide

    ; — now write them out —
    Loop, % eggItems.Length()
        IniWrite, % (eggItem%A_Index% ? 1 : 0), %settingsFile%, Egg, Item%A_Index%

    Loop, % gearItems.Length()
        IniWrite, % (GearItem%A_Index% ? 1 : 0), %settingsFile%, Gear, Item%A_Index%

    Loop, % seedItems.Length()
        IniWrite, % (SeedItem%A_Index% ? 1 : 0), %settingsFile%, Seed, Item%A_Index%

    Loop, % honeyItems.Length()
    	IniWrite, % (HoneyItem%A_Index% ? 1 : 0), %settingsFile%, Honey, Item%A_Index%

    Loop, % seedCraftingItems.Length()
    	IniWrite, % (SeedCraftingItem%A_Index% ? 1 : 0), %settingsFile%, SeedCrafting, Item%A_Index%

    Loop, % bearCraftingItems.Length()
    	IniWrite, % (BearCraftingItem%A_Index% ? 1 : 0), %settingsFile%, BearCrafting, Item%A_Index%

    IniWrite, %AutoAlign%, %settingsFile%, Main, AutoAlign
    IniWrite, %PingSelected%, %settingsFile%, Main, PingSelected
    IniWrite, %MultiInstanceMode%, %settingsFile%, Main, MultiInstanceMode
    IniWrite, %UINavigationFix%, %settingsFile%, Main, UINavigationFix
    IniWrite, %BuyAllCosmetics%, %settingsFile%, Cosmetic, BuyAllCosmetics
    IniWrite, %SelectAllEggs%, %settingsFile%, Egg, SelectAllEggs
    IniWrite, %SelectAllHoney%, %settingsFile%, Honey, SelectAllHoney
    IniWrite, %AutoHoney%, %settingsFile%, AutoHoney, AutoHoneySetting

Return

StopMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings
    Gui, Destroy
    if (terminate)
        ExitApp

}

PauseMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings

}

; pressing x on window closes macro 
GuiClose:

    StopMacro(1)

Return

; pressing f7 button reloads
Quit:

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

Return

; f7 reloads
F7::

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

Return

; f5 starts scan
F5:: 

Gosub, StartScanMultiInstance

Return

F8::

MsgBox, 1, Message, % "Delete debug file?"

IfMsgBox, OK
FileDelete, debug.txt

Return

#MaxThreadsPerHotkey, 2
