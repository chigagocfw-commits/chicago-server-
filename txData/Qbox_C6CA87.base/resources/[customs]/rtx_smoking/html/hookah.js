// This script was leaked inside at TCHub Website so check that out https://tchub.st/dashboard

var resourceName = 'rtx_smoking';

let flavors = {};
let previewCoalTimer = null;

let locale = {};

function t(key, fallback) {
  return locale[key] || fallback;
}

function stateText(stateValue) {
  return t(`state_${stateValue}`, textCap(stateValue));
}

const defaults = () => ({
  visible: false,
  water: { state: 'empty', level: 0 },
  tobacco: { state: 'empty', amount: 0, flavor: '' },
  coal: { state: 'missing', progress: 0, durability: 0 },
  hoses: { connected: 0, max: 1 },
  ready: false,
  canRemove: true,
  isAdmin: false,
  static: false,
  accent: '#ff66ff'
});

let state = defaults();

function formatType(type) {
  if (!type) return 'Unknown';
  return type.charAt(0).toUpperCase() + type.slice(1);
}

function hexToRgb(hex) {
  const s = hex.replace('#', '');

  return {
    r: parseInt(s.substring(0, 2), 16),
    g: parseInt(s.substring(2, 4), 16),
    b: parseInt(s.substring(4, 6), 16)
  };
}

function rgba(hex, a) {
  const c = hexToRgb(hex);
  return `rgba(${c.r}, ${c.g}, ${c.b}, ${a})`;
}

function lighten(hex, amt = 0.12) {
  const s = hex.replace('#', '');
  if (s.length !== 6) return hex;

  const to = i =>
    Math.min(255, Math.round(parseInt(s.substring(i, i + 2), 16) * (1 + amt)));

  const h = n => n.toString(16).padStart(2, '0');

  return `#${h(to(0))}${h(to(2))}${h(to(4))}`;
}

function setTheme(accentHex) {
  const acc2 = lighten(accentHex, 0.12);
  const root = document.documentElement.style;

  root.setProperty('--accent', accentHex);
  root.setProperty('--accent-2', acc2);
  root.setProperty('--accent-a10', rgba(accentHex, 0.10));
  root.setProperty('--accent-a20', rgba(accentHex, 0.20));
  root.setProperty('--accent-glow', rgba(accentHex, 0.18));

  state.accent = accentHex;

  try {
    localStorage.setItem('housing_theme', accentHex);
  } catch (e) {}
}

