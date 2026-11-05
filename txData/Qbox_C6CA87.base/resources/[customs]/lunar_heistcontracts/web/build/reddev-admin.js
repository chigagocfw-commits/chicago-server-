(function () {
  const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "lunar_heistcontracts";
  let isAdmin = false;
  let adminChecked = false;
  let infoStylesInjected = false;

  async function nuiPost(name, data, fallback) {
    try {
      const response = await fetch(`https://${resourceName}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data || {})
      });

      return await response.json();
    } catch (error) {
      return fallback;
    }
  }

  function findAdminContainer() {
    const playerIdInput = document.querySelector('#root input[placeholder="Player ID"]');

    if (playerIdInput) {
      let current = playerIdInput.parentElement;

      while (current && current.id !== "root") {
        const classes = current.classList;

        if (classes.contains("w-full") && classes.contains("h-full") && classes.contains("flex") && classes.contains("flex-col")) {
          return current;
        }

        current = current.parentElement;
      }
    }

    const containers = Array.from(document.querySelectorAll("#root div")).filter((container) => {
      const classes = container.classList;
      return classes.contains("w-full") && classes.contains("h-full") && classes.contains("flex") && classes.contains("flex-col");
    });

    return containers.find((container) => {
      const hasPlayerInput = container.querySelector('input[placeholder="Player ID"]');
      const hasContractSelect = container.querySelector("select");
      const text = (container.textContent || "").toLowerCase();

      return hasPlayerInput || (hasContractSelect && (text.includes("contract") || text.includes("delete") || text.includes("refund")));
    });
  }

  function isAdminPageVisible() {
    return Boolean(findAdminContainer());
  }

  function setStatus(card, message, type) {
    const status = card.querySelector("[data-reddev-status]");
    if (!status) return;

    status.textContent = message || "";
    status.style.color = type === "error" ? "#ff8c8c" : "#9dffb2";
  }

  function injectInfoStyles() {
    if (infoStylesInjected) return;

    const style = document.createElement("style");
    style.id = "reddev-info-styles";
    style.textContent = `
      .reddev-info-button {
        position: fixed;
        top: 7.5vh;
        right: 12.5vw;
        width: 2.45rem;
        height: 2.45rem;
        border: 1px solid var(--outline-color, #3d3d61);
        border-radius: 0.7rem;
        color: var(--primary-color2, #bdbdff);
        background: var(--normal-button-gradient, rgba(38, 38, 56, 0.92));
        box-shadow: 0 0.75rem 2.25rem rgba(0, 0, 0, 0.35);
        font-size: 1.25rem;
        line-height: 1;
        display: none;
        place-items: center;
        z-index: 2147483000;
        cursor: pointer;
        transition: border-color 140ms ease, color 140ms ease, filter 140ms ease, transform 140ms ease;
      }

      .reddev-info-button:hover {
        color: #ffffff;
        border-color: var(--primary-color, #a0a0ffc0);
        background: var(--hover-button-gradient, rgba(60, 60, 88, 0.96));
        filter: brightness(1.12);
        transform: translateY(-1px);
      }

      .reddev-info-modal {
        position: fixed;
        inset: 0;
        display: none;
        align-items: center;
        justify-content: center;
        padding: 1.25rem;
        background: rgba(9, 9, 14, 0.42);
        backdrop-filter: blur(0.2rem);
        z-index: 2147483001;
      }

      .reddev-info-card {
        width: min(34rem, 92vw);
        border: 1px solid var(--outline-color, #3d3d61);
        border-radius: 1rem;
        padding: 1.35rem;
        color: #f5f5ff;
        background: var(--background-gradient2, radial-gradient(80.87% 394.5% at 50% 50%, rgba(26, 26, 36, 0.96) 0%, rgba(40, 40, 54, 0.96) 100%));
        box-shadow: 0 1.4rem 4rem rgba(0, 0, 0, 0.55);
      }

      .reddev-info-card h2 {
        margin: 0 0 0.65rem;
        color: var(--primary-color2, #bdbdff);
        font-size: clamp(1.15rem, 2.6vw, 1.5rem);
        font-weight: 700;
      }

      .reddev-info-card p {
        margin: 0.35rem 0;
        color: #c9c9df;
        font-size: clamp(0.92rem, 2.2vw, 1rem);
        line-height: 1.55;
      }

      .reddev-info-card a {
        color: var(--primary-color2, #bdbdff);
        text-decoration: none;
      }

      .reddev-info-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.65rem;
        margin-top: 1.25rem;
      }

      .reddev-info-close {
        min-width: 6.5rem;
        height: 2.45rem;
        border: 1px solid var(--outline-color, #3d3d61);
        border-radius: 0.65rem;
        color: #f5f5ff;
        background: var(--background-gradient, linear-gradient(90deg, #53537A 0%, #3E3E71 100%));
        cursor: pointer;
        transition: filter 140ms ease, transform 140ms ease;
      }

      .reddev-info-close:hover {
        filter: brightness(1.14);
        transform: translateY(-1px);
      }

      @media (max-width: 760px) {
        .reddev-info-button {
          top: 1rem;
          right: 4.25rem;
          width: 2.2rem;
          height: 2.2rem;
          border-radius: 0.55rem;
        }

        .reddev-info-card {
          padding: 1.1rem;
          border-radius: 0.8rem;
        }
      }
    `;

    document.head.appendChild(style);
    infoStylesInjected = true;
  }

  function isTabletVisible() {
    const root = document.getElementById("root");
    if (!root || !root.children.length) return false;

    const rootRect = root.getBoundingClientRect();
    if (rootRect.width <= 0 || rootRect.height <= 0) return false;

    return Array.from(root.querySelectorAll("div, button, nav, main")).some((element) => {
      const rect = element.getBoundingClientRect();
      const style = window.getComputedStyle(element);

      return rect.width > 120 && rect.height > 80 && style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity || 1) > 0;
    });
  }

  function findCloseButton() {
    const buttons = Array.from(document.querySelectorAll("#root button"));
    const visibleButtons = buttons.filter((button) => {
      const rect = button.getBoundingClientRect();
      const style = window.getComputedStyle(button);

      return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    });

    return visibleButtons
      .filter((button) => {
        const rect = button.getBoundingClientRect();
        return rect.top < window.innerHeight * 0.22 && rect.left > window.innerWidth * 0.5 && rect.width <= 72 && rect.height <= 72;
      })
      .sort((a, b) => b.getBoundingClientRect().right - a.getBoundingClientRect().right)[0];
  }

  function positionInfoButton(button) {
    const closeButton = findCloseButton();

    if (!closeButton) {
      button.style.top = window.innerWidth <= 760 ? "1rem" : "7.5vh";
      button.style.right = window.innerWidth <= 760 ? "4.25rem" : "12.5vw";
      button.style.left = "";
      return;
    }

    const rect = closeButton.getBoundingClientRect();
    const buttonRect = button.getBoundingClientRect();
    const buttonWidth = buttonRect.width || 40;
    const buttonHeight = buttonRect.height || 40;
    const gap = 12;
    button.style.top = `${Math.max(8, rect.top + (rect.height - buttonHeight) / 2)}px`;
    button.style.left = `${Math.max(8, rect.left - buttonWidth - gap)}px`;
    button.style.right = "";
  }

  function closeInfoModal() {
    const modal = document.querySelector("[data-reddev-info-modal]");
    if (modal) modal.style.display = "none";
  }

  function openInfoModal() {
    const modal = ensureInfoModal();
    modal.style.display = "flex";
  }

  function ensureInfoModal() {
    injectInfoStyles();

    let modal = document.querySelector("[data-reddev-info-modal]");
    if (modal) return modal;

    modal = document.createElement("div");
    modal.dataset.reddevInfoModal = "true";
    modal.className = "reddev-info-modal";
    modal.innerHTML = `
      <section class="reddev-info-card" role="dialog" aria-modal="true" aria-labelledby="reddev-info-title">
        <h2 id="reddev-info-title">Resource Info</h2>
        <p>Reddev Development cleaned and fixed this resource.</p>
        <p>Cleaned By Reddev Using Codex 5.5</p>
        <p>Support: <a href="https://discord.gg/VW4wBRpj8c">https://discord.gg/VW4wBRpj8c</a></p>
        <div class="reddev-info-actions">
          <button type="button" class="reddev-info-close" data-reddev-info-close>Back</button>
        </div>
      </section>
    `;

    modal.addEventListener("click", (event) => {
      if (event.target === modal || event.target.closest("[data-reddev-info-close]")) {
        closeInfoModal();
      }
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closeInfoModal();
    });

    document.body.appendChild(modal);
    return modal;
  }

  function ensureInfoButton() {
    injectInfoStyles();
    ensureInfoModal();

    let button = document.querySelector("[data-reddev-info-button]");
    if (!button) {
      button = document.createElement("button");
      button.type = "button";
      button.className = "reddev-info-button";
      button.dataset.reddevInfoButton = "true";
      button.setAttribute("aria-label", "Open resource info");
      button.textContent = "ⓘ";
      button.addEventListener("click", openInfoModal);
      document.body.appendChild(button);
    }

    if (isTabletVisible()) {
      button.style.display = "grid";
      positionInfoButton(button);
    } else {
      button.style.display = "none";
      closeInfoModal();
    }
  }

  async function loadNearbyPlayers(card) {
    const select = card.querySelector("[data-reddev-player]");
    if (!select) return;

    select.innerHTML = '<option value="">Loading nearby players...</option>';
    const players = await nuiPost("reddevGetNearbyPlayers", {}, []);
    select.innerHTML = "";

    if (!players || players.length === 0) {
      const option = document.createElement("option");
      option.value = "";
      option.textContent = "No nearby players";
      select.appendChild(option);
      setStatus(card, "Move closer to a player, then refresh.", "error");
      return;
    }

    players.forEach((player) => {
      const option = document.createElement("option");
      option.value = String(player.id);
      option.textContent = `${player.name} [${player.id}] - ${player.distance}m`;
      select.appendChild(option);
    });

    setStatus(card, `${players.length} nearby player${players.length === 1 ? "" : "s"} found.`, "success");
  }

  async function giveRvcoin(card) {
    const select = card.querySelector("[data-reddev-player]");
    const amountInput = card.querySelector("[data-reddev-amount]");
    const button = card.querySelector("[data-reddev-give]");
    const playerId = Number(select && select.value);
    const amount = Math.floor(Number(amountInput && amountInput.value));

    if (!playerId) {
      setStatus(card, "Pick a nearby player first.", "error");
      return;
    }

    if (!amount || amount < 1) {
      setStatus(card, "Enter an amount above 0.", "error");
      return;
    }

    button.disabled = true;
    button.textContent = "Giving...";
    const result = await nuiPost("reddevGiveRvcoins", { playerId, amount }, { success: false, msg: "No response from client." });
    button.disabled = false;
    button.textContent = "Give";

    if (result && result.success) {
      setStatus(card, result.msg || "RVCoin given.", "success");
    } else {
      setStatus(card, result && result.msg ? result.msg : "Could not give RVCoin.", "error");
    }
  }

  function resizeAdminList(container) {
    const panels = Array.from(container.children);
    const purchasedPanel = panels.find((panel) => {
      if (panel.dataset.reddevRvcoinAdmin) return false;

      const text = (panel.textContent || "").toLowerCase();
      return text.includes("purchased") || text.includes("delete") || text.includes("refund");
    });

    if (purchasedPanel) {
      purchasedPanel.style.flex = "1 1 auto";
      purchasedPanel.style.height = "auto";
      purchasedPanel.style.minHeight = "0";
    }
  }

  function injectPanel() {
    if (!isAdmin && !isAdminPageVisible()) return;

    const container = findAdminContainer();
    if (!container || container.querySelector("[data-reddev-rvcoin-admin]")) return;

    const card = document.createElement("div");
    card.dataset.reddevRvcoinAdmin = "true";
    card.className = "h-28 px-8 bg-background2 rounded-xl flex justify-between items-center";
    card.style.flex = "0 0 auto";
    card.innerHTML = `
      <div>
        <p class="font-semibold text-2xl">Give RVCoin</p>
        <p class="text-[#aaa]">Pick a nearby player and enter the amount to add.</p>
        <p data-reddev-status class="text-sm" style="color:#aaa;">Closest players show first.</p>
      </div>
      <div class="flex gap-2 items-center">
        <select data-reddev-player class="w-64 h-10 px-2 bg-gray-50 border border-gray-300 text-gray-900 shadow-md focus:outline-none text-sm rounded-lg">
          <option value="">Loading nearby players...</option>
        </select>
        <input data-reddev-amount type="number" min="1" step="1" value="100" class="w-28 h-10 px-3 text-center bg-gray-50 border border-gray-300 text-gray-900 shadow-md focus:outline-none text-sm rounded-lg" />
        <button data-reddev-refresh class="h-10 px-4 rounded-lg hover:brightness-110 transition-all" style="background:var(--background-gradient)">Refresh</button>
        <button data-reddev-give class="h-10 px-5 rounded-lg hover:brightness-110 transition-all" style="background:var(--background-gradient)">Give</button>
      </div>
    `;

    container.insertBefore(card, container.children[1] || null);
    resizeAdminList(container);

    card.querySelector("[data-reddev-refresh]").addEventListener("click", () => loadNearbyPlayers(card));
    card.querySelector("[data-reddev-give]").addEventListener("click", () => giveRvcoin(card));
    loadNearbyPlayers(card);
  }

  async function init() {
    ensureInfoButton();

    if (!adminChecked) {
      isAdmin = await nuiPost("isAdmin", {}, false) === true;
      adminChecked = true;
    }

    injectPanel();
  }

  const observer = new MutationObserver(init);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  window.addEventListener("load", init);
  setInterval(init, 1500);
})();
