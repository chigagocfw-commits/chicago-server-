// This script was leaked inside at TCHub Website so check that out https://tchub.st/dashboard

var smokingResourceName = "rtx_smoking";

const RUNTIME_MENU_ITEMS = {
  vape_flavour: null,
  bong_fill: null,
  roll_joint: null
};

const ASSETS = {
  vape: "img/vape.png",
  cigarette: "img/cigarette.png",
  cigar: "img/cigar.png",
  joint: "img/joint.png",
  bong: "img/bong.png",
  shisha: "img/shisha_0.png",
  battery: "img/battery.png",
  water: "img/water.png",
  flavour_apple: "img/eliquid_box_apple.png",
  flavour_blueberry: "img/eliquid_box_blueberry.png",
  flavour_cherry: "img/eliquid_box_cherry.png",
  flavour_strawberry: "img/eliquid_box_strawberry.png",
  fill_og: "img/weed_og_kush.png",
  fill_purple: "img/weed_purple_haze.png",
  fill_haze: "img/weed_amnesia_haze.png"
};

const STATE = {
  visible: false,
  type: "vape",
  lit: true,
  currentPayload: {},
  currentMenu: null,
  craftTimer: null
};

function sendNui(action, data) {
  try { $.post("https://" + smokingResourceName + "/" + action, JSON.stringify(data || {})); } catch (e) {}
}

function clamp(n) {
  return Math.max(0, Math.min(100, Number(n) || 0));
}

function hexToRgb(hex) {
   const s = hex.replace("#", "");
   return {
      r: parseInt(s.substr(0, 2), 16),
      g: parseInt(s.substr(2, 2), 16),
      b: parseInt(s.substr(4, 2), 16),
   };
}

function rgba(hex, a) {
   const c = hexToRgb(hex);
   return `rgba(${c.r}, ${c.g}, ${c.b}, ${a})`;
}

function lighten(hex, amt = 0.18) {
   const s = hex.replace("#", "");
   if (s.length !== 6) return hex;
   const to = i =>
      Math.min(255, Math.round(parseInt(s.substr(i, 2), 16) * (1 + amt)));
   const h = n => n.toString(16).padStart(2, "0");
   return `#${h(to(0))}${h(to(2))}${h(to(4))}`;
}

function setTheme(accentHex) {
   const acc2 = lighten(accentHex, 0.12);

   $(":root")
      .css("--accent", accentHex)
      .css("--accent-2", acc2)
      .css("--accent-a20", rgba(accentHex, 0.2))
      .css("--accent-a10", rgba(accentHex, 0.1))
      .css("--accent-glow", rgba(accentHex, 0.18));

   const $grad = $("#hmh-pinkwave");
   if ($grad.length) {
      const $stops = $grad.find("stop");
      $stops
         .eq(0)
         .attr("stop-color", accentHex)
         .attr("stop-opacity", ".55");
      $stops
         .eq(1)
         .attr("stop-color", acc2)
         .attr("stop-opacity", ".32");
   }
}


