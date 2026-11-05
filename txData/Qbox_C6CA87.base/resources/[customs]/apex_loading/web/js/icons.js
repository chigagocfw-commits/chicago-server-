// APEX HUD (stroke icon set (24×24, currentColor). No external deps.
(function () {
  const P = {
    // vitals
    heart: '<path d="M19.5 12.6 12 20l-7.5-7.4A5 5 0 1 1 12 6.3a5 5 0 1 1 7.5 6.3Z"/>',
    shield: '<path d="M12 3l7 3v5c0 4.6-3 8.2-7 10-4-1.8-7-5.4-7-10V6z"/>',
    food: '<path d="M4 9h16"/><path d="M5 9a7 7 0 0 1 14 0"/><path d="M4 13h16"/><path d="M6 17h12a2 2 0 0 0 2-2v-2H4v2a2 2 0 0 0 2 2Z"/>',
    droplet: '<path d="M12 3s6 6.3 6 10.5a6 6 0 0 1-12 0C6 9.3 12 3 12 3Z"/>',
    bolt: '<path d="M13 2 4 14h6l-1 8 9-12h-6z"/>',
    lungs: '<path d="M12 4v6"/><path d="M9.5 10c-1.5-2-4-1.6-5.2.6C3 13 3 16.5 3 18.2c0 1.3 1.1 2 2.3 1.7l2.4-.7c1.1-.3 1.8-1.2 1.8-2.3z"/><path d="M14.5 10c1.5-2 4-1.6 5.2.6C21 13 21 16.5 21 18.2c0 1.3-1.1 2-2.3 1.7l-2.4-.7a2.4 2.4 0 0 1-1.8-2.3z"/>',
    brain: '<path d="M9.5 3A2.5 2.5 0 0 0 7 5.5v.6A3 3 0 0 0 5 9a3 3 0 0 0-1 5.2 3 3 0 0 0 2 4.9A2.9 2.9 0 0 0 9 21c1.7 0 3-1.3 3-3V5.5A2.5 2.5 0 0 0 9.5 3Z"/><path d="M14.5 3A2.5 2.5 0 0 1 17 5.5v.6A3 3 0 0 1 19 9a3 3 0 0 1 1 5.2 3 3 0 0 1-2 4.9A2.9 2.9 0 0 1 15 21c-1.7 0-3-1.3-3-3"/>',
    // identity / info
    mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/>',
    micOff: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/><path d="M4 4l16 16"/>',
    radio: '<rect x="3" y="9" width="18" height="11" rx="2"/><path d="m8 9 8-5"/><circle cx="8.5" cy="14.5" r="2.5"/><path d="M17 12v.01M17 15v.01M14 13.5v.01"/>',
    wallet: '<path d="M20 8V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h13a2 2 0 0 0 2-2v-2"/><path d="M22 10h-7a2 2 0 0 0 0 4h7z"/>',
    bank: '<path d="M3 9.5 12 4l9 5.5"/><path d="M5 10v7M9.5 10v7M14.5 10v7M19 10v7"/><path d="M3 20h18"/>',
    briefcase: '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><path d="M3 12h18"/>',
    badge: '<rect x="4" y="4" width="16" height="16" rx="2"/><circle cx="12" cy="10" r="2.6"/><path d="M7.5 19c.6-2.6 2.4-4 4.5-4s3.9 1.4 4.5 4"/>',
    users: '<circle cx="9" cy="8" r="3.2"/><path d="M3.5 20c.7-3.3 2.9-5 5.5-5s4.8 1.7 5.5 5"/><path d="M16 5.6a3.2 3.2 0 0 1 0 5"/><path d="M17.5 15.3c1.6.7 2.6 2.2 3 4.7"/>',
    clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
    // weapons / vehicle
    gun: '<path d="M3 8h17v4h-2.5l-.8 3.2a2 2 0 0 1-2 1.5h-1.9a1.5 1.5 0 0 1-1.5-1.8l.6-2.9H8.5L7 15H3.8L5 10.5 3 10z"/><path d="M20 8V6.5"/>',
    crosshair: '<circle cx="12" cy="12" r="7.5"/><path d="M12 2.5v4M12 17.5v4M2.5 12h4M17.5 12h4"/>',
    belt: '<path d="M5 4c6 2.5 9 7 10.5 16"/><path d="M4.2 8.7C8 10.5 10.6 13.4 12.3 18"/><rect x="12.5" y="13.5" width="6.5" height="4.5" rx="1.2"/>',
    engine: '<path d="M7 6h6v3h3l2 2h3v6h-3l-2 2h-8l-2-2H4v-3H2v-4h2V8h3z"/><path d="M10 3v3"/>',
    fuel: '<path d="M4 20V6a2 2 0 0 1 2-2h5a2 2 0 0 1 2 2v14"/><path d="M2.5 20h12"/><path d="M13 9h2.5a1.5 1.5 0 0 1 1.5 1.5v6a1.5 1.5 0 1 0 3 0V9.8a2 2 0 0 0-.6-1.4L17 5.5"/><path d="M6 8h5"/>',
    gauge: '<path d="M4.5 18a8.5 8.5 0 1 1 15 0"/><path d="m12 14 3.5-4.5"/><circle cx="12" cy="14" r="1.6"/>',
    beamLow: '<path d="M10 7c5 0 8 2 8 5s-3 5-8 5c-1.8 0-3-2.2-3-5s1.2-5 3-5Z"/><path d="M2.5 9.5 5 10M2.5 12.5H5M2.5 15.5 5 15"/>',
    beamHigh: '<path d="M10 7c5 0 8 2 8 5s-3 5-8 5c-1.8 0-3-2.2-3-5s1.2-5 3-5Z"/><path d="M2 9h3.5M2 12h3.5M2 15h3.5"/>',
    arrowL: '<path d="M15 5.5 8.5 12l6.5 6.5"/>',
    arrowR: '<path d="m9 5.5 6.5 6.5L9 18.5"/>',
    hazard: '<path d="M12 3.5 21.5 20h-19z"/><path d="M12 10v4M12 17.2v.01"/>',
    lock: '<rect x="5" y="10.5" width="14" height="9.5" rx="2"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
    unlock: '<rect x="5" y="10.5" width="14" height="9.5" rx="2"/><path d="M8 10.5V8a4 4 0 0 1 7.8-1.2"/>',
    door: '<path d="M4 20V6a2 2 0 0 1 2-2h9l5 5v11"/><path d="M2.5 20h19"/><path d="M14.5 12.5h.01"/>',
    window: '<rect x="4" y="5" width="16" height="14" rx="2"/><path d="M4 12h16M12 5v7"/>',
    seat: '<path d="M7 4c1.8 0 2.6 1 2.8 2.6l.7 5.4H16a3 3 0 0 1 3 3V20h-2.5v-3.5H9.3A3.3 3.3 0 0 1 6 13.6L5.3 7A2.6 2.6 0 0 1 7 4Z"/>',
    neon: '<path d="M4 5h16"/><path d="M6 5v4a6 6 0 0 0 12 0V5"/><path d="M8 17l-1.5 3.5M16 17l1.5 3.5M12 17.5V21"/>',
    power: '<path d="M12 3v8"/><path d="M6.6 6.6a8 8 0 1 0 10.8 0"/>',
    bell: '<path d="M6 9a6 6 0 1 1 12 0c0 4 1.5 5.5 2 6H4c.5-.5 2-2 2-6Z"/><path d="M10 19a2.2 2.2 0 0 0 4 0"/>',
    heartbeat: '<path d="M3.5 12h4l2-4.5 3 9 2.5-6 1.5 1.5h4"/>',
    plane: '<path d="M10.5 13.5 3 11l1.5-2 6.5 1L16.5 4 19 5l-3.5 6.5 4 2.5-2 2-4.5-1.5-2 3.5H9z"/>',
    anchorIc: '<circle cx="12" cy="5.5" r="2.5"/><path d="M12 8v12"/><path d="M4.5 13a7.5 7.5 0 0 0 15 0"/><path d="M9 13H4.5M19.5 13H15"/>',
    train: '<rect x="5" y="3.5" width="14" height="13" rx="3"/><path d="M5 10.5h14M12 3.5v7"/><path d="m8 20-1.5 2M16 20l1.5 2M7 16.5h.01M17 16.5h.01"/>',
    ship: '<path d="M4 15.5 3 12l9-3 9 3-1 3.5"/><path d="M12 9V4.5h4L13.5 7"/><path d="M3.5 18.5c1.5 1.2 3 1.2 4.5 0s3-1.2 4 0 3 1.2 4.5 0 3-1.2 4 0"/>',
    bike: '<circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M9.5 16 12 9h4l2 7"/><path d="m12 9-2-3H7.5"/>',
    // creator chrome
    move: '<path d="M12 2.5v19M2.5 12h19"/><path d="m9 5 3-3 3 3M9 19l3 3 3-3M5 9 2 12l3 3M19 9l3 3-3 3"/>',
    palette: '<path d="M12 3a9 9 0 1 0 0 18h1.8a2 2 0 0 0 1.5-3.3 2 2 0 0 1 1.5-3.2H19a3 3 0 0 0 3-3C22 6.5 17.5 3 12 3Z"/><path d="M7.5 11h.01M10.5 7h.01M15 7h.01"/>',
    sliders: '<path d="M5 4v6M5 14v6M12 4v2M12 10v10M19 4v10M19 18v2"/><path d="M3 10h4M10 6h4M17 14h4"/>',
    layers: '<path d="m12 3 9 5-9 5-9-5z"/><path d="m4.5 12.8 7.5 4.2 7.5-4.2"/><path d="m4.5 16.8 7.5 4.2 7.5-4.2"/>',
    settings: '<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.15-1.4l2.1-1.6-2-3.5-2.5 1a7 7 0 0 0-2.4-1.4L13.6 2.5h-3.2l-.45 2.6a7 7 0 0 0-2.4 1.4l-2.5-1-2 3.5 2.1 1.6a7 7 0 0 0 0 2.8l-2.1 1.6 2 3.5 2.5-1a7 7 0 0 0 2.4 1.4l.45 2.6h3.2l.45-2.6a7 7 0 0 0 2.4-1.4l2.5 1 2-3.5-2.1-1.6c.1-.45.15-.92.15-1.4Z"/>',
    sparkle: '<path d="M12 3.5 14 9l5.5 2L14 13l-2 5.5L10 13l-5.5-2L10 9z"/><path d="M19 16.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z"/>',
    save: '<path d="M5 3h11l3.5 3.5V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z"/><path d="M7.5 3v5h8V3"/><rect x="7.5" y="13" width="9" height="8"/>',
    undo: '<path d="M8 6 3.5 10.5 8 15"/><path d="M3.5 10.5H15a5.5 5.5 0 0 1 0 11h-3"/>',
    redo: '<path d="m16 6 4.5 4.5L16 15"/><path d="M20.5 10.5H9a5.5 5.5 0 0 0 0 11h3"/>',
    close: '<path d="m5.5 5.5 13 13M18.5 5.5l-13 13"/>',
    check: '<path d="m4.5 12.5 5 5 10-11"/>',
    chevD: '<path d="m6 9.5 6 6 6-6"/>',
    reset: '<path d="M3.5 12a8.5 8.5 0 1 0 2.5-6L3.5 8.5"/><path d="M3.5 3.5v5h5"/>',
    eye: '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z"/><circle cx="12" cy="12" r="3"/>',
    eyeOff: '<path d="M4 4l16 16"/><path d="M9.9 5.9A9.6 9.6 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a17 17 0 0 1-3.2 4M6.1 7.4A16 16 0 0 0 2.5 12s3.5 6.5 9.5 6.5c1.4 0 2.7-.35 3.9-.9"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
    grid: '<rect x="3.5" y="3.5" width="7" height="7" rx="1"/><rect x="13.5" y="3.5" width="7" height="7" rx="1"/><rect x="3.5" y="13.5" width="7" height="7" rx="1"/><rect x="13.5" y="13.5" width="7" height="7" rx="1"/>',
    code: '<path d="m8.5 8-4.5 4 4.5 4M15.5 8l4.5 4-4.5 4"/>',
    copy: '<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    map: '<path d="m9 4.5-5 2v13l5-2 6 2 5-2v-13l-5 2z"/><path d="M9 4.5v13M15 6.5v13"/>',
    compassIc: '<circle cx="12" cy="12" r="8.5"/><path d="m15.5 8.5-2 5-5 2 2-5z"/>',
    pin: '<path d="M12 21s-7-6-7-11a7 7 0 0 1 14 0c0 5-7 11-7 11Z"/><circle cx="12" cy="10" r="2.5"/>',
    image: '<rect x="3.5" y="4.5" width="17" height="15" rx="2"/><circle cx="9" cy="10" r="1.8"/><path d="m5 18 5-5 3 3 3.5-3.5L20 16"/>',
    limit: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="5.5"/>',
    speedo: '<path d="M4.5 18a8.5 8.5 0 1 1 15 0"/><path d="m12 14 4-5"/><circle cx="12" cy="14" r="1.6"/><path d="M5.5 14H4M20 14h-1.5M12 6.5V5"/>',
  };

  window.APX = window.APX || {};
  APX.icon = function (name, cls) {
    const body = P[name] || P.sparkle;
    return '<svg class="ic' + (cls ? ' ' + cls : '') + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + body + '</svg>';
  };
  APX.iconPath = function (raw) {
    // custom stat icons may pass raw SVG path data from the config
    if (P[raw]) return APX.icon(raw);
    return '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="' + raw + '"/></svg>';
  };
  APX.icons = P;
})();

