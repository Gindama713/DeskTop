# Extract 256px shell icons for every start-menu app and write assets/icons.js
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$outDir = Join-Path $root 'assets\icons'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not ('ShellIcons' -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public static class ShellIcons
{
    [StructLayout(LayoutKind.Sequential)]
    public struct SIZE { public int cx; public int cy; public SIZE(int x, int y) { cx = x; cy = y; } }

    [Flags]
    public enum SIIGBF
    {
        RESIZETOFIT = 0x00, BIGGERSIZEOK = 0x01, MEMORYONLY = 0x02, ICONONLY = 0x04,
        THUMBNAILONLY = 0x08, INCACHEONLY = 0x10, CROPTOSQUARE = 0x20,
        WIDETHUMBNAILS = 0x40, ICONBACKGROUND = 0x80, SCALEUP = 0x100
    }

    [ComImport, Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IShellItemImageFactory
    {
        void GetImage(SIZE size, SIIGBF flags, out IntPtr phbm);
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    static extern void SHCreateItemFromParsingName(
        [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
        IntPtr pbc,
        [MarshalAs(UnmanagedType.LPStruct)] Guid riid,
        [MarshalAs(UnmanagedType.Interface)] out object ppv);

    [DllImport("gdi32.dll")]
    static extern bool DeleteObject(IntPtr hObject);

    public static Bitmap Get(string path, int size)
    {
        object item;
        SHCreateItemFromParsingName(path, IntPtr.Zero, typeof(IShellItemImageFactory).GUID, out item);
        var factory = (IShellItemImageFactory)item;
        IntPtr hbm;
        factory.GetImage(new SIZE(size, size), SIIGBF.ICONONLY | SIIGBF.BIGGERSIZEOK | SIIGBF.SCALEUP, out hbm);
        var src = Image.FromHbitmap(hbm);
        var copy = new Bitmap(src);
        src.Dispose();
        DeleteObject(hbm);
        return copy;
    }
}
"@ -ReferencedAssemblies System.Drawing
}

function Slug([string]$name) { return ($name -replace '[\\/:*?"<>|\s]', '_') }

# every .lnk in both start menus, same filtering as collect.ps1
$skip = 'uninstall|help|readme|documentation|license|release note|update|website|administrative tools|nahimic|file explorer|system information'
$dirs = @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
$map = @{}
$seen = @{}
foreach ($d in $dirs) {
    Get-ChildItem $d -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
        $n = $_.BaseName
        if ($n -match $skip) { return }
        if ($n.Length -gt 22) { return }
        if ($seen.ContainsKey($n)) { return }
        $seen[$n] = $true
        $slug = Slug $n
        $file = Join-Path $outDir ($slug + '.png')
        if (-not (Test-Path $file)) {
            try {
                $bmp = [ShellIcons]::Get($_.FullName, 256)
                $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
                $bmp.Dispose()
            } catch { return }
        }
        $map[$n] = 'assets/icons/' + $slug + '.png'
    }
}

# folder icon, taken from the real Documents folder
try {
    $bmp = [ShellIcons]::Get((Join-Path $env:USERPROFILE 'Documents'), 256)
    $bmp.Save((Join-Path $outDir '_folder.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
} catch { }

$json = $map | ConvertTo-Json -Compress
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $root 'assets\icons.js'), "window.APP_ICONS = $json;", $enc)
Write-Output ("icons: " + $map.Count)
Write-Output ("folder icon: " + (Test-Path (Join-Path $outDir '_folder.png')))
