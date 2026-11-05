import testpage from '../pages/testpage/index.js';
import marketpage from '../pages/marketpage/index.js';
import profilepage from '../pages/profilepage/index.js';
import leaderboardpage from '../pages/leaderboardpage/index.js';
import mainpage from '../pages/mainpage/index.js';
import { sharedState } from '../js/sharadState.js';

export function updateValue(newValue) {
	sharedState.value = newValue;
}

const store = Vuex.createStore({
	components: {
		testpage: testpage,
		marketpage: marketpage,
		profilepage: profilepage,
		leaderboardpage: leaderboardpage,
		mainpage: mainpage,
	},
	state: {
		activePage: 'mainpage',
		currencyUnit: '$',
		ConfigItems: [],
		PlayerInventory: [],
		PlayerInfo: [],
		Top10: [],
		Locales: {},
		myRank: 0,
		PlayerDailyMission: [],
		PlayerMoney: {},
		AllLevel: [],
		ConfigDailyDelivery: [],
	},
	getters: {},
	mutations: {},
	actions: {},
});

const app = Vue.createApp({
	components: {
		testpage: testpage,
		marketpage: marketpage,
		leaderboardpage: leaderboardpage,
		profilepage: profilepage,
		mainpage: mainpage,
	},
	data: () => ({
		MainCategories: [
			{ name: 'mainpage', label: 'Main' },
			{ name: 'marketpage', label: 'Market' },
			{ name: 'leaderboardpage', label: 'Leaderboard' },
			{ name: 'profilepage', label: 'Profile' },
		],
		MiniGameProgressBarValue: 0,
		MiniGameFishProgressBar: false,
		MiniGameFishProgressBarValue: 0,
		SelectedFisingBarLocation: 0,
		MiniGameTimer: 25,
		MiniGameTimerInterval: null,
		FishCaught: false,
		InfoPopup: {
			PlayerZone: false,
			SelectBait: false,
			show: false,
		},
		FishingBarLocation: [
			{
				left: 2.1,
			},
			{
				left: 15.8,
			},
			{
				left: 24.7,
			},
			{
				left: 37.7,
			},
			{
				left: 44.6,
			},
			{
				left: 52.6,
			},
			{
				left: 74.6,
			},
			{
				left: 86.6,
			},
		],
		notificationlocation: 'top',
		ShowMiniGameBar: false,
		notifications: [],
		BaitSwiperValue: null,
		FishingMinigameColor: '#49CE92',
		OpenMenu: false,
		DailyMissions: [],
		RentFishingVehicles: [],
		RentMenu: false,
		BaitList: [],
		ActiveBaitSwiperIndex: 0,
		CoughtFishNotification: [],
		BaitLeft: 0,
		SelectedRod: false,
		incrementInterval: null,
		KeyMapping: {},
		minigameEventListeners: {
			mousedown: null,
			mouseup: null,
			mouseleave: null,
			touchstart: null,
			touchend: null
		},
	}),
	methods: {
		translate(key, params = {}) {
			const localizedString = this.Locales[key] || key;
			return localizedString.replace(/%\{(\w+)\}/g, (match, p1) => {
				if (params[p1] !== undefined) {
					return `<span class="${params.classname || ''}">${params[p1]}</span>`;
				}
				return match;
			});
		},
		RentVehicle(name) {
			postNUI('RentVehicle', name);
		},
		SelectBait(name) {
			postNUI('SelectBait', name);
		},
		ChangeBait(value) {
			if (value == 'left') {
				if (this.ActiveBaitSwiperIndex == this.BaitList.length - 1) return;
				this.ActiveBaitSwiperIndex++;
			} else {
				if (this.ActiveBaitSwiperIndex == 0) return;
				this.ActiveBaitSwiperIndex--;
			}
		},

		notification(header, text) {
			const timeout = 5000;
			let id = Date.now();
			if (this.notifications.some((notification) => notification.text === text)) {
				return;
			}

			let newNotification = {
				id: id,
				text: text,
				header: header,
				timeout: setTimeout(() => {
					this.notifications = this.notifications.filter((notification) => notification.id != id);
				}, timeout),
			};

			this.notifications.push(newNotification);
		},
		stopMinigame(val) {
			postNUI('MiniGameStopped');

			this.ShowMiniGameBar = false;
			this.FishCaught = false;
			if (this.OpenMenu) this.OpenMenu = false;

			this.MiniGameFishProgressBarValue = 0;
			this.MiniGameProgressBarValue = 0;
			
			clearTimeout(this.MiniGameTimerInterval);
			this.stopIncrement();
			
			// Remove global event listeners
			this.removeMinigameEventListeners();
			
			this.MiniGameTimer = this.ConfigMiniGameTimer;
			
			Object.assign(this.InfoPopup, {
				show: false,
				SelectBait: false,
				PlayerZone: false,
			});
		},
		formatTime(seconds) {
			const minutes = Math.floor(seconds / 60);
			const remainingSeconds = seconds % 60;
			return `${String(minutes).padStart(2, '0')}:${String(remainingSeconds).padStart(2, '0')}`;
		},
		debounce(func, delay) {
			let timeout;
			return (...args) => {
				clearTimeout(timeout);
				timeout = setTimeout(() => func.apply(this, args), delay);
			};
		},

		AddPointMinigame() {
			if (!this.ShowMiniGameBar) return;
			if (this.FishCaught) {
				return;
			}
			if (this.MiniGameTimer <= 0) {
				return;
			}

			if (this.MiniGameProgressBarValue >= 100) return;
			this.MiniGameProgressBarValue += 3;
		},
		startIncrement() {
			if (this.incrementInterval) return;
			if (!this.ShowMiniGameBar || this.FishCaught) return;
			this.incrementInterval = setInterval(() => {
				this.AddPointMinigame();
			}, 100);
		},
		stopIncrement() {
			if (this.incrementInterval) {
				clearInterval(this.incrementInterval);
				this.incrementInterval = null;
			}
		},
		
		addMinigameEventListeners() {
			// Remove existing listeners first
			this.removeMinigameEventListeners();
			
			// Create event listener functions with proper context
			this.minigameEventListeners.mousedown = (e) => this.startIncrement(e);
			this.minigameEventListeners.mouseup = (e) => this.stopIncrement(e);
			this.minigameEventListeners.mouseleave = (e) => this.stopIncrement(e);
			this.minigameEventListeners.touchstart = (e) => this.startIncrement(e);
			this.minigameEventListeners.touchend = (e) => this.stopIncrement(e);
			
			// Add global event listeners
			document.addEventListener('mousedown', this.minigameEventListeners.mousedown);
			document.addEventListener('mouseup', this.minigameEventListeners.mouseup);
			document.addEventListener('mouseleave', this.minigameEventListeners.mouseleave);
			document.addEventListener('touchstart', this.minigameEventListeners.touchstart);
			document.addEventListener('touchend', this.minigameEventListeners.touchend);
		},
		
		removeMinigameEventListeners() {
			// Remove global event listeners
			if (this.minigameEventListeners.mousedown) {
				document.removeEventListener('mousedown', this.minigameEventListeners.mousedown);
				document.removeEventListener('mouseup', this.minigameEventListeners.mouseup);
				document.removeEventListener('mouseleave', this.minigameEventListeners.mouseleave);
				document.removeEventListener('touchstart', this.minigameEventListeners.touchstart);
				document.removeEventListener('touchend', this.minigameEventListeners.touchend);
				
				// Clear references
				this.minigameEventListeners.mousedown = null;
				this.minigameEventListeners.mouseup = null;
				this.minigameEventListeners.mouseleave = null;
				this.minigameEventListeners.touchstart = null;
				this.minigameEventListeners.touchend = null;
			}
		},

		setupMiniGameProgressbar() {
			if (this.MiniGameTimerInterval) {
				clearTimeout(this.MiniGameTimerInterval);
			}
			// Clear any existing intervals
			this.stopIncrement();
			
			this.ShowMiniGameBar = true;
			this.FishCaught = false;
			this.MiniGameFishProgressBarValue = 0;
			this.MiniGameProgressBarValue = 0;
			this.MiniGameTimer = this.ConfigMiniGameTimer;
			
			// Add global event listeners for minigame
			this.addMinigameEventListeners();
			
			let existingBar = document.querySelector('.fishingbar');
			if (existingBar) {
				existingBar.style.display = 'block';
				existingBar.innerHTML = '';
			}

			let existingBar2 = document.querySelector('.fishingbar2');
			if (existingBar2) {
				existingBar.style.display = 'none';
				existingBar2.innerHTML = '';
			}
			setTimeout(() => {
				let query = document.querySelector('.fishingbar');
				if (query) {
					query.style.display = 'block';
					if (query instanceof HTMLElement) {
						this.MiniGameFishProgressBar = new ldBar(query);
						this.MiniGameFishProgressBar.set(this.MiniGameFishProgressBarValue);
					}
				}
				let MultiSpeed = 0;
				if (this.InfoPopup.SelectBait && this.InfoPopup.SelectBait.baitEffect) {
					this.InfoPopup.SelectBait.baitEffect.forEach((effect) => {
						if (effect.type === 'speed') {
							MultiSpeed = 1 + effect.value / 100;
						}
					});
				}
				let query2 = document.querySelector('.minigamebar');
				if (query2) {
					this.startProgressBarDecay();
					this.startProximityCheck(query2, query, MultiSpeed);
					this.startFishingBarLocationUpdate();
					this.startCountdown();
				}
			}, 350);
		},
		updateFishingBarLocation() {
			let random = Math.floor(Math.random() * this.FishingBarLocation.length);
			this.SelectedFisingBarLocation = random;
		},
		startFishingBarLocationUpdate() {
			let timeoutId2;

			const updateLocation = () => {
				if (this.FishCaught) {
					clearTimeout(timeoutId2);
					return;
				}
				if (this.MiniGameTimer <= 0) {
					clearTimeout(timeoutId2);
					return;
				}
				this.updateFishingBarLocation();
				timeoutId2 = setTimeout(updateLocation, 5000);
			};

			updateLocation();
		},

		startProximityCheck(minigameBar, fishingBar, MultiSpeed) {
			let timeoutId;

			const proximityCheck = () => {
				if (this.FishCaught) {
					clearTimeout(timeoutId);
					return;
				}
				if (this.MiniGameTimer <= 0) {
					this.stopMinigame('start proximity');
					clearTimeout(timeoutId);
					return;
				}
				this.checkProximity(minigameBar, fishingBar, MultiSpeed);
				timeoutId = setTimeout(proximityCheck, 100);
			};

			proximityCheck();
		},
		startCountdown() {
			const updateCountdown = () => {
				if (this.FishCaught) {
					clearTimeout(this.MiniGameTimerInterval);
					return;
				}
				if (this.MiniGameTimer <= 0) {
					clearTimeout(this.MiniGameTimerInterval);
					this.stopMinigame('timer expired');
					return;
				}
				this.MiniGameTimer--;
				this.MiniGameTimerInterval = setTimeout(updateCountdown, 1000);
			};
			updateCountdown();
		},
		startProgressBarDecay() {
			let timeoutId3;

			const decay = () => {
				if (this.FishCaught || this.MiniGameTimer <= 0 || this.ShowMiniGameBar == false) {
					clearTimeout(timeoutId3);
					return;
				}
				if (this.MiniGameProgressBarValue > 0) {
					this.MiniGameProgressBarValue -= 2;
					if (this.MiniGameProgressBarValue < 0) {
						this.MiniGameProgressBarValue = 0;
					}
				}
				timeoutId3 = setTimeout(decay, 150);
			};

			decay();
		},

		checkProximity(minigameBar, fishingBar, MultiSpeed) {
			if (this.FishCaught) {
				return;
			}
			if (this.MiniGameTimer <= 0) {
				return;
			}

			const normalizeRect = (rect) => ({
				top: Math.round(rect.top),
				bottom: Math.round(rect.bottom),
				left: Math.round(rect.left),
				right: Math.round(rect.right),
				height: Math.round(rect.height),
			});

			const minigameBarRect = normalizeRect(minigameBar.getBoundingClientRect());
			const fishingBarRect = normalizeRect(fishingBar.getBoundingClientRect());

			const isHorizontallyAligned = minigameBarRect.right >= fishingBarRect.left && minigameBarRect.right <= fishingBarRect.right;

			if (isHorizontallyAligned) {
				if (this.MiniGameFishProgressBarValue <= 100) {
					this.MiniGameFishProgressBarValue += 2 * MultiSpeed;
					this.MiniGameFishProgressBar.set(this.MiniGameFishProgressBarValue);
				} else {
					let query2 = document.querySelector('.fishingbar2');
					if (query2) {
						query2.innerHTML = '';
						this.MiniGameFishProgressBar = new ldBar(query2);
						this.MiniGameFishProgressBar.set(100);
					}

					let query = document.querySelector('.fishingbar');
					if (query) {
						query.style.display = 'none';
					}
					this.FishCaught = true;
					postNUI('FishCaught');
					clearTimeout(this.MiniGameTimerInterval);

					this.ShowMiniGameBar = false;
				}
			} else {
				if (this.MiniGameFishProgressBarValue > 0) {
					this.MiniGameFishProgressBarValue -= 2 * MultiSpeed;
					if (this.MiniGameFishProgressBarValue < 0) {
						this.MiniGameFishProgressBarValue = 0;
					}
					this.MiniGameFishProgressBar.set(this.MiniGameFishProgressBarValue);
				} else {
					this.MiniGameFishProgressBarValue = 0;
					this.MiniGameFishProgressBar.set(this.MiniGameFishProgressBarValue);
				}
			}
		},

		GetNavLeft() {
			if (this.activePage === 'mainpage') return '0';
			if (this.activePage === 'marketpage') return '20';
			if (this.activePage === 'leaderboardpage') return '40';
			if (this.activePage === 'profilepage') return '60';
		},
		ChangePage(page) {
			if (page == 'mainpage') {
				this.$store.state.activePage = false;
				updateValue(false);
				setTimeout(() => {
					this.$store.state.activePage = 'mainpage';
					updateValue(false);
				}, 250);
			} else {
				if (this.activePage === page) return;
				this.$store.state.activePage = page;
			}
		},
		calculateProgress(mission, complete) {
			if ((mission / complete) * 100 > 100) return 100;
			return (mission / complete) * 100;
		},
		mergeData(sqlData, configData) {
			const mergedData = Object.keys(configData).map((missionKey) => {
				const mission = configData[missionKey];
				const sqlMissionData = sqlData[missionKey];
				return {
					...mission,
					complete: sqlMissionData ? sqlMissionData.complete : false,
					currentCount: sqlMissionData ? sqlMissionData.count : 0,
					progressbar: sqlMissionData ? this.calculateProgress(sqlMissionData.count, mission.Count) : 0,
				};
			});
			this.$store.state.PlayerDailyMission = mergedData;
			// this.PlayerDailyMission = mergedData;
		},
		eventHandler(event) {
			switch (event.data.action) {
				case 'CHECK_NUI':
					postNUI('LoadedNUI');
					break;
				case 'START_MINIGAME':
					this.FishCaught = false;
					this.MiniGameFishProgressBarValue = 0;
					this.MiniGameProgressBarValue = 0;
					this.MiniGameTimer = this.ConfigMiniGameTimer;
					this.stopIncrement();
					this.setupMiniGameProgressbar();
					break;
				case 'OPEN_UI':
					this.OpenMenu = true;
					this.$store.state.activePage = 'mainpage';
					break;
				case 'CONFIG_ITEMS':
					this.$store.state.ConfigItems = event.data.payload;
					break;
				case 'LOAD_DAILYMISSON':
					this.DailyMissions = event.data.payload;
					break;
				case 'DAILY_DELIVERY':
					this.$store.state.ConfigDailyDelivery = event.data.payload;
					break;
				case 'UPDATE_DELIVERY':
					this.$store.state.PlayerInfo.dailydelivery = event.data.payload;
					break;
				case 'LOAD_PLAYERINFO':
					this.$store.state.PlayerInfo = event.data.payload;
					this.mergeData(this.$store.state.PlayerInfo.dailymission.missions, this.DailyMissions);
					Object.values(this.ConfigItems).forEach((item) => {
						if (item.type === 'bait') {
							this.BaitList.push(item);
						}
					});
					break;
				case 'LOAD_PLAYERINVENTORY':
					this.$store.state.PlayerInventory = event.data.payload;
					this.BaitList.forEach((bait) => {
						bait.amount = 0;
					});
					this.$store.state.PlayerInventory.forEach((item) => {
						this.BaitList.forEach((bait) => {
							if (item.name === bait.name) {
								bait.amount = item.amount;
							}
						});
					});

					this.BaitList.forEach((bait) => {
						if (bait.amount === undefined) {
							bait.amount = 0;
						}
					});
					break;
				case 'LOAD_TOP10':
					this.$store.state.Top10 = event.data.payload;
					break;
				case 'LOAD_MYRANK':
					this.$store.state.myRank = event.data.payload;
					break;
				case 'PLAYER_IN_ZONE':
					this.InfoPopup.PlayerZone = true;
					this.InfoPopup.SelectBait = false;
					break;
				case 'SELECTED_BAIT':
					this.InfoPopup.SelectBait = event.data.payload;
					break;
				case 'COUGHT_FISH_NOTIFICATION':
					let fish = event.data.payload;
					let timeouts = 3500;
					let id = Date.now();
					let newNotification = {
						id: Date.now(),
						class: fish.classname,
						fishname: fish.name,
						fishlabel: fish.label,
						timeouts: setTimeout(() => {
							this.CoughtFishNotification = this.CoughtFishNotification.filter((notification) => notification.id != id);
						}, timeouts),
					};

					this.CoughtFishNotification.push(newNotification);

					break;
				case 'SHOW_POPUP':
					this.InfoPopup.show = event.data.payload;
					break;
				case 'REFRESH_BAIT_MENU':
					this.InfoPopup.show = false;
					// this.InfoPopup.SelectBait = false;
					// this.InfoPopup.PlayerZone = false;
					break;
				case 'LOAD_MINIGAMETIMER':
					this.ConfigMiniGameTimer = event.data.payload;
					break;
				case 'SHOW_POPUP':
					this.InfoPopup.show = event.data.payload;
					break;
				case 'OPEN_RENT_UI':
					this.RentMenu = true;
					break;
				case 'LOAD_RENTBOAT':
					this.RentFishingVehicles = event.data.payload;
					break;
				case 'CLOSE_RENT_UI':
					this.RentMenu = false;
					break;
				case 'NOTIFY':
					this.notification(event.data.payload.header, event.data.payload.text);
					break;
				case 'GET_PLAYER_MONEY':
					this.$store.state.PlayerMoney = event.data.payload;
					break;
				case 'UPDATE_MONEY':
					this.$store.state.PlayerMoney = event.data.payload;
					break;
				case 'LOAD_ALLLVL':
					this.$store.state.AllLevel = event.data.payload;
					break;
				case 'UPDATE_SOLD':
					this.$store.state.PlayerInfo.totalfishes = event.data.payload.totalfishes;
					this.$store.state.PlayerInfo.totalearnings = event.data.payload.totalearnings;
					break;
				case 'UPDATE_LATEST':
					if (this.$store.state.PlayerInfo.latetest.length <= 0) {
						this.$store.state.PlayerInfo.latetest = [];
					}
					this.$store.state.PlayerInfo.latetest.push(event.data.payload);
					break;
				case 'STOP_MINIGAME':
					this.stopMinigame('stop event');
					break;
				case 'REOPEN_MENU':
					this.ShowMiniGameBar = false;
					this.FishCaught = false;
					clearTimeout(this.MiniGameTimerInterval);
					this.stopIncrement();
					this.removeMinigameEventListeners();
					this.MiniGameFishProgressBarValue = 0;
					this.MiniGameProgressBarValue = 0;
					this.MiniGameTimer = this.ConfigMiniGameTimer;
					break;
				case 'UPDATE_BAIT_AMOUNT':
					this.BaitLeft = event.data.payload;
					break;
				case 'UPDATE_ROD':
					this.SelectedRod = event.data.payload;
					break;
				case 'LOAD_KEYMAPPING':
					this.KeyMapping = event.data.payload;
					break;
				case 'LOAD_LOCALES':
					this.$store.state.Locales = event.data.payload;
					break;
				case 'UPDATE_LEVEL':
					this.$store.state.PlayerInfo.level = event.data.payload.level;
					this.$store.state.PlayerInfo.xp = event.data.payload.xp;
					break;

				default:
					break;
			}
		},
		keyHandler(event) {
			if (event.key === 'Escape') {
				if (this.ShowMiniGameBar) {
					this.stopMinigame('escape key');
					return;
				}

				if (this.RentMenu) {
					this.RentMenu = false;
				}

				this.InfoPopup.show = false;
				this.InfoPopup.SelectBait = false;
				this.InfoPopup.PlayerZone = false;
				this.OpenMenu = false;
				postNUI('CloseUI');
			}
		},
	},
	computed: {
		...Vuex.mapState({
			activePage: (state) => state.activePage,
			Locales: (state) => state.Locales,
			ConfigItems: (state) => state.ConfigItems,
			PlayerInfo: (state) => state.PlayerInfo,
			currencyUnit: (state) => state.currencyUnit,
		}),
	},
	mounted() {
		window.addEventListener('message', this.eventHandler);
		window.addEventListener('keyup', this.keyHandler);
		document.querySelector('#app').style.display = 'block';
	},
	watch: {
		OpenMenu(val) {
			this.notificationlocation = val ? 'bottom' : 'top';
		},
	},
});

app.use(store).mount('#app');

var resourceName = 'codem-fishing';

if (window.GetParentResourceName) {
	resourceName = window.GetParentResourceName();
}

window.postNUI = async (name, data) => {
	try {
		const response = await fetch(`https://${resourceName}/${name}`, {
			method: 'POST',
			mode: 'cors',
			cache: 'no-cache',
			credentials: 'same-origin',
			headers: {
				'Content-Type': 'application/json',
			},
			redirect: 'follow',
			referrerPolicy: 'no-referrer',
			body: JSON.stringify(data),
		});
		return !response.ok ? null : response.json();
	} catch (error) {}
};
