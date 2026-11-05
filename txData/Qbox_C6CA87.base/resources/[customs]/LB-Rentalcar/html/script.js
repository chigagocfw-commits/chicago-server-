var AudioCtx = null;
function initAudio() { if (!AudioCtx) AudioCtx = new (window.AudioContext || window.webkitAudioContext)(); }

function playClick(freq, vol) {
    try {
        initAudio();
        var o = AudioCtx.createOscillator();
        var g = AudioCtx.createGain();
        o.type = 'sine';
        o.frequency.value = freq || 600;
        g.gain.setValueAtTime((vol || 0.06), AudioCtx.currentTime);
        g.gain.exponentialRampToValueAtTime(0.0001, AudioCtx.currentTime + 0.08);
        o.connect(g);
        g.connect(AudioCtx.destination);
        o.start(AudioCtx.currentTime);
        o.stop(AudioCtx.currentTime + 0.08);
    } catch (e) {}
}

document.addEventListener('click', function (e) {
    var tag = (e.target.tagName || '').toLowerCase();
    if (tag === 'button' || tag === 'span' || tag === 'input' || e.target.closest('.vc') || e.target.closest('.cx') || e.target.closest('.vr') || e.target.closest('.vc-badge') || e.target.closest('.cat-tab') || e.target.closest('.ret-btn') || e.target.closest('.confirm-btn')) {
        playClick(480, 0.04);
    }
});

var ICONS = {
    super: '\u{1F3CE}\uFE0F',
    sports: '\u{1F3C1}',
    coupes: '\u{1F698}',
    compacts: '\u{1F697}',
    motorcycles: '\u{1F3CD}\uFE0F',
    sedans: '\u{1F3CE}\uFE0F',
    suvs: '\u{1F699}',
    default: '\u{1F697}',
};

var MOCK = [
    { label: 'Adder', model: 'adder', price: 500, category: 'super', image: 'https://docs.fivem.net/vehicles/adder.webp', stats: { speed: 9.5, accel: 8.5, braking: 7.0, handling: 7.5 } },
    { label: 'Zentorno', model: 'zentorno', price: 450, category: 'super', image: 'https://docs.fivem.net/vehicles/zentorno.webp', stats: { speed: 9.0, accel: 9.0, braking: 7.5, handling: 8.0 } },
    { label: 'Sultan', model: 'sultan', price: 150, category: 'sports', image: 'https://docs.fivem.net/vehicles/sultan.webp', stats: { speed: 7.0, accel: 6.5, braking: 6.0, handling: 7.0 } },
    { label: 'Sentinel', model: 'sentinel', price: 120, category: 'coupes', image: 'https://docs.fivem.net/vehicles/sentinel.webp', stats: { speed: 6.5, accel: 6.0, braking: 6.5, handling: 7.5 } },
    { label: 'Dilettante', model: 'dilettante', price: 50, category: 'compacts', image: 'https://docs.fivem.net/vehicles/dilettante.webp', stats: { speed: 4.0, accel: 4.5, braking: 5.0, handling: 6.0 } },
    { label: 'Bati 801', model: 'bati', price: 100, category: 'motorcycles', image: 'https://docs.fivem.net/vehicles/bati.webp', stats: { speed: 8.5, accel: 8.0, braking: 5.0, handling: 8.5 } },
    { label: 'Schafter', model: 'schafter2', price: 180, category: 'sedans', image: 'https://docs.fivem.net/vehicles/schafter2.webp', stats: { speed: 6.0, accel: 5.5, braking: 6.5, handling: 6.5 } },
    { label: 'XLS', model: 'xls', price: 200, category: 'suvs', image: 'https://docs.fivem.net/vehicles/xls.webp', stats: { speed: 5.5, accel: 5.0, braking: 6.0, handling: 6.0 } },
];

var isBrowser = typeof GetParentResourceName === 'undefined';
var hasRental = false;
var rentalInfo = null;
var allVehicles = [];
var visibleVehicles = [];
var currentCategory = 'all';
var searchQuery = '';
var imageBaseUrl = 'https://docs.fivem.net/vehicles/';
var labels = {};

function normalizeQuery(value) {
    return (value || '').toString().trim().toLowerCase();
}

