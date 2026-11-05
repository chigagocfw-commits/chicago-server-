// This script was leaked inside at TCHub Website so check that out https://tchub.st/dashboard

createjs.Sound.registerPlugins([
  createjs.WebAudioPlugin,
  createjs.HTMLAudioPlugin
]);

createjs.Sound.alternateExtensions = ["mp3", "wav", "ogg"];

const registeredSounds = new Set();
const loopSounds = {};
const loopTokens = {};
const loopVolumes = {};

let loopTokenSequence = 0;

function nextLoopToken(loopId) {
  loopTokenSequence += 1;
  loopTokens[loopId] = loopTokenSequence;
  return loopTokenSequence;
}

function registerSound(src, channels = 6) {
  if (!src || registeredSounds.has(src)) return;

  registeredSounds.add(src);

  createjs.Sound.registerSound({
    src: src,
    id: src,
    data: channels
  });
}

function playSound(src, volume = 1.0, channels = 6) {
  if (!src) return;

  registerSound(src, channels);

  if (createjs.Sound.loadComplete(src)) {
    createjs.Sound.play(src, {
      interrupt: createjs.Sound.INTERRUPT_ANY,
      volume: volume
    });
    return;
  }

  const onLoad = function (event) {
    if (event.id !== src) return;

    createjs.Sound.off("fileload", onLoad);

    createjs.Sound.play(src, {
      interrupt: createjs.Sound.INTERRUPT_ANY,
      volume: volume
    });
  };

  createjs.Sound.on("fileload", onLoad);
}

function startLoopSound(loopId, src, volume = 1.0, channels = 12) {
  if (!loopId || !src) return;

  stopLoopSound(loopId);

  const token = nextLoopToken(loopId);

  registerSound(src, channels);
  loopVolumes[loopId] = volume;

  const start = function () {
    if (loopTokens[loopId] !== token) return;

    const instance = createjs.Sound.play(src, {
      interrupt: createjs.Sound.INTERRUPT_NONE,
      volume: loopVolumes[loopId] !== undefined ? loopVolumes[loopId] : volume,
      loop: -1
    });

    if (!instance || instance.playState === createjs.Sound.PLAY_FAILED) {
      delete loopSounds[loopId];
      delete loopVolumes[loopId];
      delete loopTokens[loopId];
      return;
    }

    instance.on("complete", function () {
      if (loopSounds[loopId] === instance) {
        delete loopSounds[loopId];
        delete loopVolumes[loopId];
      }
    });

    instance.on("failed", function () {
      if (loopSounds[loopId] === instance) {
        delete loopSounds[loopId];
        delete loopVolumes[loopId];
      }
    });

    if (loopTokens[loopId] !== token) {
      instance.stop();
      return;
    }

    loopSounds[loopId] = instance;
  };

  if (createjs.Sound.loadComplete(src)) {
    start();
    return;
  }

  const onLoad = function (event) {
    if (event.id !== src) return;

    createjs.Sound.off("fileload", onLoad);
    start();
  };

  createjs.Sound.on("fileload", onLoad);
}

function setLoopVolume(loopId, volume) {
  if (!loopId) return;
  if (typeof volume !== "number") return;

  loopVolumes[loopId] = volume;

  const instance = loopSounds[loopId];
  if (instance) {
    instance.volume = volume;
  }
}

function stopLoopSound(loopId) {
  if (!loopId) return;

  nextLoopToken(loopId);

  const instance = loopSounds[loopId];

  if (instance) {
    try {
      instance.stop();
    } catch (err) {}

    delete loopSounds[loopId];
  }

  delete loopVolumes[loopId];
  delete loopTokens[loopId];
}

function stopAllLoopSounds() {
  const ids = new Set(
    Object.keys(loopTokens).concat(Object.keys(loopSounds))
  );

  ids.forEach(function (loopId) {
    stopLoopSound(loopId);
  });

  try {
    createjs.Sound.stop();
  } catch (err) {}
}

window.addEventListener("message", function (event) {
  const item = event.data || {};

  if (item.message === "rtx_smoking:playSound") {
    playSound(item.src, item.volume || 1.0, item.channels || 6);
  }

  if (item.message === "rtx_smoking:startLoopSound") {
    startLoopSound(
      item.loopId,
      item.src,
      item.volume || 1.0,
      item.channels || 12
    );
  }

  if (item.message === "rtx_smoking:setLoopVolume") {
    setLoopVolume(item.loopId, item.volume);
  }

  if (item.message === "rtx_smoking:stopLoopSound") {
    stopLoopSound(item.loopId);
  }

  if (item.message === "rtx_smoking:stopAllLoopSounds") {
    stopAllLoopSounds();
  }
});

window.addEventListener("beforeunload", function () {
  stopAllLoopSounds();
});
