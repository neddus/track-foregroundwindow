
# WINEVENTPROC callback

We need to handle the fact that there are no delegate keyword in Powershell

The callback delegate in C#:

```C#
private delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);
```

Inspecting it with ILViewer tells us how to use TypeBuilder to create a delegate in Powershell

```IL
.class nested private sealed auto ansi 
    WinEventDelegate
      extends [mscorlib]System.MulticastDelegate
  {

    .method public hidebysig specialname rtspecialname instance void 
      .ctor(
        object 'object', 
        native int 'method'
      ) runtime managed 
    {
      // Can't find a body
    } // end of method WinEventDelegate::.ctor

    .method public hidebysig virtual newslot instance void 
      Invoke(
        native int hWinEventHook, 
        unsigned int32 eventType, 
        native int hwnd, 
        int32 idObject,
        int32 idChild, 
        unsigned int32 dwEventThread, 
        unsigned int32 dwmsEventTime
      ) runtime managed 
    {
      // Can't find a body
    } // end of method WinEventDelegate::Invoke

    .method public hidebysig virtual newslot instance class [mscorlib]System.IAsyncResult 
      BeginInvoke(
        native int hWinEventHook, 
        unsigned int32 eventType, 
        native int hwnd, 
        int32 idObject, 
        int32 idChild, 
        unsigned int32 dwEventThread, 
        unsigned int32 dwmsEventTime, 
        class [mscorlib]System.AsyncCallback callback, 
        object 'object'
      ) runtime managed 
    {
      // Can't find a body
    } // end of method WinEventDelegate::BeginInvoke

    .method public hidebysig virtual newslot instance void 
      EndInvoke(
        class [mscorlib]System.IAsyncResult result
      ) runtime managed 
    {
      // Can't find a body
    } // end of method WinEventDelegate::EndInvoke
  } // end of class WinEventDelegate
````