function escapeHtml(value) {
    return (value || '').toString()
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function formatCategory(cat) {
    if (!cat) return 'Unknown';
    return cat.charAt(0).toUpperCase() + cat.slice(1);
}

function updateReturnBtn() {
    var btn = document.getElementById('returnBtn');
    var rentalsBtn = document.getElementById('navRentalsBtn');
    if (btn) {
        btn.classList.toggle('has-rental', hasRental);
        btn.style.opacity = hasRental ? '1' : '0.72';
    }
    if (rentalsBtn) {
        rentalsBtn.classList.toggle('disabled', !hasRental);
    }
}

function setLogo(url, brandName, brandSub) {
    var img = document.getElementById('logoImg');
    var nameEl = document.getElementById('brandName');
    var subEl = document.getElementById('brandSub');
    if (url && url !== '') {
        img.src = url;
        img.style.display = 'flex';
        img.nextElementSibling.style.display = 'none';
    } else {
        img.style.display = 'none';
        img.nextElementSibling.style.display = 'flex';
    }
    if (nameEl) nameEl.textContent = brandName || 'LB Rental';
    if (subEl) subEl.textContent = brandSub || 'Premium Vehicles';
}

function updateUILabels() {
    var el = document.getElementById('vsInput');
    if (el) el.placeholder = labels.searchPlaceholder || 'Search vehicles...';
    el = document.getElementById('retTitle');
    if (el) el.textContent = labels.returnTitle || 'Return Vehicle';
    el = document.getElementById('retSub');
    if (el) el.textContent = labels.returnSub || 'End your rental';
    el = document.getElementById('retCardTitle');
    if (el) el.textContent = labels.returnCardTitle || 'Finish Rental?';
    el = document.getElementById('retCardDesc');
    if (el) el.textContent = labels.returnCardDesc || 'Return the vehicle to receive your deposit refund';
    el = document.getElementById('retConfirmBtn');
    if (el) el.textContent = labels.returnConfirmBtn || 'Confirm Return';
    el = document.getElementById('retCancelBtn');
    if (el) el.textContent = labels.returnCancelBtn || 'Cancel';
    el = document.getElementById('confirmDurationLabel');
    if (el) el.textContent = labels.confirmDurationLabel || 'Rental Duration';
    el = document.getElementById('confirmDepositLabel');
    if (el) el.textContent = labels.confirmDepositLabel || 'Deposit (25%)';
    el = document.getElementById('confirmTotalLabel');
    if (el) el.textContent = labels.confirmTotalLabel || 'Total Charge';
    el = document.getElementById('confirmRentBtn');
    if (el) el.textContent = labels.confirmRentBtn || 'Confirm Rental';
    el = document.getElementById('confirmCancelBtn');
    if (el) el.textContent = labels.confirmCancelBtn || 'Cancel';
}

window.addEventListener('message', function (e) {
    var d = e.data;
    if (d.type === 'openTablet') {
        showInteract(false);
        document.getElementById('uiOverlay').classList.add('active');
        hasRental = d.hasRental || false;
        updateReturnBtn();
        imageBaseUrl = d.imageBaseUrl || 'https://docs.fivem.net/vehicles/';
        labels = d.labels || {};
        setLogo(d.logo || '', d.brandName, d.brandSub);
        updateUILabels();
        currentCategory = 'all';
        searchQuery = '';
        document.getElementById('vsInput').value = '';
        setCategory('all');
        if (d.vehicles && d.vehicles.length) {
            allVehicles = d.vehicles;
            showVehiclesPage();
            applyFilters();
        } else {
            showVehiclesPage();
        }
        // Test notification
        showNotification('Menu Opened', 'Welcome to LB Rental!', 'success');
    }
    if (d.type === 'setVehicles') {
        allVehicles = Array.isArray(d.vehicles) ? d.vehicles : [];
        applyFilters();
    }
    if (d.type === 'setRentalInfo') {
        hasRental = d.hasRental || false;
        rentalInfo = d.info;
        updateReturnBtn();
        updateRetInfo();
        if (!hasRental) {
            showVehiclesPage();
        }
    }
    if (d.type === 'closeTablet') { closeUI(); }
    if (d.type === 'notify') {
        showNotification(d.title, d.text, d.type);
    }
    if (d.type === 'interact') {
        showInteract(d.show, d.label);
    }
});

function showInteract(show, label) {
    var el = document.getElementById('interactPrompt');
    if (!el) return;
    if (label) {
        var l = el.querySelector('.ip-label');
        if (l) l.textContent = label;
    }
    el.classList.toggle('active', !!show);
}

function showNotification(title, text, type) {
    type = type || 'primary';
    var container = document.getElementById('notification-container');
    
    var notification = document.createElement('div');
    notification.className = 'notification ' + type;
    
    var icons = {
        success: '✓',
        error: '✕',
        primary: 'ℹ'
    };
    
    notification.innerHTML = `
        <div class="notification-icon">${icons[type]}</div>
        <div class="notification-content">
            <div class="notification-title">${title}</div>
            <div class="notification-text">${text}</div>
        </div>
        <button class="notification-close" onclick="this.parentElement.remove()">×</button>
    `;
    
    container.appendChild(notification);
    
    setTimeout(function() {
        notification.style.animation = 'slideOut 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards';
        setTimeout(function() {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 350);
    }, 4000);
}

function doClose() { fetchNui('closeTablet'); closeUI(); }
function closeUI() {
    document.getElementById('uiOverlay').classList.remove('active');
    document.getElementById('confirmModal').classList.remove('active');
}

function showVehiclesPage() {
    var p = document.querySelectorAll('.page');
    for (var i = 0; i < p.length; i++) p[i].classList.remove('active');
    document.getElementById('pageVehicles').classList.add('active');
    setActiveNav('home');
    if (!allVehicles.length) {
        document.getElementById('vehGrid').innerHTML = '<div class="load-w"><div class="load-s"></div><span class="load-t">' + (labels.loading || 'Loading vehicles...') + '</span></div>';
        fetchNui('getVehicles').then(function(result) {
            allVehicles = Array.isArray(result) ? result : [];
            applyFilters();
        });
    }
}

function applyFilters() {
    var filtered = allVehicles.slice();
    if (currentCategory !== 'all') {
        filtered = filtered.filter(function(v) { return v.category === currentCategory; });
    }
    if (searchQuery) {
        var q = normalizeQuery(searchQuery);
        filtered = filtered.filter(function(v) { return v.label.toLowerCase().includes(q); });
    }
    visibleVehicles = filtered;
    renderVeh(filtered);
}

function setCategory(cat) {
    currentCategory = cat;
    var tabs = document.querySelectorAll('.cat-tab');
    for (var i = 0; i < tabs.length; i++) {
        tabs[i].classList.toggle('active', tabs[i].dataset.cat === cat);
    }
    applyFilters();
}

function onSearchInput(el) {
    document.getElementById('vsInput').value = el.value;
    searchQuery = normalizeQuery(el.value);
    applyFilters();
}

function renderVeh(list) {
    var g = document.getElementById('vehGrid');
    g.innerHTML = '';
    visibleVehicles = list.slice();
    document.getElementById('vehCount').textContent = list.length + ' ' + (labels.vehCount || 'vehicles');
    if (!list.length) {
        g.innerHTML = '<div class="load-w"><span class="load-t" style="font-size:15px;">' + (labels.noMatch || 'No vehicles match') + '</span></div>';
        return;
    }
    for (var i = 0; i < list.length; i++) {
        var v = list[i];
        var c = document.createElement('div');
        c.className = 'vc';

        var st = v.stats;
        var statsHtml = '';
        if (st) {
            statsHtml =
                '<div class="vc-stats">' +
                    '<div class="vs"><span>Spd</span><div class="vs-bar"><div class="vs-fill" style="width:' + (st.speed * 10) + '%"></div></div></div>' +
                    '<div class="vs"><span>Acc</span><div class="vs-bar"><div class="vs-fill" style="width:' + (st.accel * 10) + '%"></div></div></div>' +
                    '<div class="vs"><span>Brk</span><div class="vs-bar"><div class="vs-fill" style="width:' + (st.braking * 10) + '%"></div></div></div>' +
                    '<div class="vs"><span>Grp</span><div class="vs-bar"><div class="vs-fill" style="width:' + (st.handling * 10) + '%"></div></div></div>' +
                '</div>';
        }

        var imgHtml = '<div class="vc-img-bg"></div>';
        if (v.image) {
            var imgSrc = v.image.indexOf('://') > -1 ? v.image : imageBaseUrl + v.image;
            imgHtml = '<div class="vc-img-bg"></div>' +
                      '<img src="' + imgSrc + '" alt="" loading="lazy" onerror="this.remove()">';
        }

        var label = escapeHtml(v.label);
        var category = escapeHtml(formatCategory(v.category));
        var badge = escapeHtml(labels.rentBadge || 'Rent');
        var priceSuffix = escapeHtml(labels.priceSuffix || '/hr');

        c.innerHTML =
            '<div class="vc-img">' + imgHtml + '</div>' +
            '<div class="vc-body">' +
                '<div class="vc-meta">' +
                    '<div class="vc-head">' +
                        '<div class="vc-name">' + label + '</div>' +
                        '<div class="vc-cat">' + category + '</div>' +
                    '</div>' +
                    '<span class="vc-fav"></span>' +
                '</div>' +
                statsHtml +
                '<div class="vc-bot">' +
                    '<div class="vc-price">$' + v.price + ' <small>' + priceSuffix + '</small></div>' +
                    '<span class="vc-badge">' + badge + '</span>' +
                '</div>' +
            '</div>';

        c.addEventListener('click', (function (idx) {
            return function () { showConfirm(idx); };
        })(i));

        g.appendChild(c);
    }
}

function showConfirm(idx) {
    var v = visibleVehicles[idx];
    if (!v) return;

    document.getElementById('confirmLabel').textContent = v.label;
    document.getElementById('confirmCategory').textContent = formatCategory(v.category);
    document.getElementById('confirmPrice').textContent = '$' + v.price + ' ' + (labels.priceSuffix || '/hr');

    var depositAmount = Math.floor(v.price * 0.25);
    document.getElementById('confirmDeposit').textContent = '$' + depositAmount;
    document.getElementById('confirmTotal').textContent = '$' + depositAmount;
    document.getElementById('confirmDuration').textContent = labels.confirmDuration || '1 hour';

    if (v.image) {
        var imgSrc = v.image.indexOf('://') > -1 ? v.image : imageBaseUrl + v.image;
        document.getElementById('confirmImg').src = imgSrc;
        document.getElementById('confirmImg').style.display = 'block';
        document.getElementById('confirmImgFallback').style.display = 'none';
    } else {
        document.getElementById('confirmImg').style.display = 'none';
        document.getElementById('confirmImgFallback').style.display = 'flex';
    }

    var flatIdx = -1;
    for (var i = 0; i < allVehicles.length; i++) {
        if (allVehicles[i] === v) { flatIdx = i; break; }
    }
    document.getElementById('confirmModal').dataset.idx = flatIdx;
    document.getElementById('confirmModal').classList.add('active');
}

function doConfirmRent() {
    var idx = parseInt(document.getElementById('confirmModal').dataset.idx);
    document.getElementById('confirmModal').classList.remove('active');
    closeUI();
    fetchNui('closeTablet');
    fetchNui('rentVehicle', { index: idx });
}

function doCancelRent() {
    document.getElementById('confirmModal').classList.remove('active');
}

function showReturnPage() {
    if (!hasRental) return;
    var p = document.querySelectorAll('.page');
    for (var i = 0; i < p.length; i++) p[i].classList.remove('active');
    document.getElementById('pageReturn').classList.add('active');
    setActiveNav('rentals');
    updateRetInfo();
}

function setActiveNav(tab) {
    var items = document.querySelectorAll('.nav-item');
    for (var i = 0; i < items.length; i++) items[i].classList.remove('active');
    if (tab === 'home' && items[0]) items[0].classList.add('active');
    if (tab === 'rentals' && items[1]) items[1].classList.add('active');
}

function updateRetInfo() {
    var el = document.getElementById('retInfo');
    var data = rentalInfo
        ? '<strong>Vehicle:</strong> ' + rentalInfo.model + '<br><strong>Plate:</strong> ' + rentalInfo.plate
        : (labels.noRentalData || 'No rental data');
    el.innerHTML = data;
}

function doReturn() {
    fetchNui('returnVehicle').then(function(r) {
        if (r && r.success) {
            fetchNui('closeTablet');
            closeUI();
        }
    });
}

function fetchNui(event, data) {
    if (isBrowser) return mockNui(event, data);
    return fetch('https://' + GetParentResourceName() + '/' + event, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {}),
    }).then(function (r) { return r.json(); }).catch(function () { return {}; });
}

