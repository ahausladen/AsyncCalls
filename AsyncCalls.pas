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
{ Portions created by Andreas Hausladen are Copyright (C) 2006-2007 Andreas Hausladen.             }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{ Contributor(s):                                                                                  }
{                                                                                                  }
{**************************************************************************************************}
{$A+,B-,C+,D-,E-,F-,G+,H+,I+,J-,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W+,X+,Y+,Z1}

unit AsyncCalls;

{$IFDEF CONDITIONALEXPRESSIONS}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARN UNIT_PLATFORM OFF}
  {$IF CompilerVersion >= 15.0}
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CODE OFF}
    {$WARN UNSAFE_CAST OFF}
  {$IFEND}
{$ELSE}
  {$DEFINE DELPHI5_LOWER}
{$ENDIF CONDITIONALEXPRESSIONS}

{$DEFINE DEBUGASYNCCALLS}
{$IFDEF DEBUGASYNCCALLS}
  {$D+}
{$ENDIF DEBUGASYNCCALLS}

interface

uses
  Windows, SysUtils, Classes, Contnrs, ActiveX, SyncObjs;

type
  {$IFDEF DELPHI5_LOWER}
  IInterface = IUnknown;
  {$ENDIF DELPHI5_LOWER}
  TCdeclFunc = Pointer; // function(Arg1: Type1; Arg2: Type2; ...); cdecl;
  TCdeclMethod = TMethod; // function(Arg1: Type1; Arg2: Type2; ...) of object; cdecl;
  TLocalAsyncProc = function: Integer;
  TLocalVclProc = procedure(Param: Integer);
  TLocalAsyncForLoopProc = function(Index: Integer; SyncLock: TCriticalSection): Boolean;

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
      result value of the called function. }
    function Sync: Integer;

    { Finished() returns True when the asynchronous call has finished. }
    function Finished: Boolean;

    { ReturnValue() returns the result of the asynchronous call. It raises an
      exception if called before the function has finished. }
    function ReturnValue: Integer;
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


{ LocalAsyncCall() executes the given local function/procedure in a separate thread.
  The result value of the asynchronous function is returned by IAsyncCall.Sync() and
  IAsyncCall.ReturnValue().

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
  end;
}
function LocalAsyncCall(LocalProc: TLocalAsyncProc): IAsyncCall;

function AsyncMTForLoop(LocalProc: TLocalAsyncForLoopProc;
  StartIndex, EndIndex: Integer; MaxThreads: Integer = 0): Boolean; // false if LoopBreak


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


{ AsyncMultiSync() waits for the async calls to finish.
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
}
function AsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean = True;
  Milliseconds: Cardinal = INFINITE): Integer;

procedure LocalVclCall(LocalProc: TLocalVclProc; Param: Integer = 0);

implementation

resourcestring
  RsAsyncCallNotFinished = 'The asynchronous call is not finished yet';
  RsAsyncCallUnknownVarRecType = 'Unknown TVarRec type %d';

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

    function AllocThread: TAsyncCallThread;
    function GetNextAsyncCall(Thread: TAsyncCallThread): TAsyncCall; // called from the threads
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddAsyncCall(Call: TAsyncCall);
    function RemoveAsyncCall(Call: TAsyncCall): Boolean;

    property MaxThreads: Integer read FMaxThreads;
    property NumberOfProcessors: Cardinal read FNumberOfProcessors;
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
  end;

  { TAsyncCall is the base class for all parameter based async call types }
  TAsyncCall = class(TInterfacedObject, IAsyncCall, IAsyncCallEx)
  private
    FEvent: THandle;
    FReturnValue: Integer;
    FFinished: Boolean;
    FFatalException: Exception;
    FFatalErrorAddr: Pointer;
    procedure InternExecuteAsyncCall;
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

{ ---------------------------------------------------------------------------- }

type
  TAsyncMTForLoopIterationRec = record
    Index: Integer;
    LoopContinue: Boolean;
    BasePointer: Pointer;
    SyncLock: TCriticalSection;
    LocalProc: TLocalAsyncForLoopProc;
  end;

