Add-Type -AssemblyName System.Windows.Forms
[Uint32]$EVENT_SYSTEM_FOREGROUND = 3;
[Uint32]$WINEVENT_OUTOFCONTEXT = 0;

$DynAssembly = New-Object System.Reflection.AssemblyName("NativeMethod")
$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule("NativeMethod", $False)

$Win32TypeBuilder = $ModuleBuilder.DefineType("Win32", "Public, Class")
$Win32TypeBuilder.DefinePInvokeMethod(
    "SetWinEventHook",
    "user32.dll",
    "Public, Static",
    "Standard",
    [IntPtr],
    @([Uint32], [Uint32], [IntPtr], [MulticastDelegate], [Uint32], [Uint32], [Uint32]),
    [Runtime.InteropServices.CallingConvention]::Winapi,
    [Runtime.InteropServices.CharSet]::Auto) | ForEach-Object { $_.SetImplementationFlags($_.GetMethodImplementationFlags() -bor [System.Reflection.MethodImplAttributes]::PreserveSig) }
$Win32TypeBuilder.DefinePInvokeMethod(
    "GetCurrentProcessId",
    "Kernel32.dll",
    "Public, Static",
    "Standard",
    [int],
    [Type]::EmptyTypes,
    [Runtime.InteropServices.CallingConvention]::Winapi,
    [Runtime.InteropServices.CharSet]::Auto) | ForEach-Object { $_.SetImplementationFlags($_.GetMethodImplementationFlags() -bor [System.Reflection.MethodImplAttributes]::PreserveSig) }
$Win32TypeBuilder.DefinePInvokeMethod(
    "UnhookWinEvent",
    "user32.dll",
    "Public, Static",
    "Standard",
    [bool],
    @([IntPtr]),
    [Runtime.InteropServices.CallingConvention]::Winapi,
    [Runtime.InteropServices.CharSet]::Auto) | ForEach-Object { $_.SetImplementationFlags($_.GetMethodImplementationFlags() -bor [System.Reflection.MethodImplAttributes]::PreserveSig) }

$mscorlib = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.ManifestModule.Name -eq "System.dll"}
$NativeMethods = $mscorlib.GetType("Microsoft.Win32.NativeMethods")
$GetWindowTextLength = $NativeMethods.GetMethod("GetWindowTextLength", ([Reflection.BindingFlags] "Public, Static"))
$GetWindowText = $NativeMethods.GetMethod("GetWindowText", ([Reflection.BindingFlags] "Public, Static"))

$Api = $Win32TypeBuilder.CreateType()

$DelegateTypeBuilder = $ModuleBuilder.DefineType("MyDelegate", "Class, Public, Sealed, AnsiClass, AutoClass", [MulticastDelegate])
$ConstructorBuilder = $DelegateTypeBuilder.DefineConstructor("RTSpecialName, HideBySig, Public", "Standard", @([System.Object], [System.IntPtr]))
$ConstructorBuilder.SetImplementationFlags("Runtime, Managed")
$MethodBuilder = $DelegateTypeBuilder.DefineMethod("Invoke", "Public, HideBySig, NewSlot, Virtual", [Void], @([IntPtr], [Uint32], [IntPtr], [Int32], [Int32], [Uint32], [Uint32]))
$MethodBuilder.SetImplementationFlags("Runtime, Managed")
$Callback = $DelegateTypeBuilder.CreateType()

$Action = {
    Param (
        [IntPtr] $hWinEventHook,
        [Uint32] $eventType,
        [IntPtr] $hwnd,
        [Int32] $idObject,
        [Int32] $idChild,
        [Uint32] $dwEventThread,
        [Uint32] $dwmsEventTime
    )
    if ($hwnd -ne [IntPtr]::Zero) {
        $WindowTitleLength = $GetWindowTextLength.Invoke($null,
            @(([Runtime.InteropServices.HandleRef] (New-Object Runtime.InteropServices.HandleRef($this, $hwnd))))) * 2
        $WindowTitleSB = New-Object Text.StringBuilder($WindowTitleLength)
        $GetWindowText.Invoke($null,
            @(([Runtime.InteropServices.HandleRef] (New-Object Runtime.InteropServices.HandleRef($this, $hwnd))),
                [Text.StringBuilder] $WindowTitleSB, $WindowTitleSB.Capacity))
        $WindowTitle = $WindowTitleSB.ToString()
        $Output = [PSCustomObject]@{
            TimeStamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            WindowTitle = $WindowTitle
        }
        Write-Host $Output
    }
    [void]
}

$WinEventProc = $Action -as $Callback
$ForeGroundHook = $Api::SetWinEventHook($EVENT_SYSTEM_FOREGROUND, $EVENT_SYSTEM_FOREGROUND, [System.IntPtr]::Zero, $WinEventProc, 0, 0, $WINEVENT_OUTOFCONTEXT)

Write-Host "ForeGroundHook = $ForeGroundHook"

While ($true) {
    [System.Windows.Forms.Application]::DoEvents() #TODO Can we create a 'normal' message loop instead of using DoEvents()?
    [System.Threading.Thread]::Sleep(10)
}
if ($Api::UnhookWinEvent($ForeGroundHook) -eq $true) { #TODO Make unhooking on application exit reliable
    Write-Host "Unhook successful"
}