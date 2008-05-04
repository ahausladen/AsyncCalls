{**************************************************************************************************}
{                                                                                                  }
{ Asynchronous function calls utilizing multiple threads.                                          }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is AsyncCalls.pas.                                                             }
{                                                                                                  }
{ The Initial Developer of the Original Code is Andreas Hausladen.                                 }
{ Portions created by Andreas Hausladen are Copyright (C) 2006-2008 Andreas Hausladen.             }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{ Contributor(s):                                                                                  }
{                                                                                                  }
{**************************************************************************************************}
{$A+,B-,C+,D-,E-,F-,G+,H+,I+,J-,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W+,X+,Y+,Z1}

unit AsyncCalls;

{.$DEFINE DEBUG_ASYNCCALLS}

interface

{$IFNDEF CONDITIONALEXPRESSIONS}
  'Your compiler version is not supported'
{$ELSE}
  {$IFDEF VER140}
    {$DEFINE DELPHI6}
    {.$MESSAGE ERROR 'Your compiler version is not supported'}
  {$ENDIF}
{$ENDIF}

{$WARN SYMBOL_PLATFORM OFF}
{$WARN UNIT_PLATFORM OFF}
{$IF CompilerVersion >= 15.0}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
{$IFEND}

{$IF CompilerVersion >= 18.0}
  {$DEFINE SUPPORTS_INLINE}
{$IFEND}

{$IFDEF DEBUG_ASYNCCALLS}
  {$D+,C+}
{$ENDIF DEBUG_ASYNCCALLS}

uses
  Windows, Messages, SysUtils, Classes, Contnrs, ActiveX, SyncObjs;

type
  {$IF not declared(INT_PTR)}
  INT_PTR = Integer;
  {$IFEND}

  TAsyncIdleMsgMethod = procedure of object;

  TCdeclFunc = Pointer; // function(Arg1: Type1; Arg2: Type2; ...); cdecl;
  TCdeclMethod = TMethod; // function(Arg1: Type1; Arg2: Type2; ...) of object; cdecl;
  TLocalAsyncProc = function: Integer;
  TLocalVclProc = function(Param: INT_PTR): INT_PTR;
  TLocalAsyncProcEx = function(Param: INT_PTR): INT_PTR;
  //TLocalAsyncForLoopProc = function(Index: Integer; SyncLock: TCriticalSection): Boolean;

  TAsyncCallArgObjectProc = function(Arg: TObject): Integer;
  TAsyncCallArgIntegerProc = function(Arg: Integer): Integer;
  TAsyncCallArgStringProc = function(const Arg: AnsiString): Integer;
  TAsyncCallArgWideStringProc = function(const Arg: WideString): Integer;
  TAsyncCallArgInterfaceProc = function(const Arg: IInterface): Integer;
  TAsyncCallArgExtendedProc = function(const Arg: Extended): Integer;
  TAsyncCallArgVariantProc = function(const Arg: Variant): Integer;

  TAsyncCallArgObjectMethod = function(Arg: TObject): Integer of object;
  TAsyncCallArgIntegerMethod = function(Arg: Integer): Integer of object;
  TAsyncCallArgStringMethod = function(const Arg: AnsiString): Integer of object;
  TAsyncCallArgWideStringMethod = function(const Arg: WideString): Integer of object;
  TAsyncCallArgInterfaceMethod = function(const Arg: IInterface): Integer of object;
  TAsyncCallArgExtendedMethod = function(const Arg: Extended): Integer of object;
  TAsyncCallArgVariantMethod = function(const Arg: Variant): Integer of object;

  TAsyncCallArgObjectEvent = procedure(Arg: TObject) of object;
  TAsyncCallArgIntegerEvent = procedure(Arg: Integer) of object;
  TAsyncCallArgStringEvent = procedure(const Arg: AnsiString) of object;
  TAsyncCallArgWideStringEvent = procedure(const Arg: WideString) of object;
  TAsyncCallArgInterfaceEvent = procedure(const Arg: IInterface) of object;
  TAsyncCallArgExtendedEvent = procedure(const Arg: Extended) of object;
  TAsyncCallArgVariantEvent = procedure(const Arg: Variant) of object;

  TAsyncCallArgRecordProc = function(var Arg{: TRecordType}): Integer;
  TAsyncCallArgRecordMethod = function(var Arg{: TRecordType}): Integer of object;
  TAsyncCallArgRecordEvent = procedure(var Arg{: TRecordType}) of object;

  EAsyncCallError = class(Exception);

  IAsyncCall = interface
    { Sync() waits until the asynchronous call has finished and returns the
      result value of the called function if that exists. }
    function Sync: Integer;

    { Finished() returns True if the asynchronous call has finished. }
    function Finished: Boolean;

    { ReturnValue() returns the result of the asynchronous call. It raises an
      exception if called before the function has finished. }
    function ReturnValue: Integer;

    { ForceDifferentThread() tells AsyncCalls that the assigned function must
      not be executed in the current thread. }
    procedure ForceDifferentThread;
  end;


{ SetMaxAsyncCallThreads() controls how many threads can be used by the
  async call thread pool. The thread pool creates threads when they are needed.
  Allocated threads are not destroyed until the application has terminated, but
  they are suspended if not used. }
procedure SetMaxAsyncCallThreads(MaxThreads: Integer);
{ GetMaxAsyncCallThreads() returns the maximum number of threads that can
  exist in the thread pool. }
function GetMaxAsyncCallThreads: Integer;


{ AsyncCall() executes the given function/procedure in a separate thread. The
  result value of the asynchronous function is returned by IAsyncCall.Sync() and
  IAsyncCall.ReturnValue().
  The AsyncExec() function calls the IdleMsgMethod in a loop, while the async.
  method is executed.

Example:
  function FileAgeAsync(const Filename: string): Integer;
  begin
    Result := FileAge(Filename);
  end;

  var
    a: IAsyncCall;
  begin
    a := AsyncCall(FileAgeAsync, 'C:\Windows\notepad.exe');
    // do something
    Age := a.Sync;
  end;
}
function AsyncCall(Proc: TAsyncCallArgObjectProc; Arg: TObject): IAsyncCall; overload;
function AsyncCall(Proc: TAsyncCallArgIntegerProc; Arg: Integer): IAsyncCall; overload;
function AsyncCall(Proc: TAsyncCallArgStringProc; const Arg: AnsiString): IAsyncCall; overload;
function AsyncCall(Proc: TAsyncCallArgWideStringProc; const Arg: WideString): IAsyncCall; overload;
function AsyncCall(Proc: TAsyncCallArgInterfaceProc; const Arg: IInterface): IAsyncCall; overload;
function AsyncCall(Proc: TAsyncCallArgExtendedProc; const Arg: Extended): IAsyncCall; overload;
function AsyncCallVar(Proc: TAsyncCallArgVariantProc; const Arg: Variant): IAsyncCall; overload;

function AsyncCall(Method: TAsyncCallArgObjectMethod; Arg: TObject): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgIntegerMethod; Arg: Integer): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgStringMethod; const Arg: AnsiString): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgWideStringMethod; const Arg: WideString): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgInterfaceMethod; const Arg: IInterface): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgExtendedMethod; const Arg: Extended): IAsyncCall; overload;
function AsyncCallVar(Method: TAsyncCallArgVariantMethod; const Arg: Variant): IAsyncCall; overload;

function AsyncCall(Method: TAsyncCallArgObjectEvent; Arg: TObject): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgIntegerEvent; Arg: Integer): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgStringEvent; const Arg: AnsiString): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgWideStringEvent; const Arg: WideString): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgInterfaceEvent; const Arg: IInterface): IAsyncCall; overload;
function AsyncCall(Method: TAsyncCallArgExtendedEvent; const Arg: Extended): IAsyncCall; overload;
function AsyncCallVar(Method: TAsyncCallArgVariantEvent; const Arg: Variant): IAsyncCall; overload;

procedure AsyncExec(Method: TNotifyEvent; Arg: TObject; IdleMsgMethod: TAsyncIdleMsgMethod);

{ LocalAsyncCall() executes the given local function/procedure in a separate thread.
  The result value of the asynchronous function is returned by IAsyncCall.Sync() and
  IAsyncCall.ReturnValue().
  The LocalAsyncExec() function calls the IdleMsgMethod while the local procedure is
  executed.

Example:
  procedure MainProc(const S: string);
  var
    Value: Integer;
    a: IAsyncCall;

    function DoSomething: Integer;
    begin
      if S = 'Abc' then
        Value := 1;
      Result := 0;
    end;

  begin
    a := LocalAsyncCall(@DoSomething);
    // do something
    a.Sync;

    LocalAsyncExec(@DoSomething, Application.ProcessMessages);
  end;
}
function LocalAsyncCall(LocalProc: TLocalAsyncProc): IAsyncCall;
function LocalAsyncCallEx(LocalProc: TLocalAsyncProcEx; Param: INT_PTR): IAsyncCall;
procedure LocalAsyncExec(Proc: TLocalAsyncProc; IdleMsgMethod: TAsyncIdleMsgMethod);



