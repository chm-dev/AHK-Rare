﻿; ===============================================================
; 	*** AHK-RARE the GUI *** -- !SEARCH COMFORTABLE! --         V0.75 September 08, 2019 by Ixiko
; ===============================================================
; ------------------------------------------------------------------------------------------------------------
; 		MISSING THINGS:
; ------------------------------------------------------------------------------------------------------------
;
;	1. Highlighting the search term(s) in the RichEdit controls
;	2. Keywords should be displayed in the description with a larger font
; ------------------------------------------------------------------------------------------------------------

;{01. script parameters

		#NoEnv
		#Persistent
		#SingleInstance, Force
		#InstallKeybdHook
		#MaxThreads, 250
		#MaxThreadsBuffer, On
		#MaxHotkeysPerInterval 99000000
		#HotkeyInterval 99000000
		#KeyHistory 1
		;ListLines Off

		SetTitleMatchMode     	, 2
		SetTitleMatchMode     	, Fast
		DetectHiddenWindows	, Off
		CoordMode                 	, Mouse, Screen
		CoordMode                 	, Pixel, Screen
		CoordMode                 	, ToolTip, Screen
		CoordMode                 	, Caret, Screen
		CoordMode                 	, Menu, Screen
		SetKeyDelay                	, -1, -1
		SetBatchLines           		, -1
		SetWinDelay                	, -1
		SetControlDelay          	, -1
		SendMode                   	, Input
		AutoTrim                     	, On
		FileEncoding                	, UTF-8

		OnExit("TheEnd")

		Menu, Tray, Icon				, % "hIcon: " Create_GemSmall_png(true)
	;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	; Script Prozess ID
	;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		scriptPID:= DllCall("GetCurrentProcessId")

;}

;{02. variables

		ARData    	:= Object()	; contains data from AHKRare.ahk
		ARFile      	:= Array() 	; indexed array of AHKRare.ahk file, index is corresponding to line number
		RC		    	:= Object()
		GuiW       	:= 1200    	; base width of gui on first start
		SR1Width	:= 250
		highlight  	:= false     	; flag to highlight search results

		global  FoundIndex:= 0 ; a flag

	; ------------------------------------------------------------------------------------------------------------------------------------------------------------
	;	loading AHK-Rare.txt
	; ------------------------------------------------------------------------------------------------------------------------------------------------------------;{
		If FileExist(A_ScriptDir . "\AHK-Rare.txt")
			ARFile:= RareLoad(A_ScriptDir "\AHK-Rare.txt")
		else
		{
				IniRead, filepattern, % A_ScriptDir "\AHK-Rare_TheGui.ini", Properties, RareFolder
				If Instr(filepattern, "ERROR")
				{
						FileSelectFile, filepattern,, % A_ScriptDir, % "Please enter the location of the AHK-Rare.txt file here!", % "AHK-Rare.txt"
						If (filepattern = "") || !FileExist(filepattern)
								ExitApp
						IniWrite, % filepattern, % A_ScriptDir "\AHK-Rare_TheGui.ini", Properties, RareFolder
				}

				ARFile:= RareLoad(filepattern)
		}
	;}

	; ------------------------------------------------------------------------------------------------------------------------------------------------------------
	;	get the last gui size
	; ------------------------------------------------------------------------------------------------------------------------------------------------------------;{
		IniRead, GuiOptions, % A_ScriptDir "\AHK-Rare.ini", Properties, GuiOptions
		If !Instr(GuiOptions, "Error") && !(GuiOptions = "")
		{
			GuiOptions	:= StrSplit(GuiOptions, "|")
			GuiW       	:= GuiOptions.3
		}

		IniRead, SearchMode, % A_ScriptDir "\AHK-Rare.ini", Properties, SearchMode
			If Instr(SearchMode, "Error") || (SearchMode = "")
				SearchMode:= "Basic"
	;}

	; ------------------------------------------------------------------------------------------------------------------------------------------------------------
	;	Settings array for the RichCode control (code & examples)
	; ------------------------------------------------------------------------------------------------------------------------------------------------------------;{
		Settings :=
		( LTrim Join Comments
		{
		"TabSize"         	: 4,
		"Indent"           	: "`t",
		"FGColor"         	: 0xEDEDCD,
		"BGColor"        	: 0x172842,
		"Font"              	: {"Typeface": "Bitstream Vera Sans Mono", "Size": 10},
		"WordWrap"    	: False,

		"UseHighlighter"	: True,
		"HighlightDelay"	: 200,

		"Colors": {
			"Comments"	:	0x7F9F7F,
			"Functions"  	:	0x7CC8CF,
			"Keywords"  	:	0xE4EDED,
			"Multiline"   	:	0x7F9F7F,
			"Numbers"   	:	0xF79B57,
			"Punctuation"	:	0x97C0EB,
			"Strings"      	:	0xCC9893,

			; AHK
			"A_Builtins"   	:	0xF79B57,
			"Commands"	:	0xCDBFA3,
			"Directives"  	:	0x7CC8CF,
			"Flow"          	:	0xE4EDED,
			"KeyNames"	:	0xCB8DD9,
			"Descriptions"	:	0xF0DD82,
			"Link"           	:	0x47B856,

			; PLAIN-TEXT
			"PlainText"		:	0x7F9F7F
			}
		}
		)

;}
;}

;{03. draw primary gui

		Logo:= Create_AHKRareGuiLogo_png(true)

		global hArg, ARG, hSearch, hTabs
		Gui, ARG: NEW
		Gui, ARG: +LastFound +HwndhARG +Resize -DPIScale
		Gui, ARG: Margin, 0, 0
		;Gui, ARG: Color, 172842
	;-: --------------------------------------
	;-: Logo and Backgroundcolouring
	;-: --------------------------------------
		Gui, ARG: Add, Progress        	, % "x0 y0 w" (GuiW) " h" (Logo.height + 5) " c172842 Disabled vBGColorLogo" , 100
		Gui, ARG: Add, Pic                	, % "x10 y10 BackgroundTrans"  	, % "HBITMAP: " logo.hBitmap
		Gui, ARG: Add, Progress        	, % "x" (logo.width + 10) " y0 w2 h" (Logo.height + 5) , 100
		Gui, ARG: Font, S7 CWhite q5, Normal
		Gui, ARG: Add, Text	                , % "x" (Logo.width - 201) " y6 w200 Right vStats2 BackgroundTrans"                   	, % ""
		Gui, ARG: Font, S7 c9090FF q5, Normal
		Gui, ARG: Add, Text	                , % "x" (Logo.width - 201) " y+0 w200 Right vStats1 BackgroundTrans"                	, % ""
	;-: --------------------------------------
	;-: temp. text controls
	;-: --------------------------------------
		Gui, ARG: Font, S12 CWhite q5, Normal
		Gui, ARG: Add, Text	                , % "x" (Logo.width + 30) " y20 vField1 BackgroundTrans"                                  	, % "  . . . . . create index: "
		GuiControlGet, Field_, ARG: Pos, Field1
		Gui, ARG: Add, Text              	, % "x" (Field_X + Field_W + 3) " y20 w300 vField2 Center BackgroundTrans "    	, % "00.00.000001"
	;-: --------------------------------------
	;-: Edit control for search patterns
	;-: --------------------------------------
		SW:= Logo.width + 20
		Gui, ARG: Font, S10 Normal CBlack q5, Normal
		Gui, ARG: Add, DDL             	, % "x" (SW) " y50 vSMode HWNDhSAlgo E0x4000"                                       	, % "Basic|RegEx"				;E0x4000
		GuiControl, ChooseString, SMode, % SearchMode
		Gui, ARG: Font, S11 Italic CAAAAAA q5, Normal
		GuiControlGet, SA_, ARG: Pos, SMode
		Gui, ARG: Add, Edit              	, % "x" (SW+SA_W+5) " y50 w500 r1 vLVExpression HWNDhSearch -Theme"          	, % "type your search pattern here"
		GuiControlGet, LVExpression_, ARG: Pos, LVExpression
		PostMessage, 0x153, -1, % LVExpression_H - 5,, ahk_id %hSAlgo%  ; sets the height of DDL
		Gui, ARG: Font, S16 Normal CWhite q5, Normal
		Gui, ARG: Add, Text             	, % "x" (SW) " y5   w300 h40 vGB1    HWNDhGB1 Border BackgroundTrans"        	, % ""
		Gui, ARG: Add, Text             	, % "x" (SW + 10) " y12 w300 h30 vField3 HWNDhField3 -Wrap BackgroundTrans"	, % ""
		Edit_SetMargins(hField3, 40, 20)
		Edit_SetMargins(hSearch, 20, 20)
		;CTLCOLORS.Attach(hSAlgo, "677892")
	;-: --------------------------------------
	;-: Functions Listview
	;-: --------------------------------------
		Gui, ARG: Font, S9 Normal CDefault q5, Normal
		Gui, ARG: Add, Listview        	, % "xm y" (Logo.height + 15) " w" GuiW+5 " r15 HWNDhLVFunc vLVFunc gShowFunction AltSubmit Section", main section|function name|short description|function nr.
		Gui, ARG: Font, S8 CDefault q5, Normal
		GuiControlGet, LV_, ARG: Pos, LVFunc
	;-: --------------------------------------
	;-: Short description section
	;-: --------------------------------------
		Gui, ARG: Add, Edit                	, % "xm y" (LV_Y + LV_H + 10) " w" SR1Width " r20 t8 HWNDhShowRoom1 vShowRoom1"
		GuiControlGet, SR_, ARG: Pos, ShowRoom1
	;-: --------------------------------------
	;-: Code highlighted RichEdit control
	;-: --------------------------------------
		Gui, ARG: Add, Tab              	,        % "x" (SR1Width+5) " y" (LV_Y+LV_H+10) " w" (GuiW-SR1Width-5) " h" SR_H-10 " HWNDhTabs vShowRoom2", FUNCTION CODE|EXAMPLE(s)|DESCRIPTION
		Gui, ARG: Tab, 1
		RC[1] := new RichCode(Settings, "ARG", "x" (SR1Width+5) " y" (LV_Y+LV_H+30) " w" (GuiW-SR1Width-5) " h" SR_H-30, 0)
		Gui, ARG: Tab, 2
		RC[2] := new RichCode(Settings, "ARG", "x" (SR1Width+5) " y" (LV_Y+LV_H+30) " w" (GuiW-SR1Width-5) " h" SR_H-30, 0)
		Gui, ARG: Tab, 3
		RC[3] := new RichCode(Settings, "ARG", "x" (SR1Width+5) " y" (LV_Y+LV_H+30) " w" (GuiW-SR1Width-5) " h" SR_H-30, 0)
		Gui, ARG: Tab
		WinRC := GetWindowInfo(RC[1].Hwnd)
	;-: --------------------------------------
	;-: Create a Statusbar - on Win 10 this Gui looks weird without a border
	;-: --------------------------------------
		Gui, ARG: Add, StatusBar, % "x0 y" WinRC.WindowY + 2 " vSB",
		GuiControlGet, SB_, ARG: Pos, SB
	;-: --------------------------------------
	;-: Create a ToolTip control
	;-: --------------------------------------
		TT := New GuiControlTips(HARG)
		TT.SetDelayTimes(500, 3000, -1)
		Loop, 3
			TT.Attach(RC[A_Index].Hwnd, "Press the right`nmouse button`nto copy the text.", True)
	;-: --------------------------------------
	;-: Show the gui
	;-: --------------------------------------
		If !Instr(GuiOptions, "Error") && !(GuiOptions = "")
		{
				DPIFactor:= screenDims().DPI / 96
				If (GuiOptions.1 + GuiOptions.3)> A_ScreenWidth || (GuiOptions.2 + GuiOptions.4) > A_ScreenHeight
					Gui, ARG: Show, AutoSize xCenter yCenter, AHK-Rare_TheGui
				else
					Gui, ARG: Show, % "x" GuiOptions.1 " y" GuiOptions.2 " w" (GuiOptions.3) " h" (GuiOptions.4), AHK-Rare_TheGui
		}
		else
				Gui, ARG: Show, AutoSize xCenter yCenter, AHK-Rare_TheGui


		OnMessage(0x200, "OnMouseHover")
		OnMessage(0x03, "ChangeStats")
		SetTimer, ShowStats, -500

;}

;{04. generate and fill listview with data

	; indexing AHK-Rare
		ARData:= RareIndexer(ARFile)
	; remove text controls
		GuiControl, ARG: Hide 	, Field1
		GuiControl, ARG: Hide 	, Field2
		GuiControl, ARG: Show	, Field3
	; populate listview with data from AHK-Rare.txt
		GuiControl, +Default, ARG: LVFunc
		For i, function in ARData
			LV_Add("", function.mainsection, function.name, function.short, function.FnHash), fc:= A_Index
	; show's the sum of functions
		GuiControl, Text, Field3, % "displayed functions: " fc

;}

;{05. Hotkey(s)


	; RButton for getting text to clipboard
		Hotkey, IfWinActive, % "ahk_id " hARG
		Hotkey, ~RButton	, CopyTextToClipboard
		Hotkey, ^f           	, FocusSearchField
		Hotkey, ^s           	, FocusSearchField

	; Listview Hotkey's
		ListviewIsFocused:= Func("ControlIsFocused").Bind("SysListview321")
		Hotkey, If             	, % ListviewIsFocused
		Hotkey, ~Up           	, ListViewUp
		Hotkey, ~Down      	, ListViewDown

	; Edit Hotkey's
		SearchIsFocused:= Func("ControlIsFocused").Bind("Edit1")
		Hotkey, If             	, % SearchIsFocused
		Hotkey, ~Enter    	, GoSearch
		Hotkey, If

		Hotkey, ^#!r        	, ReloadScript

return
;}

;--------------------------------------------------------------------------------------------------------------

