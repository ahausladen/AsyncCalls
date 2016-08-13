# AsyncCalls - Delphi asynchronous function call framework

With AsyncCalls you can execute multiple functions at the same time and synchronize them
with an **IAsyncCall** interface. This allows you to execute time consuming code in a
different thread whos result is needed at a later time.

The **AsyncCalls.pas** unit offers a variety of function prototypes to call asynchronous
functions.

Inlined VCL/main thread synchronization is supported. With this you can implement the code that
calls a VCL function directly in your thread method without having to use a helper method and
TThread.Synchronize. You have full access to all local variables.
For Delphi 2009 and newer the TAsyncCalls class utilizes generics and anonymous methods.

## Documentation

See [DOCUMENTATION.md](DOCUMENTATION.md)


## Requirements

* Supported compilers: Delphi 5 to 10.1
* Supported platforms: Win32, Win64


## Installation

Add the **AsyncCalls.pas** unit to your project's **uses**-clause.


## Example

### Using an anonymous function
```delphi
procedure TForm1.Button3Click(Sender: TObject); 
var 
  Value: Integer; 
begin 
  TAsyncCalls.Invoke(procedure 
  begin 
    // Executed in a thread
    Value := 10; 
    TAsyncCalls.VCLInvoke(procedure 
    begin 
      ShowMessage('The value may not equal 10: ' + IntToStr(Value)); 
    end); 
    Value := 20; 
    TAsyncCalls.VCLSync(procedure 
    begin 
      ShowMessage('The value equals 20: ' + IntToStr(Value)); 
    end); 
    Value := 30; 
  end); 

  Sleep(1000); 
end; // If the async. function is run yet, the "end" will sync it
```

### Using a global function
```delphi
function GetFiles(Directory: string; Filenames: TStrings): Integer;
var
  h: THandle;
  FindData: TWin32FindData;
begin
  h := FindFirstFile(PChar(Directory + '\*.*'), FindData);
  if h <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (StrComp(FindData.cFileName, '.') <> 0) and (StrComp(FindData.cFileName, '..') <> 0) then
      begin
        Filenames.Add(Directory + '\' + FindData.cFileName);
        if FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
          GetFiles(Filenames[Filenames.Count - 1], Filenames);
      end;
    until not FindNextFile(h, FindData);
    Windows.FindClose(h);
  end;
  Result := 0;
end;

procedure TFormMain.ButtonGetFilesClick(Sender: TObject); 
var
  Dir1, Dir2, Dir3: IAsyncCall;
  Dir1Files, Dir2Files, Dir3Files: TStrings;
begin
  Dir1Files := TStringList.Create;
  Dir2Files := TStringList.Create;
  Dir3Files := TStringList.Create;
  ButtonGetFiles.Enabled := False;
  try
    Dir1 := TAsyncCalls.Invoke<string, TStrings>(GetFiles, 'C:\Windows\System32', Dir1Files);
    Dir2 := TAsyncCalls.Invoke<string, TStrings>(GetFiles, 'D:\Html', Dir2Files);
    Dir3 := TAsyncCalls.Invoke<string, TStrings>(GetFiles, 'E:', Dir3Files);

    { Wait until both async functions have finished their work. While waiting make the UI
	  reacting on user interaction. }
    while AsyncMultiSync([Dir1, Dir2], True, 10) = WAIT_TIMEOUT do
      Application.ProcessMessages;
    Dir3.Sync; // Force the Dir3 function to finish here

    MemoFiles.Lines.Assign(Dir1Files);
    MemoFiles.Lines.AddStrings(Dir2Files);
    MemoFiles.Lines.AddStrings(Dir3Files);
  finally
    ButtonGetFiles.Enabled := True;
    Dir3Files.Free;
    Dir2Files.Free;
    Dir1Files.Free;
  end;
end;
```

