import importTemplate from '../../js/util/importTemplate.js';
export default {
	template: await importTemplate('pages/marketpage/index.html'),

	data: () => ({
		currentPrice: 50,
		isAnimating: false,
		ItemHoverInfo: null,
		SelectedMarketCategory: 'buy',
		MarketItems: [],

		SellItems: [],
		SellableItems: [],
		marketBasket: [],
	}),
	created() {
		this.debouncedMouseOver = this.debounce((data) => {
			this.ItemHoverInfo = data;
		}, 100);

		this.debouncedMouseLeave = this.debounce(() => {
			this.ItemHoverInfo = null;
		}, 100);
	},
	methods: {
		GetItemHoverClass() {
			if (!this.ItemHoverInfo) {
				return '';
			}

			if (this.ItemHoverInfo.type === 'rod') {
				const rates = {};
				this.ItemHoverInfo.catchRate.forEach((item) => {
					rates[item.class] = item.change;
				});
				let text = this.Locales['marketitemtext']
					.replace('${rates.common}', rates.common)
					.replace('${rates.uncommon}', rates.uncommon)
					.replace('${rates.rare}', rates.rare)
					.replace('${rates.epic}', rates.epic)
					.replace('${rates.legendary}', rates.legendary);

				return text;
			}
			if (this.ItemHoverInfo.type === 'fish') {
				let itemclass = this.ItemHoverInfo.classname.replace('class', '');
				return this.Locales[itemclass + 'fishtext'];
			}
			if (this.ItemHoverInfo.type === 'bait') {
				return this.Locales['baittext'];
			}
		},

		ChangeMarketCategory(value) {
			if (this.SelectedMarketCategory === value) return;
			this.SelectedMarketCategory = value;
			this.refreshMarket();
		},
		debounce(func, delay) {
			let timeout;
			return (...args) => {
				clearTimeout(timeout);
				timeout = setTimeout(() => func.apply(this, args), delay);
			};
		},
		updatePrice(newPrice) {
			this.currentPrice = newPrice;
		},
		addMarketBasket(item) {
			if (this.SelectedMarketCategory === 'sell') {
				item.amount = 1;
				let existsInventoryItem = this.PlayerInventory.find((i) => i.name === item.name);
				if (!existsInventoryItem || existsInventoryItem.amount <= 0) return;
				let existsInventoryAmount = existsInventoryItem.amount;
				let exists = this.marketBasket.find((i) => i.name === item.name);
				if (exists) {
					if (exists.amount < existsInventoryAmount) {
						exists.amount += 1;
					}
				} else {
					if (existsInventoryAmount >= 1) {
						this.marketBasket.push({ ...item });
					}
				}
			}
			if (this.SelectedMarketCategory == 'buy') {
				let itemlevel = Number(item.requiredLevel);
				let myLevel = Number(this.PlayerInfo.level);
				if (myLevel < itemlevel) {
					return;
				}

				item.amount = 1;
				let exists = this.marketBasket.find((i) => i.name === item.name);
				if (exists) {
					exists.amount += 1;
				} else {
					this.marketBasket.push({
						name: item.name,
						label: item.label,
						amount: 1,
						price: item.price,
						classname: item.classname,
					});
				}
			}
		},

		RemoveItem(item) {
			this.marketBasket = this.marketBasket.filter((i) => i !== item);
		},
		removeitemamount(item) {
			let exists = this.marketBasket.find((i) => i.name === item.name);
			if (exists) {
				exists.amount -= 1;
				if (exists.amount <= 0) {
					this.marketBasket = this.marketBasket.filter((i) => i !== item);
				}
			}
		},
		additemamount(item) {
			if (this.SelectedMarketCategory === 'sell') {
				let existsInventoryItem = this.PlayerInventory.find((i) => i.name === item.name);
				if (!existsInventoryItem || existsInventoryItem.amount <= 0) return;
				let existsInventoryAmount = existsInventoryItem.amount;
				let exists = this.marketBasket.find((i) => i.name === item.name);
				if (exists) {
					if (exists.amount < existsInventoryAmount) {
						exists.amount += 1;
					}
				} else {
					if (existsInventoryAmount >= 1) {
						this.marketBasket.push({ ...item });
					}
				}
			}

			if (this.SelectedMarketCategory == 'buy') {
				let exists = this.marketBasket.find((i) => i.name === item.name);
				if (exists) {
					exists.amount += 1;
				} else {
					this.marketBasket.push({
						name: item.name,
						amount: 1,
					});
				}
			}
		},

		refreshMarket() {
			this.marketBasket = [];
		},
		BuyOrSellItem(value) {
			if (this.marketBasket.length < 1) return;
			postNUI('FishingMarket', {
				value: value,
				type: this.SelectedMarketCategory,
				items: this.marketBasket,
			});
		},

		eventHandler(event) {
			switch (event.data.action) {
				case 'REFRESH_MARKET_BASKET':
					this.refreshMarket();
					break;
				default:
					break;
			}
		},
	},

	computed: {
		...Vuex.mapState({
			currencyUnit: (state) => state.currencyUnit,
			Locales: (state) => state.Locales,
			ConfigItems: (state) => state.ConfigItems,
			PlayerInventory: (state) => state.PlayerInventory,
			PlayerMoney: (state) => state.PlayerMoney,
			PlayerInfo: (state) => state.PlayerInfo,
		}),
		GetBasketTotalPrice() {
			let total = 0;
			if (this.SelectedMarketCategory === 'buy') {
				this.marketBasket.forEach((item) => {
					total += item.price * item.amount;
				});
				this.currentPrice = total;
			}
			if (this.SelectedMarketCategory === 'sell') {
				this.marketBasket.forEach((item) => {
					total += item.price * item.amount;
				});
				this.currentPrice = total;
			}
			return total;
		},
	},

	watch: {
		currentPrice(newPrice, oldPrice) {
			if (this.isAnimating) return;
			this.isAnimating = true;
			setTimeout(() => {
				this.isAnimating = false;
			}, 1000);
		},
		PlayerInventory(newVal, oldVal) {
			this.marketBasket = [];

			this.SellItems = [];
			Object.values(this.ConfigItems).forEach((item) => {
				if (item.type === 'fish') {
					this.SellItems.push(item);
				}
			});

			this.SellableItems = this.SellItems.filter((sellItem) => {
				return this.PlayerInventory.some((inventoryItem) => inventoryItem.name === sellItem.name);
			}).map((sellItem) => {
				const inventoryItem = this.PlayerInventory.find((item) => item.name === sellItem.name);
				return {
					...sellItem,
					count: inventoryItem ? inventoryItem.amount : 0,
				};
			});
		},
	},

	components: {},
	beforeUnmount() {
		window.removeEventListener('keyup', this.keyHandler);
		window.removeEventListener('message', this.eventHandler);
	},

	mounted() {
		window.addEventListener('message', this.eventHandler);
		window.addEventListener('keyup', this.keyHandler);
		this.marketBasket = [];

		this.SellItems = [];
		Object.values(this.ConfigItems).forEach((item) => {
			if (item.type === 'fish') {
				this.SellItems.push(item);
			}
		});
		const roditems = [];
		const baititems = [];
		Object.values(this.ConfigItems).forEach((item) => {
			if (item.type === 'rod') {
				roditems.push(item);
			}
		});

		Object.values(this.ConfigItems).forEach((item) => {
			if (item.type === 'bait') {
				baititems.push(item);
			}
		});

		roditems.sort((a, b) => a.requiredLevel - b.requiredLevel);

		this.MarketItems = [...roditems, ...baititems];

		this.SellableItems = this.SellItems.filter((sellItem) => {
			return this.PlayerInventory.some((inventoryItem) => inventoryItem.name === sellItem.name);
		}).map((sellItem) => {
			const inventoryItem = this.PlayerInventory.find((item) => item.name === sellItem.name);
			return {
				...sellItem,
				count: inventoryItem ? inventoryItem.amount : 0,
			};
		});
	},
};
