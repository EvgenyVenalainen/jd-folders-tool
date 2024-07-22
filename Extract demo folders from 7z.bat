set fn=demo-folders.7z
for /d %%d in (*) do rd /q /s "%%d"
"C:\Program Files\7-Zip\7z.exe" x %fn%
rem del index.md