{ LocalVclCall() executes the given local function/procedure in the main thread. It
  uses the TThread.Synchronize function which blocks the current thread.
  LocalAsyncVclCall() execute the given local function/procedure in the main thread.
  It does not wait for the main thread to execute the function unless the current
  thread is the main thread. In that case it executes and waits for the specified
  function in the current thread like LocalVclCall().

  The result value of the asynchronous function is returned by IAsyncCall.Sync() and
  IAsyncCall.ReturnValue().

Example:
  procedure TForm1.MainProc;

    procedure DoSomething;

      procedure UpdateProgressBar(Percentage: Integer);
      begin
        ProgressBar.Position := Percentage;
        Sleep(20); // This delay does not affect the time for the 0..100 loop
                   // because UpdateProgressBar is non-blocking.
      end;

      procedure Finished;
      begin
        ShowMessage('Finished');
      end;

    var
      I: Integer;
    begin
      for I := 0 to 100 do
      begin
        // Do some time consuming stuff
        Sleep(30);
        LocalAsyncVclCall(@UpdateProgressBar, I); // non-blocking
      end;
      LocalVclCall(@Finished); // blocking
    end;

  var
    a: IAsyncCall;
  begin
    a := LocalAsyncCall(@DoSomething);
    a.ForceDifferentThread; // Do not execute in the main thread because this will
                            // change LocalAyncVclCall into a blocking LocalVclCall
    // do something
    //a.Sync; The Compiler will call this for us in the Interface._Release method
  end;
}

procedure LocalVclCall(LocalProc: TLocalVclProc; Param: INT_PTR = 0);
function LocalAsyncVclCall(LocalProc: TLocalVclProc; Param: INT_PTR = 0): IAsyncCall;



{ AsyncCallEx() executes the given function/procedure in a separate thread. The
  Arg parameter can be a record type. The fields of the record can be modified
  in the asynchon function.

Example:
  type
    TData = record
      Value: Integer;
    end;

  procedure TestRec(var Data: TData);
  begin
    Data.Value := 70;
  end;

  a := AsyncCallEx(@TestRec, MyData);
  a.Sync; // MyData.Value is now 70
}
function AsyncCallEx(Proc: TAsyncCallArgRecordProc; var Arg{: TRecordType}): IAsyncCall; overload;
function AsyncCallEx(Method: TAsyncCallArgRecordMethod; var Arg{: TRecordType}): IAsyncCall; overload;
function AsyncCallEx(Method: TAsyncCallArgRecordEvent; var Arg{: TRecordType}): IAsyncCall; overload;


{ The following AsyncCall() functions support variable parameters. All reference
  counted types are protected by an AddRef and later Release. The ShortString,
  Extended, Currency and Int64 types are internally copied to a temporary location.

Supported types:
  Integer      :  Arg: Integer
  Boolean      :  Arg: Boolean
  Char         :  Arg: AnsiChar
  WideChar     :  Arg: WideChar
  Int64        :  [const] Arg: Int64
  Extended     :  [const] Arg: Extended
  Currency     :  [const] Arg: Currency
  String       :  [const] Arg: ShortString
  Pointer      :  [const] Arg: Pointer
  PChar        :  [const] Arg: PChar
  Object       :  [const] Arg: TObject
  Class        :  [const] Arg: TClass
  AnsiString   :  [const] Arg: AnsiString
  PWideChar    :  [const] Arg: PWideChar
  WideString   :  [const] Arg: WideString
  Interface    :  [const] Arg: IInterface
  Variant      :  const Arg: Variant

Example:
  procedure Test(const S: string; I: Integer; E: Extended; Obj: TObject); cdecl;
  begin
  end;

  AsyncCall(@Test, ['Hallo', 10, 3.5, MyObject]);
}
function AsyncCall(Proc: TCdeclFunc; const Args: array of const): IAsyncCall; overload;
function AsyncCall(Proc: TCdeclMethod; const Args: array of const): IAsyncCall; overload;



{ AsyncMultiSync() waits for the async calls and other handles to finish.
  MsgAsyncMultiSync() waits for the async calls, other handles and the message queue.

  Arguments:
    List            : An array of IAsyncCall interfaces for which the function
                      should wait.

    Handles         : An array of THandle for which the function should wait.

    WaitAll = True  : The function returns when all listed async calls have
                      finished. If Milliseconds is INFINITE the async calls
                      meight be executed in the current thread.
                      The return value is zero when all async calls have finished.
                      Otherwise it is -1.
                      
    WaitAll = False : The function returns when at least one of the async calls
                      has finished. The return value is the list index of the
                      first finished async call. If there was a timeout, the
                      return value is -1.

    Milliseconds    : Specifies the number of milliseconds to wait until a
                      timeout happens. The value INFINITE lets the function wait
                      until all async calls have finished.

    dwWakeMask      : see Windows.MsgWaitForMultipleObjects()

  Limitations:
    Length(List)+Length(Handles) must not exceed 62.

  Return value:
    WAIT_TIMEOUT
      The function timed out

    WAIT_OBJECT_0+index
      The first finished async call
    WAIT_OBJECT_0+Length(List)+index
      The first signaled handle
    WAIT_OBJECT_0+Length(List)+Length(Handles)
      A message was signaled

    WAIT_ABANDONED_0+index
      The abandoned async call
    WAIT_ABANDONED_0+Length(List)+index
      The abandoned handle

}
function AsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean = True;
  Milliseconds: Cardinal = INFINITE): Integer;
function AsyncMultiSyncEx(const List: array of IAsyncCall; const Handles: array of THandle;
  WaitAll: Boolean = True; Milliseconds: Cardinal = INFINITE): Integer;
function MsgAsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean;
  Milliseconds: Cardinal; dwWakeMask: DWORD): Integer;
function MsgAsyncMultiSyncEx(const List: array of IAsyncCall; const Handles: array of THandle;
  WaitAll: Boolean; Milliseconds: Cardinal; dwWakeMask: DWORD): Integer;

