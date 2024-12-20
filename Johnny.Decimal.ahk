;;; Нормализация имён папок
;;; 2024-05-13 - первая рабочая версия
;;; 2024-12-21 - последняя правка

ver = ver. 1.1 on 2024-12-21
FormatTime, t1, ,yyyyMMddHHmmss
root := A_WorkingDir
index = %A_WorkingDir%\index.md
hystory = %A_WorkingDir%\hystory.md
flag = %A_WorkingDir%\flag.md

;LCID_0019 := "Russian"  ; ru
;LCID_0819 := "Russian (Moldova)"  ; ru-MD
;LCID_0419 := "Russian (Russia)"  ; ru-RU
isRu := A_Language=00419

total = 0 ; 1 - сообщить итоги работы
total := FileExist(flag)
if total
	isRu := false
mode = 0 ; 1 - сообщать о папках с несистемным именем
count = 0 ; счётчик нормализованных папок
skip = 0 ; счётчки пропущенных папок
n_area = 0 ; количество арий
n_cate = 0 ; количество категорий

;;; Первый проход, первый заход в Areas
Loop Files, %root%\*, D
{
;	if RenameDir( "^\d\d\s", 4, 1) ; 12 текст -> 12 Текст
;		continue
	if RenameDir( "^\d\d-\d\d", 6) ; 12-34текст -> 10-19 Текст
		continue
	if RenameDir( "^\d\d", 3) ; 12текст -> 10-19 Текст
		continue
	if RenameDir( "^\d", 2) ; 1текст -> 10-19 Текст
		continue
}

;;; Второй проход, первый заход в Categories
Loop Files, %root%\*, D
	if A_LoopFileName ~= "^\d"
	{
		i := SubStr(A_LoopFileName, 1, 1)
		Loop Files, %A_LoopFileFullPath%\*, D
		{
			if A_LoopFileName ~= "^\d\d" ; X*\YZтекст -> X*\XZтекст
			{
				name := A_LoopFileDir . "\" . i . SubStr(A_LoopFileName, 2)
				FileMoveDir, %A_LoopFileFullPath%, %name%, R
				count++
				continue
			}
			if A_LoopFileName ~= "^\d" ; X*\Zтекст -> X*\XZтекст
			{
				name := A_LoopFileDir . "\" . i . A_LoopFileName
				FileMoveDir, %A_LoopFileFullPath%, %name%, R
				count++
				continue
			}
			FolderAlert(2)
		}
		n_area++
	} else
		FolderAlert(1)

;;; Третий проход, второй заход в Categories
Loop Files, %root%\*, D
	if A_LoopFileName ~= "^\d"
		Loop Files, %A_LoopFileFullPath%\*, D
			RenameDir( "^\d\d", 3, 1) ; X*\XZтекст -> X*\XZ Текст

;;; Четвёртый проход, первый заход в Items
loop Files, %root%\*, D
	if A_LoopFileName ~= "^\d"
		Loop Files, %A_LoopFileFullPath%\*, D
			if A_LoopFileName ~= "^\d\d\s"
			{
				i := SubStr(A_LoopFileName, 1, 2)
				name := false
				Loop Files, %A_LoopFileFullPath%\*, D
				{
					If A_LoopFileName ~= "^\d\d\.\d\d" ; XY\AB.CDтекст -> XY\XY.CD Текст
						name := A_LoopFileDir . "\" . i . "." . SubStr(A_LoopFileName, 4, 2) . " " . Sentence(SubStr(A_LoopFileName, 6))
					else if A_LoopFileName ~= "^\d\d\.\d" ; XY\Cтекст -> XY\XY.0C Текст
						name := A_LoopFileDir . "\" . i . ".0" . SubStr(A_LoopFileName, 4, 1) . " " . Sentence(SubStr(A_LoopFileName, 5))
					else if A_LoopFileName ~= "^\d\d" ; XY\CDтекст -> XY\XY.CD Текст
						name := A_LoopFileDir . "\" . i . "." . SubStr(A_LoopFileName, 1, 2) . " " . Sentence(SubStr(A_LoopFileName, 3))
					else if A_LoopFileName ~= "^\d" ; XY\Cтекст -> XY\XY.0C Текст
						name := A_LoopFileDir . "\" . i . ".0" . SubStr(A_LoopFileName, 1, 1) . " " . Sentence(SubStr(A_LoopFileName, 2))
					If name
					{
						FileMoveDir, %A_LoopFileFullPath%, %name%, R
						count++
					}
					else
						FolderAlert(3)
				}
				n_cate++
			}

