// APEX LOADING: YouTube playback, through the referrer bridge.
//
// The real loading screen is served from nui://, which sends no Referer
// header, and YouTube answers referrer-less embeds with "Error 153: video
// player configuration error". No player parameter fixes that: the referrer
// of a nui:// page cannot be forged. What DOES work is one level of
// indirection: an <iframe> pointing at a tiny bridge page (web/yt.html)
// that is served from a real http(s) origin. The bridge has a referrer, so
// the official IFrame API inside it plays, and this side drives it through
// postMessage (volume / mute / play / next track).
//
// Bridge origins, tried in order until one boots:
//   1. the page's own origin when it already is http(s): the creator
//      ui_page (https://cfx-nui-<res>/, proven to satisfy YouTube in game)
//      and any browser harness
//   2. https://cfx-nui-<res>/web/yt.html: the resource's NUI host, reached
//      from the nui:// loadscreen; same machine, no internet needed for the
//      page itself
//   3. the server's public URL (web_baseUrl → sv_yt.lua's HTTP handler),
//      delivered through the handover as APX.ytBridge
// If every base fails, callers get onFail() and fall back exactly like
// before: skip the track / paint the gradient. A YouTube hiccup is never
// allowed to leave an error card or a stuck screen behind.
(function () {
  window.APX = window.APX || {};

  const RE = /(?:youtube(?:-nocookie)?\.com\/(?:watch\?(?:[^#]*&)?v=|embed\/|shorts\/|live\/|v\/)|youtu\.be\/)([A-Za-z0-9_-]{6,})/i;

  function parseId(url) {
    const m = String(url || '').match(RE);
    return m ? m[1] : null;
  }
  function isYouTube(url) { return !!parseId(url); }

  // one message listener routes bridge events to every live player by key
  let seq = 0;
  const routes = {};
  let wired = false;
  function wire() {
    if (wired) return;
    wired = true;
    window.addEventListener('message', (e) => {
      const d = e.data;
      if (!d || d.apx !== 'yt' || !d.k) return;
      const r = routes[d.k];
      if (r) r(d);
    });
  }

  function bases() {
    const out = [];
    if (/^https?:\/\//i.test(location.origin || '')) {
      // this page already has a real origin: the bridge can live next door
      // (the in-game creator runs on https://cfx-nui-<res>/, which YouTube
      // provably accepts)
      out.push(new URL('yt.html', location.href).toString());
      if (APX.ytBridge) out.push(String(APX.ytBridge));
    } else {
      // the nui:// loadscreen. The server's public URL goes first: loading
      // an external https iframe from a loadscreen is a proven path (the
      // old Error-153 card rendered, so the frame itself loaded), while the
      // cfx-nui host is the backup for unlisted/offline servers.
      if (APX.ytBridge) out.push(String(APX.ytBridge));
      const res = (location.hostname || '').trim() || 'apex_loading';
      out.push('https://cfx-nui-' + res + '/web/yt.html');
    }
    return out;
  }

  // Creates a bridge player inside `host`.
  //   opts: { url|id, loop, muted, volume (0-1), onReady, onEnd, onFail }
  // Returns: { ready, setVolume, mute, unMute, play, pause, load, destroy }
  function create(host, opts) {
    opts = opts || {};
    const id = opts.id || parseId(opts.url);
    if (!id || !host) { if (opts.onFail) opts.onFail('bad url'); return null; }
    wire();

    const key = 'y' + (++seq) + '_' + Math.floor(Math.random() * 1e6);
    const list = bases();
    let attempt = -1;
    let iframe = null;
    let dead = false, failed = false, booted = false, started = false;
    let bootT = null, playT = null, loadT = null;

    const vol0 = Math.round(Math.max(0, Math.min(1, opts.volume == null ? 1 : opts.volume)) * 100);

    const send = (msg) => {
      if (!iframe || !iframe.contentWindow) return;
      msg.apx = 'yt-cmd';
      try { iframe.contentWindow.postMessage(msg, '*'); } catch (e) {}
    };
    const clearTimers = () => { clearTimeout(bootT); clearTimeout(playT); clearTimeout(loadT); };
    const say = (msg) => {
      if (APX.diag) APX.diag(msg);
      else { try { console.warn('[apex_loading] ' + msg); } catch (e) {} }
    };

    const giveUp = (why) => {
      if (dead || failed) return;
      failed = true;
      handle.ready = false;   // a caller holding this handle must recreate it
      clearTimers();
      if (iframe && iframe.parentNode) iframe.parentNode.removeChild(iframe);
      iframe = null;
      say('YouTube did not play (' + why + ') · origin=' + location.origin);
      if (opts.onFail) opts.onFail(why);
    };

    const nextBase = (why) => {
      if (dead || failed) return;
      if (attempt + 1 >= list.length) { giveUp(why); return; }
      attempt++;
      booted = false;
      started = false;
      clearTimers();
      if (iframe && iframe.parentNode) iframe.parentNode.removeChild(iframe);
      const base = list[attempt];
      const src = base + (base.indexOf('?') >= 0 ? '&' : '?') +
        'v=' + encodeURIComponent(id) + '&k=' + key +
        '&loop=' + (opts.loop === false ? '0' : '1') +
        '&muted=' + (opts.muted ? '1' : '0') + '&vol=' + vol0;
      iframe = document.createElement('iframe');
      iframe.className = 'yt-bridge';
      iframe.setAttribute('frameborder', '0');
      iframe.setAttribute('scrolling', 'no');
      iframe.setAttribute('allow', 'autoplay; encrypted-media');
      iframe.src = src;
      host.appendChild(iframe);
      if (attempt > 0) say('YouTube bridge retry ' + (attempt + 1) + '/' + list.length + ' → ' + base.split('?')[0]);
      // the bridge posts `boot` the instant its HTML runs; silence means the
      // frame itself never loaded from this base: move on quickly
      bootT = setTimeout(() => { if (!booted) nextBase('bridge did not load: ' + base.split('?')[0]); }, 5000);
      // it booted but the video never reached PLAYING: YouTube refused this
      // origin or the network is starving; the next base gets one chance
      playT = setTimeout(() => { if (!started) nextBase('never started'); }, 12000);
    };

    const handle = {
      kind: 'youtube',
      ready: false,
      setVolume(v) { send({ cmd: 'volume', v: Math.round(Math.max(0, Math.min(1, v)) * 100) }); },
      mute() { send({ cmd: 'mute' }); },
      unMute() { send({ cmd: 'unmute' }); },
      play() { send({ cmd: 'play' }); },
      pause() { send({ cmd: 'pause' }); },
      load(nextUrl) {
        const nid = parseId(nextUrl);
        if (!nid) return;
        send({ cmd: 'load', id: nid, loop: opts.loop !== false });
        // a playlist entry that never starts must not hang the queue: treat
        // it as ended so the caller advances, exactly like a broken file
        clearTimeout(loadT);
        loadT = setTimeout(() => {
          say('YouTube track never started, skipping: ' + nid);
          // a stall is a failure, not a finished track: the caller counts
          // these so a playlist of dead links cannot loop forever
          if (opts.onStall) opts.onStall();
          else if (opts.onEnd) opts.onEnd();
        }, 12000);
      },
      destroy() {
        dead = true;
        clearTimers();
        delete routes[key];
        if (iframe && iframe.parentNode) iframe.parentNode.removeChild(iframe);
        iframe = null;
      },
    };

    routes[key] = (d) => {
      if (dead || failed) return;
      if (d.ev === 'boot') { booted = true; clearTimeout(bootT); }
      else if (d.ev === 'ready') {
        handle.ready = true;
        if (opts.onReady) { try { opts.onReady(handle); } catch (e) {} }
      } else if (d.ev === 'playing' || d.ev === 'buffering') {
        started = true;
        clearTimeout(playT);
        clearTimeout(loadT);
      } else if (d.ev === 'ended') {
        clearTimeout(loadT);
        if (opts.onEnd) opts.onEnd();
      } else if (d.ev === 'error') {
        // real player errors (bad id, embedding disabled by the uploader…)
        // are about the VIDEO: no other bridge origin will fix those
        giveUp('player error ' + d.code);
      } else if (d.ev === 'slow') {
        say('YouTube API is slow to answer (' + list[attempt].split('?')[0] + ')');
      }
    };

    nextBase('start');
    return handle;
  }

  APX.yt = { isYouTube: isYouTube, parseId: parseId, create: create, bases: bases };
})();
