-- generated from config.json by tools/gen-lua.ps1 - do not edit
return {
  tabs = {
    {
      name = 'stats',
      panes = {
        { args = { '${PY}', '-u', '${LOCAL}/panes/donut.py' }, size = 0.56 },
        { args = { '${PS}', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', '${LOCAL}/panes/leetcode.ps1' }, split = 'Right', size = 0.44 },
      },
    },
    {
      name = 'console',
      panes = {
        { args = { '${PS}', '-NoLogo', '-NoExit', '-Command', '${CLAUDE}' } },
        { args = { '${PS}', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', '${LOCAL}/panes/hud.ps1' }, split = 'Left', size = 0.40 },
        { args = { '${WSL}' }, split = 'Bottom', size = 0.34 },
      },
    },
    {
      name = 'work',
      panes = {
        { args = { '${PS}', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', '${LOCAL}/panes/todo.ps1' } },
        { args = { '${PS}', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', '${LOCAL}/panes/pomodoro.ps1' }, split = 'Right', size = 0.26 },
      },
    },
  },
}