{
   EnterMainThread/LeaveMainThread can be used to temporary switch to the
   main thread. The code that should be synchonized (blocking) has to be put
   into a try/finally block and the LeaveMainThread() function must be called
   from the finally block. A missing try/finally will lead to an access violation.
   
   * All local variables can be used. (EBP points to the thread's stack while
     ESP points the the main thread's stack)
   * Unhandled exceptions are passed to the surrounding thread.
   * The integrated Debugger is not able to follow the execution flow. You have
     to use break points instead of "Step over/in".
   * Nested calls to EnterMainThread/LeaveMainThread are ignored. But they must
     strictly follow the try/finally structure.

   Example:

     procedure MyThreadProc;
     var
       S: string;
     begin
       Assert(GetCurrentThreadId <> MainThreadId);
       S := 'Hallo, I''m executed in the main thread';

       EnterMainThread;
       try
         Assert(GetCurrentThreadId = MainThreadId);
         ShowMessage(S);
       finally
         LeaveMainThread;
       end;

       Assert(GetCurrentThreadId <> MainThreadId);
     end;
}
procedure EnterMainThread;
procedure LeaveMainThread;

implementation

resourcestring
  RsAsyncCallNotFinished = 'The asynchronous call is not finished yet';
  RsAsyncCallUnknownVarRecType = 'Unknown TVarRec type %d';
  RsLeaveMainThreadNestedError = 'Unpaired call to AsyncCalls.LeaveMainThread()';
  RsLeaveMainThreadThreadError = 'AsyncCalls.LeaveMainThread() was called outside of the main thread';

{$IFDEF DELPHI6}
var
  OrgWakeMainThread: TNotifyEvent;

var
  SyncEvent: THandle;

type
  TThread = class(Classes.TThread)
  private
    class procedure WakeMainThread(Sender: TObject);
  public
    class procedure StaticSynchronize(AThread: TThread; AMethod: TThreadMethod);
  end;

class procedure TThread.StaticSynchronize(AThread: TThread; AMethod: TThreadMethod);
var
  Obj: TThread;
begin
  if GetCurrentThreadId = MainThreadId then
    AMethod
  else if AThread <> nil then
    AThread.Synchronize(AMethod)
  else
  begin
    {$WARNINGS OFF}
    Obj := TThread.Create(True);
    {$WARNINGS ON}
    try
      Obj.Synchronize(AMethod);
    finally
      Obj.Free;
    end;
  end;
end;

class procedure TThread.WakeMainThread(Sender: TObject);
begin
  if Assigned(OrgWakeMainThread) then
    OrgWakeMainThread(Sender);
  SetEvent(SyncEvent);
end;

procedure HookWakeMainThread;
begin
  OrgWakeMainThread := Classes.WakeMainThread;
  Classes.WakeMainThread := TThread.WakeMainThread;
end;

procedure UnhookWakeMainThread;
begin
  Classes.WakeMainThread := OrgWakeMainThread;
end;
{$ENDIF DELPHI6}

type
  TAsyncCall = class;

  IAsyncCallEx = interface
    ['{A31D8EE4-17B6-4FC7-AC94-77887201EE56}']
    function GetEvent: THandle;
    function SyncInThisThreadIfPossible: Boolean;
  end;

  { TAsyncCallThread is a pooled thread. It looks itself for work. }
  TAsyncCallThread = class(TThread)
  protected
    procedure Execute; override;
  public
    procedure ForceTerminate;
  end;

  { TThreadPool contains a pool of threads that are either suspended or busy. }
  TThreadPool = class(TObject)
  private
    FMaxThreads: Integer;
    FThreads: TThreadList;
    FAsyncCalls: TThreadList;
    FNumberOfProcessors: Cardinal;

    FMainThreadSyncEvent: THandle;
    FMainThreadVclHandle: HWND;
    procedure MainThreadWndProc(var Msg: TMessage);
    procedure ProcessMainThreadSync;

    function AllocThread: TAsyncCallThread;
    function GetNextAsyncCall(Thread: TAsyncCallThread): TAsyncCall; // called from the threads
  public
    constructor Create;
    destructor Destroy; override;

    procedure SendVclSync(Call: TAsyncCall);

    procedure AddAsyncCall(Call: TAsyncCall);
    function RemoveAsyncCall(Call: TAsyncCall): Boolean;

    property MaxThreads: Integer read FMaxThreads;
    property NumberOfProcessors: Cardinal read FNumberOfProcessors;
    property MainThreadSyncEvent: THandle read FMainThreadSyncEvent;
  end;

  { TSyncCall is a fake IAsyncCall implementor. The async call was already
    executed when the interface is returned. }
  TSyncCall = class(TInterfacedObject, IAsyncCall)
  private
    FReturnValue: Integer;
  public
    constructor Create(AReturnValue: Integer);
    function Sync: Integer;
    function Finished: Boolean;
    function ReturnValue: Integer;
    procedure ForceDifferentThread;
  end;

  { TAsyncCall is the base class for all parameter based async call types }
  TAsyncCall = class(TInterfacedObject, IAsyncCall, IAsyncCallEx)
  private
    FEvent: THandle;
    FReturnValue: Integer;
    FFinished: Boolean;
    FFatalException: Exception;
    FFatalErrorAddr: Pointer;
    FForceDifferentThread: Boolean;
    procedure InternExecuteAsyncCall;
    procedure InternExecuteSyncCall;
    procedure Quit(AReturnValue: Integer);
  protected
    { Decendants must implement this method. It is called  when the async call
      should be executed. }
    function ExecuteAsyncCall: Integer; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    function ExecuteAsync: TAsyncCall;
    function SyncInThisThreadIfPossible: Boolean;

    function GetEvent: Cardinal;

    function Sync: Integer;
    function Finished: Boolean;
    function ReturnValue: Integer;
    procedure ForceDifferentThread;
  end;

{ ---------------------------------------------------------------------------- }

  TAsyncCallArgObject = class(TAsyncCall)
  private
    FProc: TAsyncCallArgObjectProc;
    FArg: TObject;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgObjectProc; AArg: TObject);
  end;

  TAsyncCallArgString = class(TAsyncCall)
  private
    FProc: TAsyncCallArgStringProc;
    FArg: AnsiString;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgStringProc; const AArg: AnsiString);
  end;

  TAsyncCallArgWideString = class(TAsyncCall)
  private
    FProc: TAsyncCallArgWideStringProc;
    FArg: WideString;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgWideStringProc; const AArg: WideString);
  end;

  TAsyncCallArgInterface = class(TAsyncCall)
  private
    FProc: TAsyncCallArgInterfaceProc;
    FArg: IInterface;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgInterfaceProc; const AArg: IInterface);
  end;

  TAsyncCallArgExtended = class(TAsyncCall)
  private
    FProc: TAsyncCallArgExtendedProc;
    FArg: Extended;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgExtendedProc; const AArg: Extended);
  end;

  TAsyncCallArgVariant = class(TAsyncCall)
  private
    FProc: TAsyncCallArgVariantProc;
    FArg: Variant;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgVariantProc; const AArg: Variant);
  end;

{ ---------------------------------------------------------------------------- }

  TAsyncCallLocalProc = class(TAsyncCall)
  private
    FProc: TLocalAsyncProc;
    FBasePointer: Pointer;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TLocalAsyncProc; ABasePointer: Pointer);
  end;

  TAsyncCallLocalProcEx = class(TAsyncCall)
  private
    FProc: TLocalAsyncProc;
    FBasePointer: Pointer;
    FParam: INT_PTR;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TLocalAsyncProc; AParam: INT_PTR; ABasePointer: Pointer);
  end;

  TAsyncVclCallLocalProc = class(TAsyncCall)
  private
    FProc: TLocalVclProc;
    FBasePointer: Pointer;
    FParam: INT_PTR;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TLocalVclProc; AParam: INT_PTR; ABasePointer: Pointer);
  end;

{ ---------------------------------------------------------------------------- }

  TAsyncCallMethodArgObject = class(TAsyncCall)
  private
    FProc: TAsyncCallArgObjectMethod;
    FArg: TObject;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgObjectMethod; AArg: TObject);
  end;

  TAsyncCallMethodArgString = class(TAsyncCall)
  private
    FProc: TAsyncCallArgStringMethod;
    FArg: AnsiString;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgStringMethod; const AArg: AnsiString);
  end;

  TAsyncCallMethodArgWideString = class(TAsyncCall)
  private
    FProc: TAsyncCallArgWideStringMethod;
    FArg: WideString;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgWideStringMethod; const AArg: WideString);
  end;

  TAsyncCallMethodArgInterface = class(TAsyncCall)
  private
    FProc: TAsyncCallArgInterfaceMethod;
    FArg: IInterface;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgInterfaceMethod; const AArg: IInterface);
  end;

  TAsyncCallMethodArgExtended = class(TAsyncCall)
  private
    FProc: TAsyncCallArgExtendedMethod;
    FArg: Extended;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgExtendedMethod; const AArg: Extended);
  end;

  TAsyncCallMethodArgVariant = class(TAsyncCall)
  private
    FProc: TAsyncCallArgVariantMethod;
    FArg: Variant;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgVariantMethod; const AArg: Variant);
  end;

{ ---------------------------------------------------------------------------- }

  TAsyncCallArgRecord = class(TAsyncCall)
  private
    FProc: TAsyncCallArgRecordProc;
    FArg: Pointer;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgRecordProc; AArg: Pointer);
  end;

  TAsyncCallMethodArgRecord = class(TAsyncCall)
  private
    FProc: TAsyncCallArgRecordMethod;
    FArg: Pointer;
  protected
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: TAsyncCallArgRecordMethod; AArg: Pointer);
  end;

  TAsyncCallArrayOfConst = class(TAsyncCall)
  private
    FProc: function: Integer register;
    FArgs: array of TVarRec;
  protected
    function CopyVarRec(const Data: TVarRec): TVarRec;
    function ExecuteAsyncCall: Integer; override;
  public
    constructor Create(AProc: Pointer; const AArgs: array of const); overload;
    constructor Create(AProc: Pointer; MethodData: TObject; const AArgs: array of const); overload;
    destructor Destroy; override;
  end;

{ ---------------------------------------------------------------------------- }
var
  ThreadPool: TThreadPool;

procedure SetMaxAsyncCallThreads(MaxThreads: Integer);
begin
  if MaxThreads >= 0 then
    ThreadPool.FMaxThreads := MaxThreads;
end;

function GetMaxAsyncCallThreads: Integer;
begin
  Result := ThreadPool.FMaxThreads
end;

{ ---------------------------------------------------------------------------- }

function AsyncCall(Proc: TAsyncCallArgObjectProc; Arg: TObject): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgObject.Create(Proc, Arg).ExecuteAsync;
end;

function AsyncCall(Proc: TAsyncCallArgIntegerProc; Arg: Integer): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgObjectProc(Proc), TObject(Arg));
end;

function AsyncCall(Proc: TAsyncCallArgStringProc; const Arg: AnsiString): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgString.Create(Proc, Arg).ExecuteAsync;
end;

function AsyncCall(Proc: TAsyncCallArgWideStringProc; const Arg: WideString): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgWideString.Create(Proc, Arg).ExecuteAsync;
end;

function AsyncCall(Proc: TAsyncCallArgInterfaceProc; const Arg: IInterface): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgInterface.Create(Proc, Arg).ExecuteAsync;
end;

function AsyncCall(Proc: TAsyncCallArgExtendedProc; const Arg: Extended): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgExtended.Create(Proc, Arg).ExecuteAsync;
end;

function AsyncCallVar(Proc: TAsyncCallArgVariantProc; const Arg: Variant): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgVariant.Create(Proc, Arg).ExecuteAsync;
end;

