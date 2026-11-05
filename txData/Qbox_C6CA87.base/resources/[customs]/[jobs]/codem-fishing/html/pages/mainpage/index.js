import importTemplate from '../../js/util/importTemplate.js';
import { sharedState } from '../../js/sharadState.js';
export default {
	template: await importTemplate('pages/mainpage/index.html'),

	data: () => ({
		MarketItems: [],
		RateSwiperValue: null,
		SelectedShowWikiItem: null,
		CurrentMainPage: 'main',
		DeliverySwiperValue: null,
	}),
	methods: {
		DeliverFish(name) {
			postNUI('deliverFish', name);
		},
		OpenInspect() {
			this.CurrentMainPage = 'wiki';
		},
		translate(key, params = {}) {
			const localizedString = this.Locales[key] || key;
			return localizedString
				.replace('${change}', `<span class="${params.classname || ''}textcolor">%${params.change || ''}</span>`)
				.replace('${classname}', `<span class="${params.classname || ''}textcolor">${this.Locales[params.classname] || ''}</span>`);
		},
		transleteText(key, params = {}) {
			const localizedString = this.Locales[key] || key;
			return localizedString
				.replace('${amount}', `<span class="${params.classname}textcolor">${params.amount || ''}</span>`)
				.replace('${classname}', `<span class="${params.classname}textcolor">${this.Locales[params.classname] || params.classname || ''}</span>`);
		},
		ShowWikiItem(value) {
			this.SelectedShowWikiItem = value;
			if (value.type == 'rod') {
				setTimeout(() => {
					this.RateSwiper();
				}, 500);
			}
		},
		RateSwiper() {
			this.RateSwiperValue = new Swiper('#rateswipers', {
				slidesPerView: 1,
				loop: false,
				slidesPerGroup: 1,
				spaceBetween: 10,

				navigation: {
					nextEl: '.nextbutton',
					prevEl: '.prevbutton',
				},
			});
		},

		DeliverySwiper() {
			this.DeliverySwiperValue = new Swiper('#deliverieswipers', {
				slidesPerView: 1,
				loop: false,
				slidesPerGroup: 1,
				spaceBetween: 0,

				navigation: {
					nextEl: '.buttonnext',
					prevEl: '.buttonprev',
				},
			});
		},
	},

	computed: {
		...Vuex.mapState({
			currencyUnit: (state) => state.currencyUnit,
			Locales: (state) => state.Locales,
			PlayerInfo: (state) => state.PlayerInfo,
			PlayerDailyMission: (state) => state.PlayerDailyMission,
			ConfigItems: (state) => state.ConfigItems,
			activePage: (state) => state.activePage,
			ConfigDailyDelivery: (state) => state.ConfigDailyDelivery,
		}),
	},

	watch: {
		sharedState: {
			handler(newValue, oldValue) {
				this.CurrentMainPage = 'main';
			},
			immediate: true,
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
		const rods = [];
		const baits = [];

		Object.values(this.ConfigItems).forEach((item) => {
			if (item.type === 'rod') {
				rods.push(item);
			} else if (item.type === 'bait') {
				baits.push(item);
			}
		});

		rods.sort((a, b) => a.requiredLevel - b.requiredLevel);
		baits.sort((a, b) => a.requiredLevel - b.requiredLevel);

		this.MarketItems = [...rods, ...baits];
		this.SelectedShowWikiItem = false;

		setTimeout(() => {
			this.DeliverySwiper();
		}, 500);
	},
};
