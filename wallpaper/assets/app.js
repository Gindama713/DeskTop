/* ASCII ocean wallpaper. The terminal is a real window (see pin-terminal.ps1). */
(function () {
  const mod = window.__OCEAN_MODULE__;
  const canvas = document.getElementById('ocean');
  if (!mod || !mod.OceanEngine || !canvas) {
    document.body.style.background =
      'radial-gradient(120vmin 80vmin at 50% 40%, #16302a, #08100e 70%)';
    return;
  }

  const engine = new mod.OceanEngine(canvas, { fadeIn: false });
  const cell = Math.max(9, Math.min(14, Math.round(window.innerWidth / 168)));

  engine.setSettings({
    species: 'shark',
    theme: 'dark',
    transparent: false,
    background: '#0c211c',
    koiColor: '#dbbc7f',
    goldfishColor: '#e69875',
    sharkColor: '#c3e8cf',
    dotPrimary: '#6a9c80',
    dotSecondary: '#e6f2d8',
    accent: '#a7c080',
    dotDensity: 0.18,
    grid: 0.015,
    cellSize: cell,
    heroOpacity: 1,
    idleOpacity: 1,
    linkOpacity: true
  });
  engine.start();
})();
