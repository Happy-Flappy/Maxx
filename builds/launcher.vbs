Dim fso, shell, buildEnvDir, scriptDir, helperBatPath

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
buildEnvDir = scriptDir & "\buildEnvironment"
helperBatPath = scriptDir & "\launcherParameters\helper.bat"

shell.CurrentDirectory = scriptDir

shell.Run "cmd /k """ & helperBatPath & """", 1, True

WScript.Sleep 1000

DeleteAllFiles buildEnvDir
DeleteFolder buildEnvDir

Function DeleteAllFiles(folderPath)
    On Error Resume Next
    
    If fso.FolderExists(folderPath) Then
        Dim folder, file, subfolder
        Set folder = fso.GetFolder(folderPath)
        
        For Each file In folder.Files
            fso.DeleteFile file.Path, True
        Next
        
        For Each subfolder In folder.SubFolders
            DeleteAllFiles subfolder.Path
            fso.DeleteFolder subfolder.Path, True
        Next
    End If
    
    On Error GoTo 0
End Function

Function DeleteFolder(folderPath)
    On Error Resume Next
    
    If fso.FolderExists(folderPath) Then
        fso.DeleteFolder folderPath, True
        WScript.Sleep 500
        
        If fso.FolderExists(folderPath) Then
            shell.Run "cmd /c rmdir /s /q """ & folderPath & """", 0, True
            WScript.Sleep 500
        End If
    End If
    
    On Error GoTo 0
End Function