;{06. Gui-Labels
;--------------------------------------------------------------------------------------------------------------
ShowFunction:                 	;{

	toshow  	 := []
	selRow:= LV_GetNext(0)

	ShowFunctionsOnUpDown:
	LV_GetText(fnr, selRow , 4)

	For i, function in ARData
		If Instr(function.FnHash, fnr)
				break

	; adding informations to Edit-Control (ShowRoom1)
		toshow[1]:= "FUNCTION:`n"                    	ARData[i].name
		toshow[1].= "`n-----------------------------------------------------------------`n"
		toshow[1].= "SHORT DESCRIPTION:`n"    	ARData[i].short
		toshow[1].= "`n-----------------------------------------------------------------`n"
		toshow[1].= "MAIN SECTION:`n"            	ARData[i].mainsection
		toshow[1].= "`n-----------------------------------------------------------------`n"
		toshow[1].= "MAIN SECTION DESC.:`n"  	ARData[i].mainsectionDescription
		toshow[1].= "`n-----------------------------------------------------------------`n"
		toshow[1].= "SUB SECTION:`n"                	ARData[i].subsection
		toshow[1].= "`n-----------------------------------------------------------------`n"
		GuiControl, ARG:, ShowRoom1, % toshow[1]

	; populate function code tab and examples  tab
		RC[1].Settings.Highlighter := "HighlightAHK"
		RC[1].Value := ARData[i].code
		If StrLen(ARData[i].examples) > 0
		{
				HighlightTab(hTabs, 1, 1)
				RC[2].Settings.Highlighter := "HighlightAHK"
				RC[2].Value := ARData[i].examples
		}
		else
		{
				HighlightTab(hTabs, 1, 0)
				RC[2].Value := ""
		}

	; reading data from the function included description section
		toshow[2]:=""
		If IsObject(ARData[i]["Description"])
		{
				 For descKey, Text in ARData[i]["Description"]
				{
						If descKey
							toshow[2].= Format("{:U}", Trim(descKey)) ":`n"
						else
							continue
						Text:= StrReplace(Text, "`n`r`n`r", "`n")
						Text:= StrReplace(Text, "`r`n`r`n", "`n")
						Loop, 5
							Text	:= StrReplace(Text, SubStr("`t`t`t`t`t`t`t`t", 7 - A_Index) , A_Tab)
						Loop, Parse, Text, `n
							toshow[2].= Rtrim(A_LoopField, ",") "`n"
						;toshow[2].= "-----------------------------------------------------------------`n`n"
				}
				If StrLen(toshow[2])> 0
				{
						HighlightTab(hTabs, 2, 1)
					; populate the description Tab
						RC[3].Value := toshow[2]
						RC[3].Settings.Highlighter := "HighlightAHK"
				}
				else
				{
						HighlightTab(hTabs, 2, 0)
						RC[3].Value := ""
				}
		}

	; highlight search terms
		If highlight
		{
				RE_FindTextAndSelect(RC[1].Hwnd, LVExpression, {1:"Down"})
		}
return
;}
;--------------------------------------------------------------------------------------------------------------
GoSearch:                       	;{

		Gui, Arg: Submit, NoHide
		If StrLen(LVExpression) = 0
				return

		foundIndex:= 0
		GuiControl, ARG:Focus, LVFunc

		results:= RareSearch(LVExpression, ARData, ARFile, SMode)
		If results.MaxIndex() > 0
		{
			; fill listview with collection
				highlight:= true				; flag to highlight searchtearms in RichEdit code
				Gui, ARG: Default
				LV_Delete()
				GuiControl, ARG: -Redraw, LVFunc
				Loop, % results.MaxIndex()
				{
					foundIndex:= Results[A_Index]
					For i, function in ARData
						If Instr(function.FnHash, foundIndex)
							LV_Add("", function.mainsection, function.name, function.short, function.FnHash)
				}
				GuiControl, ARG: +Redraw, LVFunc
				GuiControl, Text, Field3, % "Search result: " results.MaxIndex() " functions"
		}
		else
		{
				highlight:= false
				GuiControl, Text, Field3, % "Search result: nothing matched"
		}

return ;}
;--------------------------------------------------------------------------------------------------------------
ARGGuiSize:                    	;{

	Critical, Off
	Critical
	GuiControl, ARG: Move, BGColorLogo	, % "w" (A_GuiWidth)
	GuiControl, ARG: Move, LVExpression	, % "w" (A_GuiWidth - Logo.width - 32 - SA_W)
	GuiControl, ARG: Move, GB1           		, % "w" (A_GuiWidth - Logo.width - 30) " h40 y5"
	GuiControl, ARG: Move, Field3            	, % "w" (A_GuiWidth - Logo.width - 40) " h30"
	GuiControl, ARG: Move, LVFunc          	, % "w" (A_GuiWidth) ;" h"(A_GuiHeight//3)
	GuiControlGet, LV_, ARG: Pos, LVFunc
	LV_AutoColumSizer(hLVFunc, "10% 15% 60%")
	GuiControl, ARG: Move, ShowRoom1 	, % "y" (LV_Y+LV_H+10)                                                                                 " h" (A_GuiHeight-LV_Y-LV_H-10-SB_H)
	GuiControl, ARG: Move, ShowRoom2 	, % "x" (SR1Width+5) " y" (LV_Y+LV_H+10) " w" (A_GuiWidth-SR1Width-5) " h" (A_GuiHeight-LV_Y-LV_H-10-SB_H)
	GuiControl, ARG: Move, % RC[1].hwnd	, % "x" (SR1Width+5) " y" (LV_Y+LV_H+30) " w" (A_GuiWidth-SR1Width-5) " h" (A_GuiHeight-LV_Y-LV_H-30-SB_H)
	GuiControl, ARG: Move, % RC[2].hwnd	, % "x" (SR1Width+5) " y" (LV_Y+LV_H+30) " w" (A_GuiWidth-SR1Width-5) " h" (A_GuiHeight-LV_Y-LV_H-30-SB_H)
	GuiControl, ARG: Move, % RC[3].hwnd	, % "x" (SR1Width+5) " y" (LV_Y+LV_H+30) " w" (A_GuiWidth-SR1Width-5) " h" (A_GuiHeight-LV_Y-LV_H-30-SB_H)
	GuiControl, ARG: Move, SB                	, % "x" 0 " y" (A_GuiHeight - SB_H) " w" (A_GuiWidth)
	Critical, Off
	SetTimer, ShowStats, -200

return ;}
;--------------------------------------------------------------------------------------------------------------
ARGGuiClose:                  	;{
ARGEscape:

	Gui, Arg: Submit, NoHide
	win := GetWindowInfo(hARG)
	IniWrite, % SMode, % A_ScriptDir "\AHK-Rare.ini", Properties, SearchMode
	IniWrite, % win.WindowX "|" win.WindowY "|" (win.ClientW) "|" (win.ClientH), % A_ScriptDir "\AHK-Rare.ini", Properties, GuiOptions

ExitApp ;}
;--------------------------------------------------------------------------------------------------------------
ShowStats:                       	;{

	WinGetPos, wx, wy, ww, wh, % "ahk_id " hARG
	GuiControl, ARG:, Stats2, % "x" wx "  y" wy "  w" ww "  h" wh " (Logo: w" Logo.width "  h" Logo.height ")"

return
ChangeStats() {

	WinGetPos, wx, wy, ww, wh, % "ahk_id " hARG
	GuiControl, ARG:, Stats2, % "x" wx "  y" wy "  w" ww "  h" wh

}
;}
;--------------------------------------------------------------------------------------------------------------
CopyTextToClipboard:     	;{

	toCopy := ""
	MouseGetPos, mx, my,, hControlOver, 2
	RichEditControls:= RC.1 "," RC.2 "," RC.3
	If Instr(hControlOver, hTabs) || hControlOver in %RichtEditControls%
	{
			Loop, Parse, AhkRare, `n, `r
			{
					If (A_Index >= ARData[i].start) && (A_Index <= ARData[i].end)
							tocopy .= A_LoopField "`n"
					else if (A_Index > ARData[i].end)
							break
			}
			Clipboard := tocopy
			ToolTip, % "copied to clipboard...", % mx -10, % my + 10, 2
			SetTimer, TTOff, -4000
	}

return

TTOff:
	ToolTip,,,, 2
return ;}
;--------------------------------------------------------------------------------------------------------------
FocusSearchField:            	;{
	GuiControl, ARG: Focus, LVExpression
return ;}
;--------------------------------------------------------------------------------------------------------------
ListViewUp:
ListViewDown:                 	;{

	If !WinActive("AHK-Rare_TheGui ahk_class AutoHotkeyGUI")
			return
	If Instr(A_ThisLabel, "ListViewUp")
			Send, {Up}
	else
			Send, {Down}

	selRow:= LV_GetNext("F")
	gosub ShowFunctionsOnUpDown

return ;}
;--------------------------------------------------------------------------------------------------------------
ReloadScript:                   	;{	only for reloading the script after hotkey press (development purposes)
	Reload
return ;}

;}

;{07. AHK Rare Gui Functions

RareSearch(LVExpression, ARData, ARFile, mode:="RegEx") {               	;-- search all AHK Rare functions

		results:= Array()

	; collecting all results
	Loop, % ARFile.MaxIndex()
	{
			If RegExMatch(ARFile[A_Index], "(;\s*\<\d\d\.\d\d\.\d\d\d\d\d)|(;\s*\<\d\d\.\d\d\.\d\d.\d\d\d\d\d)")
			{
					RegExMatch(ARFile[A_Index], "[\d\.]+", FnHash)
					found:= 0
					continue
			}

			If (found = 0)
				If Instr(mode, "RegEx") && RegExMatch(ARFile[A_Index], LVExpression)
					results.Push(FnHash), found:= 1
				else if Instr(mode, "Basic") && Instr(ARFile[A_Index], LVExpression)
					results.Push(FnHash), found:= 1
	}

return results
}

RareLoad(FileFullPath) {                                                                       	;-- loads AHK Rare as an indexed array

	ARFile:= Array()

	FileRead, filestring, % FileFullPath
	Loop, Parse, filestring, `n, `r
		ARFile[A_Index]:= A_LoopField, i:= A_Index

	ARFile[i+1]:= FileFullPath

return ARFile
}

RareSave(ARFile) {                                                                               	;-- save back changes to AHK Rare

	filepath:= ARFile[ARFile.MaxIndex()]
	File:= FileOpen(filepath, "w")
	Loop, % ARFile.MaxIndex() - 1
		File.WriteLine(ARFile[A_Index])
	File.Close()

return Errorlevel
}

RareIndexer(ARFile) {                                                                           	;-- list all functions inside AHK RARE script

	; defining some variables
		ARData:= Object(), ARData.DescriptionKeys := Object()
		s:=fI:=descFlag:=descKeyFlag:=descKeyFlagO :=0
		Brackets             	:= 0                                                         	; counter to find the end of a function
		DoBracketCount	:= 0                                                        	; flag
		FirstBracket      	:= 0                                                        	; flag
		originchange    	:= 0                                                         ; counter for changed lines in AHKRare.ahk - Autosyntax correcting functionality

	; parsing algorithm for AHK-Rare
		Loop, % ARFile.MaxIndex() - 1
		{
			line:= ARFile[A_Index]
			If (DoBracketCount = 1) && !descflag && !exampleFlag                                                                                                                                              	; to find the last bracket of a function
			{
					Brackets += BracketCount(line)
					If (Brackets > 0) && (FirstBracket = 0)
						FirstBracket:= 1
			}

			If RegExMatch(line, "(?<=\{\s;)[\w\s-\+\/\(\)]+(?=\(\d+\))")                                                                                                                                         	; name of mainsection
			{
						RegExMatch(line, "(?<=\{\s;)[\w\s-\+\/\(\)]+(?=\(\d+\))", mainsection)
						mainsection	:= Trim(mainsection)
						subsection	:= ""
						RegExMatch(line, "(?<=--\s)[\w\s]+(?=\s--)", MainSectionDescription)
						descFlag:=descKeyFlag:=descKeyFlagO:=TrailingSpacesO:=TrailingSpaces := 0
						continue
			}
			else If RegExMatch(line, "(?<=\{\s;)\<\d\d\.\d\d[\d\.]*\>\:\s[\w\-\_\+\/\(\)]+")                                                                                                              	; name of subsection
			{
						RegExMatch(line, "(?<=\>\:\s)[\w\-\_\s\+\/]+", subsection)
						subsection:= Trim(subsection)
						continue
			}
			else If RegExMatch(line, "(;\s*\<\d\d\.\d\d\.\d\d\d\d\d)|(;\s*\<\d\d\.\d\d\.\d\d.\d\d\d\d\d\d)")                                                                                 	; new function
			{
				; ---------------------------------------------------------------------------------------------------------------------------------------------------------
				; last data from previous function will be stored
				; --------------------------------------------------------------------------------------------------------------------------------------------------------- ;{

				; if function boundaries are not set proper, e.g. missing function index at the end of a function or mispellings between start index and end index
				/*
					If (ARData[(fI)].end = "")
					{
							i:= A_Index
							While, (i > 0)
								If RegExMatch(ARFile[i:= i - 1], "^\s*\}")
								{
										ARData[(fI)].end := i
										RegExMatch(ARFile[i], "^\s*\}", prepend)
										RegExMatch(ARFile[i], "\s*\}\s*[;<\d./>]*\s*(.*)", append)
										ARFile[i] := prepend " `;<`/" ARData[(fI)].FnHash ">" (StrLen(append1) > 0 ? " " append1 : "")
										originchange ++
										break
								}
					}
				*/

					RegExmatch(ARFile[(ARData[(fI)].start)-1],"[\d\.]+", startIndex)
					RegExmatch(ARFile[(ARData[(fI)].end)], "[\d\.]+", endIndex)
					If (startIndex <> endIndex)
					{
							i:= ARData[(fI)].end
							RegExMatch(ARFile[i], "^\s*\}", prepend)
							RegExMatch(ARFile[i], "\s*\}\s*[;<\d./>]*\s*(.*)", append)
							ARFile[i] := prepend " `;<`/" ARData[(fI)].FnHash ">" (StrLen(append1) > 0 ? " " append1 : "")
							originchange ++
							origin .= i "(" A_Index "), "
					}

				; close the last function code to have a right syntax
					ARData[(fI)].code     	:=   Trim(ARData[(fI)].code, "`n")
					ARData[(fI)].code     	:=   Trim(ARData[(fI)].code, "`r")
					If !RegExMatch(ARData[(fI)].code, "m)\}\s*\;\<\/[\d\.]+\>\s*") && !RegExMatch(ARData[(fI)].code, "m)\n\s*\}\s*$")
							ARData[(fI)].code     	.= "`n}"

				; shorten example code
					ARData[(fI)].examples :=    Trim(ARData[(fI)].examples, "`n`r")
					Loop, 5                                                                                                 	; deletes up 2 empty lines
					{
							ARData[(fI)].examples 	:= StrReplace(ARData[(fI)].examples	, SubStr("`n`n`n`n`n`n`n`n`n", 1, 8 - A_Index), "`n")
							ARData[(fI)].code      	:= StrReplace(ARData[(fI)].code       	, SubStr("`n`n`n`n`n`n`n`n`n", 1, 8 - A_Index), "`n")
					}
					ARData[(fi)]["description"][(descKey)] := RTrim(ARData[(fi)]["description"][(descKey)], "`n")

				;}

				; ---------------------------------------------------------------------------------------------------------------------------------------------------------
				; data collecting for a new function starts here
				; --------------------------------------------------------------------------------------------------------------------------------------------------------- ;{
					FirstBracket:= descFlag:=descKeyFlag:=descKeyFlagO:=TrailingSpacesO:=TrailingSpaces:=NoCode:= 0       	; re-initialize flags
					RegExMatch(line, "[\d\.]+", FnHash)                                                                                                                 	; gets the function hash
					fi ++                                                                                                                                                                   	; function index (fi) enumerator
					ARData[(fI)]                                                   	:= Object()
					ARData[(fi)].description                                	:= Object()
					ARData[(fI)].FnHash                                       	:= FnHash
					ARData[(fI)].start                                          	:= A_Index+1
					ARData[(fI)].mainsection                              	:= mainsection
					ARData[(fI)].mainsectionDescription           	:= mainsectionDescription
					ARData[(fI)].subsection                                	:= subsection

					GuiControl, Text, Field2, % fI ", " fname "`)"
					continue
				;}
			}
			else If RegExMatch(line, "^\s*\}\s*\;\s*\<\/") || ((DoBracketCount = 1) && (FirstBracket = 1) && (Brackets = 0))                                                        	; function end
			{
					ARData[(fI)].end  := A_Index
					descFlag           	:= 0
					NoCode           	:= 1
					Brackets				:= 0
					FirstBracket			:= 0
					DoBracketCount	:= 0
			}
			else If RegExMatch(line, "[\w\_-]+\([\w\d\s\,\=\.\*#-|\:\""""]*\)\s*\{\s+;--.*") || RegExMatch(line, "[\w\_-]+\([\w\d\s\,\=\.\*#-|\:\""""]*\s*;--.*")          	; find function
			{
					;TrailingSpaces:= countTrailingSpaces(line)
					RegExMatch(line, "^\s*", trailing)
					RegExMatch(line, "[\w\_-\d]+\(", fname)
					RegExMatch(line, "(?<=;--).*", fshort)
					ARData[(fI)].name         	:= Trim(fname) "`)"
					ARData[(fI)].short         	:= Trim(fshort)
					ARData[(fI)].subsection	:= subsection
					ARData[(fI)].code         	:= RegExReplace(line, "^" trailing) "`n"
					Brackets                       	:= BracketCount(line)
					DoBracketCount          	:= 1
			}
			else if RegExMatch(line, "i).*DESCRIPTION\s")                                                                                                                                                             	; description section
			{
					exampleFlag:= 0
					descFlag:= 1
					descKey:= Text:= ""
					continue
			}
			else if RegExMatch(line, ".*(EXAMPLE\(s\))|(EXAMPLES)|(\/\*\s*Example)")                                                                                                                    	; example section
			{
					exampleFlag:= 1
					descFlag:= 0
					descKey:= Text:= ""
					continue
			}
			else if ( descFlag = 1 || exampleFlag = 1) && (Instr(line, "--------------") || Instr(line, "========================"))                                 	; ignores specific internal layout lines
					continue
			else if ( descFlag = 1 || exampleFlag = 1) && RegExMatch(line, "\*\/")                                                                                                                          	; end of descriptions or examples section
			{
					exampleFlag:= descFlag:= descKeyFlag:= exampleIndent := 0
					descKey:=""
					continue
			}
			else if (descFlag = 1) && RegExMatch( line, "^\s+[\w\(\)-\s]+(?=\s+\:\s+|\N)" )                                                                                                           	; description key is found
			{
				; ---------------------------------------------------------------------------------------------------------------------------------------------------------
				; the formatting of the AHK-Rare.txt file creates difficulties in distinguishing the description key from the associated text
				; ---------------------------------------------------------------------------------------------------------------------------------------------------------
					TrailingSpaces:=  countTrailingSpaces(line)
					If TrailingSpacesO && (TrailingSpaces >= (TrailingSpacesO + 1))
					{
							ARData[(fi)]["description"][(descKey)] .= LTrim(line) "`n"
							continue
					}

					descKeyFlagO := descKeyFlag
					descKeyFlag ++

					RegExMatch(line, "^\s+[\w\(\)-\s]+(?=\s+:\s+)", descKey)                                                                               	  ; determines the description key
					descKey:= Trim(descKey)

					If !ARData.DescriptionKeys.HasKey(descKey)                                                                          	  ; collecting available keys for search function
							ARData.DescriptionKeys[(descKey)].Push(FnHash "|")

					RegExMatch(line, "(?<=\:).*", Text)                                                                                  	 ; determines the corresponding text of the description
					ARData[(fi)]["description"][(descKey)] := LTrim(Trim(Text), "`n`r") "`n"

					TrailingSpacesO := TrailingSpaces
			}
			else if (descFlag = 1) && (descKeyFlag > descKeyFlagO)                                                                                                                                              	; adding descriptions
					ARData[(fi)]["description"][(descKey)] .= LTrim(line) "`n"
			else if (exampleFlag = 1)                                                                                                                                                                                               	; parsing example section
			{
					If !exampleIndent && StrLen(line) >= 2
							exampleIndent := countTrailingSpaces(line)
					If (StrLen(line) <= 2 && StrLen(ARData[(fI)].examples) <= 2) || (StrLen(line) >= 2)
							ARData[(fI)].examples 	.= SubStr(line, exampleIndent +1, StrLen(line) - exampleIndent) "`n"
			}
			else  if (NoCode = 0)                                                                                                                                                                                                      	; if nothing fits it is program code
			{
					ARData[(fI)].code	.= RegExReplace(line, "^" trailing) "`n"
			}
	}

	; this function save's correction made to AHK-Rare code from parsing algorithm before
		If (originchange > 0)
		{
				GuiControl, ARG:, Stats1, % originchange " lines of code corrected"
				RareSave(ARFile)
		}

return ARData
}

BracketCount(str, brackets:="{}") {                                                       	;-- helps to find the last bracket of a function
	RegExReplace(str, SubStr(brackets, 1, 1), "", open)
	RegExReplace(str, SubStr(brackets, 2, 1), "", closed)
return open - closed
}

countTrailingSpaces(str) {                                                                    	;-- counts all leading spaces of a string

	Loop, % StrLen(str)
		If Instr(A_Space "`t", SubStr(str, A_Index, 1))
				TrailingSpaces ++
		else
				Break

return TrailingSpaces
}

;}

;{08. all the  other functions

HighlightAHK(Settings, ByRef Code) {
	static Flow := "break|byref|catch|class|continue|else|exit|exitapp|finally|for|global|gosub|goto|if|ifequal|ifexist|ifgreater|ifgreaterorequal|ifinstring|ifless|iflessorequal|ifmsgbox|ifnotequal|ifnotexist|ifnotinstring|ifwinactive|ifwinexist|ifwinnotactive|ifwinnotexist|local|loop|onexit|pause|return|settimer|sleep|static|suspend|throw|try|until|var|while"
	, Commands := "autotrim|blockinput|clipwait|control|controlclick|controlfocus|controlget|controlgetfocus|controlgetpos|controlgettext|controlmove|controlsend|controlsendraw|controlsettext|coordmode|critical|detecthiddentext|detecthiddenwindows|drive|driveget|drivespacefree|edit|envadd|envdiv|envget|envmult|envset|envsub|envupdate|fileappend|filecopy|filecopydir|filecreatedir|filecreateshortcut|filedelete|fileencoding|filegetattrib|filegetshortcut|filegetsize|filegettime|filegetversion|fileinstall|filemove|filemovedir|fileread|filereadline|filerecycle|filerecycleempty|fileremovedir|fileselectfile|fileselectfolder|filesetattrib|filesettime|formattime|getkeystate|groupactivate|groupadd|groupclose|groupdeactivate|gui|guicontrol|guicontrolget|hotkey|imagesearch|inidelete|iniread|iniwrite|input|inputbox|keyhistory|keywait|listhotkeys|listlines|listvars|menu|mouseclick|mouseclickdrag|mousegetpos|mousemove|msgbox|outputdebug|pixelgetcolor|pixelsearch|postmessage|process|progress|random|regdelete|regread|regwrite|reload|run|runas|runwait|send|sendevent|sendinput|sendlevel|sendmessage|sendmode|sendplay|sendraw|setbatchlines|setcapslockstate|setcontroldelay|setdefaultmousespeed|setenv|setformat|setkeydelay|setmousedelay|setnumlockstate|setregview|setscrolllockstate|setstorecapslockmode|settitlematchmode|setwindelay|setworkingdir|shutdown|sort|soundbeep|soundget|soundgetwavevolume|soundplay|soundset|soundsetwavevolume|splashimage|splashtextoff|splashtexton|splitpath|statusbargettext|statusbarwait|stringcasesense|stringgetpos|stringleft|stringlen|stringlower|stringmid|stringreplace|stringright|stringsplit|stringtrimleft|stringtrimright|stringupper|sysget|thread|tooltip|transform|traytip|urldownloadtofile|winactivate|winactivatebottom|winclose|winget|wingetactivestats|wingetactivetitle|wingetclass|wingetpos|wingettext|wingettitle|winhide|winkill|winmaximize|winmenuselectitem|winminimize|winminimizeall|winminimizeallundo|winmove|winrestore|winset|winsettitle|winshow|winwait|winwaitactive|winwaitclose|winwaitnotactive"
	, Functions := "abs|acos|array|asc|asin|atan|ceil|chr|comobjactive|comobjarray|comobjconnect|comobjcreate|comobject|comobjenwrap|comobjerror|comobjflags|comobjget|comobjmissing|comobjparameter|comobjquery|comobjtype|comobjunwrap|comobjvalue|cos|dllcall|exception|exp|fileexist|fileopen|floor|func|getkeyname|getkeysc|getkeystate|getkeyvk|il_add|il_create|il_destroy|instr|isbyref|isfunc|islabel|isobject|isoptional|ln|log|ltrim|lv_add|lv_delete|lv_deletecol|lv_getcount|lv_getnext|lv_gettext|lv_insert|lv_insertcol|lv_modify|lv_modifycol|lv_setimagelist|mod|numget|numput|objaddref|objclone|object|objgetaddress|objgetcapacity|objhaskey|objinsert|objinsertat|objlength|objmaxindex|objminindex|objnewenum|objpop|objpush|objrawset|objrelease|objremove|objremoveat|objsetcapacity|onmessage|ord|regexmatch|regexreplace|registercallback|round|rtrim|sb_seticon|sb_setparts|sb_settext|sin|sqrt|strget|strlen|strput|strsplit|substr|tan|trim|tv_add|tv_delete|tv_get|tv_getchild|tv_getcount|tv_getnext|tv_getparent|tv_getprev|tv_getselection|tv_gettext|tv_modify|tv_setimagelist|varsetcapacity|winactive|winexist|_addref|_clone|_getaddress|_getcapacity|_haskey|_insert|_maxindex|_minindex|_newenum|_release|_remove|_setcapacity"
	, Keynames := "alt|altdown|altup|appskey|backspace|blind|browser_back|browser_favorites|browser_forward|browser_home|browser_refresh|browser_search|browser_stop|bs|capslock|click|control|ctrl|ctrlbreak|ctrldown|ctrlup|del|delete|down|end|enter|esc|escape|f1|f10|f11|f12|f13|f14|f15|f16|f17|f18|f19|f2|f20|f21|f22|f23|f24|f3|f4|f5|f6|f7|f8|f9|home|ins|insert|joy1|joy10|joy11|joy12|joy13|joy14|joy15|joy16|joy17|joy18|joy19|joy2|joy20|joy21|joy22|joy23|joy24|joy25|joy26|joy27|joy28|joy29|joy3|joy30|joy31|joy32|joy4|joy5|joy6|joy7|joy8|joy9|joyaxes|joybuttons|joyinfo|joyname|joypov|joyr|joyu|joyv|joyx|joyy|joyz|lalt|launch_app1|launch_app2|launch_mail|launch_media|lbutton|lcontrol|lctrl|left|lshift|lwin|lwindown|lwinup|mbutton|media_next|media_play_pause|media_prev|media_stop|numlock|numpad0|numpad1|numpad2|numpad3|numpad4|numpad5|numpad6|numpad7|numpad8|numpad9|numpadadd|numpadclear|numpaddel|numpaddiv|numpaddot|numpaddown|numpadend|numpadenter|numpadhome|numpadins|numpadleft|numpadmult|numpadpgdn|numpadpgup|numpadright|numpadsub|numpadup|pause|pgdn|pgup|printscreen|ralt|raw|rbutton|rcontrol|rctrl|right|rshift|rwin|rwindown|rwinup|scrolllock|shift|shiftdown|shiftup|space|tab|up|volume_down|volume_mute|volume_up|wheeldown|wheelleft|wheelright|wheelup|xbutton1|xbutton2"
	, Builtins := "base|clipboard|clipboardall|comspec|errorlevel|false|programfiles|true"
	, Keywords := "abort|abovenormal|activex|add|ahk_class|ahk_exe|ahk_group|ahk_id|ahk_pid|all|alnum|alpha|altsubmit|alttab|alttabandmenu|alttabmenu|alttabmenudismiss|alwaysontop|and|autosize|background|backgroundtrans|base|belownormal|between|bitand|bitnot|bitor|bitshiftleft|bitshiftright|bitxor|bold|border|bottom|button|buttons|cancel|capacity|caption|center|check|check3|checkbox|checked|checkedgray|choose|choosestring|click|clone|close|color|combobox|contains|controllist|controllisthwnd|count|custom|date|datetime|days|ddl|default|delete|deleteall|delimiter|deref|destroy|digit|disable|disabled|dpiscale|dropdownlist|edit|eject|enable|enabled|error|exit|expand|exstyle|extends|filesystem|first|flash|float|floatfast|focus|font|force|fromcodepage|getaddress|getcapacity|grid|group|groupbox|guiclose|guicontextmenu|guidropfiles|guiescape|guisize|haskey|hdr|hidden|hide|high|hkcc|hkcr|hkcu|hkey_classes_root|hkey_current_config|hkey_current_user|hkey_local_machine|hkey_users|hklm|hku|hotkey|hours|hscroll|hwnd|icon|iconsmall|id|idlast|ignore|imagelist|in|insert|integer|integerfast|interrupt|is|italic|join|label|lastfound|lastfoundexist|left|limit|lines|link|list|listbox|listview|localsameasglobal|lock|logoff|low|lower|lowercase|ltrim|mainwindow|margin|maximize|maximizebox|maxindex|menu|minimize|minimizebox|minmax|minutes|monitorcount|monitorname|monitorprimary|monitorworkarea|monthcal|mouse|mousemove|mousemoveoff|move|multi|na|new|no|noactivate|nodefault|nohide|noicon|nomainwindow|norm|normal|nosort|nosorthdr|nostandard|not|notab|notimers|number|off|ok|on|or|owndialogs|owner|parse|password|pic|picture|pid|pixel|pos|pow|priority|processname|processpath|progress|radio|range|rawread|rawwrite|read|readchar|readdouble|readfloat|readint|readint64|readline|readnum|readonly|readshort|readuchar|readuint|readushort|realtime|redraw|regex|region|reg_binary|reg_dword|reg_dword_big_endian|reg_expand_sz|reg_full_resource_descriptor|reg_link|reg_multi_sz|reg_qword|reg_resource_list|reg_resource_requirements_list|reg_sz|relative|reload|remove|rename|report|resize|restore|retry|rgb|right|rtrim|screen|seconds|section|seek|send|sendandmouse|serial|setcapacity|setlabel|shiftalttab|show|shutdown|single|slider|sortdesc|standard|status|statusbar|statuscd|strike|style|submit|sysmenu|tab|tab2|tabstop|tell|text|theme|this|tile|time|tip|tocodepage|togglecheck|toggleenable|toolwindow|top|topmost|transcolor|transparent|tray|treeview|type|uncheck|underline|unicode|unlock|updown|upper|uppercase|useenv|useerrorlevel|useunsetglobal|useunsetlocal|vis|visfirst|visible|vscroll|waitclose|wantctrla|wantf2|wantreturn|wanttab|wrap|write|writechar|writedouble|writefloat|writeint|writeint64|writeline|writenum|writeshort|writeuchar|writeuint|writeushort|xdigit|xm|xp|xs|yes|ym|yp|ys|__call|__delete|__get|__handle|__new|__set"
	, Needle :="
	(LTrim Join Comments
		ODims)
		((?:^|\s);[^\n]+)                	; Comments
		|(^\s*\/\*.+?\n\s*\*\/)      	; Multiline comments
		|((?:^|\s)#[^ \t\r\n,]+)      	; Directives
		|([+*!~&\/\\<>^|=?:
			,().```%{}\[\]\-]+)           	; Punctuation
		|\b(0x[0-9a-fA-F]+|[0-9]+)	; Numbers
		|(""[^""\r\n]*"")                	; Strings
		|\b(A_\w*|" Builtins ")\b   	; A_Builtins
		|\b(" Flow ")\b                  	; Flow
		|\b(" Commands ")\b       	; Commands
		|\b(" Functions ")\b          	; Functions (builtin)
		|\b(" Keynames ")\b         	; Keynames
		|\b(" Keywords ")\b          	; Other keywords
		|(([a-zA-Z_$]+)(?=\())       	; Functions
		|(^\s*[A-Z()-\s]+\:\N)        	; Descriptions
	)"

	GenHighlighterCache(Settings)
	Map := Settings.Cache.ColorMap

	Pos := 1
	while (FoundPos := RegExMatch(Code, Needle, Match, Pos))
	{
		RTF .= "\cf" Map.Plain " "
		RTF .= EscapeRTF(SubStr(Code, Pos, FoundPos-Pos))

		; Flat block of if statements for performance
		if (Match.Value(1) != "")
			RTF .= "\cf" Map.Comments
		else if (Match.Value(2) != "")
			RTF .= "\cf" Map.Multiline
		else if (Match.Value(3) != "")
			RTF .= "\cf" Map.Directives
		else if (Match.Value(4) != "")
			RTF .= "\cf" Map.Punctuation
		else if (Match.Value(5) != "")
			RTF .= "\cf" Map.Numbers
		else if (Match.Value(6) != "")
			RTF .= "\cf" Map.Strings
		else if (Match.Value(7) != "")
			RTF .= "\cf" Map.A_Builtins
		else if (Match.Value(8) != "")
			RTF .= "\cf" Map.Flow
		else if (Match.Value(9) != "")
			RTF .= "\cf" Map.Commands
		else if (Match.Value(10) != "")
			RTF .= "\cf" Map.Functions
		else if (Match.Value(11) != "")
			RTF .= "\cf" Map.Keynames
		else if (Match.Value(12) != "")
			RTF .= "\cf" Map.Keywords
		else if (Match.Value(13) != "")
			RTF .= "\cf" Map.Functions
		else If (Match.Value(14) != "")
			RTF .= "\cf" Map.Descriptions
		else
			RTF .= "\cf" Map.Plain

		RTF .= " " EscapeRTF(Match.Value())
		Pos := FoundPos + Match.Len()
	}

	return Settings.Cache.RTFHeader . RTF . "\cf" Map.Plain " " EscapeRTF(SubStr(Code, Pos)) "\`n}"
}

GenHighlighterCache(Settings) {

	if Settings.HasKey("Cache")
		return
	Cache := Settings.Cache := {}


	; --- Process Colors ---
	Cache.Colors := Settings.Colors.Clone()

	; Inherit from the Settings array's base
	BaseSettings := Settings
	while (BaseSettings := BaseSettings.Base)
		for Name, Color in BaseSettings.Colors
			if !Cache.Colors.HasKey(Name)
				Cache.Colors[Name] := Color

	; Include the color of plain text
	if !Cache.Colors.HasKey("Plain")
		Cache.Colors.Plain := Settings.FGColor

	; Create a Name->Index map of the colors
	Cache.ColorMap := {}
	for Name, Color in Cache.Colors
		Cache.ColorMap[Name] := A_Index


	; --- Generate the RTF headers ---
	RTF := "{\urtf"

	; Color Table
	RTF .= "{\colortbl;"
	for Name, Color in Cache.Colors
	{
		RTF .= "\red"    	Color>>16	& 0xFF
		RTF .= "\green"	Color>>8 	& 0xFF
		RTF .= "\blue"  	Color        	& 0xFF ";"
	}
	RTF .= "}"

	; Font Table
	if Settings.Font
	{
		FontTable .= "{\fonttbl{\f0\fmodern\fcharset0 "
		FontTable .= Settings.Font.Typeface
		FontTable .= ";}}"
		RTF .= "\fs" Settings.Font.Size * 2 ; Font size (half-points)
		if Settings.Font.Bold
			RTF .= "\b"
	}

	; Tab size (twips)
	RTF .= "\deftab" GetCharWidthTwips(Settings.Font) * Settings.TabSize

	Cache.RTFHeader := RTF
}

GetCharWidthTwips(Font) {

	static Cache := {}

	if Cache.HasKey(Font.Typeface "_" Font.Size "_" Font.Bold)
		return Cache[Font.Typeface "_" font.Size "_" Font.Bold]

	; Calculate parameters of CreateFont
	Height	:= -Round(Font.Size*A_ScreenDPI/72)
	Weight	:= 400+300*(!!Font.Bold)
	Face 	:= Font.Typeface

	; Get the width of "x"
	hDC 	:= DllCall("GetDC", "UPtr", 0)
	hFont 	:= DllCall("CreateFont"
					, "Int", Height 	; _In_ int       	  nHeight,
					, "Int", 0         	; _In_ int       	  nWidth,
					, "Int", 0        	; _In_ int       	  nEscapement,
					, "Int", 0        	; _In_ int       	  nOrientation,
					, "Int", Weight ; _In_ int        	  fnWeight,
					, "UInt", 0     	; _In_ DWORD   fdwItalic,
					, "UInt", 0     	; _In_ DWORD   fdwUnderline,
					, "UInt", 0     	; _In_ DWORD   fdwStrikeOut,
					, "UInt", 0     	; _In_ DWORD   fdwCharSet, (ANSI_CHARSET)
					, "UInt", 0     	; _In_ DWORD   fdwOutputPrecision, (OUT_DEFAULT_PRECIS)
					, "UInt", 0     	; _In_ DWORD   fdwClipPrecision, (CLIP_DEFAULT_PRECIS)
					, "UInt", 0     	; _In_ DWORD   fdwQuality, (DEFAULT_QUALITY)
					, "UInt", 0     	; _In_ DWORD   fdwPitchAndFamily, (FF_DONTCARE|DEFAULT_PITCH)
					, "Str", Face   	; _In_ LPCTSTR  lpszFace
					, "UPtr")
	hObj := DllCall("SelectObject", "UPtr", hDC, "UPtr", hFont, "UPtr")
	VarSetCapacity(SIZE, 8, 0)
	DllCall("GetTextExtentPoint32", "UPtr", hDC, "Str", "x", "Int", 1, "UPtr", &SIZE)
	DllCall("SelectObject", "UPtr", hDC, "UPtr", hObj, "UPtr")
	DllCall("DeleteObject", "UPtr", hFont)
	DllCall("ReleaseDC", "UPtr", 0, "UPtr", hDC)

	; Convert to twpis
	Twips := Round(NumGet(SIZE, 0, "UInt")*1440/A_ScreenDPI)
	Cache[Font.Typeface "_" Font.Size "_" Font.Bold] := Twips
	return Twips
}

EscapeRTF(Code) {
	for each, Char in ["\", "{", "}", "`n"]
		Code := StrReplace(Code, Char, "\" Char)
	return StrReplace(StrReplace(Code, "`t", "\tab "), "`r")
}

ControlIsFocused(ControlID) {                                                                  	;-- true or false if specified gui control is active or not

	GuiControlGet, FControlID, ARG:Focus
	If Instr(FControlID, ControlID)
			return true

return false
}

LV_AutoColumSizer(hLV, Sizes, Options:="") {                                         	;-- computes and changes the pixel width of the columns across the full width of a listview

	; PARAMETERS:
	; ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	; Sizes   	- 	this example is for a 4 column listview, for a better understanding it is possible to use a different syntax
	;               	Sizes:= "15%, 18%, 60%" or "15, 18, 60" or "15,18,60" or "15|18|60" or "15% 18% 60%"
	;               	It does not matter which characters or strings you use for subdivision, the little RegEx algorithm recognizes the dividers
	;               	REMARK: !avoid specifying the last column width, this size will be computed!
	;                 	    *		*		*		*		*		*		*		*		*		*		*		*		*		*		*
	; ** todo **	there is also an automatic mode which calculates the column width of the listview over the maximum pixel width of the content of the columns
	;                	you have to use Sizes:= "AutoColumnWidth"
	;
	; ** todo ** Options 	-	can be passed to limit the maximum column width to the maximum pixel width of the column contents
	;                  	or to prevent undersizing of columns

	static hHeader, LVP, hLVO, SizesO
	w:= LVP:= []

	If hLVO <> hLV
			hHeader:= LV_EX_GetHeader(hLV), hLVO:= hLV

	If SizesO <> Sizes
	{
			pos := 1
			If !Instr(Sizes, "AutoColumnWidth")
					While pos:= RegExMatch(Sizes, "\d+", num, StrLen(num)+pos)
							LVP[A_Index] := num
			else
				nin:=1

			LVP_Last := 100

			Loop, % LVP.MaxIndex()
			{
					LVP[A_Index]	:= 	"0" . LVP[A_Index]
					LVP[A_Index]	+=	0
					LVP_Last      	-=	LVP[A_Index]
					LVP[A_Index]	:= 	Round(LVP[A_Index]/100, 2)
			}
			LVP.Push(Round((LVP_Last-1)/100, 2))
			SizesO:= Sizes
	}

	ControlGetPos,,, LV_Width,,, % "ahk_id " hLV
	LV_Width -= DllCall("GetScrollPos", "UInt", hLV, "Int", 1)	;subtracts the width of the vertical scrollbar to get the client size of the listview

	Loop, % LVP.MaxIndex()
		DllCall("SendMessage", "uint", hLV, "uint", 4126, "uint", A_Index-1, "int", Floor(LV_Width * LVP[A_Index])) 	;sets the column width
}

LV_EX_GetHeader(HLV) {                                                                         	;-- Retrieves the handle of the header control used by the list-view control.
   ; LVM_GETHEADER = 0x101F -> http://msdn.microsoft.com/en-us/library/bb774937(v=vs.85).aspx
   SendMessage, 0x101F, 0, 0, , % "ahk_id " . HLV
   Return ErrorLevel
}

LV_EX_GetColumnWidth(HLV, Column) {                                                	;-- gets the width of a column in report or list view.
   ; LVM_GETCOLUMNWIDTH = 0x101D -> http://msdn.microsoft.com/en-us/library/bb774915(v=vs.85).aspx
   SendMessage, 0x101D, % (Column - 1), 0, , % "ahk_id " . HLV
   Return ErrorLevel
}

OnMouseHover(wparam, lparam, msg, hwnd) {                                     	;-- Autofocus for Listview, Edit and RichEdit controls ;{

	static lastFocusedControl

	MouseGetPos,mx, my,, hControlOver
	WinGetClass, cclass, % "ahk_id " hwnd

	;ToolTip, % hControlOver "`n" hWinOver "`n" GetHex(wparam) "`n" GetHex(lparam) "`n" GetHex(msg) "`n" GetHex(hwnd) "`n" cclass
	If RegExMatch(hControlOver, "(Edit)|(SysListView32)|(SysListviewHeader)|(RichEdit)|(ComboBox)")
	{
			If (lastFocusedControl != hControlOver)
			{
					If !Instr(hControlOver, "SysListView32")
						ControlFocus, % hControlOver 	, % "ahk_id " hARG

					ControlGetText, SText, Edit1    	, % "ahk_id " hARG
					If (Trim(SText) = "type your search pattern here") && (hControlOver = "Edit1")
							NormalEditFont()
					else If (Trim(SText) = "") && (hControlOver <> "Edit1")
							ItalicEditFont()
			}
			lastFocusedControl := hControlOver
	}
	else if Instr(cclass, "RichEdit")
	{
			If !Instr(lastFocusedControl, cclass)
			{
					ControlFocus,, % "ahk_id " hwnd
					WinGetPos, wx, wy, ww, wh, % "ahk_id " hARG
					ControlGetPos, tx, ty, tw, th,, % "ahk_id " hTabs
					ToolTip, % "Press the right`nmouse button`nto copy the text.",% (wx + tx + tw - 195), % (wy + ty + 40), 2
					SetTimer, TTOff, -4000
			}

			ControlGetText, SText, Edit1, % "ahk_id " hArg
			If (Trim(SText) = "")
					ItalicEditFont()

			lastFocusedControl := cclass
	}

}

NormalEditFont() {
	Gui, Arg: Font, S11 Normal C000000
	GuiControl, ARG:Font	, Edit1
	GuiControl, ARG:     	, Edit1, % ""
return
}

ItalicEditFont() {

	Gui, Arg: Font, S11 Italic CAAAAAA
	GuiControl, ARG:Font	, Edit1
	GuiControl, ARG:     	, Edit1, % "type your search pattern here"
	; restore all functions
	If foundIndex
	{
			LV_Delete()
			For i, function in ARData
					LV_Add("", function.mainsection, function.name, function.short, function.FnHash)
			GuiControl, Text, Field3, % "displayed functions: " fc
			foundIndex:= 0
	}

return
} ;}

GetHex(hwnd) {                                                                                       	;-- integer to hex
return Format("0x{:x}", hwnd)
}

GetDec(hwnd) {                                                                                       	;-- hex to integer
return Format("{:u}", hwnd)
}

Edit_SetFont(hEdit,hFont,p_Redraw=False) {

	;{------------------------------
	;
	; Function: Edit_SetFont
	;
	; Description:
	;
	;   Sets the font that the Edit control is to use when drawing text.
	;
	; Parameters:
	;
	;   hEdit - Handle to the Edit control.
	;
	;   hFont - Handle to the font (HFONT).  Set to 0 to use the default system
	;       font.
	;
	;   p_Redraw - Specifies whether the control should be redrawn immediately upon
	;       setting the font.  If set to TRUE, the control redraws itself.
	;
	; Remarks:
	;
	; * This function can be used to set the font on any control.  Just specify
	;   the handle to the desired control as the first parameter.
	;   Ex: Edit_SetFont(hLV,hFont) where "hLV" is the handle to ListView control.
	;
	; * The size of the control does not change as a result of receiving this
	;   message.  To avoid clipping text that does not fit within the boundaries of
	;   the control, the program should set/correct the size of the control before
	;   the font is set.
	;
	;-------------------------------------------------------------------------------;}
    Static WM_SETFONT:=0x30
    SendMessage WM_SETFONT,hFont,p_Redraw,,ahk_id %hEdit%
    }

Edit_SetMargins(hEdit, p_LeftMargin:="",p_RightMargin:="")  {

    Static 	 EM_SETMARGINS 	:=0xD3
		    	,EC_LEFTMARGIN 	:=0x1
		    	,EC_RIGHTMARGIN	:=0x2
	    		,EC_USEFONTINFO	:=0xFFFF

    l_Flags  	:= 0
    l_Margins	:= 0

    if p_LeftMargin is Integer
	{
        l_Flags  	|= EC_LEFTMARGIN
        l_Margins	|= p_LeftMargin           	;-- LOWORD
    }

    if p_RightMargin is Integer
    {
        l_Flags  	|=EC_RIGHTMARGIN
        l_Margins	|=p_RightMargin<<16	;-- HIWORD
    }

    if l_Flags
        SendMessage EM_SETMARGINS, l_Flags, l_Margins,, % "ahk_id " %hEdit%
}

RE_FindTextAndSelect(hRichEdit, Text, Mode) {

	; from Class_RichEdit modified to be a function without class

	Static FR:= {DOWN: 1, WHOLEWORD: 2, MATCHCASE: 4}
      Flags := 0
      For Each, Value In Mode
         If FR.HasKey(Value)
            Flags |= FR[Value]

	  Sel := RE_GetSel(hRichEdit)
      Min := (Flags & FR.DOWN) ? Sel.E : Sel.S
      Max := (Flags & FR.DOWN) ? -1 : 0

	VarSetCapacity(FT, 16 + A_PtrSize, 0)
	NumPut(CpMin,	FT, 0, "Int")
	NumPut(CpMax,	FT, 4, "Int")
	NumPut(&Text,	FT, 8, "Ptr")

	SendMessage, 0x047C, % hFlags, &FT, , % "ahk_id " hRichEdit
	S := NumGet(FT, 8 + A_PtrSize	, "Int")
	E := NumGet(FT, 12 + A_PtrSize	, "Int")
	 If (S = -1) && (E = -1)
         Return False

Return RE_SetSel(S, E, hRichEdit)
}

RE_GetSel(hRichEdit) {                                                                             	;-- Retrieves the starting and ending character positions of the selection in a rich edit control.
      ; Returns an object containing the keys S (start of selection) and E (end of selection)).
      ; EM_EXGETSEL = 0x0434
      VarSetCapacity(CR, 8, 0)
      SendMessage, 0x0434, 0, &CR, , % "ahk_id " hRichEdit
      Return {S: NumGet(CR, 0, "Int"), E: NumGet(CR, 4, "Int")}
}

RE_SetSel(Start, End, hRichEdit) {                                                            	;-- Selects a range of characters.
      ; Start : zero-based start index
      ; End   : zero-based end index (-1 = end of text))
      ; EM_EXSETSEL = 0x0437
      VarSetCapacity(CR, 8, 0)
      NumPut(Start, CR, 0, "Int")
      NumPut(End,   CR, 4, "Int")
      SendMessage, 0x0437, 0, &CR, , % "ahk_id " hRichEdit
      Return ErrorLevel
}

RE_GetTextLen(hRichEdit) {                                                                     	;-- Calculates text length in various ways.
      ; EM_GETTEXTLENGTHEX = 0x045F
      VarSetCapacity(GTL, 8, 0)     ; GETTEXTLENGTHEX structure
      NumPut(1200, GTL, 4, "UInt")  ; codepage = Unicode
      SendMessage, 0x045F, &GTL, 0, , % "ahk_id " hRichEdit
      Return ErrorLevel
}

Gdip_ResizeBitmap(oImage, givenW, givenH, KeepRatio                          	;-- resizes a pBitmap image (function is modified!!)
, InterpolationMode:=7, KeepPixelFormat:=0) {

	; function is modified to work only here, it uses an object created by Create_AHKRareGuiLogo_png()
	; It returns a pointer to a new pBitmap.

    If KeepRatio=1
		calcIMGdimensions(oImage.Width, oImage.Height, givenW, givenH, ResizedW, ResizedH)
    Else
       ResizedW := givenW, ResizedH := givenH

    If (KeepPixelFormat=1)
		PixelFormat := Gdip_GetImagePixelFormat(oImage.pBitmap, 1)
	else
		PixelFormat := 0x26200A  ; 32-ARGB

	new_pBitmap := DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", ResizedW, "int", ResizedH, "int", 0, "int", PixelFormat, A_PtrSize ? "UPtr" : "UInt", 0, A_PtrSize ? "UPtr*" : "uint*", oImage.pBitmap)
	DllCall("gdiplus\GdipGetImageGraphicsContext", A_PtrSize ? "UPtr" : "UInt", new_pBitmap, A_PtrSize ? "UPtr*" : "UInt*", G)				                                                	;G := Gdip_GraphicsFromImage(new_Bitmap)
    DllCall("gdiplus\GdipSetInterpolationMode", A_PtrSize ? "UPtr" : "UInt", G, "int", InterpolationMode)                                                                                                 	;Gdip_SetInterpolationMode(G, InterpolationMode)
	DllCall("gdiplus\GdipDrawImageRect", A_PtrSize ? "UPtr" : "UInt", G, A_PtrSize ? "UPtr" : "UInt", new_pBitmap, "float", 0, "float", 0, "float", ResizedW, "float", ResizedH)	;Gdip_DrawImageRect(G, pBitmap, 0, 0, ResizedW, ResizedH)
    DllCall("gdiplus\GdipDeleteGraphics", A_PtrSize ? "UPtr" : "UInt", G)                                                                                                                                             	;Gdip_DeleteGraphics(G)

Return new_pBitmap
}

Gdip_GetImagePixelFormat(pBitmap, mode:=0) {
; Mode options
; 0 - in decimal
; 1 - in hex
; 2 - in human readable string
;
; PXF01INDEXED = 0x00030101  ; 1 bpp, indexed
; PXF04INDEXED = 0x00030402  ; 4 bpp, indexed
; PXF08INDEXED = 0x00030803  ; 8 bpp, indexed
; PXF16GRAYSCALE = 0x00101004; 16 bpp, grayscale
; PXF16RGB555 = 0x00021005   ; 16 bpp; 5 bits for each RGB
; PXF16RGB565 = 0x00021006   ; 16 bpp; 5 bits red, 6 bits green, and 5 bits blue
; PXF16ARGB1555 = 0x00061007 ; 16 bpp; 1 bit for alpha and 5 bits for each RGB component
; PXF24RGB = 0x00021808   ; 24 bpp; 8 bits for each RGB
; PXF32RGB = 0x00022009   ; 32 bpp; 8 bits for each RGB, no alpha.
; PXF32ARGB = 0x0026200A  ; 32 bpp; 8 bits for each RGB and alpha
; PXF32PARGB = 0x000E200B ; 32 bpp; 8 bits for each RGB and alpha, pre-mulitiplied
; PXF48RGB = 0x0010300C   ; 48 bpp; 16 bits for each RGB
; PXF64ARGB = 0x0034400D  ; 64 bpp; 16 bits for each RGB and alpha
; PXF64PARGB = 0x001A400E ; 64 bpp; 16 bits for each RGB and alpha, pre-multiplied
; modified by Marius Șucan

   Static PixelFormatsList := {0x30101:"1-INDEXED", 0x30402:"4-INDEXED", 0x30803:"8-INDEXED", 0x101004:"16-GRAYSCALE", 0x021005:"16-RGB555", 0x21006:"16-RGB565", 0x61007:"16-ARGB1555", 0x21808:"24-RGB", 0x22009:"32-RGB", 0x26200A:"32-ARGB", 0xE200B:"32-PARGB", 0x10300C:"48-RGB", 0x34400D:"64-ARGB", 0x1A400E:"64-PARGB"}
   E := DllCall("gdiplus\GdipGetImagePixelFormat", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "UInt*", PixelFormat)
   If E
      Return -1

   If (mode=0)
      Return PixelFormat

   inHEX := Format("{1:#x}", PixelFormat)
   If (PixelFormatsList.Haskey(inHEX) && mode=2)
      result := PixelFormatsList[inHEX]
   Else
      result := inHEX
   return result
}

calcIMGdimensions(imgW, imgH, givenW, givenH, ByRef ResizedW
, ByRef ResizedH) {
   PicRatio := Round(imgW/imgH, 5)
   givenRatio := Round(givenW/givenH, 5)
   If (imgW <= givenW) && (imgH <= givenH)
   {
      ResizedW := givenW
      ResizedH := Round(ResizedW / PicRatio)
      If (ResizedH>givenH)
      {
         ResizedH := (imgH <= givenH) ? givenH : imgH
         ResizedW := Round(ResizedH * PicRatio)
      }
   } Else If (PicRatio > givenRatio)
   {
      ResizedW := givenW
      ResizedH := Round(ResizedW / PicRatio)
   } Else
   {
      ResizedH := (imgH >= givenH) ? givenH : imgH         ;set the maximum picture height to the original height
      ResizedW := Round(ResizedH * PicRatio)
   }
}

HighlightTab(hTab, TabNr, status) {                                                       	;-- Sendmessage Wrapper for highlight a tab
	SendMessage, 0x1333, % TabNr, % status,, %  "ahk_id " hTab ; TCM_HIGHLIGHTITEM
}

screenDims() {                                                                                         	;--returns a key:value pair of width screen dimensions (only for primary monitor)

	W := A_ScreenWidth
	H := A_ScreenHeight
	DPI := A_ScreenDPI
	Orient := (W>H)?"L":"P"
	yEdge := DllCall("GetSystemMetrics", "Int", SM_CYEDGE)
	yBorder := DllCall("GetSystemMetrics", "Int", SM_CYBORDER)

 return {W:W, H:H, DPI:DPI, OR:Orient, yEdge:yEdge, yBorder:yBorder}
}

GetWindowInfo(hWnd) {                                                                         	;-- returns an Key:Val Object with the most informations about a window (Pos, Client Size, Style, ExStyle, Border size...)
    NumPut(VarSetCapacity(WINDOWINFO, 60, 0), WINDOWINFO)
    DllCall("GetWindowInfo", "Ptr", hWnd, "Ptr", &WINDOWINFO)
    wi := Object()
    wi.WindowX 	:= NumGet(WINDOWINFO, 4	, "Int")
    wi.WindowY		:= NumGet(WINDOWINFO, 8	, "Int")
    wi.WindowW 	:= NumGet(WINDOWINFO, 12, "Int") 	- wi.WindowX
    wi.WindowH 	:= NumGet(WINDOWINFO, 16, "Int") 	- wi.WindowY
    wi.ClientX 		:= NumGet(WINDOWINFO, 20, "Int")
    wi.ClientY 		:= NumGet(WINDOWINFO, 24, "Int")
    wi.ClientW   	:= NumGet(WINDOWINFO, 28, "Int") 	- wi.ClientX
    wi.ClientH    	:= NumGet(WINDOWINFO, 32, "Int") 	- wi.ClientY
    wi.Style   	    	:= NumGet(WINDOWINFO, 36, "UInt")
    wi.ExStyle 		:= NumGet(WINDOWINFO, 40, "UInt")
    wi.Active  		:= NumGet(WINDOWINFO, 44, "UInt")
    wi.BorderW  	:= NumGet(WINDOWINFO, 48, "UInt")
    wi.BorderH   	:= NumGet(WINDOWINFO, 52, "UInt")
    wi.Atom        	:= NumGet(WINDOWINFO, 56, "UShort")
    wi.Version    	:= NumGet(WINDOWINFO, 58, "UShort")
    Return wi
}

bcrypt_sha512(string) {                                                                            	;-- used to compare versions of files
    static BCRYPT_SHA512_ALGORITHM := "SHA512"
    static BCRYPT_OBJECT_LENGTH    := "ObjectLength"
    static BCRYPT_HASH_LENGTH      := "HashDigestLength"

    if !(hBCRYPT := DllCall("LoadLibrary", "str", "bcrypt.dll", "ptr"))
        throw Exception("Failed to load bcrypt.dll", -1)

    if (NT_STATUS := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "ptr*", hAlgo, "ptr", &BCRYPT_SHA512_ALGORITHM, "ptr", 0, "uint", 0) != 0)
        throw Exception("BCryptOpenAlgorithmProvider: " NT_STATUS, -1)

    if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_OBJECT_LENGTH, "uint*", cbHashObject, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
        throw Exception("BCryptGetProperty: " NT_STATUS, -1)

    if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_HASH_LENGTH, "uint*", cbHash, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
        throw Exception("BCryptGetProperty: " NT_STATUS, -1)

    VarSetCapacity(pbHashObject, cbHashObject, 0)
    if (NT_STATUS := DllCall("bcrypt\BCryptCreateHash", "ptr", hAlgo, "ptr*", hHash, "ptr", &pbHashObject, "uint", cbHashObject, "ptr", 0, "uint", 0, "uint", 0) != 0)
        throw Exception("BCryptCreateHash: " NT_STATUS, -1)

    VarSetCapacity(pbInput, StrPut(string, "UTF-8"), 0) && cbInput := StrPut(string, &pbInput, "UTF-8") - 1
    if (NT_STATUS := DllCall("bcrypt\BCryptHashData", "ptr", hHash, "ptr", &pbInput, "uint", cbInput, "uint", 0) != 0)
        throw Exception("BCryptHashData: " NT_STATUS, -1)

    VarSetCapacity(pbHash, cbHash, 0)
    if (NT_STATUS := DllCall("bcrypt\BCryptFinishHash", "ptr", hHash, "ptr", &pbHash, "uint", cbHash, "uint", 0) != 0)
        throw Exception("BCryptFinishHash: " NT_STATUS, -1)

    loop % cbHash
        hash .= Format("{:02x}", NumGet(pbHash, A_Index - 1, "uchar"))

    DllCall("bcrypt\BCryptDestroyHash", "ptr", hHash)
    DllCall("bcrypt\BCryptCloseAlgorithmProvider", "ptr", hAlgo, "uint", 0)
    DllCall("FreeLibrary", "ptr", hBCRYPT)

    return hash
}

UpdateAHKRare() {

	hash := []
	FileRead, file, % A_ScriptDir "\..\AHK-Rare.txt"
	hash[1]:= bcrypt_sha512(file)
	FileRead, file, % A_ScriptDir "\..\AHKRareTheGui.ahk"
	hash[2] := bcrypt_sha512(file)

	;Download(versions, "")
}

Download(ByRef Result,URL) {
 UserAgent := "" ;User agent for the request
 Headers := "" ;Headers to append to the request

 hModule := DllCall("LoadLibrary","Str","wininet.dll"), hInternet := DllCall("wininet\InternetOpenA","UInt",&UserAgent,"UInt",0,"UInt",0,"UInt",0,"UInt",0), hURL := DllCall("wininet\InternetOpenUrlA","UInt",hInternet,"UInt",&URL,"UInt",&Headers,"UInt",-1,"UInt",0x80000000,"UInt",0)
 If Not hURL
 {
  DllCall("FreeLibrary","UInt",hModule)
  Return, 0
 }
 VarSetCapacity(Buffer,512,0), TotalRead := 0
 Loop
 {
  DllCall("wininet\InternetReadFile","UInt",hURL,"UInt",&Buffer,"UInt",512,"UInt*",ReadAmount)
  If Not ReadAmount
   Break
  Temp1 := DllCall("LocalAlloc","UInt",0,"UInt",ReadAmount), DllCall("RtlMoveMemory","UInt",Temp1,"UInt",&Buffer,"UInt",ReadAmount), BufferList .= Temp1 . "|" . ReadAmount . "`n", TotalRead += ReadAmount
 }
 BufferList := SubStr(BufferList,1,-1), TotalRead -= 2, VarSetCapacity(Result,TotalRead,122), pResult := &Result
 Loop, Parse, BufferList, `n
 {
  StringSplit, Temp, A_LoopField, |
  DllCall("RtlMoveMemory","UInt",pResult,"UInt",Temp1,"UInt",Temp2), DllCall("LocalFree","UInt",Temp1), pResult += Temp2
 }
 DllCall("wininet\InternetCloseHandle","UInt",hURL), DllCall("wininet\InternetCloseHandle","UInt",hInternet), DllCall("FreeLibrary","UInt",hModule)
 Return, TotalRead
}

TheEnd(ExitReason, ExitCode) {
	;OnExit("")
	ExitApp
}

;}

;{08. Include(s) and TrayIcon + Logo

Create_GemSmall_png(NewHandle := False) {
Static hBitmap := 0
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 31464 << !!A_IsUnicode)
;{
B64 := "iVBORw0KGgoAAAANSUhEUgAAADAAAAAyCAYAAAFtzWgaAAAACXBIWXMAAA7EAAAOxAGVKw4bAABB82lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMwNjcgNzkuMTU3NzQ3LCAyMDE1LzAzLzMwLTIzOjQwOjQyICAgICAgICAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgICAgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgICAgICAgICAgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyI+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+QWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKFdpbmRvd3MpPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDE4LTEyLTE1VDE2OjE1OjM2KzAxOjAwPC94bXA6Q3JlYXRlRGF0ZT4KICAgICAgICAgPHhtcDpNb2RpZnlEYXRlPjIwMTgtMTItMTVUMTY6NDI6MzErMDE6MDA8L3htcDpNb2RpZnlEYXRlPgogICAgICAgICA8eG1wOk1ldGFkYXRhRGF0ZT4yMDE4LTEyLTE1VDE2OjQyOjMxKzAxOjAwPC94bXA6TWV0YWRhdGFEYXRlPgogICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3BuZzwvZGM6Zm9ybWF0PgogICAgICAgICA8cGhvdG9zaG9wOkNvbG9yTW9kZT4zPC9waG90b3Nob3A6Q29sb3JNb2RlPgogICAgICAgICA8eG1wTU06SW5zdGFuY2VJRD54bXAuaWlkOmU5ZjdkMGIwLTdmMDctMTY0MC05ZmU3LWI1YmEzYTNiNzU3YTwveG1wTU06SW5zdGFuY2VJRD4KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOmZiNzY3NDhlLTAwN2YtMTFlOS04YWQ0LWYwZGEyMWYxNDhhYTwveG1wTU06RG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD54bXAuZGlkOjI0YmE4NTQ1LTdhMjEtYmQ0OC05M2JkLWYzMDVhMDkzYjhiZDwveG1wTU06T3JpZ2luYWxEb2N1bWVudElEPgogICAgICAgICA8eG1wTU06SGlzdG9yeT4KICAgICAgICAgICAgPHJkZjpTZXE+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNyZWF0ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDoyNGJhODU0NS03YTIxLWJkNDgtOTNiZC1mMzA1YTA5M2I4YmQ8L3N0RXZ0Omluc3RhbmNlSUQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDp3aGVuPjIwMTgtMTItMTVUMTY6MTU6MzYrMDE6MDA8L3N0RXZ0OndoZW4+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE1IChXaW5kb3dzKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDo2OWZlNzMzZS0wOTM0LTkyNGYtODA4OS1mZjY2OTBlY2ZhMTE8L3N0RXZ0Omluc3RhbmNlSUQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDp3aGVuPjIwMTgtMTItMTVUMTY6NDA6NDErMDE6MDA8L3N0RXZ0OndoZW4+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE1IChXaW5kb3dzKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6ZWM3YzY4ZTMtNzY5Ny1iMjQ1LThmZTMtMzYzZWY4NWJhZjI2PC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE4LTEyLTE1VDE2OjQyOjMxKzAxOjAwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNSAoV2luZG93cyk8L3N0RXZ0OnNvZnR3YXJlQWdlbnQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpjaGFuZ2VkPi88L3N0RXZ0OmNoYW5nZWQ+CiAgICAgICAgICAgICAgIDwvcmRmOmxpPgogICAgICAgICAgICAgICA8cmRmOmxpIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5jb252ZXJ0ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OnBhcmFtZXRlcnM+ZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZzwvc3RFdnQ6cGFyYW1ldGVycz4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmRlcml2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OnBhcmFtZXRlcnM+Y29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmc8L3N0RXZ0OnBhcmFtZXRlcnM+CiAgICAgICAgICAgICAgIDwvcmRmOmxpPgogICAgICAgICAgICAgICA8cmRmOmxpIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5zYXZlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6aW5zdGFuY2VJRD54bXAuaWlkOmU5ZjdkMGIwLTdmMDctMTY0MC05ZmU3LWI1YmEzYTNiNzU3YTwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxOC0xMi0xNVQxNjo0MjozMSswMTowMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OnNvZnR3YXJlQWdlbnQ+QWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKFdpbmRvd3MpPC9zdEV2dDpzb2Z0d2FyZUFnZW50PgogICAgICAgICAgICAgICAgICA8c3RFdnQ6Y2hhbmdlZD4vPC9zdEV2dDpjaGFuZ2VkPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L3htcE1NOkhpc3Rvcnk+CiAgICAgICAgIDx4bXBNTTpEZXJpdmVkRnJvbSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgIDxzdFJlZjppbnN0YW5jZUlEPnhtcC5paWQ6ZWM3YzY4ZTMtNzY5Ny1iMjQ1LThmZTMtMzYzZWY4NWJhZjI2PC9zdFJlZjppbnN0YW5jZUlEPgogICAgICAgICAgICA8c3RSZWY6ZG9jdW1lbnRJRD54bXAuZGlkOjI0YmE4NTQ1LTdhMjEtYmQ0OC05M2JkLWYzMDVhMDkzYjhiZDwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgICAgPHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD54bXAuZGlkOjI0YmE4NTQ1LTdhMjEtYmQ0OC05M2JkLWYzMDVhMDkzYjhiZDwvc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPgogICAgICAgICA8L3htcE1NOkRlcml2ZWRGcm9tPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj45NjAwMDAvMTAwMDA8L3RpZmY6WFJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOllSZXNvbHV0aW9uPjk2MDAwMC8xMDAwMDwvdGlmZjpZUmVzb2x1dGlvbj4KICAgICAgICAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICAgICAgICAgPGV4aWY6Q29sb3JTcGFjZT42NTUzNTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8ZXhpZjpQaXhlbFhEaW1lbnNpb24+NDg8L2V4aWY6UGl4ZWxYRGltZW5zaW9uPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+NTA8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg"
B64 .= "ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAKPD94cGFja2V0IGVuZD0idyI/Plszt9AAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAAGbNJREFUeNpiZIAARgYGBj4GBgY2BgaGXwwMDJ8YGRgYGHMdPP9Zf9ZiYGG+zWCYX89wdOc+BhYGBgYmtXJ+hh3ZGxiYdQwZ/j+azvDp/V0Ghk2LlzOEePnWJ7ma/N9pIv//yvZd/xkYGDgZZ+9cy8DAwMDgG5X6392Vg8H3je1z7QQfKSa5NyIMGi//MUi8fcfywpuHoWXPShk2Li4GdMABYwAAAAD//2JGEuBjYGDgYWBg+M/AwPCHMZ4t+f8fqysMYb+EGa6XOzAUWWcwOLk7lzAJsN9i+H/5JcMMCQGG38f5GdYn9jAcOXt6IdPEz4eZ+PSFGJIef2cIUeZiOHj3GMOm9aveMECdK5rnKPY/zz/wPwMDA+vyJYsZmDRe/GY4vGj164D9fxi2nr8wc+26tb85eLlRnMoIxQwMDAwMAAAAAP//Yty1dRaDm3ca8xJm5T/lUXwMmRd/M7CwsTPw/+FmeKUsx6DCycbwmKWQgVWi/HFxxzYFZlcbuypLLfODPF8eMiR/EGFg/+vO4PTrM8Pk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"
;}
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", DecLen, "UPtr")
pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")
DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, "UPtr", DecLen)
DllCall("Kernel32.dll\GlobalUnlock", "Ptr", hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, "PtrP", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, "Ptr", 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, "PtrP", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "PtrP", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
DllCall(NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, "UPtr"), "Ptr", pStream)
Return hBitmap
}

Create_AHKRareGuiLogo_png(NewHandle := False) {
Static hBitmap := Create_AHKRareGuiLogo_png()
oImage:= Object()
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 131888 << !!A_IsUnicode)
;{
B64 := "iVBORw0KGgoAAAANSUhEUgAAApQAAABoCAYAAABPAGB3AAACVWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS41LjAiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6YXV4PSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wL2F1eC8iCiAgICB4bWxuczpleGlmRVg9Imh0dHA6Ly9jaXBhLmpwL2V4aWYvMS4wLyIKICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICBhdXg6TGVucz0iIgogICBleGlmRVg6TGVuc01vZGVsPSIiCiAgIHRpZmY6SW1hZ2VMZW5ndGg9IjM2OSIKICAgdGlmZjpJbWFnZVdpZHRoPSIxODk3IgogICB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIEltYWdlUmVhZHkiLz4KIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9InIiPz675bcRAAABg2lDQ1BzUkdCIElFQzYxOTY2LTIuMQAAKJF1kb9LQlEUxz9qYZT9oBqKGiSsyaIfELU0KGVBNahBVou+/BGoPd4zQlqDVqEgaunXUH9BrUFzEBRFEC0tzUUtJa/zVDAiz+Xc87nfe8/h3nPBGkwqKb2qH1LpjOb3eZzzoQWn/QU77TTQTEdY0dWZwESQivZ5j8WMt71mrcrn/rW65aiugKVGeExRtYzwpPD0ekY1eUe4VUmEl4XPhN2aXFD4ztQjRX41OV7kb5O1oN8L1iZhZ/wXR36xktBSwvJyXKnkmlK6j/kSRzQ9F5DYJd6Jjh8fHpxMMY6XYQYYlXmYXgbpkxUV8vsL+bOsSq4is0oWjRXiJMjgFnVNqkclxkSPykiSNfv/t696bGiwWN3hgepnw3jvBvs25HOG8XVkGPljsD3BZbqcv3oIIx+i58qa6wAaN+H8qqxFduFiC9oe1bAWLkg2cWssBm+nUB+ClhuoXSz2rLTPyQMEN+SrrmFvH3rkfOPSD1W/Z97kqnedAAAACXBIWXMAAAsTAAALEwEAmpwYAAAgAElEQVR4nOy9d5hdV3X//dmn3H7vzNzpfUYa9W7JllVcsXEjptqm2BgIbxISQkhCyC+BXyCUB0LJS4IhJhAwMeBgHIwxxkXuNmq2+kgazYzK9D733rn9lL3fP86MZixsg7Es+QV9n+c8t5179l67fvdaa68teP1BvMT7MwX1Eu/PJs5UmZwt2c9knatTXl8pznRdvNb1cDb62+uxj/2+QZzy+nrCi9X5uXZwDufwmyHgTUCvgEYBodlflgEHX8ukDyjwAQFgp3yJzL1uIF7igjNHMmbeK0By5ib1l8LcMtD49fI4XeUyV84Xu14rnFrH2pz3c19fLU6HfGeifZ7Jeng5eeA3y/S75meuLK+HPvb7hrM5jr4cXmyM5UVeX+79OZzDa41X2kcEXhudeX0l97zKtl0p4IMCugXARVfAM48+DFz16h77onhUQeI3zkOvB0J5GfAg4D9L6Q8Bfw08DLh4k5w85f1rTaxOgVgJ6j6g5TVOKA/8HfA/gMWsvHPlfy1krwf+G7j8ND/3VDjA7cDn8GQ9tV7n1u+LwQDeA9wGRF7jvP4Yry5SvHgbfLl8/rYIAv8X+DBg8uv1+1Ik9tTvTiWCv4kIZ/Hq4S6gyK+X/1noY79PMALg/DFeO3294Tt49XoEeJrZes4Dabw+mgbs6ft/Uxs8h3P4LbFA8OalxJ95hm9961vs2rWLL33pSyIUOp9MBqB7+r554mWn2gBgZeAiCVtNIDjbWl8O9UDgEP/1jx/jkUee5sc/zsz+Fk5y0XkFde+996qKiopX267Fhz/8YfHZz35WlFVXw6pr4bmZn2Yy6gf0V/jYmW7arqDnt+p/xitM4XQjDPwfhPBfdNHVmEmoywfQprNd0CTd0SyuUIRDFi0NSQxjdnxJpKIMjVYj8LSvDgZRLU3c3013MEJBGASVy8J89mSCuYBOImDSHyphUsuQ++WBWsa5BTgMjOFN4jbeQGdPf3ZPJnpm8Mchn9myZskCIgEdqWa1yz5HUp7Kg/AUlkWtjNGqCNJvgwIhXYL9oyDl9HJIY9RsZNysRgiJ3nSCmGNgHHfZ13kwaJG7FdgN9EzLPCP3ayn724MB4/LNF7ZSW6mBkkgh2T9RQjIfxJSCmpIpKmLpF/2zYQlCKQ0h566HJGPZZeRlKUg4MpBhaGKLAekrgV8C+/j1unV44YR1KhqA9wdLzMiGNy8lldSwBmqpU0fJlhcZqZ1Vqc48IJaSRDM2CBcx/XgpIxStGphup5gWMpLCrzT8BZdjnUMc7XVuwiNdndP5nJtH56SQr64e3gDcumHj6miZiqHycYQbO7mslLqkGHRQmkQohULhKp2c5j+ZqgIQLoGSEZxoEmkWiWUdqgckZlGQD+VwZd6T2ypSGMxxaNSlV3IzsBUYnCPTjIwzsp1M4hxeCeRlCG6rWlRH5QXzyeOgWxoVA+E59yhcUSQdL0Pq5vQ34JNJoqldKAFCQLkZBaUx6QaZdAIn/x0xoMSnndRAKCTKUlgHBY4UpMp1UhELKR3CCY3AlE42nWXSGf2gFShiWxZu8QVWsn6gA49MtgNH8UjnQWYXLXLO+9eL1egcXjdYKyAgYOqU70MCmgCYb0jqli2jqqqKT3ziE9x3331E65rYuRNIN/3mJMJQeT6UjPdx2cINPFHYz4hqIr2L2ZmxjlnL8+T0haeB0FnKRRddRdEV/HjXAzAMZICNUBYsE0eOHBGapqk3vOENasuWLb+z1ee2225Tt912G4DguZ/NfD9nglwqIPYKH2sBu+fmabb7vwTONqGcB9SUN7fx9r/9v1z8uI8Fx30nc501JHcv6CHnczhv4wku2NSLPj2DO5akq0Nn7/PXUSiU4dfyNAeepy3wHFFTsbW0iu1lDVwxOkZLIYdCIBScaPYzFA5wX3MDDweeQfxZD+oHU5uAhXgTnIWnRSngFaCFV4AuZwyKqGlww0Xncf7SJeTHR2GaVLoyjJhso9xKEsimMMOS9k3NSE2BJgn2jVP2xC5QAgXYWpDtZTfRHVyFhsSs76XVOcy42cfhzhNY5ErwiFPqDMreEjRNbn37Mt583WKEM0gm6ePhhzYwOVmGT2pUN4/TdME+gpX9aIaNdE1QGkqBltCoafcRsLQ5XcZi69HPkrXrGBuAn4+k2SKWUlToeD2pFI+8zJUPfn2imosoEAtVC2765jrCiSiBHytqRwNkyl2eezOkGkAgPPKuFE1bGikd8YFw0TULhAPCJG/VIZRCKCCUwW7pYrxzOc/cP0DRfB6P71IKlJ2SzyIvrq15pSgFPtW2uLHu01/5c6oDgtz33oRQ0dmS8E/h1u3H8vkoyji2CpNVESa0KKg56kllEbz2R6iqHlzDwV+QVA5Z1HdplHXtwbHSFPomSe7PcyQM+yVF4MB0KrFT5JvBOQ3U7wzZLISg7JIWrvvqB7DJo6YUK+9vQnO8ylUoimHoWTUPx+cDAQqd0swDNHT142qC0kCIZn8dmtI4VoizJ1uPVF7bbi7RaC6ZnS6kkogRjeRX8rgaWHV+MqVg10SoKC4gNlZCOp0jFUhw4OIDnKg7xFsOBMml0wyOpunuH2oYGkk2HOlJMZWx3gok8RYb+4DngR/gjcfunOvFNNrn2swfLCoExITH6F4EK2CNELReeCGPPfYY1dXVvOc97+Gr99wD8QXeUoYcsAdYijf0zuAAmpZlw4UXMpGEtpYl/PM/f4EH1n3IW92fD+heyvkRSOS2Agpqm2FJAwAlAVimQyAAfh9sWgNHtsP4Ulg1ncrAwABKKeGEw4L51yqO7gaGX027nvnfKeb1Q2ekn5xtQnkxsLzh2uuZDOnEGsqJdEuwJAgIC0FtPkqhcpRLLh/A9HnZdV3o7S0gs5LlS36O1j2fJf4nCevpaY2R4o3j49R0tjGvKYMjTECRjRnoIZ0qN8eEvp18uAfeXgk/mipFsgFv/VDEa2U6s5XyYivk1xICJM7UBNp4gsqKBnKjQ2iuzZbqj1BsqMIVClcpzm/+Z1r0H5LJbCRXXEjt1g5ETkMgUAoKZpCcWkjUCqCUovepVo4dSzB/3sAMjzCAEiCON8HnmFW8zR3AOY2yC+XC4X2S668aRMklHLp3AbGROCXCS8Y93Maxo+/GCGWINbZT1rafWP0Rpsw0z+WjXBC1OG9MIZTwSksG0fLzsEd1On8FIhGmnBUM8rSBR6bKX0I+l5f2gRGAUEhS4RM0pVtp0BTKVUSHNS5+ELbdAsVy72b/UIjysWp022tvQoDUFNHJAAtPKIoRl1xMkY+Uc3h4GffcM8TBwyHsQC1zCOVMPvPM2ihOh9n768GQf+37//ytrFk/D1EwGTMrUY5+klBqxhg+4zgwBUKiMBlhDVK/HCVBKpASZEkBf1svSmgoTNywZEqPIiaWIPUp/D/7CelOi1RQ8dVxxaBnW3oEbx1vTMs3VzZ3pqxfhXx/8MgaFiPhFBfQxAiTGDGDwKSBMgXmuEvgmRzSLjByVRmaJVFagOpEP0ENfD6d1mAFQeGNsc2BAgMFScb1Y+hQHTSImPqcFY1C5gVWsogeMDEGfTAI2jFFrMwkFliMrRfRNY2QswajOstbmvZQzThSCSQmjnT4yaTiM88nyG59vjS1bVdpIZlcAtwAfBa4F/g3oJdftxid6pJzrt2cwwtwcQU88MADfO973+MHP/gB5eXlvPe97+U/v/1touugdwRi1wS5xneR2LVrD93Vlqem7+3llksu4ujRY2x/soMrrqhn9ep17Nv3HLfeugiAf7vt31i86Dz27Blg2ZIQf/qOWxBC0NPby/2/+AWrVq9GOFB0YOfOrXR1dGCMjrKkBZQG+ckM434/Bw9687RMJNhcjzg4aamrr36X+JM/+RMuvfRSBSghxO/StucSyzOGs0koY8B6XyiiNV16CYW8TU9lkXkNQcRxG6lJikaGmsIkLZfsQpumNK6jGDhWZLRPITQBSpG1U+i+IhoKlGIkXcV9z9/Cnr713Hr1N2ip70AhGCs3wHVJDB1nMtwHpQHEohBqqQHtzjvxfHzyeP5lgtnJbmbwOhMQMy9CQH5kEJSJEWmkXa4mH6hFU6Arj1iXaMdRjBCO3Utp6gYIbYTcDhxfgeSKAAfePw/nwDDyvhIGBxwG97bzR7kfscLfxffJgzexz2jGZkiM4oUm19M/0QuQjkbh31swY7UYWi26aSOd6TlCsxCajlusJNF1GROHLqVYeYjUpbehKY3nKg1q4rswXYEmNWQhgNv1OHt2rCExWYHrG8PSJqCAjkeYT5Vvxvw9M0m9LJQs4uw7gplfioyW4qRTlJ1QrP8fePpPAmBoRI9VIazpxwswLIOqnnKa2qvIx7qIJkAoSBaKfH/wGB1dSdQLS7UUj9jn8Prm3Hqw+d0GBx14F/DuizZcJN568btwD9WCFcZYlsDpjqBLhVBT6KEejICDwo+SCiVdqt199GkXoTBBSjQymM1bUXmFGxQoKTD7I2hb4xw5vJv7jue51lLYS+EnXYojkjTwo+kynlsHclom41XIdg5zIByDfF5xRI2wwGlERcC/z8HXmUMbtVBKseD7HThk6F83TDHbi0zspkU3qA2VENJCJ9tjzMhTZmbJun4qzAI1potwfUiho9CRBRP5aBUoicCdHh0U9vwi+z/2IIbcQfPPLuSIuYodbXGyY2V8xtfMWyPPsilwjJCQuAUftfko57fUM7F0MckP3MTUgQ4x/uRThjzYYeQmc++xlLoSz8f7R0Afs31hZmw6nT7G5/D7giBMTY2KjRs3MjExwcTEBHfeeSfz589nQVsb+aEBWtebMAktF15Ib+8YtZqDpsFQoIkNG66gqaWL9tz99PX1Mm9eKwCFQpYTJ04QME3sYp4/uu6NtLaabN++nUAgwObNm7lw/Xr+6Z/+iVWrVs1mJxhkbGzsBVlsa2vDiPkAcF2X3t5ePvCB94slS5bypS99U335y98Un/jE34p7772Xj33sY8rn86nDhw+/0jZ+RvvE2SSUVcC1VavXUh6J4DiSHttlZF6IkuIAE+4hkrHjBH0JRu8WOMcF8fWSsYzFaL9C0wQIRV/XUkYHm3FaLZor25HJML949kN0jrchhcW9z7yL97zx24RahrBNyGYn6RnsYsFgHjlRwaDmkFgQRran6oB1wH48DdZcwjF38IIzUEmabhAJR0jnV9N3cCVa6UpkfRW6mk1c1xRh0QdCoMkyCoPvxr2gDS25lmNrt3DiqiD4wF+3l9GuPpb9fBd/k7uP80UP2ggEUKS9yT2CR7qMaRktZs2tc3eXnw4I8IjVIitG3ImgJcZYWmbQUdnE+GQWqWdRxgQmcSyrGSHALesje/5d6MpTbDnKIBt0MFURlEvOSmBWvInaRTfQW/tOusP/y8Sxg9D7svLpv4180vExdXw1uUM5Mse7CLe0YZZUUMwlmCqtQ3cXIQ0TK1YEYwphC0qHo9QeraJsOIbUiyjN07rbuQzjh57AGolisxiECREfJABvkTWTT4XX7grTn3/XelgNfLymtlb76E1fIDayGumCLJ9AP2+SjL+H8s4ODPsYojiJsmpwo6XguijXRRc5qulg3JhPhKOEtcOYx4fI5ctJNaeYGlJMPZtmsPcg6cwUomjyk/8T4fDxJIe/SgG4B883OcasiduZU/7niOTpgBLEO1tpu+MaQkWQmo+KiRTB/UexUvb0mCFQSkcduJ+J0ifB0ckInXERw+f6qdAU+vTa0SmaqK5SSJex/vI9GI5EOYDQcNFItjdhDYGgBJBowiZQn6Xjr8fJLSzgqh5G/+EAHU9+A7foZbGA4ofJ9fRpVZw3YDF2vJ6BgRoWm0eZKuskF88zuSrE1MrzEIeC9D+b5/iOYlVu6vBHlHLXAd8HtuH1liJeP54Zm+GctvIcplFSNSqS2RFWr7iQ7u5uxsbGGByEvXv30trayrPPPkt1dfWcf8zHc1+H2lqIRLwBd01JCQCHDh3i6quvZvfu3QCsWLGCo0eP8sEPLuLrX7+bujqDRCLBd77zHT75yU9y3XXXsWfPHiorKwGor6/npptuemEeS0ooLPLcT9LpNG1tbSxcuJDPf/7zBIONQtPg5ptv4YEH7lM333yzeOSRR8S6dev4zGc+I6+55hp+R83la4qzSShvEEIrn7diI7WTAUIiQk5r5vGqAKvre7APtONYNqChHBjfrpPoVxSWawhNYYgCU+OVjPQ2IQQMBEqZKq9AlGj0UYFSEiEgkYvw2N5rWTf/pxScBI8ePsTw3iTvflpSag8zUC74f4M2e/ygilwNHGOWdMz1Y5vRqpwJX0oBYJomfX3vYirbgJ6EuA3zInCsDJQLhp7Cp09Mq8wvxS02AwZW1WoSK08gfP1IJMciHQxd8SS3/dNR/NPTd1o245IAUhre7t/QtHxFvGBTc0nMaZ/0TaVTJ0PoApCKeHKY0hKH4oI4yeE04ZBFWenDpMYuYGJqPtlFj6BCCcDzDcXVsNwQQT1HejzBaPsk+ZSLuvZJnr66hbH7t8G/w7QMgZeQby6hfCmTNzJfyXD7jWgxl5FFR1l94n4qKks4fv16OlbFkQGvG6XnB9AfquTiQy4lQzHMojn9GAVC4aQzDB/4Bf3pozSVlPHWqS5MoXimzKCnD3j5epgbUum3HUjKgL8wfb4ln/7S51jetATdlgi/gtI8QS1EsTWPMXwUvZgD5YdkAhGLIQM+pAOFQAMx4WDKnRgcRUkLx4LCthH6b9/ORDhARipsZXhaTL/GoJum83tSWQm24W24CDC7SJvrSnKOALx6eG1XQWQ4Tv3WRQRy3g9Z5xixsjDSyuDkPc6lBQWjK4+D6/MsPHgDXYclafb7KEHHzhjs+OVaho5W4bo6XSUtLLngGEgNUGTSAYalSdScqUYfkaDB4tbj6KOKXQsEru5ZWDRswIeYHkHywqT74CqMQ0GcnAYSKqaClPaEKZS7yCUnMNwkqbYA1cZ1SHEtw93fIXH0PzYonAXAnXj+lSlmx+Yis5u8zm3u+oPGqADP1JMIh7n++uvZtm0bV1xxBZblJ51Os3DhQg4efPUBG1esWEE2m6W01EAICAQCSClpb2/nuuuu4+GHHz5JKLu7u9m2bdvJ/+bzeSKRCO/78IenJ9cI8+ZtIJ1OU1ISY5rHYpoRvvjFL4rFixcjhKC1tVUZhqF94xsPAx9V8LWzMX6+5Bx0NgnlW0srG1jUuJiV6XEMy8d4NEzGhed8K9jQso9MdxdKTo8PCtxBneaFuwkbKUwshkQb++QlGIaNprtIAeiKhVc+wt67bkBJzxRzNF2FnShnf+8+fvpcP2UFxdtTUDFmEx6GhesVe0tAjbICb0Kf0QwF8PbbF/DG3dfG/PsScJwg2Xyl54vnwngvlEto2gC9JgR8/ZiaxLZLcFJvwOMjYBZNApkgU0A//WzhQYx4Av+0q2BeNdJhfQ7BXzEtj4lHXky8NnEq2Zq577T5UAoFQs6qW4UrsUfGSLouVa0lhEQ/AklV4xaU+SQTDUdRQmA4itIpSSyX4YnMFyjRn6e0/3OEipKoI/iX993AeDyKDF2J+MqRaeMzvpeR7zdCYSDtILYuGahcwbHaC2moeBJtQz0BbLIU0FDYnXF6DrZwfxreaY3gw0bhuWU4UxkOdj3CtuphMovLiQ+nWZzpRZdQ7JH0eEnN1MNMXvVT8vlKif0VwC3v++AHjGvfeBXaaB4GfaiSHJqhoes6sYo4enk1enoSlETZITL9b8WRZbi1CdzyFLrtEHJ8uI4knZik86kt9O3bhVV0qGxxKdGVN5vrMFol2HW7Q/6o6gJ2MKsVnmk/c034M+4G50yWpwMClO5dALmMj0RfmprNcVKdkxTqU6QXJ1EXZxH9LowYML2vrdEfJqRHKKKYKkbp66jz+iew/5n5xGtSVDVO4joaJ/rqkX6JU2tBt1dpkYBDSLM4/1GT+IifLdc7OCEXTTgofChdJ6IUb39qO6ETzQwEV6Dp4LoKpWVRUkERinkbSzhojoOcbCCWX4lo+xJRUmLgxH2Vjpv6G+Aa4Fa8/bIz/u5FrwReYAY/157+oOCRSWLQI2CNjBKJRNi5c+fJO0ZGItxyyy3kct6qy+fznfxNnDK6unir4eUvkVo0GgUgHH7h95lMhljs5XdUu65LoVCYE4vOYCZyYskMmwRisRjpdJrx8XGSySSmaYr9+/fT2ZnnkksGqKq6QSQSCa644kr193//ccrLy9XQ0BB/9Vd/xbe+9S2UUqepD+gCagRsnC6ln7yoYu1sEcoW4PzGpkY2BxIsyx3hSOT9GJrn+G9ZPvpiG6muSFAcGwOlUEIgAz58ykFTBVwlqQh14xRHsZwgYWGhkCAEZfEsKxdKRKYKvykQ5UWO5PrYcmAfSigmo9BRAovGIFCEZlMQrBBkR5UBbAYexSOTM4RyhojYvHByfO2gwPbbRNt+hZWowc5W4eRLGe8xiPug4nzQg/1IF8gvQ2WXYToQzUN5UqPph5dxx43H+MXqe5lgnHCjhm0IbKeVfvlnKO1k9gUeYdF5IYE5NSjyaUXG7+fehmbC4SqaptKUW0X8SmKnJwiJLIFYFCubQbng13OEc4poxiFQ9CiiLUMcG1jF/f97MSND7+S82gcY/p+HGIs3IChASwuqOQ7jkzCr4Zu55sr1G+UTCs+Telr50TA2xNKOMHvaximZV05UBMkWLKytJWgFwZQJ/1NexUXpFPMLeSZLUjxu7qWzZRyVNzFyElcYKE0H6Z601zFb9i+W11daD21CiK+tWbfWuOnmdyNc0EskWsZFhvNoQkMIjWAkBA0taIMSR9ZQsDehWeXojkREJUIHy4KpEUXfLknvnkPkUjq2XIUwUuDrRgkHISAdhl8dcMkeVgk802SG2c1sc3d253mhyfLc5H8aoGFhkEEoH0r5kEYJBQUDvZ2E3hbCElOQAidQxNxQwG33IU+YlGsmK4LlKG/5gy9k4ws7OBlvw1ZhymTfUwtZf207/WPVKCUQriA/P03gVxEEGsFoFoEGQtG2XxJLB3nqWpNhlad1OMPqQ51c2ncc39QUnQGdoeBilDRR0kbJAqAoFl2cgovtc3CwKY7HcR3QxgIE9cuoqS0wMbGLfP74EpD/ibdxp5sXLhBntJVwrl39QSIGxBnloouu4b777uPEiRO0tLQAnsn70ksvZd68eYyOjuK6Lrlcjg0bojz2WJJIJMLEhIFlGV7LyfCSEYgTiQRS+igWJX6/huM4CCE4//zzeeCBB4hEZv/o4vlp9ByC1BisXXvq05Lk80cIhTbR3n6QlpZlaBqcOHGET33qk7S3t5+8c2pqChpNkkdGBaOQSMCBAxaJRILJyaS4/vpb+PSn/5ojR46gaRpKKXXjjTdi2zaf//znWbNmDfF4nB/+8IcQbIYqqOVy8rHn2Xb33fzXf/0XsViMq6++mr+57TaeH5ei8HDxt7LNni1C+VG/abC5KcwiI4myHbKEQYE+vboedBqIVi3Dn9lBXgqmouWMSR8HnlnFxYG7EFmXXDpKdudD7KeaMuMwldkB6s0S2PGXVOn1GBXgOjA5Xsa2dIK047lwKWBrk+Dt3Z5mpXkcyucLsoeUBrTiaYj8c665JtIzEj7I0XVSjSNcdMmfU5ysIzfaTH60lezQAnLDK9A7Gqm7ahRFkODEJcTGqojlwW955nD9cBAyGqP/NgJCkDFhuLSKwugfU6DGc6SfxYuRltfUt00CR6MR/rdtARW5PK2pKSpTo9RH+rCyUwgzjj9agpVOMR5xSQUCODhEdJtwrkhndzU/v8fPQC9AHTt6/h9UyEZMOyOCDdEIMDmXOJ4q528lo2FOUlqxH5lZQbiYZ/ngCKbUmfeY5HDFGFUlFYT7y5k6GPOs2wKmdI1HY6Ucj2Q5uvheJh8/AraLmNYIOT4Dxyfw29OEdRan5vN3qYcq4PZ4SbTuI+98CytLY4hCHukXiPIsugGaoSM0DU3TMJvnYedLcZ3F6FYEiiAshR10yE3kGemYYKRjioGDV5AefS9FK4+l8tj6ENXhv8T095MOFdmfmGJfh6Pw4k0eYzaeZhGPRGanr9z05xmt/zkz5auEAGLaCPWB7eAGsJ0YumUSrvTTu6yPdNpHvKIGx29jhwtoAdBWWbgxyaaeBvzC8Dbk6IJAIUdVcITBXD0ChS5g5HicA3vbiNTlEIZCSbDieYLxKFoOgn4LoSnQBEqDqm6La34Qo9nax+LDg0RSaYiFkbpBhTOIroqAiZIWStm4UlIsSuyCjqVD3i3iJmtwbLAKYDubiWlbcWPrqZKCnmL3CuDvga/hxa+cuxAuzimac6TyDwyFQhGlTJYtW8nnP/9PVLe2cmwCSEFrayu7du1i7dq13HHHHZSVlXH48GFuvvlmDh06RLFYZOPGViwr6bWcE8By6OsDXdepqqpidHSUnh7w+4cZGHBZtGgZJ04cxufzcdVVVyGl5IEHHqC1tZVxpk0xNuw/hkdQgQG8mIkzCAaDtLe3s2LFCv7iLz7MT3/6BJoGH/jAH+M4Dtu3bz9JULu6ulixcSNdwSAynwdgZOS4ePbZZ9F1Qw0MJNi2bRvf/OY3ufHGGxkddcWjjz7Hpz71UbZt24Zt21iWxcqVq0jLhRy3wb8wQ4XRxne+8x0uueQSMpkM3/vej2jfegIjX/1bs56zRSivjgQDnDevEUNKXGVgiRIv1KKYDoBoZRkySokt3Exvbyd7tx1hpG+YTLbA8cImmvI+HNcl5uRYY3aR3duOlhghYfjoa3+Qod5VrF4iWLYQjh4qoc9XjlyiaCkq3tAjeFOPoDEoyFqKBWOK2DUCtiAo0Ag04k14L0YoZ1RVr+kg5eg6Y9nlTAzVUdX4GKHqYyixBdcJ4AwsJ7/vbQQHBeG6d1LR/laELaYd/mBidIB/veqL/Oxt94CQVKbgg7e7+JLVFKejtciXr/ozslFCA3QlSYcTDpwAACAASURBVAX87AlW0aCHuOygH0cHYQi0yijBliqOV2zH0kxyIZMJ18f46BgPPd/CYP8pkf/1Obq+k5v0T0M+/UmWnPcFipGrKN+yEVN6G2yqOk3Gd7r0XjFMvGM1URlkStgnU59Iatz35u8y/LaHKbtQZ9HdlUT2VGHpPrKLjtG+2aFyXDHcjmdbOT0w8U7CufjdV17MjSuX45+cQBlTKNOkGA9jxwIIzUDTDDRhoAXL0DItGEkdrQhaVmFlHMaPjjDRM8HUcBa36OLzgxkI4sogjgWmE6bixBo0YwHHA6PsSW5FquIOvED5MybtuWQyw6yZcsaNZG74l3N4FdCFQ9CcxPRLlKERnIyiWwFCu9dzdNVuknKYyppGREh5kVNNMOZb1I4EUQ4oXWD0ZfDvGOL82ASPTV7DWDKK7bgoBMWtZVRUh5C6izJdpOmQ9eUonQphijwoFyFN0ASp0gBP2VcSkQa6PoImDE/LbxuUOpOEghY5AVJaKOmQtyyi8QTvWv4saeGQkTY/XtbHlNOCdaIUTW/AytYQdga4NHQZz7kl+j5n11rgjcA4v+7Ccjpit57D/w9hWQZ1dW1MTAzS19dHSbyVviOADZMNLv3bt1NbW8vwcDW1tRp9fX3s2LGDD33oQzz00EPs2LEDn89HPF6OF29/PkNDB/nxj3/Mhg0bOHToENu2/S8rV67krrvu5sYb17Ju3TqWLFnCnj17+NrXvnbSdzLR28veXbvYv+eAF6NgGsN4hLKzsxOlFH6/HyEE3/zmN9m8eTPvfOeV6LrOwYMH+eEPv09DQwMDfj/NwNNPP01ZWRnvecc7uPPOO+liiiqGOXz4MEJIUVKS4xvf+AaJRIKbbrpJ3X7799i161luuWUXH//4x6moqCCVSjExMcHHPvYVyKzhxBBcf6nL7t27+bM/+zPKy8u55557qQlX09Hz25f92SCUbwdqa+MlLG5tROQkjl6GnHsah8xjTB4iISS7Tgyz95Ff4NgeRXZRFPNBigWFEhoaEFaAUkgJqmjR2vIZNssvYUzFMDqbWKOHWDR8nPXHNJZNTI8600briCGonIQbxiXJFZL+51QpUAMc54WEcsan7eU2cZxeKI3EyAaEHaTMUcjeTbjHNkKhGb+wSQb+BztYS6ymi+jROmy9lKP+w3zoHz7IvtX7ATBceN+din/4Cvidw1SLz2CpCsbZjJprbD3DEEIhxAzh8zbatPS7iGwpM1tZ5CQEkgHqFtXTp/qRrstIboKfdW9nsCYLPhuBCd7BNCjlR8ulMIoaYk8WdUySeYn0XwkU4AuMUr3wB4S2xxGT873vBSz7ZYC+ZQ5H/yvEvAYIx3SyUy6ZjM2zowfouuERZJVN6k02JxZryFVPARM0zv8gVWWPMBWHdo3TRSgFcClw6+KWZvOLH/pTgkL3gkcCShMIQ6GZCk0ItGkNpdAU/ibPlaA45jI1YDHWm8SKZxFKYQY09FApRqwCPQVawdPCVsmD+FzFkF/xxGSnGnXTfXjuIgVmDwmYIZNpPDKZZdbkPaOdPLcx57RAgBIoJdBtHcMyQFP4i0HKkuex7fph+vCxIvEB2ivuxEjoXHr3DZQOhUlsfhpxuJfiLzoYH0ziFGyqks/wlfT5pMlRgY/rDlXRgc700hUNDYVCj6QheYhVFTr9l2mMnZdFRUrof+56fEGD5PwW4uFHsasLjPjGyMSzFEdsyu7/G5S0sJ0ilm1w2Ue+RqRiANsW6Lbizs/+B7b4d3S3lPxABeK7Pub/7DgltbtZWZeh7zH0yR7eh2dN/CUvXAjPbVNn+qSzczir0NmxYzfbtv0U2ED3kZ1obj2aUY/y+QiFQnz9618HzkfTDGpqarjnnnv49re/DcRoalrB3XffTSaTYcOGDQBccMEy7rqrm7vuumv68wWYJqxaFeHee+8lkfAsY83NzTQ0NMxmxWniX758G36/ZPHidRzp9gjE5kiEgYEBPvnJTwJewzR8PlpbW7n77l7g7ukHrGXTpvkM450R3QzU1LRx++0PotR/oOs6mzZtoqvrIE8++Qjr169HCEE2W+Czn/0shhERNTVraZo+FOi9733vyawJIVi8dCMHDoxCFlIpLxTh/fffTyaT4ZEtD1FVfd5LHTM509de0KfOBqFcAwQv3Xg5dmgpVqAURwtR4XYxSQuOozAm9gAOuYzNvVu2E0lDWdDLugJMKX59ZNDUye9M3aWiKoufHJoxgowbmE4JSwY0NDFHazWtxNIU3PSEYMdmjcHdbki6NAJ78TQpM+bvU3c+nwEINM0m3X8Rofa3YRg+NAEEFPmSQ6hAimxKMqTvpbqwD/b1cv9Nd3KkbXZJsfoA3Ppd8GfwbKtKwydGqBX3YZB9yZRfcwhFyDdJXO/HdkOYmRAVyV8nuMXhLLXdUcrLF9E52M5j+54lnyiBp/4O0kGUANP0dvWpL69m3ehnaN3RSWRsnHvdLIdOR1aBnIwzrpqwlgdYPKXw51yKgSL9i08wFNuB+f6jOE+vpbG+nt5jAXbuGGf42geQ0dzJ52jVA0hNIorlOInFSPnIrL779KAS+Mvq6qqmL3/1CwSUBN130o9EaQLlm9ZKCgNNM71LGMiYhbVgnIl5vSSv6CUjh0ns1knsVoT7LycYXwwVGo6CYgfo2FSILgo+ly12B3vd4wk8MlnEm8BnQjPlmNVMZvDI5AzhPKedPJ0QYGmCREAnMBUkNBMsSEGm3EaaGlm7yFBvmPXH/pbz72gkui9KMVFg6q4sh+RPccam8Fne/8IU+bT2K75dsYgF+SCBtLfLe2aklSgKIZud1+7DPPJmEtYQqQX3oA8IDKOPB+7+Icnx+ZTXRun5xBbKV0wRNfyUGD6Ci75Lfaifpc+uxxmZYukV9xJr6sEuClAwFDKYECEgj6WncJrGqX1PkhXBA7hTijID1l4F2+6BzKT4a1BDeEeezPjsnnqizhk86ewcziaCQYfW1hAkl9I19jyf+9wXueOOO4jHYWxsjEAgwKZNmwAYG5uEYJy2pUtJjY2d1CxGoyuw7TFSqdTJTTJLlmQIhTaRTntD6tgYBINeSKCllUuhErJZGBtLIoRDRUUFVGWgeRVSCMK5DPM3RajB+29d3QJWt67mni1PkQKGsrDAD5s26VjWJlKpDPG4p14pLRRYmE6jVVQAWRoaXKamSk7GumxpaaGkpISuri7q6+uBNmCCJUtaice9chkfh4ULFxIKhQhP7yQaSKUI1unkfXmG7UrkWAm6rvPggw+ydNV57Jw57vyl8QJi+Vvtcj2NqAcu9Iei5pI3vBdHr8fVvUMwo/oE5eoYZroDTWRwhWBwLEE6MUUhryNmIvMBxpzpRynQfJKw5hIvQmVRo8IxUX4/voiPQmUDD9Z8lE83fZUnSlZ4f565xPQeYE3DyAlqhuNUiSbw4lGW4WklZ8jki2kpzwAEGEWkf5b8ufoUVmkHaA5KKVK5FIWxCcSxn/DhzyV41+1+fFmvbD72r4oFh5hm4syZus901b8QprJY4B5irfYg64xfsjr/HCHb8n6cY6ySwiafSGKPZhh44DnqfmXRuPU6GN4IwtOVlDlQraDm++vY+PMhakf6cZA4p6mKbBXhieR72DtxA+3NcR594xSPrjvAQ5fsYtu123Ej"
B64 .= "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"
B64 .= "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"
B64 .= "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"
B64 .= "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"
B64 .= "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"
B64 .= "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"
B64 .= "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"
B64 .= "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"
;}
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", DecLen, "UPtr")
pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")
DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, "UPtr", DecLen)
DllCall("Kernel32.dll\GlobalUnlock", "Ptr", hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, "PtrP", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, "Ptr", 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, "PtrP", pBitmap)
If A_ScreenWidth <=1920 && A_ScreenHeight <= 1080
{
	DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", width)
	DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", height)
	oImage.pBitmap:= pBitmap, oImage.height:= height, oImage.width:= width
	pBitMap:= Gdip_ResizeBitmap(oImage, Round(width/2), Round(height/2), 0, 7, 0)
}
DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", width)
DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", height)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
DllCall(NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, "UPtr"), "Ptr", pStream)
oImage.hBitmap:= hBitmap, oImage.height:= height, oImage.width:= width, oImage.pBitmap:= 0
Return oImage
}

#Include %A_ScriptDir%\lib\RichCode.ahk
#Include %A_ScriptDir%\lib\class_bcrypt.ahk
;}