function AsyncMTForLoopIteration(var Context): Integer;
asm
  push eax // backup for the LoopContinue result

  mov edx, [eax].TAsyncMTForLoopIterationRec.BasePointer
  push edx

  mov edx, [eax].TAsyncMTForLoopIterationRec.SyncLock
  mov ecx, [eax].TAsyncMTForLoopIterationRec.LocalProc
  mov eax, [eax].TAsyncMTForLoopIterationRec.Index
  call ecx

  pop ecx // take BasePointer from the stack

  pop edx
  mov [edx].TAsyncMTForLoopIterationRec.LoopContinue, al
end;

function InternAsyncMTForLoop(LocalProc: TLocalAsyncForLoopProc;
  StartIndex, EndIndex: Integer; MaxThreads: Integer; BasePointer: Pointer): Boolean;
var
  Asyncs: array of IAsyncCall;
  Contexts: array of TAsyncMTForLoopIterationRec;
  SingleContext: TAsyncMTForLoopIterationRec;
  Index, AsyncIndex, I: Integer;
  SyncLock: TCriticalSection;
begin
  if StartIndex > EndIndex then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  SyncLock := TCriticalSection.Create;
  try
    if (StartIndex = EndIndex) or (MaxThreads = 1) then
    begin
      SingleContext.BasePointer := BasePointer;
      SingleContext.SyncLock := SyncLock;
      SingleContext.LocalProc := LocalProc;
      Result := False;
      for Index := StartIndex to EndIndex do
      begin
        SingleContext.Index := StartIndex;
        AsyncMTForLoopIteration(SingleContext);
        if not SingleContext.LoopContinue then
          Exit;
      end;
      Result := True;
    end
    else
    begin
      if MaxThreads <= 0 then
        MaxThreads := ThreadPool.NumberOfProcessors * 2;
      SetLength(Asyncs, MaxThreads);
      SetLength(Contexts, MaxThreads);
      for I := 0 to MaxThreads - 1 do
      begin
        Contexts[I].BasePointer := BasePointer;
        Contexts[I].SyncLock := SyncLock;
        Contexts[I].LocalProc := LocalProc;
      end;

      AllocConsole;
      Index := StartIndex;
      repeat
        for I := 0 to MaxThreads - 1 do
        begin
          if Asyncs[I] = nil then
          begin
            Contexts[I].Index := Index;
            WriteLn(Index);
            Asyncs[I] := AsyncCallEx(AsyncMTForLoopIteration, Contexts[I]);
            if Index < EndIndex then
              Inc(Index)
            else
              Break;
          end;
        end;
        if Index = EndIndex then
          Break;

        AsyncIndex := AsyncMultiSync(Asyncs, False, 15000);
        if not Contexts[AsyncIndex].LoopContinue then
        begin
          Result := False;
          Break;
        end;

        Asyncs[AsyncIndex] := nil;
      until Index > EndIndex;
      { Wait for all remaining threads to finish. } 
      AsyncMultiSync(Asyncs, True);
    end;
  finally
    SyncLock.Free;
  end;
end;

function AsyncMTForLoop(LocalProc: TLocalAsyncForLoopProc;
  StartIndex, EndIndex: Integer; MaxThreads: Integer): Boolean;
asm
  pop ebp // remove stackframe
  push [esp+4]
  push ebp
  call InternAsyncMTForLoop
  push ebp
end;

{ ---------------------------------------------------------------------------- }

function AsyncCallEx(Proc: TAsyncCallArgRecordProc; var Arg{: TRecordType}): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
  if ThreadPool.MaxThreads = 0 then
    Result := TSyncCall.Create(Proc(Arg))
  else
    Result := TAsyncCallArgRecord.Create(Proc, @Arg).ExecuteAsync;
end;

function AsyncCallEx(Method: TAsyncCallArgRecordMethod; var Arg{: TRecordType}): IAsyncCall;
begin
  { Execute the function synchron when no thread pool exists }
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
    Call.InternExecuteAsyncCall
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
    Call.InternExecuteAsyncCall
  else
    Call.ExecuteAsync;
  Result := Call;