;;; Сообщение о результатах
If total
{
	if isRu
		mess =  Нормализовано папок:`t%count%`nПропущено папок:`t`t%skip%`n`nОглавление сейчас будет записано в файл:`n%index%
	else
		mess =  Folders normalized:`t%count%`nFolders skipped:`t%skip%`n`nThe TOC will be written to the file:`n%index%
	MsgBox, 64, Johnny.Decimal folders' normalization tool %ver%, %mess%
}

;;; Файл index.md
FileDelete, %index%
FileEncoding, UTF-8
RegExMatch(root, "[^\\]*$", name)
git := GetSize(".git")
bytes := GetFolderSize(root, size, false)
git := false
green = <span style="color:green">
red = <span style="color:red">
blue = <span style="color:blue">
FileAppend, # %green%%name%</span> [%size%](<file:///%root%>) %red%A%n_area%</span>/%blue%C%n_cate%</span> [[hystory.md|📜]]`n, %index%
If Not FileExist(hystory)
	FileAppend, | Date | %red%A</span> | %blue%C</span> | %green%Size`, MB</span>|`n|---|---|---|---|`n, %hystory%
FormatTime, t2, ,yyyy-MM-dd HH:mm:ss
size := Format("{:.1f}", GetSize(root) / 1024 / 1024)
FileAppend, | %t2% | %n_area% | %n_cate% | %size% |`n, %hystory%
chart = `n`n---`n`n# Chart of categories`n``````tinychart`n
piech = `n`n``````mermaid`npie title Pie chart`n
Loop Files, %root%\*, D
	if A_LoopFileName ~= "^\d"
	{
		path0 := A_LoopFileName
		bytes := GetFolderSize(A_LoopFileFullPath, size, false)
		FileAppend, ---`n## %A_LoopFileName% [%size%](<file:///%A_LoopFileFullPath%>)`n, %index%
		Loop Files, %A_LoopFileFullPath%\*, D
			if A_LoopFileName ~= "^\d\d\s"
			{
				path1 := path0 . "/" . A_LoopFileName
				bytes := GetFolderSize(A_LoopFileFullPath, size, false)
				FileAppend, ### %A_LoopFileName% [%size%](<file:///%A_LoopFileFullPath%>)`n, %index%
				chart .= A_LoopFileName . Format(", {:d}", bytes) . "`n"
				piech .= """" .  A_LoopFileName . Format(""" : {:.1f}`n", bytes)
				indexID := A_LoopFileFullPath . "\" . SubStr(A_LoopFileName, 1, 2) . ".00"
				IfExist, %indexID%
				{
					path2 := path1 . "/" . SubStr(A_LoopFileName, 1, 2) . ".00"
					If FileExist(indexID . "\*.jpg") or FileExist(indexID . "\*.jpeg") or FileExist(indexID . "\*.png")
					{
						t := isRu ? "Вид" : "Look"
						FileAppend, > [!tip]- %t%`n, %index%
						Loop Files, %indexID%\*, F
							If InStr("jpg_jpeg_png", A_LoopFileExt)
								FileAppend, ![](<%path2%/%A_LoopFileName%>)&nbsp;, %index%
						FileAppend, `n`n, %index%
					}
					AppendCallout("readme", "Суть", "Point", "info")
					AppendCallout("nimbus", "Облако", "Cloud", "abstract")
					AppendCallout("tempus", "Время", "Time", "danger", false)
				}
				b_has_md := false
				If FileExist(A_LoopFileFullPath . "\" . SubStr(A_LoopFileName, 1, 2) . "*")
				{
					t := isRu ? "Склад" : "Store"
					FileAppend, > [!example]- %t%`n, %index%
					Loop Files, %A_LoopFileFullPath%\*, D
					{
						If Not b_has_md
							b_has_md := (Not A_LoopFileName ~=  "^\d\d\.00$") And FileExist(A_LoopFileFullPath . "\*.md")
						if A_LoopFileName ~= "^\d\d\.\d\d"
						{
							bytes := GetFolderSize(A_LoopFileFullPath, size)
							s := A_LoopFileName
							if InStr(A_LoopFileName, "■")
								s := "*" . s . "*"
							else
								s .= " [" . size . "](<file:///" . A_LoopFileFullPath . ">)"
							FileAppend, %s%`n, %index%
						}
					}
					If b_has_md
					{
						FileAppend, `n, %index%
						t := isRu ? "Заметки" : "Notes"
						FileAppend, > [!quote]- %t%`n, %index%
						Loop Files, %A_LoopFileFullPath%\*, D
							If Not A_LoopFileName ~=  "^\d\d\.00$"
							{
								path2 := path1 . "/" . A_LoopFileName
								Loop Files, %A_LoopFileFullPath%\*.md
									FileAppend, > [[%path2%/%A_LoopFileName%|%A_LoopFileName%>>]]`n, %index%
							}
					}
					FileAppend, `n, %index%
				}
			}
	} else if Not A_LoopFileName ~= "^\." {
		bytes := GetFolderSize(A_LoopFileFullPath, size)
		chart .= A_LoopFileName . Format(", {:d}", bytes) . "`n"
		piech .= """" .  A_LoopFileName . Format(""" : {:.1f}`n", bytes)
	}

chart .= "```````n"
piech .= "```````n"
FileAppend, %chart%, %index%
FileAppend, %piech%, %index%
IfExist, index.jpg
	FileAppend, ---`n![](index.jpg)`n, %index%
FormatTime, t2, ,yyyyMMddHHmmss
t2 -= t1, "yyyyMMddHHmmss"
if isRu
	FileAppend, `n*Файл создан в день %A_YDay% во время %A_Hour%:%A_Min% за %t2% сек. / %A_UserName%@%A_ComputerName%!%A_OSVersion%*`n, %index%
else
	FileAppend, `n*This file was created on the %A_YDay% day at %A_Hour%:%A_Min% in %t2% seconds / %A_UserName%@%A_ComputerName%!%A_OSVersion%*`n, %index%

;;; Сообщение о результатах
If total
{
	if isRu
		mess =  Файл`n%index%`nзаписан.`n`nДля просмотра в Obsidian надо открыть хранилище по адресу`n%root%`nи перейти к файлу index.md.
	else
		mess =  The file`n%index%`nwas written.`n`nTo observe this one in the Obsidian application open the vault at`n%root%`nand navigate to the file index.md.
	MsgBox, 64, Johnny.Decimal folders' normalization tool %ver%, %mess%
}
ExitApp

;;; Размер файлов в папке в МБ или КБ
GetFolderSize(path, ByRef txt, isFloat:=true)
{
	global isRu, total, git

	size := GetSize(path)
	if git
		size -= git
	size /= 1024.0
	if not total
		size /= 1024
	FormatStr := "(" . (isFloat ? "{:.1f}" : "{:d}") . (total ? "&nbsp;" : " ") . (isRu ? (total ? "КБ" : "МБ") : (total ? "KB" : "MB")) . ")"
	txt := Format(FormatStr, size)
	if isFloat and isRu	; запятая дробной части по-русски
		txt := StrReplace(txt, ".", ",")
	if (size >= 1000)		; отбивка тысяч апострофом
	{
		pos := StrLen(Format("{:d}", size/1000))
		txt := SubStr(txt, 1, pos+1) . "'" .  SubStr(txt, pos+2)
	}
	return size
}

GetSize(path)
{
	return FileExist(path) ? ComObjCreate("Scripting.FileSystemObject").GetFolder(path).Size : false
}

;;; Сообщение о неформатной папке и ея уровне
FolderAlert(l)
{
	global
	skip++
	If mode = 1
		MsgBox, 49, Уровень: %l%, %A_LoopFileDir% `n`n`t %A_LoopFileName%
		IfMsgBox, Cancel
			ExitApp
	return
}

;;; Делает первую букву строки прописной и удаляем лишнии пробелы слева
Sentence(s)
{
	z := Trim(s)
	x := SubStr(z, 1, 1)
	StringUpper, x, x
	y := SubStr(z, 2)
	return x . y
}

;;; Меняет имя Area (b=0) или Category (b=1)
RenameDir(s, n, b:=0) ; b=1 - сохраняем двубуквие
{
	global count
	res := RegExMatch(A_LoopFileName, s, x)
	if res
	{
		a := SubStr(A_LoopFileName, 1, 1+b) ; только первая цифра или две первых
		c := Sentence(SubStr(A_LoopFileName, n)) ; текст
		if b {
			c := A_LoopFileDir . "\" . a . " " . c
		} else {
			c := A_LoopFileDir . "\" . a . "0-" . a . "9 " . c
		}
		FileMoveDir, %A_LoopFileFullPath%, %c%, R
		count++
	}
	return res
}

;;; Вставляет сложенную вкладку
AppendCallout(fn, ru_tag, en_tag, tag, b:=true)
{
	Global indexID, path2, isRu, index
	IfExist, %indexID%\%fn%.md
	{
		t := isRu ? ru_tag : en_tag
		FileAppend, > [!%tag%]- %t%`n, %index%
		FileAppend, > [[%path2%/%fn%|%fn%>>]]`n, %index%
		Loop, read, %indexID%\%fn%.md
		{
			If b
			{
				IfEqual, A_LoopReadLine, ---, break
				FileAppend, >%A_LoopReadLine%`n, %index%
			}
			else
			{
				FileAppend, >%A_LoopReadLine%`n, %index%
				IfEqual, A_LoopReadLine, ``````, break
			}
		}
		FileAppend, `n, %index%
	}
}

