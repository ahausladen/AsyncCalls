# AsyncCalls - Delphi asynchronous function call framework

## IAsyncCall interface

All AsyncCall functions return an **IAsyncCall** interface that is used to control the async. function.
If the last reference to the interface is gone, the async. function will be synchronized to the thread
that released the last reference unless `Forget` was called.

```delphi
  IAsyncCall = interface 
    function Sync: Integer; 
    function Finished: Boolean; 
    function ReturnValue: Integer; 
    function Canceled: Boolean; 
    procedure ForceDifferentThread; 
    procedure CancelInvocation; 
    procedure Forget; 
  end;
```
* `Sync` waits until the function is finished and returns the return value of the function.
  It is undefined for procedures.
* `Finished` returns **True** when the async. function is finished. Otherwise it returns **False**.
* `ReturnValue` returns the async. function's return value. It is undefined for procedures.
  If the async. function is still executing, it raises an **EAsyncCallError** exception.
* `Canceled` returns **True** if the AsyncCall was canceled .
* `ForceDifferentThread` tells AsyncCalls to not execute the function in the current thread.
* `CancelInvocation` stops the async. function from being executed. If the function is already
  executing, a call to **CancelInvocation** has no effect and the **Canceled** method will
  return **False**.
* `Forget` unlinks the async. function from the returned interface. This means that if the las
  reference to the **IAsyncCall** interface is gone, the async. function will still be executed.
  The interface's methods will throw an exception if called after **Forget**. The async. function
  must not call into the main thread because it could be executed after the TThread.Synchronize/Queue
  mechanism was shut down by the RTL what can cause a dead lock.


## TAsyncCalls class (Delphi 2009 and newer)

```delphi
type
  TAsyncCalls = class(TObject)
  public
    { Invoke an asynchronous function call }
    class function Invoke<T>(Proc: TAsyncCallArgGenericProc<T>; const Arg: T): IAsyncCall; overload; static;
    class function Invoke<T>(Event: TAsyncCallArgGenericMethod<T>; const Arg: T): IAsyncCall; overload; static;
    class function Invoke<T1, T2>(Proc: TAsyncCallArgGenericProc<T1, T2>; const Arg1: T1;
	  const Arg2: T2): IAsyncCall; overload; static;
    class function Invoke<T1, T2>(Event: TAsyncCallArgGenericMethod<T1, T2>; const Arg1: T1;
	  const Arg2: T2): IAsyncCall; overload; static;
    class function Invoke<T1, T2, T3>(Proc: TAsyncCallArgGenericProc<T1, T2, T3>; const Arg1: T1;
	  const Arg2: T2; const Arg3: T3): IAsyncCall; overload; static;
    class function Invoke<T1, T2, T3>(Event: TAsyncCallArgGenericMethod<T1, T2, T3>; const Arg1: T1;
	  const Arg2: T2; const Arg3: T3): IAsyncCall; overload; static;
    class function Invoke<T1, T2, T3, T4>(Proc: TAsyncCallArgGenericProc<T1, T2, T3, T4>;
	  const Arg1: T1; const Arg2: T2; const Arg3: T3; const Arg4: T4): IAsyncCall; overload; static;
    class function Invoke<T1, T2, T3, T4>(Event: TAsyncCallArgGenericMethod<T1, T2, T3, T4>;
	  const Arg1: T1; const Arg2: T2; const Arg3: T3; const Arg4: T4): IAsyncCall; overload; static;

    { Invoke an asynchronous anonymous method call }
    class function Invoke(Func: TIntFunc): IAsyncCall; overload; static;
    class function Invoke(Proc: TProc): IAsyncCall; overload; static;

    class procedure MsgExec(AsyncCall: IAsyncCall; IdleMsgMethod: TAsyncIdleMsgMethod); static;

    { Synchronize with the VCL }
    class procedure VCLSync(Proc: TProc); static;
    class function VCLInvoke(Proc: TProc): IAsyncCall; static;
  end;
```

