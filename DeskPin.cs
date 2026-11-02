using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

class DeskPin
{
    [StructLayout(LayoutKind.Sequential)]
    struct RECT { public int Left, Top, Right, Bottom; }

    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);

    static int ReadInt(string path, string key, int fallback)
    {
        try
        {
            if (!System.IO.File.Exists(path)) return fallback;
            foreach (var line in System.IO.File.ReadAllLines(path))
            {
                var t = line.Trim();
                if (t.StartsWith("#")) continue;
                var parts = t.Split('=');
                if (parts.Length == 2 && parts[0].Trim().Equals(key, StringComparison.OrdinalIgnoreCase))
                {
                    int v;
                    if (int.TryParse(parts[1].Trim(), out v)) return v;
                }
            }
        }
        catch { }
        return fallback;
    }

    static void Main()
    {
        string layout = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "layout.txt");
        int X = ReadInt(layout, "X", 444);
        int Y = ReadInt(layout, "Y", 274);

        IntPtr bottom = new IntPtr(1);
        const uint MOVE = 0x0001 | 0x0010;      // NOSIZE | NOACTIVATE
        const uint PIN  = 0x0010 | 0x0001 | 0x0002; // NOACTIVATE | NOSIZE | NOMOVE

        while (true)
        {
            foreach (var p in Process.GetProcessesByName("wezterm-gui"))
            {
                IntPtr h = p.MainWindowHandle;
                if (h == IntPtr.Zero) continue;
                RECT r;
                GetWindowRect(h, out r);
                if ((r.Right - r.Left) > 200 && (r.Left != X || r.Top != Y))
                    SetWindowPos(h, IntPtr.Zero, X, Y, 0, 0, MOVE);
                SetWindowPos(h, bottom, 0, 0, 0, 0, PIN);
            }
            Thread.Sleep(500);
        }
    }
}