(function () {
  var minigameFrame = null;
  var minigameReady = false;
  var queuedMessages = [];

  function getResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'lunar_heistcontracts';
  }

  async function callNui(name, payload) {
    var response = await fetch('https://' + getResourceName() + '/' + name, {
      method: 'post',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: JSON.stringify(payload == null ? {} : payload)
    });

    return response.json();
  }

  function ensureMinigameFrame() {
    if (minigameFrame) {
      return minigameFrame;
    }

    minigameFrame = document.createElement('iframe');
    minigameFrame.src = './minigames/index.html';
    minigameFrame.style.position = 'fixed';
    minigameFrame.style.inset = '0';
    minigameFrame.style.width = '100vw';
    minigameFrame.style.height = '100vh';
    minigameFrame.style.border = '0';
    minigameFrame.style.background = 'transparent';
    minigameFrame.style.display = 'none';
    minigameFrame.style.zIndex = '2147483647';
    minigameFrame.setAttribute('title', 'Lunar Minigames');

    minigameFrame.addEventListener('load', function () {
      minigameReady = true;

      while (queuedMessages.length > 0) {
        minigameFrame.contentWindow.postMessage(queuedMessages.shift(), '*');
      }
    });

    document.body.appendChild(minigameFrame);

    return minigameFrame;
  }

  function openMinigame(data) {
    var frame = ensureMinigameFrame();
    frame.style.display = 'block';

    if (minigameReady && frame.contentWindow) {
      frame.contentWindow.postMessage(data, '*');
    } else {
      queuedMessages.push(data);
    }

    setTimeout(function () {
      if (frame.contentWindow) {
        frame.contentWindow.focus();
      }
    }, 50);
  }

  function closeMinigame() {
    if (minigameFrame) {
      minigameFrame.style.display = 'none';
    }
  }

  window.addEventListener('message', function (event) {
    var data = event.data;

    if (!data || typeof data !== 'object') {
      return;
    }

    if (data.action === 'openMinigame') {
      openMinigame(data);
    } else if (data.action === 'closeInternalMinigame') {
      closeMinigame();
    } else if (data.action === 'minigameNuiCallback') {
      var sourceWindow = event.source || (minigameFrame && minigameFrame.contentWindow);
      if (!sourceWindow) {
        return;
      }

      callNui(data.name, data.payload).then(function (response) {
        sourceWindow.postMessage({
          action: 'minigameNuiResponse',
          requestId: data.requestId,
          data: response
        }, '*');
      }).catch(function (error) {
        sourceWindow.postMessage({
          action: 'minigameNuiResponse',
          requestId: data.requestId,
          error: error && error.message ? error.message : String(error)
        }, '*');
      });
    }
  });
})();