* `Invoke<T...>` executes an anonymous method (TIntProc, TProc), a global function (TAsnyCallArgGenericProc)
   or an event (TAsyncCallArgGenericMethod) asynchronously. The specified arguments are transfered to
   the async. function.
* `MsgExec` waits for the **AsyncCall** to finish. If there are any messages in the message queue and
  the function was called from the main thread, it will call **IdleMsgMethod**. You can specify
  **Application.ProcessMessages** as **IdleMsgMethod** (with all its implications).
* `VCLSync` blocks the thread and returns after the anonymous method was executed in the main thread.
  If the current thread is the main thread, the anonymous method is executed directly.
* `VCLInvoke` returns immediately. The anonymous method will be executed in the main thread.


## AsyncCall functions

```delphi
function AsyncCall(Proc: TAsyncCallArgObjectProc; Arg: TObject): IAsyncCall; overload; 
function AsyncCall(Proc: TAsyncCallArgIntegerProc; Arg: Integer): IAsyncCall; overload; 
function AsyncCall(Proc: TAsyncCallArgStringProc; const Arg: string): IAsyncCall; overload; 
function AsyncCall(Proc: TAsyncCallArgWideStringProc; const Arg: WideString): IAsyncCall; overload; 
function AsyncCall(Proc: TAsyncCallArgInterfaceProc; const Arg: IInterface): IAsyncCall; overload; 
function AsyncCall(Proc: TAsyncCallArgExtendedProc; const Arg: Extended): IAsyncCall; overload; 
function AsyncCallVar(Proc: TAsyncCallArgVariantProc; const Arg: Variant): IAsyncCall; overload; 

function AsyncCall(Method: TAsyncCallArgObjectMethod; Arg: TObject): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgIntegerMethod; Arg: Integer): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgStringMethod; const Arg: string): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgWideStringMethod; const Arg: WideString): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgInterfaceMethod; const Arg: IInterface): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgExtendedMethod; const Arg: Extended): IAsyncCall; overload; 
function AsyncCallVar(Method: TAsyncCallArgVariantMethod; const Arg: Variant): IAsyncCall; overload; 

function AsyncCall(Method: TAsyncCallArgObjectEvent; Arg: TObject): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgIntegerEvent; Arg: Integer): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgStringEvent; const Arg: string): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgWideStringEvent; const Arg: WideString): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgInterfaceEvent; const Arg: IInterface): IAsyncCall; overload; 
function AsyncCall(Method: TAsyncCallArgExtendedEvent; const Arg: Extended): IAsyncCall; overload; 
function AsyncCallVar(Method: TAsyncCallArgVariantEvent; const Arg: Variant): IAsyncCall; overload; 

procedure AsyncExec(Method: TNotifyEvent; Arg: TObject; IdleMsgMethod: TAsyncIdleMsgMethod);
```

* `AsyncCall` start a specified async. function.
* `AsyncCallVar` like *AsyncCall* but expects a **Variant** argument.
* `AsyncExec` calls the IdleMsgMethod in a loop, while the async. method is executed.
* **Arguments**

  <table>
   <tr><td>Proc/Method</td><td>Function that should be executed async.</td></tr>
   <tr><td>Arg        </td><td>User defined argument that is copied to the async. function argument.</td></tr>
  </table>

### Example

```delphi
function TestFunc(const Text: string): Integer; 
begin 
  Result := TimeConsumingFuncion(Text); 
end;

a := AsyncCall(TestFunc, 'A Text');
```


## AsyncCallEx functions

```delphi
function AsyncCallEx(Proc: TAsyncCallArgRecordProc; var Arg{: TRecordType}): IAsyncCall; overload; 
function AsyncCallEx(Method: TAsyncCallArgRecordMethod; var Arg{: TRecordType}): IAsyncCall; overload; 
function AsyncCallEx(Method: TAsyncCallArgRecordEvent; var Arg{: TRecordType}): IAsyncCall; overload;
```

* `AsyncCallEx` starts the specified async. function with a referenced value type (record) that can
  be manipulated in the async. function.