{ ---------------------------------------------------------------------------- }

function AsyncCall(Method: TAsyncCallArgObjectMethod; Arg: TObject): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgObject.Create(Method, Arg).ExecuteAsync;
end;

function AsyncCall(Method: TAsyncCallArgIntegerMethod; Arg: Integer): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgObjectMethod(Method), TObject(Arg));
end;

function AsyncCall(Method: TAsyncCallArgStringMethod; const Arg: AnsiString): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgString.Create(Method, Arg).ExecuteAsync;
end;

function AsyncCall(Method: TAsyncCallArgWideStringMethod; const Arg: WideString): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgWideString.Create(Method, Arg).ExecuteAsync;
end;

function AsyncCall(Method: TAsyncCallArgInterfaceMethod; const Arg: IInterface): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgInterface.Create(Method, Arg).ExecuteAsync;
end;

function AsyncCall(Method: TAsyncCallArgExtendedMethod; const Arg: Extended): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgExtended.Create(Method, Arg).ExecuteAsync;
end;

function AsyncCallVar(Method: TAsyncCallArgVariantMethod; const Arg: Variant): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgVariant.Create(Method, Arg).ExecuteAsync;
end;

{ ---------------------------------------------------------------------------- }

function AsyncCall(Method: TAsyncCallArgObjectEvent; Arg: TObject): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgObjectMethod(Method), Arg);
end;

function AsyncCall(Method: TAsyncCallArgIntegerEvent; Arg: Integer): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgIntegerMethod(Method), Arg);
end;

function AsyncCall(Method: TAsyncCallArgStringEvent; const Arg: AnsiString): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgStringMethod(Method), Arg);
end;

function AsyncCall(Method: TAsyncCallArgWideStringEvent; const Arg: WideString): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgWideStringMethod(Method), Arg);
end;

function AsyncCall(Method: TAsyncCallArgInterfaceEvent; const Arg: IInterface): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgInterfaceMethod(Method), Arg);
end;

function AsyncCall(Method: TAsyncCallArgExtendedEvent; const Arg: Extended): IAsyncCall;
begin
  Result := AsyncCall(TAsyncCallArgExtendedMethod(Method), Arg);
end;

function AsyncCallVar(Method: TAsyncCallArgVariantEvent; const Arg: Variant): IAsyncCall;
begin
  Result := AsyncCallVar(TAsyncCallArgVariantMethod(Method), Arg);
end;

{ ---------------------------------------------------------------------------- }

procedure AsyncExec(Method: TNotifyEvent; Arg: TObject; IdleMsgMethod: TAsyncIdleMsgMethod);
var
  Handle: IAsyncCall;
begin
  Handle := AsyncCall(Method, Arg);
  if Assigned(IdleMsgMethod) then
  begin
    Handle.ForceDifferentThread;
    IdleMsgMethod;
    while MsgAsyncMultiSync([Handle], False, INFINITE, QS_ALLINPUT) = 1 do
      IdleMsgMethod;
  end;
end;

{ ---------------------------------------------------------------------------- }
function InternLocalAsyncCall(LocalProc: TLocalAsyncProc; BasePointer: Pointer): IAsyncCall;
begin
  Result := TAsyncCallLocalProc.Create(LocalProc, BasePointer).ExecuteAsync;
end;

function LocalAsyncCall(LocalProc: TLocalAsyncProc): IAsyncCall;
asm
  mov ecx, edx // interface return address
  mov edx, ebp
  jmp InternLocalAsyncCall
end;

function InternLocalAsyncCallEx(LocalProc: TLocalAsyncProc; Param: INT_PTR; BasePointer: Pointer): IAsyncCall;
begin
  Result := TAsyncCallLocalProcEx.Create(LocalProc, Param, BasePointer).ExecuteAsync;
end;

function LocalAsyncCallEx(LocalProc: TLocalAsyncProcEx; Param: INT_PTR): IAsyncCall;
asm
  push ecx // interface return address
  mov ecx, ebp
  call InternLocalAsyncCallEx
end;

procedure InternLocalAsyncExec(LocalProc: TLocalAsyncProc; IdleMsgMethod: TAsyncIdleMsgMethod; BasePointer: Pointer);
var
  Handle: IAsyncCall;
begin
  Handle := TAsyncCallLocalProc.Create(LocalProc, BasePointer).ExecuteAsync;
  if Assigned(IdleMsgMethod) then
  begin
    Handle.ForceDifferentThread;
    IdleMsgMethod;
    while MsgAsyncMultiSync([Handle], False, INFINITE, QS_ALLINPUT) = 1 do
      IdleMsgMethod;
  end;
end;

{$STACKFRAMES ON}
procedure LocalAsyncExec(Proc: TLocalAsyncProc; IdleMsgMethod: TAsyncIdleMsgMethod);
asm // TMethod causes the compiler to generate a stackframe
  pop ebp // remove stackframe
  mov edx, ebp
  jmp InternLocalAsyncExec
end;
{$STACKFRAMES OFF}

{ ---------------------------------------------------------------------------- }

