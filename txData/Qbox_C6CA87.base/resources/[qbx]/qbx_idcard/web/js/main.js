import { fetchNui } from './fetchNui.js';
import { Global } from '../../lang/global.js';
import config from './config.js';

const FALLBACK_MUGSHOT = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
let autoCloseTimer = null;

/**
 * Get element by id
 * @param id {string}
 **/
const getElementById = (id) => document.getElementById(id);

/**
 * Set visibility
 * @param visibility {string}
 **/
const setVisibility = (visibility) => {
  const el = getElementById('um-idcard');
  if (el) el.style.visibility = visibility;
};

/**
 * Set visibility of badge
 * @param badge {string|Object|null}
 **/
const setBadgeVisibility = (badge) => {
  const badgeElement = getElementById('badge');
  if (!badgeElement) return;
  if (!badge || badge === 'none') {
    badgeElement.style.display = 'none';
    return;
  }
  const badgeImg = getElementById('badgeimg');
  const badgeGrade = getElementById('badgegrade');
  if (badgeImg) badgeImg.src = `badges/${badge.img}.png`;
  if (badgeGrade) badgeGrade.textContent = badge.grade || '';
  badgeElement.style.display = 'flex';
};

const closeFunction = () => {
  if (autoCloseTimer) {
    clearTimeout(autoCloseTimer);
    autoCloseTimer = null;
  }
  const el = getElementById('um-idcard');
  if (el) {
    el.classList.remove('animate__animated', 'animate__fadeInLeft', 'animate__faster');
  }
  setVisibility('hidden');
  setBadgeVisibility('none');
  fetchNui('closeIdCard');
};

/**
 * Open id card
 * @param playerData {Object}
 **/
const openIdCard = (playerData) => {
  try {
    if (!playerData) return;
    const licenses = (config && config.licenses) || {};
    const license = licenses[playerData.cardtype] || {
      header: (playerData.cardtype || 'Identity Card').toUpperCase(),
      background: '#ebf7fd',
      backgroundImage: '',
    };

    const elements = {
      lastname: playerData.lastname || '',
      name: playerData.firstname || '',
      citizenid: playerData.citizenid || '',
      sign: `${playerData.firstname || ''} ${playerData.lastname || ''}`.trim(),
      dob: playerData.birthdate || '',
      sex: playerData.sex || '',
      nationality: playerData.nationality || '',
      cardtype: license.header || (playerData.cardtype || 'Identity Card').toUpperCase(),
    };

    Object.entries(elements).forEach(([key, value]) => {
      const el = getElementById(key);
      if (el) el.textContent = value;
    });

    const mugshotSrc = playerData.mugShot || FALLBACK_MUGSHOT;
    const mugshotEl = getElementById('mugshot');
    const smallMugshotEl = getElementById('smallmugshot');
    if (mugshotEl) {
      mugshotEl.onerror = () => { mugshotEl.src = FALLBACK_MUGSHOT; };
      mugshotEl.src = mugshotSrc;
    }
    if (smallMugshotEl) {
      smallMugshotEl.onerror = () => { smallMugshotEl.src = FALLBACK_MUGSHOT; };
      smallMugshotEl.src = mugshotSrc;
    }

    const cardEl = getElementById('um-idcard');
    if (cardEl) {
      cardEl.style.backgroundImage = license.backgroundImage ? `url(${license.backgroundImage})` : 'none';
      cardEl.style.backgroundColor = license.background || '#ebf7fd';
      cardEl.classList.add('animate__animated', 'animate__fadeInLeft', 'animate__faster');
    }

    setBadgeVisibility(playerData.badge);
    setVisibility('visible');
    autoClose();
  } catch (err) {
    console.error('[um-idcard] Error rendering ID card:', err);
    closeFunction();
  }
};

const autoClose = () => {
  if (autoCloseTimer) {
    clearTimeout(autoCloseTimer);
    autoCloseTimer = null;
  }
  if (!config || !config.idCardSettings || !config.idCardSettings.autoClose || !config.idCardSettings.autoClose.status) return;
  autoCloseTimer = setTimeout(closeFunction, config.idCardSettings.autoClose.time || 3000);
};

window.addEventListener('message', (event) => {
  const { type, playerData, configData } = event.data;
  if (type === 'playerData') {
    openIdCard(playerData);
  } else if (type === 'configData') {
    Object.assign(config, configData);
  }
});

window.addEventListener('load', () => {
  if (Global && typeof Global === 'object') {
    Object.entries(Global).forEach(([key, value]) => {
      const el = getElementById(key);
      if (el) el.textContent = value;
    });
  }
});

document.addEventListener('keydown', (e) => {
  const closeKey = (config && config.idCardSettings && config.idCardSettings.closeKey) || 'Backspace';
  if (e.key !== closeKey && e.key !== 'Escape') return;
  closeFunction();
});