* **Arguments**

  <table>
   <tr><td>Proc/Method</td><td>Function that should be executed async.</td></tr>
   <tr><td>Arg        </td><td>User defined value type (record).</td></tr>
  </table>

### Example

```delphi
type 
  TData = record 
    Value: Integer; 
  end; 

procedure TestRec(var Data: TData); 
begin 
  Data.Value := 70; 
end; 

a := AsyncCallEx(@TestRec, MyData); 
{ Don't access "MyData" here until the async. function has finished. } 
a.Sync;
// MyData.Value is now 70
```

## IAsyncRunnable

```delphi
type
  IAsyncRunnable = interface
    ['{1A313BBD-0F89-43AD-8B57-BBA3205F4888}']
    procedure AsyncRun;
  end;

function AsyncCall(Runnable: IAsyncRunnable): IAsyncCall; overload;
```
* `AsyncCall` executes the Runnable asynchronously.


## AsyncMultiSync - Thread synchronization

```delphi
function AsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean = True; 
  Milliseconds: Cardinal = INFINITE): Cardinal; 
function AsyncMultiSyncEx(const List: array of IAsyncCall; const Handles: array of THandle; 
  WaitAll: Boolean = True; Milliseconds: Cardinal = INFINITE): Cardinal; 
function MsgAsyncMultiSync(const List: array of IAsyncCall; WaitAll: Boolean; 
  Milliseconds: Cardinal; dwWakeMask: DWORD): Cardinal; 
function MsgAsyncMultiSyncEx(const List: array of IAsyncCall; const Handles: array of THandle; 
  WaitAll: Boolean; Milliseconds: Cardinal; dwWakeMask: DWORD): Cardinal;
```
  
* `AsyncMultiSync` waits for the async calls and other handles to finish. MsgAsyncMultiSync()
  waits for the async calls, other handles and the message queue.
* **Arguments**
  
  <table>
   <tr><td>List         </td><td>An array of IAsyncCall interfaces for which the function should
                                 wait.</td></tr>
   <tr><td>Handles      </td><td>An array of THandle for which the function should wait.</td>
   <tr><td>WaitAll=True </td><td>The function returns when all listed async calls have finished.
	                             If Milliseconds is INFINITE the async calls meight be executed
								 in the current thread. The return value is zero when all async.
								 calls have finished. Otherwise it is WAIT_FAILED.</td></tr>
   <tr><td>WaitAll=False</td><td>The function returns when at least one of the async calls has
                                 finished. The return value is the list index of the first finished
								 async call. If there was a timeout, the return value is WAIT_FAILED.</td></tr>
   <tr><td>Milliseconds </td><td>Specifies the number of milliseconds to wait until a timeout
                                 happens. The value INFINITE lets the function wait until all async
								 calls have finished.</td></tr>
   <tr><td>dwWakeMask   </td><td>See Windows.MsgWaitForMultipleObjects()</td></tr>
  </table>

* **Limitation**: Length(List)+Length(Handles) must not exceed **MAXIMUM_ASYNC_WAIT_OBJECTS**.
  (61 elements)
* **Return value**

  <table>
   <tr><td>WAIT_TIMEOUT                              </td><td>The function timed out</td></tr>
   <tr><td>WAIT_OBJECT_0+index                       </td><td>The first finished async call</td></tr>
   <tr><td>WAIT_OBJECT_0+Length(List)+index          </td><td>The first signaled handle</td></tr>
   <tr><td>WAIT_OBJECT_0+Length(List)+Length(Handles)</td><td>A message was signaled</td></tr>
   <tr><td>WAIT_ABANDONED_0+index                    </td><td>The abandoned async call</td></tr>
   <tr><td>WAIT_ABANDONED_0+Length(List)+index       </td><td>The abandoned handle</td></tr>
   <tr><td>WAIT_FAILED                               </td><td>The function failed</td></tr>
  </table>


## LocalAsyncCall function (deprecated, Win32 only)