// APEX LOADING) extra icons + aliases on top of the shared set
(function () {
  const P = APX.icons;
  P.music = '<path d="M9 18.5V6l11-2v12.5"/><circle cx="6.5" cy="18.5" r="2.5"/><circle cx="17.5" cy="16.5" r="2.5"/>';
  P.globe = '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17"/><path d="M12 3.5c2.6 2.4 3.9 5.2 3.9 8.5s-1.3 6.1-3.9 8.5c-2.6-2.4-3.9-5.2-3.9-8.5s1.3-6.1 3.9-8.5Z"/>';
  P.user = '<circle cx="12" cy="8" r="3.4"/><path d="M5.5 20c.8-3.6 3.2-5.5 6.5-5.5s5.7 1.9 6.5 5.5"/>';
  P.discord = '<path d="M8.5 5.5C10.8 5 13.2 5 15.5 5.5l1-1.5c1.6.3 3.1.8 4.5 1.6 1.6 3.7 2.1 7.4 1.5 11.2-1.6 1.2-3.3 2-5.2 2.5l-1-1.9c-2.2.6-4.4.6-6.6 0l-1 1.9c-1.9-.5-3.6-1.3-5.2-2.5C2.9 13 3.4 9.3 5 5.6 6.4 4.8 7.9 4.3 9.5 4z"/><circle cx="9" cy="12" r="1.3"/><circle cx="15" cy="12" r="1.3"/>';
  P.wand = '<path d="m5 19 9.5-9.5"/><path d="m14.5 4 1 2 2 1-2 1-1 2-1-2-2-1 2-1z"/><path d="M19 12v.01M17 18v.01M8 5v.01"/>';
  P.sparkles = P.sparkle;
  P.x = P.close;
})();