function mockNui(event, data) {
    return new Promise(function (r) {
        setTimeout(function () {
            if (event === 'getVehicles') { allVehicles = MOCK; applyFilters(); r({}); }
            else if (event === 'rentVehicle') {
                var v = MOCK[data.index];
                hasRental = true;
                rentalInfo = { model: v.label, plate: 'RENT' };
                updateReturnBtn();
                closeUI(); r({ success: true });
            }
            else if (event === 'returnVehicle') {
                hasRental = false; rentalInfo = null;
                updateReturnBtn();
                closeUI(); r({ success: true });
            }
            else if (event === 'closeTablet') { closeUI(); r({}); }
            else { r({}); }
        }, 350);
    });
}

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        if (document.getElementById('confirmModal').classList.contains('active')) {
            doCancelRent(); return;
        }
        if (document.getElementById('uiOverlay').classList.contains('active')) { doClose(); }
    }
    if (e.key === 'Backspace') {
        var tag = document.activeElement && document.activeElement.tagName;
        if (tag === 'INPUT' || tag === 'TEXTAREA') return;
        if (document.getElementById('confirmModal').classList.contains('active')) {
            doCancelRent(); return;
        }
        if (document.getElementById('uiOverlay').classList.contains('active')) { doClose(); }
    }
});



if (isBrowser) {
    document.addEventListener('DOMContentLoaded', function () {
        setTimeout(function () {
            document.getElementById('uiOverlay').classList.add('active');
            hasRental = false;
            updateReturnBtn();
            setLogo('', 'LB Rental', 'Premium Vehicles');
            allVehicles = MOCK;
            applyFilters();
            // Test notification in browser
            showNotification('Browser Test', 'Notifications are working!', 'success');
        }, 400);
    });
}