function AsyncCallEx(Proc: TAsyncCallArgRecordProc; var Arg{: TRecordType}): IAsyncCall;
begin
  { Execute the function synchron if no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgRecord.Create(Proc, @Arg).ExecuteAsync;
end;

function AsyncCallEx(Method: TAsyncCallArgRecordMethod; var Arg{: TRecordType}): IAsyncCall;
begin
  { Execute the function synchron if no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Method(Arg))
  else
    Result := TAsyncCallMethodArgRecord.Create(Method, @Arg).ExecuteAsync;
end;

function AsyncCallEx(Method: TAsyncCallArgRecordEvent; var Arg{: TRecordType}): IAsyncCall;
begin
  Result := AsyncCallEx(TAsyncCallArgRecordMethod(Method), Arg);
end;

{ ---------------------------------------------------------------------------- }

function AsyncCall(Proc: TCdeclFunc; const Args: array of const): IAsyncCall; overload;
var
  Call: TAsyncCall;
begin
  Call := TAsyncCallArrayOfConst.Create(Proc, Args);
  if ThreadPool.MaxThreads = 0 then
    Call.InternExecuteSyncCall
  else
    Call.ExecuteAsync;
  Result := Call;
end;

function AsyncCall(Proc: TCdeclMethod; const Args: array of const): IAsyncCall; overload;
var
  Call: TAsyncCall;
begin
  Call := TAsyncCallArrayOfConst.Create(Proc.Code, TObject(Proc.Data), Args);
  if ThreadPool.MaxThreads = 0 then
    Call.InternExecuteSyncCall
  else
    Call.ExecuteAsync;
  Result := Call;
end;

{ ---------------------------------------------------------------------------- }

function WaitForSingleObjectMainThread(AHandle: THandle; Timeout: Cardinal;
  MsgWait: Boolean = False; dwWakeMask: DWORD = 0): Cardinal;
var
  Handles: array[0..2] of THandle;
begin
  Handles[0] := AHandle;
  Handles[1] := SyncEvent;
  Handles[2] := ThreadPool.MainThreadSyncEvent;
  {$IFDEF DELPHI6}
  HookWakeMainThread;
  try
  {$ENDIF DELPHI6}
  repeat
    if MsgWait then
    begin
      Result := MsgWaitForMultipleObjects(3, Handles[0], False, Timeout, dwWakeMask);
      if Result = WAIT_OBJECT_0 + 3 then
      begin
        ThreadPool.ProcessMainThreadSync; // also uses the message queue
        Result := WAIT_OBJECT_0 + 1; // caller doesn't know about the 2 synchronization events
        Exit;
      end;
    end
    else
      Result := WaitForMultipleObjects(3, @Handles[0], False, Timeout);
    if Result = WAIT_OBJECT_0 + 1 then
      CheckSynchronize
    else if Result = WAIT_OBJECT_0 + 2 then
      ThreadPool.ProcessMainThreadSync;
  until (Result <> WAIT_OBJECT_0 + 1) and (Result <> WAIT_OBJECT_0 + 2);
  {$IFDEF DELPHI6}
  finally
    UnhookWakeMainThread;
  end;
  {$ENDIF DELPHI6}
end;

function WaitForMultipleObjectsMainThread(Count: Cardinal;
  const AHandles: array of THandle; WaitAll: Boolean; Timeout: Cardinal;
  MsgWait: Boolean; dwWakeMask: DWORD): Cardinal;
var
  Handles: array of THandle;
  Index: Cardinal;
  FirstFinished: Cardinal;
begin
  { Wait for the specified events, for the VCL SyncEvent and for the MainThreadSync event }
  SetLength(Handles, Count + 2);
  Move(AHandles[0], Handles[0], Count * SizeOf(THandle));
  Handles[Count] := SyncEvent;
  Handles[Count + 1] := ThreadPool.MainThreadSyncEvent;
  {$IFDEF DELPHI6}
  HookWakeMainThread;
  try
  {$ENDIF DELPHI6}
  if not WaitAll then
  begin
    repeat
      if MsgWait then
      begin
        Result := MsgWaitForMultipleObjects(Count + 2, Handles[0], WaitAll, Timeout, dwWakeMask);
        if Result = WAIT_OBJECT_0 + Count + 2 then
        begin
          ThreadPool.ProcessMainThreadSync; // also uses the message queue
          Result := WAIT_OBJECT_0 + Count; // caller doesn't know about the 2 synchronization events
          Exit;
        end;
      end
      else
        Result := WaitForMultipleObjects(Count + 2, @Handles[0], WaitAll, Timeout);

      if Result = WAIT_OBJECT_0 + Count then
        CheckSynchronize
      else if Result = WAIT_OBJECT_0 + Count + 1 then
        ThreadPool.ProcessMainThreadSync;
    until (Result <> WAIT_OBJECT_0 + Count) and (Result <> WAIT_OBJECT_0 + Count + 1);
  end
  else
  begin
    FirstFinished := WAIT_TIMEOUT;
    repeat
      if MsgWait then
      begin
        Result := MsgWaitForMultipleObjects(Count + 2, Handles[0], False, Timeout, dwWakeMask);
        if Result = WAIT_OBJECT_0 + Count + 2 then
        begin
          ThreadPool.ProcessMainThreadSync; // also uses the message queue
          Result := WAIT_OBJECT_0 + Count; // caller doesn't know about the 2 synchronization events
          Exit;
        end;
      end
      else
        Result := WaitForMultipleObjects(Count + 2, @Handles[0], False, Timeout);

      if Result = WAIT_OBJECT_0 + Count then
        CheckSynchronize
      else if Result = WAIT_OBJECT_0 + Count + 1 then
        ThreadPool.ProcessMainThreadSync
      else
      if {(Result >= WAIT_OBJECT_0) and} (Result <= WAIT_OBJECT_0 + Count) then
      begin
        if FirstFinished = WAIT_TIMEOUT then
          FirstFinished := Result;
        Dec(Count);
        if Count > 0 then
        begin
          Index := Result - WAIT_OBJECT_0;
          Move(Handles[Index + 1], Handles[Index], ((Count + 1) - Index) * SizeOf(THandle));
        end;
      end
      else
        Break;
    until Count = 0;
    if Count = 0 then
      Result := FirstFinished;
  end;
  {$IFDEF DELPHI6}
  finally
    UnhookWakeMainThread;
  end;
  {$ENDIF DELPHI6}
end;

{ ---------------------------------------------------------------------------- }

function InternalAsyncMultiSync(const List: array of IAsyncCall; const Handles: array of THandle;
  WaitAll: Boolean; Milliseconds: Cardinal; MsgWait: Boolean; dwWakeMask: DWORD): Integer;

  function InternalWait(const List: array of IAsyncCall; const Handles: array of THandle;
    WaitAll: Boolean; Milliseconds: Cardinal; MsgWait: Boolean; dwWakeMask: DWORD): Integer;
  var
    WaitHandles: array of THandle;
    Mapping: array of Integer;
    I: Integer;
    Count: Cardinal;
    EventIntf: IAsyncCallEx;
    SignalState: Cardinal;
  begin
    SetLength(WaitHandles, Length(List) + Length(Handles));
    SetLength(Mapping, Length(WaitHandles));
    Count := 0;
    { Get the TAsyncCall events }
    for I := 0 to High(List) do
    begin
      if (List[I] <> nil) and Supports(List[I], IAsyncCallEx, EventIntf) then
      begin
        WaitHandles[Count] := EventIntf.GetEvent;
        if WaitHandles[Count] <> 0 then
        begin
          Mapping[Count] := I;
          Inc(Count);
        end;
      end
      else
      if not WaitAll then
      begin
        { There are synchron calls in List[] and the caller does not want to
          wait for all handles. }
        Result := I;
        Exit;
      end;
    end;

    { Append other handles }
    for I := 0 to High(Handles) do
    begin
      WaitHandles[Count] := Handles[I];
      Mapping[Count] := Length(List) + I;
      Inc(Count);
    end;

    { Wait for the async calls }
    if Count > 0 then
    begin
      if GetCurrentThreadId = MainThreadID then
      begin
        SignalState := WaitForMultipleObjectsMainThread(Count, WaitHandles, WaitAll, Milliseconds, MsgWait, dwWakeMask);
        if SignalState = Count then // "message" was signaled
        begin
          Result := SignalState;
          Exit;
        end;
      end
      else
      begin
        if MsgWait then
        begin
          SignalState := MsgWaitForMultipleObjects(Count, WaitHandles[0], WaitAll, Milliseconds, dwWakeMask);
          if SignalState = Count then // "message" was signaled
          begin
            Result := SignalState;
            Exit;
          end;
        end
        else
          SignalState := WaitForMultipleObjects(Count, @WaitHandles[0], WaitAll, Milliseconds);
      end;
      if {(SignalState >= WAIT_OBJECT_0) and} (SignalState < WAIT_OBJECT_0 + Count) then
        Result := WAIT_OBJECT_0 + Mapping[SignalState - WAIT_OBJECT_0]
      else if (SignalState >= WAIT_ABANDONED_0) and (SignalState < WAIT_ABANDONED_0 + Count) then
        Result := WAIT_ABANDONED_0 + Mapping[SignalState - WAIT_ABANDONED_0] 
      else
        Result := -1;
    end
    else
      Result := 0;
  end;

  function InternalWaitAllInfinite(const List: array of IAsyncCall; const Handles: array of THandle): Integer;
  var
    I: Integer;
  begin
    { Wait for the async calls that aren't finished yet. }
    for I := 0 to High(List) do
      if List[I] <> nil then
        List[I].Sync;

    if Length(Handles) > 0 then
    begin
      if GetCurrentThreadId = MainThreadID then
        WaitForMultipleObjectsMainThread(Length(Handles), Handles, True, INFINITE, False, 0)
      else
        WaitForMultipleObjects(Length(Handles), @Handles[0], True, INFINITE);
    end;
    Result := 0;
  end;

begin
  if Length(List) > 0 then
  begin
    if WaitAll and (Milliseconds = INFINITE) and not MsgWait and (GetCurrentThreadId <> MainThreadId) then
      Result := InternalWaitAllInfinite(List, Handles)
    else
      Result := InternalWait(List, Handles, WaitAll, Milliseconds, MsgWait, dwWakeMask);
  end
  else
    Result := 0;
end;

function AsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean;
  Milliseconds: Cardinal): Integer;
begin
  Result := InternalAsyncMultiSync(List, [], WaitAll, Milliseconds, False, 0);
end;

function AsyncMultiSyncEx(const List: array of IAsyncCall; const Handles: array of THandle;
  WaitAll: Boolean = True; Milliseconds: Cardinal = INFINITE): Integer;
begin
  Result := InternalAsyncMultiSync(List, Handles, WaitAll, Milliseconds, False, 0);
end;

function MsgAsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean;
  Milliseconds: Cardinal; dwWakeMask: DWORD): Integer;
begin
  Result := InternalAsyncMultiSync(List, [], WaitAll, Milliseconds, True, dwWakeMask);
end;

function MsgAsyncMultiSyncEx(const List: array of IAsyncCall; const Handles: array of THandle;
  WaitAll: Boolean; Milliseconds: Cardinal; dwWakeMask: DWORD): Integer;
begin
  Result := InternalAsyncMultiSync(List, Handles, WaitAll, Milliseconds, True, dwWakeMask);
end;

procedure NotFinishedError(const FunctionName: string);
begin
  {$IFDEF DEBUG_ASYNCCALLS}
  if FunctionName <> '' then
    OutputDebugString(PChar(FunctionName));
  {$ENDIF DEBUG_ASYNCCALLS}
  raise EAsyncCallError.Create(RsAsyncCallNotFinished);
end;

procedure UnknownVarRecType(VType: Byte);
begin
  raise EAsyncCallError.CreateFmt(RsAsyncCallUnknownVarRecType, [VType]);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallThread }

function GetMainWnd(wnd: THandle; var MainWnd: THandle): LongBool; stdcall;
begin
  Result := False;
  MainWnd := wnd;
end;

procedure TAsyncCallThread.Execute;
var
  FAsyncCall: TAsyncCall;
  CoInitialized: Boolean;
begin
  CoInitialized := CoInitialize(nil) = S_OK;
  try
    while not Terminated do
    begin
      FAsyncCall := ThreadPool.GetNextAsyncCall(Self); // calls Suspend if nothing has to be done.
      if FAsyncCall <> nil then
      begin
        try
          FAsyncCall.InternExecuteAsyncCall;
        except
          {$IFDEF DEBUG_ASYNCCALLS}
          on E: Exception do
            OutputDebugString(PChar('[' + E.ClassName + '] ' + E.Message));
          {$ENDIF DEBUG_ASYNCCALLS}
        end;
      end;
    end;
  finally
    if CoInitialized then
      CoUninitialize;
  end;