function hexToRgba(hex, alpha) {
  let h = String(hex || "#ff66ff").replace("#", "");
  if (h.length === 3) h = h.split("").map(x => x + x).join("");
  const bigint = parseInt(h, 16);
  const r = (bigint >> 16) & 255;
  const g = (bigint >> 8) & 255;
  const b = bigint & 255;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function valueFromPayload(payload, key, fallback) {
  return payload && payload[key] != null && payload[key] !== "" ? payload[key] : fallback;
}

function setImage(src, fallback) {
  $("#itemIconImage").attr("src", src || fallback || ASSETS.vape);
}

function openMain() { $("body").css("display", "block"); }
function closeMain() { $("body").css("display", "none"); }

function getSetup(type, lit) {
  const map = {
    vape: {
      title: "Vape",
      icon: ASSETS.vape,
      metaLabel: "Flavor",
      metaKey: "flavour",
      metaFallback: "Not selected",
      progress: [
        { label: "Flavor level", key: "flavourPercent", fallback: 0 },
        { label: "Akku", key: "batteryPercent", fallback: 0 }
      ],
      actions: [
        { key: "E", text: "Take a hit", event: "smoking:takeHit" },
        { key: "F", text: "Settings", menu: "vape_settings" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ]
    },
    cigarette: {
      title: "Cigarette",
      icon: ASSETS.cigarette,
      metaLabel: "Brand",
      metaKey: "brand",
      metaFallback: "Redwood",
      progress: lit ? [{ label: "Status", key: "statusPercent", fallback: 0 }] : [],
      actions: lit ? [
        { key: "E", text: "Take a puff", event: "smoking:takePuff" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "H", text: "Position", event: "smoking:position" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ] : [
        { key: "E", text: "Light", event: "smoking:light" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "H", text: "Position", event: "smoking:position" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ]
    },
    cigar: {
      title: "Cigar",
      icon: ASSETS.cigar,
      metaLabel: "Brand",
      metaKey: "brand",
      metaFallback: "Cohiba",
      progress: lit ? [{ label: "Status", key: "statusPercent", fallback: 0 }] : [],
      actions: lit ? [
        { key: "E", text: "Take a puff", event: "smoking:takePuff" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ] : [
        { key: "E", text: "Light", event: "smoking:light" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ]
    },
    bong: {
      title: "Bong",
      icon: ASSETS.bong,
      metaLabel: "Fill",
      metaKey: "fill",
      metaFallback: "Not selected",
      progress: [
        { label: "Fill level", key: "fillPercent", fallback: 0 },
        { label: "Water", key: "waterPercent", fallback: 0 }
      ],
      actions: [
        { key: "E", text: "Take a hit", event: "smoking:takeHit" },
        { key: "F", text: "Settings", menu: "bong_settings" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ]
    },
    joint: {
      title: "Joint",
      icon: ASSETS.joint,
      metaLabel: "Fill",
      metaKey: "fill",
      metaFallback: "Not selected",
      progress: lit ? [{ label: "Status", key: "statusPercent", fallback: 0 }] : [],
      actions: lit ? [
        { key: "E", text: "Take a puff", event: "smoking:takePuff" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ] : [
        { key: "E", text: "Light", event: "smoking:light" },
        { key: "G", text: "Pass", event: "smoking:give" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
	  ]
	},
    shisha: {
      title: "Shisha",
      icon: ASSETS.shisha,
      metaLabel: "Flavor",
      metaKey: "flavour",
      metaFallback: "Doppelter Apfel",
      progress: [{ label: "Status", key: "statusPercent", fallback: 0 }],
      actions: [
        { key: "E", text: "Take a hit", event: "smoking:takeHit" },
        { key: "BACK", text: "Cancel", event: "smoking:cancel" }
      ]
    }
  };
  return map[type] || map.vape;
}

const MENUS = {
  vape_settings: {
    kicker: "Vape Settings",
    title: "Manage Vape",
    subtitle: "Choose what you want to change.",
    items: [
      { id: "flavour", label: "Flavor", image: ASSETS.flavour_blueberry, meta: "Change or refill the flavor", openMenu: "vape_flavour" },
      { id: "battery", label: "Change battery", image: ASSETS.battery, meta: "Replace the battery", event: "smoking:changeBattery" }
    ]
  },
  vape_flavour: {
    kicker: "Vape Settings",
    title: "Select a Flavor",
    subtitle: "Choose a flavor cartridge.",
    items: [
      { id: "apple", label: "Apple", image: ASSETS.flavour_apple, meta: "Crisp and refreshing apple flavor", event: "smoking:setFlavour" },
      { id: "blueberry", label: "Blueberry", image: ASSETS.flavour_blueberry, meta: "Sweet and juicy blueberry flavor", event: "smoking:setFlavour" },
      { id: "cherry", label: "Cherry", image: ASSETS.flavour_cherry, meta: "Rich and lightly tart cherry flavor", event: "smoking:setFlavour" }
    ]
  },
  bong_settings: {
    kicker: "Bong Settings",
    title: "Manage Bong",
    subtitle: "Choose a fill or add water.",
    items: [
      { id: "fill", label: "Fill", image: ASSETS.fill_og, meta: "Choose what to put in the bowl", openMenu: "bong_fill" },
      { id: "water", label: "Change water", image: ASSETS.water, meta: "Refill the water chamber", event: "smoking:addWater" }
    ]
  },
  bong_fill: {
    kicker: "Bong Settings",
    title: "Select a Fill",
    subtitle: "Choose what goes in the bowl.",
    items: [
      { id: "og_kush", label: "OG Kush", image: ASSETS.fill_og, meta: "Classic bowl fill", event: "smoking:setBongFill" },
      { id: "purple_haze", label: "Purple Haze", image: ASSETS.fill_purple, meta: "Sweet, aromatic fill", event: "smoking:setBongFill" },
      { id: "amnesia_haze", label: "Amnesia Haze", image: ASSETS.fill_haze, meta: "Strong citrus profile", event: "smoking:setBongFill" }
    ]
  }
};

const ROLL_MENU = {
  title: "Roll a Joint",
  subtitle: "Choose a filling to roll a joint.",
  items: [
    { id: "og_kush", label: "OG Kush", image: ASSETS.fill_og, meta: "Dense, classic fill", event: "smoking:craftJoint" },
    { id: "purple_haze", label: "Purple Haze", image: ASSETS.fill_purple, meta: "Sweet, purple fill", event: "smoking:craftJoint" },
    { id: "amnesia_haze", label: "Amnesia Haze", image: ASSETS.fill_haze, meta: "Bright citrus profile", event: "smoking:craftJoint" }
  ]
};

function renderActions(actions) {
  const html = (actions || []).map(action => {
    const attrs = [
      action.event ? `data-event="${action.event}"` : "",
      action.menu ? `data-open-menu="${action.menu}"` : ""
    ].filter(Boolean).join(" ");
    return `<div class="action-item" ${attrs}><span class="key">${action.key}</span><span class="action-text">${action.text}</span></div>`;
  }).join("");
  $("#mainActions").html(html);
}

function renderProgress(setup, payload) {
  const html = (setup.progress || []).map(item => {
    const value = clamp(valueFromPayload(payload, item.key, item.fallback));
    return `<div class="progress-item"><div class="progress-head"><span class="progress-name">${item.label}</span><span class="progress-percent">${value}%</span></div><div class="bar"><span style="width:${value}%"></span></div></div>`;
  }).join("");
  $("#progressStack").html(html);
}

function render(payload) {
  payload = payload || {};
  STATE.currentPayload = Object.assign({}, STATE.currentPayload, payload);
  STATE.type = STATE.currentPayload.type || STATE.type;
  if (payload.lit != null) STATE.lit = !!payload.lit;

  const current = STATE.currentPayload;
  const setup = getSetup(STATE.type, STATE.lit);
  $("#itemTitle").text(current.itemLabel || setup.title);
  setImage(current.icon || setup.icon, setup.icon);

  const metaValue = valueFromPayload(current, setup.metaKey, setup.metaFallback);
  $("#metaLabel").text(setup.metaLabel || "Status");
  $("#metaValue").text(metaValue);
  $("#metaRow").toggleClass("hidden", !setup.metaLabel);

  renderProgress(setup, current);
  renderActions(setup.actions || []);
}

function showUI(payload) {
  openMain();
  render(payload || {});
  STATE.visible = true;
  $("#smokingRoot").css("display", "block");
}

function hideUI() {
  STATE.visible = false;
  $("#smokingRoot").hide();
  $("#selectionModal, #craftModal").addClass("hidden");
  STATE.currentMenu = null;
  if (STATE.craftTimer) {
    clearInterval(STATE.craftTimer);
    STATE.craftTimer = null;
  }
}

function openSelectionMenu(name) {
  const menu = MENUS[name];
  if (!menu) return;

  const runtimeItems = RUNTIME_MENU_ITEMS[name];
  const finalItems = Array.isArray(runtimeItems) ? runtimeItems : (menu.items || []);

  STATE.currentMenu = name;
  $("#selectionKicker").text(menu.kicker || "Settings");
  $("#selectionTitle").text(menu.title || "Select an option");
  $("#selectionSubtitle").text(menu.subtitle || "Select an item.");

  const html = finalItems.map(item => {
    const attrs = item.openMenu
      ? `data-open-menu="${item.openMenu}"`
      : `data-event="${item.event}" data-id="${item.id}" data-label="${item.label}"`;
    const buttonText = item.openMenu ? "Open" : "Select";
    return `<div class="selection-item"><div class="selection-thumb"><img src="${item.image}" alt="${item.label}"></div><div><div class="selection-name">${item.label}</div><div class="selection-meta">${item.meta}</div></div><button class="select-btn" ${attrs}>${buttonText}</button></div>`;
  }).join("");

  $("#selectionGrid").html(html);
  $("#selectionModal").removeClass("hidden");
}

function closeSelectionMenu() {
  STATE.currentMenu = null;
  $("#selectionModal").addClass("hidden");
   sendNui("closemenu", {  });
}

function openCraftMenu() {
  $("#craftTitle").text(ROLL_MENU.title);
  $("#craftSubtitle").text(ROLL_MENU.subtitle);

  const finalItems = Array.isArray(RUNTIME_MENU_ITEMS.roll_joint) ? RUNTIME_MENU_ITEMS.roll_joint : ROLL_MENU.items;

  const html = finalItems.map(item => {
    return `<div class="craft-item"><div class="craft-thumb"><img src="${item.image}" alt="${item.label}"></div><div><div class="craft-name">${item.label}</div><div class="craft-meta">${item.meta}</div></div><button class="select-btn" data-craft-event="${item.event}" data-id="${item.id}" data-label="${item.label}">Roll</button></div>`;
  }).join("");

  $("#craftGrid").html(html);
  $("#craftProgressWrap").addClass("hidden");
  $("#craftProgressBar").css("width", "0%");
  $("#craftProgressValue").text("0%");
  $("#craftModal").removeClass("hidden");
}
function closeCraftMenu() {
  if (STATE.craftTimer) {
    clearInterval(STATE.craftTimer);
    STATE.craftTimer = null;
  }
  $("#craftModal").addClass("hidden");
   sendNui("closemenu", {  });
}

function chooseMenuItem(eventName, id, label) {
  sendNui(eventName, { id, label, menu: STATE.currentMenu, type: STATE.type });

  if (eventName === "smoking:setFlavour") {
  }

  if (eventName === "smoking:changeBattery") {
  }

  if (eventName === "smoking:setBongFill") {
  }

  if (eventName === "smoking:addWater") {
  }

  closeSelectionMenu();
}

function startCraftProgress(eventName, id, label) {
  sendNui(eventName, { id, label, system: "roll_joint" });
  if (STATE.craftTimer) {
    clearInterval(STATE.craftTimer);
    STATE.craftTimer = null;
  }
  $("#craftModal").addClass("hidden");
   sendNui("closemenu", {  });
}

$(function() {


  $(document).on("click", ".action-item[data-open-menu], .select-btn[data-open-menu], [data-open-menu]", function() {
    const menu = $(this).data("open-menu");
    if (menu) openSelectionMenu(menu);
  });

  $(document).on("click", "[data-open-roll]", function() {
    openCraftMenu();
  });

  $(document).on("click", ".action-item[data-event]", function() {
    sendNui($(this).data("event"), { type: STATE.type, payload: STATE.currentPayload || {} });
  });

  $(document).on("click", ".select-btn[data-event]", function() {
    chooseMenuItem($(this).data("event"), $(this).data("id"), $(this).data("label"));
  });

  $(document).on("click", ".select-btn[data-craft-event]", function() {
    startCraftProgress($(this).data("craft-event"), $(this).data("id"), $(this).data("label"));
  });

  $(document).on("click", "[data-close-overlay]", closeSelectionMenu);
  $(document).on("click", "[data-close-craft]", closeCraftMenu);
  $("#closeMenusBtn").on("click", function(){ closeSelectionMenu(); closeCraftMenu(); });

});

window.addEventListener("message", function(event) {
  const item = event.data || {};
  const action = item.action || item.message;
  const payload = item.data || item;

  if (action === "SmokingOpen" || action === "smoking:open") showUI(payload);
  if (action === "SmokingUpdate" || action === "smoking:update") render(payload);
  if (action === "SmokingHide" || action === "smoking:hide") hideUI();
	if (action === "updateinterfacedata") {
		let theme = item.interfacecolordata;


		setTheme(theme);
		smokingResourceName = item.smokingresourcenamedata;
	} 
  if (action === "SmokingMenu" || action === "smoking:menu") {
    const name = payload.menu || payload.name;
    if (name === "roll_joint") openCraftMenu(); else openSelectionMenu(name);
  }
  if (action === "SmokingCraft" || action === "smoking:craft") {
    openCraftMenu();
  }
if (action === "SmokingMenuItems" || action === "smoking:menuItems") {
  const menuName = payload.menu;
  const items = payload.items;

  if (menuName && Array.isArray(items)) {
    RUNTIME_MENU_ITEMS[menuName] = items;
  }
}  
});