end;

{ ---------------------------------------------------------------------------- }

function WaitForSingleObjectMainThread(AHandle: THandle; Timeout: Cardinal): Cardinal;
var
  Handles: array[0..1] of THandle;
begin
  Handles[0] := AHandle;
  Handles[1] := Classes.SyncEvent;
  repeat
    Result := WaitForMultipleObjects(2, @Handles[0], False, Timeout);
    if Result = WAIT_OBJECT_0 + 1 then
      CheckSynchronize(0);
  until Result <> WAIT_OBJECT_0 + 1;
end;

function WaitForMultipleObjectsMainThread(Count: Cardinal;
  const AHandles: array of THandle; WaitAll: Boolean; Timeout: Cardinal): Cardinal;
var
  Handles: array of THandle;
  Index: Cardinal;
  FirstFinished: Cardinal;
begin
  SetLength(Handles, Count + 1);
  Move(AHandles[0], Handles[0], Count * SizeOf(THandle));
  Handles[Count] := Classes.SyncEvent;
  if not WaitAll then
  begin
    repeat
      Result := WaitForMultipleObjects(Count + 1, @Handles[0], WaitAll, Timeout);
      if Result = WAIT_OBJECT_0 + Count then
        CheckSynchronize(0);
    until Result <> WAIT_OBJECT_0 + Count;
  end
  else
  begin
    FirstFinished := WAIT_TIMEOUT;
    repeat
      Result := WaitForMultipleObjects(Count + 1, @Handles[0], False, Timeout);
      if Result = WAIT_OBJECT_0 + Count then
        CheckSynchronize(0)
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
end;

{ ---------------------------------------------------------------------------- }

function AsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean;
  Milliseconds: Cardinal): Integer;

  function InternalWait(const List: array of IAsyncCall; WaitAll: Boolean;
    Milliseconds: Cardinal): Integer;
  var
    Events: array of THandle;
    Mapping: array of Integer;
    I: Integer;
    Count: Cardinal;
    EventIntf: IAsyncCallEx;
    SignalState: Cardinal;
  begin
    { Get the TAsyncCall events and ignore TSyncCall objects }
    Count := 0;
    SetLength(Events, Length(List));
    SetLength(Mapping, Length(List));
    for I := 0 to High(List) do
    begin
      if (List[I] <> nil) and Supports(List[I], IAsyncCallEx, EventIntf) then
      begin
        Events[Count] := EventIntf.GetEvent;
        if Events[Count] <> 0 then
        begin
          Mapping[Count] := I;
          Inc(Count);
        end;
      end;
    end;

    { Wait for the async calls }
    if Count > 0 then
    begin
      if GetCurrentThreadId = MainThreadID then
        SignalState := WaitForMultipleObjectsMainThread(Count, Events, WaitAll, Milliseconds)
      else
        SignalState := WaitForMultipleObjects(Count, @Events[0], WaitAll, Milliseconds);
      if {(SignalState >= WAIT_OBJECT_0) and} (SignalState < WAIT_OBJECT_0 + Count) then
        Result := Mapping[SignalState - WAIT_OBJECT_0]
      else
        Result := -1;
    end
    else
      Result := 0;
  end;

  function InternalWaitAllInfinite(const List: array of IAsyncCall): Integer;
  var
    I: Integer;
    Intf: IAsyncCallEx;
  begin
    { We can execute some async calls in this thread. }
    for I := 0 to High(List) - 1 do
    begin
      if (List[I] <> nil) and Supports(List[I], IAsyncCallEx, Intf) then
      begin
        Intf.SyncInThisThreadIfPossible;
        Intf := nil;
      end;
    end;
    { Wait for the async calls that aren't finished yet. }
    for I := 0 to High(List) do
      if List[I] <> nil then
        List[I].Sync;
    Result := 0;
  end;


begin
  if Length(List) > 0 then
  begin
    if WaitAll and (Milliseconds = INFINITE) and (GetCurrentThreadId <> MainThreadId) then
      Result := InternalWaitAllInfinite(List)
    else
      Result := InternalWait(List, WaitAll, Milliseconds);
  end
  else
    Result := 0;
end;

procedure NotFinishedError(const FunctionName: string);
begin
  {$IFDEF DEBUGASYNCCALLS}
  if FunctionName <> '' then
    OutputDebugString(PChar(FunctionName));
  {$ENDIF DEBUGASYNCCALLS}
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
  //MainWnd: THandle;
  CoInitialized: Boolean;
begin
  CoInitialized := CoInitialize(nil) = S_OK;
  try
    while not Terminated do
    begin
      FAsyncCall := ThreadPool.GetNextAsyncCall(Self); { calls Suspend if nothing has to be done. }
      if FAsyncCall <> nil then
      begin
        try
          FAsyncCall.InternExecuteAsyncCall;
        except
          on E: Exception do
          begin
            {$IFDEF DEBUGASYNCCALLS}
            OutputDebugString(PChar('[' + E.ClassName + '] ' + E.Message));
            {$ENDIF DEBUGASYNCCALLS}
            {MainWnd := 0;
            EnumThreadWindows(MainThreadID, @GetMainWnd, Integer(@MainWnd));
            if Windows.GetParent(MainWnd) <> 0 then
              MainWnd := Windows.GetParent(MainWnd);
            MessageBox(MainWnd, PChar(E.Message), PChar(string(E.ClassName)), MB_OK or MB_ICONERROR);}
            FAsyncCall.FFatalErrorAddr := ErrorAddr;
            FAsyncCall.FFatalException := AcquireExceptionObject;
          end;
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

  { There is nothing to do, go sleeping... }
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
    end;
  end;
  inherited Destroy;
end;

function TAsyncCall.Finished: Boolean;
begin
  Result := (FEvent = 0) or FFinished or (WaitForSingleObject(FEvent, 0) = WAIT_OBJECT_0);
end;

function TAsyncCall.GetEvent: Cardinal;
begin
  Result := FEvent;
end;

procedure TAsyncCall.InternExecuteAsyncCall;
begin
  try
    FReturnValue := ExecuteAsyncCall;
  finally
    FFinished := True;
    SetEvent(FEvent);
  end;
end;

function TAsyncCall.ReturnValue: Integer;
var
  E: Exception;
begin
  if not Finished then
    NotFinishedError('ReturnValue');
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
    if not SyncInThisThreadIfPossible then
    begin
      if GetCurrentThreadId = MainThreadID then
      begin
        if WaitForSingleObjectMainThread(FEvent, INFINITE) <> WAIT_OBJECT_0 then
          NotFinishedError('Sync');
      end
      else
      if WaitForSingleObject(FEvent, INFINITE) <> WAIT_OBJECT_0 then
        NotFinishedError('Sync');
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
    { If no thread was assigned to this async call, remove it form the waiting
      queue and execute it in the current thread. }
    if ThreadPool.RemoveAsyncCall(Self) then
    begin
      InternExecuteAsyncCall;
      Result := True;
    end
    else
      Result := False;
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
    Param: Integer;
  end;

procedure LocalVclCallProc(Data: PLocalVclCallRec);
asm
  mov edx, [eax].TLocalVclCallRec.BasePointer
  mov ecx, [eax].TLocalVclCallRec.Proc
  mov eax, [eax].TLocalVclCallRec.Param
  push edx // parent EBP
  call ecx
  pop ecx // clean up
end;

procedure InternLocalVclCall(LocalProc: TLocalVclProc; Param: Integer; BasePointer: Pointer);
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
    TThread.Synchronize(nil, TThreadMethod(M));
  end;
end;

procedure LocalVclCall(LocalProc: TLocalVclProc; Param: Integer);
asm
  mov ecx, ebp
  jmp InternLocalVclCall
end;

initialization
  ThreadPool := TThreadPool.Create;

finalization
  ThreadPool.Free;
  ThreadPool := nil;

end.