end;

procedure TAsyncCallThread.ForceTerminate;
begin
  if Suspended then
  begin
    Terminate;
    { Do not call Self.Resume() here because it can lead to memory corruption.

        procedure TThread.Resume;
        var
          SuspendCount: Integer;
        begin
          SuspendCount := ResumeThread(FHandle);
          => Thread could be destroyed by FreeOnTerminate <=
          CheckThreadError(SuspendCount >= 0);
          if SuspendCount = 1 then
            FSuspended := False; => accesses the destroyed thread
        end;
     }
    ResumeThread(Handle);
  end
  else
    Terminate;
end;

{ ---------------------------------------------------------------------------- }
{ TThreadPool }

constructor TThreadPool.Create;
var
  SysInfo: TSystemInfo;
begin
  inherited Create;
  FThreads := TThreadList.Create;
  FAsyncCalls := TThreadList.Create;
  FMainThreadVclHandle := AllocateHWnd(MainThreadWndProc);
  FMainThreadSyncEvent := CreateEvent(nil, False, False, nil);

  GetSystemInfo(SysInfo);
  FNumberOfProcessors := SysInfo.dwNumberOfProcessors;
  FMaxThreads := SysInfo.dwNumberOfProcessors * 4 - 2 {main thread};
end;

destructor TThreadPool.Destroy;
var
  I: Integer;
  List: TList;
begin
  List := FThreads.LockList;
  for I := List.Count - 1 downto 0 do
    TAsyncCallThread(List[I]).ForceTerminate;
  FThreads.UnlockList;
  FThreads.Free;

  List := FAsyncCalls.LockList;
  for I := List.Count - 1 downto 0 do
    SetEvent(TAsyncCall(List[I]).FEvent);
  FAsyncCalls.UnlockList;
  FAsyncCalls.Free;

  CloseHandle(FMainThreadSyncEvent);
  DeallocateHWnd(FMainThreadVclHandle);

  inherited Destroy;
end;

function TThreadPool.GetNextAsyncCall(Thread: TAsyncCallThread): TAsyncCall;
var
  List: TList;
begin
  List := FAsyncCalls.LockList;
  if List.Count > 0 then
  begin
    { Get the "oldest" async call }
    Result := List[0];
    List.Delete(0);
  end
  else
    Result := nil;
  FAsyncCalls.UnlockList;

  { Nothing to do, go sleeping... }
  if Result = nil then
    Thread.Suspend;
end;

function TThreadPool.RemoveAsyncCall(Call: TAsyncCall): Boolean;
var
  List: TList;
  Index: Integer;
begin
  List := FAsyncCalls.LockList;
  Index := List.IndexOf(Call);
  Result := Index >= 0;
  if Result then
    List.Delete(Index);
  FAsyncCalls.UnlockList;
end;

procedure TThreadPool.AddAsyncCall(Call: TAsyncCall);
var
  List: TList;
  FreeThreadFound: Boolean;
  I: Integer;
begin
  List := FAsyncCalls.LockList;
  List.Add(Call);
  FAsyncCalls.UnlockList;

  FreeThreadFound := False;
  List := FThreads.LockList;
  for I := 0 to List.Count - 1 do
  begin
    if TAsyncCallThread(List[I]).Suspended then
    begin
      { Wake up the thread so it can execute the waiting async call. }
      TAsyncCallThread(List[I]).Resume;
      FreeThreadFound := True;
      Break;
    end;
  end;
  { All threads are busy, we need to allocate another thread if possible }
  if not FreeThreadFound and (List.Count < MaxThreads) then
    AllocThread;
  FThreads.UnlockList;
end;

function TThreadPool.AllocThread: TAsyncCallThread;
begin
  Result := TAsyncCallThread.Create(True);
  Result.FreeOnTerminate := True;
  FThreads.Add(Result);
  Result.Resume;
end;

const
  WM_VCLSYNC = WM_USER + 12;

procedure TThreadPool.SendVclSync(Call: TAsyncCall);
begin
  if not PostMessage(FMainThreadVclHandle, WM_VCLSYNC, 0, LPARAM(Call)) then
    Call.Quit(0)
  else
    SetEvent(FMainThreadSyncEvent);
end;

procedure TThreadPool.MainThreadWndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_VCLSYNC:
      TAsyncCall(Msg.LParam).InternExecuteSyncCall;
  else
    with Msg do
      Result := DefWindowProc(FMainThreadVclHandle, Msg, WParam, LParam);
  end;
end;

procedure TThreadPool.ProcessMainThreadSync;
var
  Msg: TMsg;
begin
  Assert( GetCurrentThreadId = MainThreadId ); 
  while PeekMessage(Msg, FMainThreadVclHandle, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

{ ---------------------------------------------------------------------------- }
{ TSyncCall }

constructor TSyncCall.Create(AReturnValue: Integer);
begin
  inherited Create;
  FReturnValue := AReturnValue;
end;

function TSyncCall.Finished: Boolean;
begin
  Result := True;
end;

procedure TSyncCall.ForceDifferentThread;
begin
end;

function TSyncCall.ReturnValue: Integer;
begin
  Result := FReturnValue;
end;

function TSyncCall.Sync: Integer;
begin
  Result := FReturnValue;
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCall }

constructor TAsyncCall.Create;
begin
  inherited Create;
  FEvent := CreateEvent(nil, True, False, nil);
end;

destructor TAsyncCall.Destroy; 
begin
  if FEvent <> 0 then
  begin
    try
      Sync;
    finally
      CloseHandle(FEvent);
      FEvent := 0;
    end;
  end;
  inherited Destroy;
end;

function TAsyncCall.Finished: Boolean;
begin
  Result := (FEvent = 0) or FFinished or (WaitForSingleObject(FEvent, 0) = WAIT_OBJECT_0);
end;

procedure TAsyncCall.ForceDifferentThread;
begin
  FForceDifferentThread := True;
end;

function TAsyncCall.GetEvent: Cardinal;
begin
  Result := FEvent;
end;

procedure TAsyncCall.InternExecuteAsyncCall;
var
  Value: Integer;
begin
  Value := 0;
  try
    Value := ExecuteAsyncCall;
  except
    FFatalErrorAddr := ErrorAddr;
    FFatalException := AcquireExceptionObject;
  end;
  Quit(Value);
end;

procedure TAsyncCall.InternExecuteSyncCall;
begin
  Quit( ExecuteAsyncCall() );
end;

procedure TAsyncCall.Quit(AReturnValue: Integer);
begin
  FReturnValue := AReturnValue;
  FFinished := True;
  SetEvent(FEvent);
end;

function TAsyncCall.ReturnValue: Integer;
var
  E: Exception;
begin
  if not Finished then
    NotFinishedError('IAsyncCall.ReturnValue');
  Result := FReturnValue;

  if FFatalException <> nil then
  begin
    E := FFatalException;
    FFatalException := nil;
    raise E at FFatalErrorAddr;
  end;
end;

function TAsyncCall.Sync: Integer;
var
  E: Exception;
begin
  if not Finished then
  begin
    if not SyncInThisThreadIfPossible then
    begin
      if GetCurrentThreadId = MainThreadID then
      begin
        if WaitForSingleObjectMainThread(FEvent, INFINITE) <> WAIT_OBJECT_0 then
          NotFinishedError('IAsyncCall.Sync');
      end
      else
      if WaitForSingleObject(FEvent, INFINITE) <> WAIT_OBJECT_0 then
        NotFinishedError('IAsyncCall.Sync');
    end;
  end;
  Result := FReturnValue;

  if FFatalException <> nil then
  begin
    E := FFatalException;
    FFatalException := nil;
    raise E at FFatalErrorAddr;
  end;
end;

function TAsyncCall.SyncInThisThreadIfPossible: Boolean;
begin
  if not Finished then
  begin
    Result := False;
    if not FForceDifferentThread then
    begin
      { If no thread was assigned to this async call, remove it form the waiting
        queue and execute it in the current thread. }
      if ThreadPool.RemoveAsyncCall(Self) then
      begin
        InternExecuteSyncCall;
        Result := True;
      end;
    end;
  end
  else
    Result := True;
end;

function TAsyncCall.ExecuteAsync: TAsyncCall;
begin
  ThreadPool.AddAsyncCall(Self);
  Result := Self;
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArrayOfConst }

constructor TAsyncCallArrayOfConst.Create(AProc: Pointer; const AArgs: array of const);
var
  I: Integer;
begin
  inherited Create;
  FProc := AProc;
  SetLength(FArgs, Length(AArgs));
  for I := 0 to High(AArgs) do
    FArgs[I] := CopyVarRec(AArgs[I]);
end;

constructor TAsyncCallArrayOfConst.Create(AProc: Pointer; MethodData: TObject; const AArgs: array of const);
var
  I: Integer;
