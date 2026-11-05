// APEX LOADING: theme engine. One accent drives the whole screen; every
// derived tint is precomputed in JS because CEF renders `color-mix()` with
// var() as `initial` (invisible) and never warns.
(function () {
  window.APX = window.APX || {};

  function hexToRgb(hex) {
    const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
    if (!m) return { r: 227, g: 38, b: 54 };
    return { r: parseInt(m[1], 16), g: parseInt(m[2], 16), b: parseInt(m[3], 16) };
  }
  function rgbToHex(r, g, b) {
    const h = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, '0');
    return '#' + h(r) + h(g) + h(b);
  }
  function mix(a, b, t) {
    const ca = hexToRgb(a), cb = hexToRgb(b);
    return rgbToHex(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t);
  }
  function alpha(hex, a) {
    const c = hexToRgb(hex);
    return 'rgba(' + c.r + ',' + c.g + ',' + c.b + ',' + a + ')';
  }
  // WCAG-ish ink: pick black or white text for a given accent
  function inkFor(hex) {
    const c = hexToRgb(hex);
    const lum = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) / 255;
    return lum > 0.62 ? '#0A0A0C' : '#FFFFFF';
  }

  function apply(theme) {
    const root = document.documentElement;
    const acc = theme.accent || '#E32636';
    const set = (k, v) => root.style.setProperty(k, v);

    set('--acc', acc);
    set('--acc-ink', inkFor(acc));
    set('--acc-300', mix(acc, '#FFFFFF', 0.35));
    set('--acc-600', mix(acc, '#000000', 0.25));
    set('--acc-a06', alpha(acc, 0.06));
    set('--acc-a12', alpha(acc, 0.12));
    set('--acc-a22', alpha(acc, 0.22));
    set('--acc-a40', alpha(acc, 0.40));
    set('--acc-a55', alpha(acc, 0.55));
    set('--r-lg', (theme.radius != null ? theme.radius : 14) + 'px');
    set('--r-md', Math.max(6, Math.round((theme.radius != null ? theme.radius : 14) * 0.64)) + 'px');
    set('--r-sm', Math.max(4, Math.round((theme.radius != null ? theme.radius : 14) * 0.42)) + 'px');

    // surfaces: glass (translucent over the art) or solid panels
    const op = theme.surface == null ? 0.7 : Math.max(0.15, Math.min(1, theme.surface));
    if (theme.glass === false) {
      set('--sf-0', '#090909');
      set('--sf-1', '#151515');
      set('--sf-2', '#1F1F1F');
      set('--ln-1', 'rgba(255,255,255,.10)');
    } else {
      set('--sf-0', 'rgba(9,9,9,' + (op * 0.89).toFixed(3) + ')');
      set('--sf-1', 'rgba(21,21,21,' + op.toFixed(3) + ')');
      set('--sf-2', 'rgba(28,28,28,' + Math.min(1, op * 1.11).toFixed(3) + ')');
      set('--ln-1', 'rgba(255,255,255,.12)');
    }

    const tx1 = theme.textColor || '#F4F4F5';
    const tx2 = theme.mutedColor || '#B9B9C2';
    set('--tx-1', tx1);
    set('--tx-2', tx2);
    set('--tx-3', mix(tx2, '#000000', 0.32));
    set('--glow', '0 0 22px ' + alpha(acc, 0.45));
    set('--glow-soft', '0 0 14px ' + alpha(acc, 0.3));

    // shadow strength: 0 flattens the design, 2 makes it float
    const sh = theme.shadow == null ? 1 : Math.max(0, Math.min(2, theme.shadow));
    set('--sh-sm', sh === 0 ? 'none' : '0 ' + (4 * sh).toFixed(0) + 'px ' + (12 * sh).toFixed(0) +
      'px rgba(0,0,0,' + (0.3 * sh).toFixed(2) + ')');
    set('--sh-lg', sh === 0 ? 'none' : '0 ' + (10 * sh).toFixed(0) + 'px ' + (30 * sh).toFixed(0) +
      'px rgba(0,0,0,' + Math.min(0.75, 0.35 * sh).toFixed(2) + ')');

    // fonts + global size: uiScale multiplies the root rem, so a single
    // slider rescales the ENTIRE screen and stays responsive
    const FONTS = {
      geist: "'Geist', sans-serif",
      sans: "'Segoe UI', 'Helvetica Neue', Arial, sans-serif",
      mono: "'Geist Mono', monospace",
      serif: "Georgia, 'Times New Roman', serif",
    };
    set('--font-ui', FONTS[theme.font] || FONTS.geist);
    const k = Math.max(0.6, Math.min(1.6, theme.uiScale || 1));
    set('--ui-k', k);

    // entrance animation for the widgets
    const ENTR = { rise: 'wg-in', fade: 'wg-fade', zoom: 'wg-zoom', none: 'none' };
    set('--wg-anim', ENTR[theme.entrance] || 'wg-in');
    set('--wg-dur', Math.round(700 / Math.max(0.3, Math.min(3, theme.entranceSpeed || 1))) + 'ms');
  }

  APX.theme = { apply: apply, mix: mix, alpha: alpha, inkFor: inkFor };
})();