function postNui(action, data = {}) {

  fetch(`https://${resourceName}/${action}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8'
    },
    body: JSON.stringify(data)
  }).catch(() => {});
}

function textCap(v) {
  return String(v || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, m => m.toUpperCase());
}

function badgeTone(type) {
  if (['good', 'prepared', 'ready', 'placed'].includes(type)) return 'ok';
  if (['low', 'filled', 'heating'].includes(type)) return 'warn';
  if (['empty', 'missing'].includes(type)) return 'bad';

  return 'neutral';
}

function isReady(data) {
  return (
    data.water.state === 'good' &&
    data.tobacco.state === 'prepared' &&
    data.coal.state === 'placed'
  );
}

function setBadge(el, text, tone) {
  if (!el) return;

  el.className = `hookah-mini-badge ${tone}`;
  el.textContent = text;
}

function cleanHookahState() {
  if (previewCoalTimer) {
    clearInterval(previewCoalTimer);
    previewCoalTimer = null;
  }

  const accent = state.accent;

  state = defaults();
  state.accent = accent;

  updateUI({});
}

function updateBowlButton() {
  const bowlBtn = document.getElementById('btn-prepare-bowl');
  if (!bowlBtn) return;

  if (state.tobacco.state === 'empty') {
    bowlBtn.innerHTML = '<i class="fa-solid fa-leaf"></i> Add flavor';
  } else if (state.tobacco.state === 'filled') {
    bowlBtn.innerHTML = '<i class="fa-solid fa-bowl-food"></i> Prepare bowl';
  } else {
    bowlBtn.innerHTML = '<i class="fa-solid fa-rotate"></i> Change flavor';
  }
}

function updateUI(data = {}) {
  if (data.water) state.water = { ...state.water, ...data.water };
  if (data.tobacco) state.tobacco = { ...state.tobacco, ...data.tobacco };
  if (data.coal) state.coal = { ...state.coal, ...data.coal };
  if (data.hoses) state.hoses = { ...state.hoses, ...data.hoses };

  if (typeof data.visible === 'boolean') {
    state.visible = data.visible;
  }

  if (data.accent) {
    setTheme(data.accent);
  }

  state.ready = isReady(state);

  const hookahUi = document.getElementById('hookah-ui');

  if (hookahUi) {
    if (state.visible) {
      hookahUi.classList.add('show');
    } else {
      hookahUi.classList.remove('show');
    }
  }

  const waterLevel = Math.max(0, Math.min(100, Number(state.water.level) || 0));

  document.getElementById('water-sub').textContent =
    state.water.state === 'empty'
      ? 'There is no water in the base.'
      : state.water.state === 'low'
        ? 'The water level is too low for a good hit.'
        : 'The water level is good.';

		   
setBadge(document.getElementById('water-badge'), stateText(state.water.state), badgeTone(state.water.state));
							   
								
	

  document.getElementById('water-value').textContent = `${waterLevel}%`;
  document.getElementById('water-bar').style.width = `${waterLevel}%`;

  const tobaccoAmount = Math.max(0, Math.min(100, Number(state.tobacco.amount) || 0));

  document.getElementById('tobacco-sub').textContent =
    state.tobacco.state === 'empty'
      ? 'Choose a flavor for the bowl.'
      : state.tobacco.state === 'filled'
        ? 'Flavor selected. Prepare the bowl now.'
        : 'The bowl is prepared and ready.';

		   
setBadge(document.getElementById('tobacco-badge'), stateText(state.tobacco.state), badgeTone(state.tobacco.state));
								 
								  
	

  document.getElementById('tobacco-value').textContent = `${tobaccoAmount}%`;
  document.getElementById('tobacco-bar').style.width = `${tobaccoAmount}%`;

  const flavorInline = document.getElementById('tobacco-flavor-inline');

  if (flavorInline) {
    if (state.tobacco.flavor) {
      flavorInline.classList.remove('hide-ui');
      flavorInline.textContent = state.tobacco.flavor;
    } else {
      flavorInline.classList.add('hide-ui');
      flavorInline.textContent = '';
    }
  }

  document.getElementById('coal-sub').textContent =
    state.coal.state === 'missing'
      ? 'Light the coal first.'
      : state.coal.state === 'heating'
        ? 'The coal is heating. Wait until it is ready.'
        : state.coal.state === 'ready'
          ? 'The coal is ready. You can place it now.'
          : 'The coal is on the bowl and slowly burning out.';

		   
										  
							  
							   
	

setBadge(document.getElementById('coal-badge'), stateText(state.coal.state), badgeTone(state.coal.state));
  const coalWrap = document.getElementById('coal-progress-wrap');
  const coalLabel = document.getElementById('coal-progress-label');
  const coalValue = document.getElementById('coal-value');
  const coalBar = document.getElementById('coal-bar');

  if (state.coal.state === 'heating') {
    const progress = Math.max(0, Math.min(100, Number(state.coal.progress) || 0));

    coalWrap.classList.remove('hide-ui');
    coalLabel.textContent = 'Heating';
    coalValue.textContent = `${progress}%`;
    coalBar.style.width = `${progress}%`;
  } else if (state.coal.state === 'placed') {
    const durability = Math.max(0, Math.min(100, Number(state.coal.durability) || 0));

    coalWrap.classList.remove('hide-ui');
    coalLabel.textContent = 'Durability';
    coalValue.textContent = `${durability}%`;
    coalBar.style.width = `${durability}%`;
  } else {
    coalWrap.classList.add('hide-ui');
    coalLabel.textContent = 'Heating';
    coalValue.textContent = '0%';
    coalBar.style.width = '0%';
  }

  const hoseText = `${state.hoses.connected} / ${state.hoses.max}`;

  setBadge(document.getElementById('hose-badge'), hoseText, 'neutral');

  document.getElementById('hose-sub').textContent =
    state.hoses.connected > 0
      ? 'At least one hose is connected.'
      : 'No hose is connected yet.';

  const readyChip = document.getElementById('status-ready-chip');

  if (readyChip) {
    readyChip.className = `hookah-status-chip ${state.ready ? 'ready' : ''}`;
	readyChip.innerHTML = `
	  <i class="fa-solid fa-circle-dot"></i>
	  <span>${state.ready ? t('ready', 'Ready') : t('preparing', 'Preparing')}</span>
	`;
  }

  document.getElementById('btn-light-coal').disabled =
    ['heating', 'ready', 'placed'].includes(state.coal.state);

  document.getElementById('btn-place-coal').disabled =
    state.coal.state !== 'ready';

  updateRemoveButton();
  updateBowlButton();
}

function updateRemoveButton() {
  const removeBtn = document.getElementById('btn-remove');
  if (!removeBtn) return;

  const blocked = state.canRemove === false;

  removeBtn.disabled = blocked;
  removeBtn.classList.toggle('is-disabled', blocked);

  if (blocked) {
    removeBtn.title = t('nohookahpermission', 'You do not have permission to remove this hookah.');
  } else if (state.isAdmin && state.hoses.connected > 0) {
    removeBtn.title = t('adminforceremove', 'Force remove (connected hoses will be disconnected).');
  } else {
    removeBtn.title = '';
  }

  const label = state.isAdmin
    ? t('forceremovehookah', 'Force remove')
    : t('removehookah', 'Remove hookah');

  removeBtn.innerHTML = `<i class="fa-solid fa-trash"></i> ${label}`;
}

function openFlavorModal() {
  renderFlavors();

  const modal = document.getElementById('flavor-modal');
  if (modal) modal.classList.add('show');
}

function closeFlavorModal() {
  const modal = document.getElementById('flavor-modal');
  if (modal) modal.classList.remove('show');
}

function renderFlavors() {
  const wrap = document.getElementById('flavor-grid');
  if (!wrap) return;

  const entries = Object.entries(flavors || {});

  wrap.innerHTML = entries.map(([flavorKey, flavor]) => `
    <button
      class="hookah-flavor-btn ${state.tobacco.flavor === (flavor.label || flavorKey) ? 'selected' : ''}"
      data-flavor-key="${flavorKey}"
    >
      <div class="hookah-flavor-badge">
        <i class="fa-solid fa-leaf"></i>
      </div>

      <div style="flex:1;">
        <div class="hookah-flavor-name">${flavor.label || flavorKey}</div>
        <div class="hookah-flavor-type type-${flavor.type || 'default'}">
          ${formatType(flavor.type)}
        </div>
      </div>
    </button>
  `).join('');
}

function startPreviewCoalHeating() {
  if (previewCoalTimer) {
    clearInterval(previewCoalTimer);
  }

  updateUI({
    coal: {
      state: 'heating',
      progress: 0
    }
  });

  let progress = 0;

  previewCoalTimer = setInterval(() => {
    progress += 20;

    if (progress >= 100) {
      clearInterval(previewCoalTimer);
      previewCoalTimer = null;

      updateUI({
        coal: {
          state: 'ready',
          progress: 100
        }
      });

      return;
    }

    updateUI({
      coal: {
        state: 'heating',
        progress
      }
    });
  }, 220);
}


document.addEventListener('DOMContentLoaded', () => {
  const closeFlavorBtn = document.getElementById('close-flavor-modal');
  const flavorModal = document.getElementById('flavor-modal');
  const flavorGrid = document.getElementById('flavor-grid');

  if (closeFlavorBtn) {
    closeFlavorBtn.addEventListener('click', closeFlavorModal);
  }

  if (flavorModal) {
    flavorModal.addEventListener('click', e => {
      if (e.target.id === 'flavor-modal') {
        closeFlavorModal();
      }
    });
  }

  if (flavorGrid) {
    flavorGrid.addEventListener('click', e => {
      const btn = e.target.closest('[data-flavor-key]');
      if (!btn) return;

      const flavorKey = btn.getAttribute('data-flavor-key');
      const flavorData = flavors[flavorKey];

      closeFlavorModal();

      postNui('hookahSelectFlavor', {
        flavorKey: flavorKey,
        itemname: flavorData?.itemname || flavorKey
      });
    });
  }

  const fillWaterBtn = document.getElementById('btn-fill-water');

  if (fillWaterBtn) {
    fillWaterBtn.addEventListener('click', () => {

      postNui('hookahFillWater');
    });
  }

  const prepareBowlBtn = document.getElementById('btn-prepare-bowl');

  if (prepareBowlBtn) {
    prepareBowlBtn.addEventListener('click', () => {
      if (state.tobacco.state === 'empty') {
        openFlavorModal();
        return;
      }

      if (state.tobacco.state === 'filled') {
        postNui('hookahPrepareOrChangeBowl');
        return;
      }

      if (state.tobacco.state === 'prepared') {
        openFlavorModal();
      }
    });
  }

  const lightCoalBtn = document.getElementById('btn-light-coal');

  if (lightCoalBtn) {
    lightCoalBtn.addEventListener('click', () => {

      postNui('hookahLightCoal');
    });
  }

  const placeCoalBtn = document.getElementById('btn-place-coal');

  if (placeCoalBtn) {
    placeCoalBtn.addEventListener('click', () => {

      postNui('hookahPlaceCoal');
    });
  }

  const connectHoseBtn = document.getElementById('btn-connect-hose');

  if (connectHoseBtn) {
    connectHoseBtn.addEventListener('click', () => {
      postNui('hookahConnectHose');
    });
  }

  const cleanBtn = document.getElementById('btn-clean');

  if (cleanBtn) {
    cleanBtn.addEventListener('click', () => {

      postNui('hookahClean');
    });
  }

  const removeBtn = document.getElementById('btn-remove');

  if (removeBtn) {
    removeBtn.addEventListener('click', () => {
      if (state.canRemove === false) return;

      postNui('hookahRemove');
    });
  }

  updateUI({});
});

window.addEventListener('message', event => {
  const item = event.data || {};

  if (item.message === 'hookah:toggle') {
    updateUI({
      visible: !!item.visible
    });
  }

	if (item.message === 'hookah:setLocale') {
	  locale = item.locale || {};
	  updateUI({});
	}
  if (item.message === 'hookah:update') {
    updateUI(item.data || {});
  }

  if (item.message === 'updateinterfacedata' && item.interfacecolordata) {
    setTheme(item.interfacecolordata);
  }

  if (item.message === 'hookah:setFlavors') {
    flavors = item.flavors || {};
  }

  if (item.message === 'hookah:setPermissions') {
    state.canRemove = item.canRemove !== false;
    state.isAdmin = item.isAdmin === true;
    state.static = item.static === true;

    updateUI({});
  }

  if (item.message === 'infonotifyshow') {
    const notifyText = document.getElementsByClassName('infonotifytext')[0];

    if (notifyText) {
      notifyText.innerHTML = item.infonotifytext;
    }

    $('#infonotifyshow').show();
  }

  if (item.message === 'hidenotify') {
    $('#infonotifyshow').hide();
  }
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    postNui('hookahQuit');
  }
});