begin
  inherited Create;
  FProc := AProc;
  SetLength(FArgs, 1 + Length(AArgs));

  // insert "Self"
  FArgs[0].VType := vtObject;
  FArgs[0].VObject := MethodData;

  for I := 0 to High(AArgs) do
    FArgs[I + 1] := CopyVarRec(AArgs[I]);
end;

destructor TAsyncCallArrayOfConst.Destroy;
var
  I: Integer;
  V: PVarRec;
begin
  for I := 0 to High(FArgs) do
  begin
    V := @FArgs[I];
    case V.VType of
      vtAnsiString: AnsiString(V.VAnsiString) := '';
      vtWideString: WideString(V.VWideString) := '';
      vtInterface : IInterface(V.VInterface) := nil;

      vtString    : Dispose(V.VString);
      vtExtended  : Dispose(V.VExtended);
      vtCurrency  : Dispose(V.VCurrency);
      vtInt64     : Dispose(V.VInt64);
      vtVariant   : Dispose(V.VVariant);
    end;
  end;
  inherited Destroy;
end;

function TAsyncCallArrayOfConst.CopyVarRec(const Data: TVarRec): TVarRec;
begin
  if (Data.VPointer <> nil) and
     (Data.VType in [vtString, vtAnsiString, vtWideString, vtExtended,
                     vtCurrency, vtInt64, vtVariant, vtInterface]) then
  begin
    Result.VType := Data.VType;
    Result.VPointer := nil;
    { Copy and redirect TVarRec data to prevent conflicts with other threads,
      especially the calling thread. Otherwise reference counted types could
      be freed while this asynchron function is still executed. }
    case Result.VType of
      vtAnsiString: AnsiString(Result.VAnsiString) := AnsiString(Data.VAnsiString);
      vtWideString: WideString(Result.VWideString) := WideString(Data.VWideString);
      vtInterface : IInterface(Result.VInterface) := IInterface(Data.VInterface);

      vtString    : begin New(Result.VString);   Result.VString^ := Data.VString^; end;
      vtExtended  : begin New(Result.VExtended); Result.VExtended^ := Data.VExtended^; end;
      vtCurrency  : begin New(Result.VCurrency); Result.VCurrency^ := Data.VCurrency^; end;
      vtInt64     : begin New(Result.VInt64);    Result.VInt64^ := Data.VInt64^; end;
      vtVariant   : begin New(Result.VVariant);  Result.VVariant^ := Data.VVariant^; end;
    end;
  end
  else
    Result := Data;
end;

function TAsyncCallArrayOfConst.ExecuteAsyncCall: Integer;
var
  I: Integer;
  V: ^TVarRec;
  ByteCount: Integer;
begin
  ByteCount := Length(FArgs) * SizeOf(Integer) + $40;
  { Create a zero filled buffer for functions that want more arguments than
    specified. }
  asm
    xor eax, eax
    mov ecx, $40 / 8
@@FillBuf:
    push eax
    push eax
    dec ecx
    jnz @@FillBuf
  end;

  for I := High(FArgs) downto 0 do // cdecl => right to left
  begin
    V := @FArgs[I];
    case V.VType of
      vtInteger:     // [const] Arg: Integer
        asm
          mov eax, V
          push [eax].TVarRec.VInteger
        end;

      vtBoolean,     // [const] Arg: Boolean
      vtChar:        // [const] Arg: AnsiChar
        asm
          mov eax, V
          xor edx, edx
          mov dl, [eax].TVarRec.VBoolean
          push edx
        end;

      vtWideChar:    // [const] Arg: WideChar
        asm
          mov eax, V
          xor edx, edx
          mov dx, [eax].TVarRec.VWideChar
          push edx
        end;

      vtExtended:    // [const] Arg: Extended
        asm
          add [ByteCount], 8 // two additional DWORDs
          mov eax, V
          mov edx, [eax].TVarRec.VExtended
          movzx eax, WORD PTR [edx + 8]
          push eax
          push DWORD PTR [edx + 4]
          push DWORD PTR [edx]
        end;

      vtCurrency,    // [const] Arg: Currency
      vtInt64:       // [const] Arg: Int64
        asm
          add [ByteCount], 4 // an additional DWORD
          mov eax, V
          mov edx, [eax].TVarRec.VCurrency
          push DWORD PTR [edx + 4]
          push DWORD PTR [edx]
        end;

      vtString,      // [const] Arg: ShortString
      vtPointer,     // [const] Arg: Pointer
      vtPChar,       // [const] Arg: PChar
      vtObject,      // [const] Arg: TObject
      vtClass,       // [const] Arg: TClass
      vtAnsiString,  // [const] Arg: AnsiString
      vtPWideChar,   // [const] Arg: PWideChar
      vtVariant,     // const Arg: Variant
      vtInterface,   // [const]: IInterface
      vtWideString:  // [const] Arg: WideString
        asm
          mov eax, V
          push [eax].TVarRec.VPointer
        end;
    else
      UnknownVarRecType(V.VType);
    end;
  end;

  Result := FProc;

  asm // cdecl => we must clean up
    add esp, [ByteCount]
  end;
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgRecord }

constructor TAsyncCallArgRecord.Create(AProc: TAsyncCallArgRecordProc; AArg: Pointer);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgRecord.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg^);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgRecord }

constructor TAsyncCallMethodArgRecord.Create(AProc: TAsyncCallArgRecordMethod; AArg: Pointer);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgRecord.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg^);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgObject }

constructor TAsyncCallArgObject.Create(AProc: TAsyncCallArgObjectProc; AArg: TObject);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgObject.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgObject }

constructor TAsyncCallMethodArgObject.Create(AProc: TAsyncCallArgObjectMethod; AArg: TObject);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgObject.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgString }

constructor TAsyncCallArgString.Create(AProc: TAsyncCallArgStringProc;
  const AArg: AnsiString);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgString.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgString }

constructor TAsyncCallMethodArgString.Create(AProc: TAsyncCallArgStringMethod; const AArg: AnsiString);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgString.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgWideString }

constructor TAsyncCallArgWideString.Create(AProc: TAsyncCallArgWideStringProc; const AArg: WideString);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgWideString.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgWideString }

constructor TAsyncCallMethodArgWideString.Create(AProc: TAsyncCallArgWideStringMethod; const AArg: WideString);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgWideString.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgInterface }

constructor TAsyncCallArgInterface.Create(AProc: TAsyncCallArgInterfaceProc; const AArg: IInterface);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgInterface.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgInterface }

constructor TAsyncCallMethodArgInterface.Create(AProc: TAsyncCallArgInterfaceMethod; const AArg: IInterface);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgInterface.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgExtended }

constructor TAsyncCallArgExtended.Create(AProc: TAsyncCallArgExtendedProc; const AArg: Extended);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgExtended.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgExtended }

constructor TAsyncCallMethodArgExtended.Create(AProc: TAsyncCallArgExtendedMethod; const AArg: Extended);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgExtended.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallArgVariant }

constructor TAsyncCallArgVariant.Create(AProc: TAsyncCallArgVariantProc; const AArg: Variant);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallArgVariant.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }
{ TAsyncCallMethodArgVariant }

constructor TAsyncCallMethodArgVariant.Create(AProc: TAsyncCallArgVariantMethod; const AArg: Variant);
begin
  inherited Create;
  FProc := AProc;
  FArg := AArg;
end;

function TAsyncCallMethodArgVariant.ExecuteAsyncCall: Integer;
begin
  Result := FProc(FArg);
end;

{ ---------------------------------------------------------------------------- }

{ TAsyncCallLocalProc }

constructor TAsyncCallLocalProc.Create(AProc: TLocalAsyncProc; ABasePointer: Pointer);
begin
  inherited Create;
  @FProc := @AProc;
  FBasePointer := ABasePointer;
end;

function TAsyncCallLocalProc.ExecuteAsyncCall: Integer;
asm
  mov edx, [eax].TAsyncCallLocalProc.FBasePointer
  mov ecx, [eax].TAsyncCallLocalProc.FProc
  xor eax, eax // paramater
  push edx
  call ecx
  pop ecx
end;

{ TAsyncCallLocalProcEx }

constructor TAsyncCallLocalProcEx.Create(AProc: TLocalAsyncProc; AParam: INT_PTR; ABasePointer: Pointer);
begin
  inherited Create;
  @FProc := @AProc;
  FBasePointer := ABasePointer;
  FParam := AParam;
end;

function TAsyncCallLocalProcEx.ExecuteAsyncCall: Integer;
asm
  mov edx, [eax].TAsyncCallLocalProcEx.FBasePointer
  mov ecx, [eax].TAsyncCallLocalProcEx.FProc
  mov eax, [eax].TAsyncCallLocalProcEx.FParam
  push edx
  call ecx
  pop ecx
end;

{ ---------------------------------------------------------------------------- }

{ TAsyncVclCallLocalProc }