```delphi
function LocalAsyncCall(LocalProc: TLocalAsyncProc): IAsyncCall; 
function LocalAsyncCallEx(LocalProc: TLocalAsyncProcEx; Param: INT_PTR): IAsyncCall; 
procedure LocalAsyncExec(Proc: TLocalAsyncProc; IdleMsgMethod: TAsyncIdleMsgMethod);
```

* `LocalAsyncCall` executes the given local function/procedure in a separate thread. The result
  value of the async. function is returned by `IAsyncCall.Sync` and `IAsyncCall.ReturnValue`.
* `LocalAsyncCallEx` is like **LocalAsyncCall** but you can specify am INT_PTR parameter for the
  local function.
* The `LocalAsyncExec` function calls the **IdleMsgMethod** while the local procedure is executed.
* LocalProc: A local function that should be executed asynchronously.


### Example

```delphi
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
```


## VCL synchronization (deprecated, Win32 only)

```delphi
procedure LocalVclCall(LocalProc: TLocalVclProc; Param: INT_PTR = 0); 
function LocalAsyncVclCall(LocalProc: TLocalVclProc; Param: INT_PTR = 0): IAsyncCall;
```

* `LocalVclCall` executes the given local function/procedure in the main thread. It uses the
  **TThread.Synchronize** function that blocks the current thread.
* `LocalAsyncVclCall` execute the given local function/procedure in the main thread. It does not
  wait for the main thread to execute the function unless the current thread is the main thread.
  In that case it executes and waits for the specified function in the current thread like **LocalVclCall**.

The result value of the asynchronous function is returned by `IAsyncCall.Sync` and `IAsyncCall.ReturnValue`.


### Example

```delphi
procedure TFormMain.MainProc; 

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
```


## EnterMainThread/LeaveMainThread (deprecated, Win32 only)

```delphi
procedure EnterMainThread; 
procedure LeaveMainThread;
```

`EnterMainThread` and `LeaveMainThread` can be used to temporary switch to the main thread.
The code that should be synchonized with the main thread (blocking) has to be put into a
**try/finally** block and the **LeaveMainThread** function must be called from the finally
block. A missing try/finally will lead to an access violation.

* All local variables can be used. (The CPU register **EBP** points to the thread's stack while
  **ESP** points the the main thread's stack)
* Unhandled exceptions are passed to the *surrounding* thread.
* The integrated debugger is not able to follow the execution flow. You have to use break points
  instead of "Step over/in". Nested calls to **EnterMainThread** and **LeaveMainThread** are ignored.
  But they must strictly follow the try/finally structure.


### Example

```delphi
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
```


## AsyncCall with a variable number of arguments (deprecated, Win32 only)

```delphi
function AsyncCall(Proc: TCdeclFunc; const Args: array of const): IAsyncCall; overload; 
function AsyncCall(Proc: TCdeclMethod; const Args: array of const): IAsyncCall; overload;
```

* `AsyncCall` starts a specified async. function with a variable number of argument. The async.
  function must be declared with call call conventsion **cdecl** and the argument's modifier must
  be const for Variants. All other types can have the const modifier but it is not necessary.
* **Arguments**

  <table>
   <tr><td>Proc/Method</td><td>Function that should be executed async.</td></tr>
   <tr><td>Arg        </td><td>An open array that specifies the async. function arguments. The
                               values are either copied or the reference counter is increased
							   during the execution of the async. function.</td></tr>
  </table>


## AsyncCalls internals - thread pool and waiting-queue

An execution request is added to the waiting-queue when an async. function is started. This
request forces the thread pool to check if there is an idle/suspended thread that could do the
job. If such a thread exists, it is reactivated/resumed. If no thread is available then it
depends on the number of threads in the pool what happens. If the maximum thread number is
already reached the request remains in the waiting-queue. Otherwise a new thread is added to
the thread pool.

Threads that aren't idle/suspended take the oldest request from the waiting-queue and execute
the associated async. function. If the waiting queue is empty the threads becomes idle/suspended.

