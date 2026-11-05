import importTemplate from '../../js/util/importTemplate.js';
export default {
	template: await importTemplate('pages/profilepage/index.html'),

	data: () => ({}),
	methods: {},

	computed: {
		...Vuex.mapState({
			currencyUnit: (state) => state.currencyUnit,
			Locales: (state) => state.Locales,
			PlayerInfo: (state) => state.PlayerInfo,
			AllLevel: (state) => state.AllLevel,
		}),
	},

	watch: {},

	components: {},
	beforeUnmount() {
		window.removeEventListener('keyup', this.keyHandler);
		window.removeEventListener('message', this.eventHandler);
	},

	mounted() {
		window.addEventListener('message', this.eventHandler);
		window.addEventListener('keyup', this.keyHandler);
	},
};