constructor TAsyncVclCallLocalProc.Create(AProc: TLocalVclProc; AParam: INT_PTR; ABasePointer: Pointer);
begin
  inherited Create;
  @FProc := @AProc;
  FBasePointer := ABasePointer;
  FParam := AParam;
end;

function TAsyncVclCallLocalProc.ExecuteAsyncCall: Integer;
asm
  mov edx, [eax].TAsyncCallLocalProcEx.FBasePointer
  mov ecx, [eax].TAsyncCallLocalProcEx.FProc
  mov eax, [eax].TAsyncCallLocalProcEx.FParam
  push edx
  call ecx
  pop ecx
end;

{ ---------------------------------------------------------------------------- }

type
  PLocalVclCallRec = ^TLocalVclCallRec;
  TLocalVclCallRec = record
    BasePointer: Pointer;
    Proc: TLocalVclProc;
    Param: INT_PTR;
  end;

function LocalVclCallProc(Data: PLocalVclCallRec): Integer;
asm
  mov edx, [eax].TLocalVclCallRec.BasePointer
  mov ecx, [eax].TLocalVclCallRec.Proc
  mov eax, [eax].TLocalVclCallRec.Param
  push edx
  call ecx
  pop ecx 
end;

procedure InternLocalVclCall(LocalProc: TLocalVclProc; Param: INT_PTR; BasePointer: Pointer);
var
  M: TMethod;
  Data: TLocalVclCallRec;
begin
  Data.BasePointer := BasePointer;
  Data.Proc := LocalProc;
  Data.Param := Param;
  if GetCurrentThreadId = MainThreadID then
    LocalVclCallProc(@Data)
  else
  begin
    M.Code := @LocalVclCallProc;
    M.Data := @Data;
    TThread.StaticSynchronize(nil, TThreadMethod(M));
  end;
end;

procedure LocalVclCall(LocalProc: TLocalVclProc; Param: INT_PTR);
asm
  mov ecx, ebp
  jmp InternLocalVclCall
end;

function InternLocalAsyncVclCall(LocalProc: TLocalVclProc; Param: INT_PTR; BasePointer: Pointer): IAsyncCall;
var
  Data: TLocalVclCallRec;
  Call: TAsyncVclCallLocalProc;
begin
  if GetCurrentThreadId = MainThreadID then
  begin
    Data.BasePointer := BasePointer;
    Data.Proc := LocalProc;
    Data.Param := Param;
    Result := TSyncCall.Create( LocalVclCallProc(@Data) );
  end
  else
  begin
    Call := TAsyncVclCallLocalProc.Create(LocalProc, Param, BasePointer);
    ThreadPool.SendVclSync(Call);
    Result := Call;
  end;
end;

function LocalAsyncVclCall(LocalProc: TLocalVclProc; Param: INT_PTR = 0): IAsyncCall;
asm
  push ecx // interface return address
  mov ecx, ebp
  call InternLocalAsyncVclCall
end;

{----------------------------------------------------------------------------}

type
  TMainThreadContext = record
    MainThreadEntered: Longint;
    MainThreadOpenBlockCount: Longint;
    
    IntructionPointer: Pointer;
    BasePointer: Pointer;
    RetAddr: Pointer;

    MainBasePointer: Pointer;
    ContextRetAddr: Pointer;
    FinallyRetAddr: Pointer;
  end;

var
  MainThreadContext: TMainThreadContext;
  MainThreadContextCritSect: TRTLCriticalSection;

procedure ExecuteInMainThread(Data: TObject);
asm
  push ebp

  mov eax, OFFSET MainThreadContext

  { Backup main thread state }
  mov edx, OFFSET @@Leave
  mov [eax].TMainThreadContext.ContextRetAddr, edx
  mov [eax].TMainThreadContext.MainBasePointer, ebp

  { Set "nested call" control }
  mov ecx, [eax].TMainThreadContext.MainThreadOpenBlockCount
  mov [eax].TMainThreadContext.MainThreadEntered, ecx
  inc ecx
  mov [eax].TMainThreadContext.MainThreadOpenBlockCount, ecx

  { Switch to the thread state }
  mov ebp, [eax].TMainThreadContext.BasePointer
  mov edx, [eax].TMainThreadContext.IntructionPointer

  { Jump to the user's synchronized code }
  jmp edx

  { LeaveMainThread() will jump to this address after it has restored the main
    thread state. }
@@Leave:
  pop ebp
end;

procedure LeaveMainThreadError(ErrorMode: Integer);
begin
  case ErrorMode of
    0: raise Exception.Create(RsLeaveMainThreadNestedError);
    1: raise Exception.Create(RsLeaveMainThreadThreadError);
  end;
end;

procedure LeaveMainThread;
asm
  { Check if we are in the main thread }
  call GetCurrentThreadId
  cmp eax, [MainThreadId]
  jne @@ThreadError

  { "nested call" control }
  mov eax, OFFSET MainThreadContext
  mov ecx, [eax].TMainThreadContext.MainThreadOpenBlockCount
  dec ecx
  js @@NestedError
  mov [eax].TMainThreadContext.MainThreadOpenBlockCount, ecx
  cmp ecx, [eax].TMainThreadContext.MainThreadEntered
  jne @@Leave
  { release "nested call" control }
  mov [eax].TMainThreadContext.MainThreadEntered, -1

  { If there is an exception the Classes.CheckSynchronize function will handle the
    exception and thread switch for us. Will also restore the EBP regíster. }
  call System.ExceptObject
  or eax, eax
  jnz @@InException

  mov eax, OFFSET MainThreadContext
  { Backup the return addresses }
  pop edx // procedure return address
  pop ecx // finally return address
  mov [eax].TMainThreadContext.FinallyRetAddr, ecx
  mov [eax].TMainThreadContext.RetAddr, edx

  { Restore the main thread state }
  mov ebp, [eax].TMainThreadContext.MainBasePointer
  mov edx, [eax].TMainThreadContext.ContextRetAddr
  jmp edx

@@NestedError:
  xor eax, eax
  call LeaveMainThreadError
@@ThreadError:
  mov eax, 1
  call LeaveMainThreadError

@@InException:
@@Leave:
end;

procedure EnterMainThread;
asm
  { There is nothing to do if we are already in the main thread }
  call GetCurrentThreadId
  cmp eax, [MainThreadId]
  je @@InMainThread

  { Enter critical section => implicit waiting queue }
  mov eax, OFFSET MainThreadContextCritSect
  push eax
  call EnterCriticalSection

  { Take the return address from the stack to "clean" the stack }
  pop edx

  { Backup the current thread state }
  mov eax, OFFSET MainThreadContext
  mov [eax].TMainThreadContext.MainThreadEntered, ecx
  mov [eax].TMainThreadContext.IntructionPointer, edx
  mov [eax].TMainThreadContext.BasePointer, ebp

  { Begin try/finally }
@@Try:
  xor eax, eax
  push ebp
  push OFFSET @@HandleFinally
  push dword ptr fs:[eax]
  mov fs:[eax], esp

  { Call Synchronize(nil, TMethod(ExecuteInMainThread)) }
  //xor eax, eax // ClassType isn't used in StaticSynchronize/Synchronize
  xor edx, edx
  push edx
  mov ecx, OFFSET ExecuteInMainThread
  push ecx
  call TThread.StaticSynchronize

  { Clean up try/finally }
  xor eax,eax
  pop edx
  pop ecx
  pop ecx
  mov fs:[eax], edx

  { Restore thread state }
  mov eax, OFFSET MainThreadContext
  mov ebp, [eax].TMainThreadContext.BasePointer
  mov ecx, [eax].TMainThreadContext.FinallyRetAddr
  mov edx, [eax].TMainThreadContext.RetAddr

  push ecx  // put finally return address back to the stack
  push edx  // put return address back to the stack

  { End try/finally }
@@Finally:
  mov eax, OFFSET MainThreadContextCritSect
  push eax
  call LeaveCriticalSection
  ret
@@HandleFinally:
  jmp System.@HandleFinally
  jmp @@Finally
@@LeaveFinally:
  ret

@@InMainThread:
  { Adjust "nested call" control.
    Threadsafe because we are in the main thread and only the main thread
    manipulates MainThreadOpenBlockCount }
  inc [MainThreadContext].TMainThreadContext.MainThreadOpenBlockCount
end;


initialization
  ThreadPool := TThreadPool.Create;
  MainThreadContext.MainThreadEntered := -1;
  {$IFDEF DELPHi6}
  SyncEvent := CreateEvent(nil, False, False, nil);
  {$ENDIF DELPHi6}
  InitializeCriticalSection(MainThreadContextCritSect);

finalization
  ThreadPool.Free;
  ThreadPool := nil;
  DeleteCriticalSection(MainThreadContextCritSect);
  {$IFDEF DELPHi6}
  CloseHandle(SyncEvent);
  SyncEvent := 0;
  {$ENDIF DELPHI6}

end.

