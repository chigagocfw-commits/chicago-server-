import importTemplate from '../../js/util/importTemplate.js';
export default {
	template: await importTemplate('pages/leaderboardpage/index.html'),

	data: () => ({}),
	methods: {
		getOpacity(rank) {
			return 1 - (rank - 1) * 0.1;
		},
		translate(key, params = {}) {
			const localizedString = this.Locales[key] || key;
			return localizedString.replace(/\${(.*?)}/g, (_, match) => params[match] || '');
		},
	},

	computed: {
		...Vuex.mapState({
			Locales: (state) => state.Locales,
			Top10: (state) => state.Top10,
			myRank: (state) => state.myRank,
		}),
		LeaderBoard() {
			let top10 = this.Top10;

			let remainingEntries = top10.slice(3);
			let placeholderEntries = 7 - remainingEntries.length;
			for (let i = 0; i < placeholderEntries; i++) {
				remainingEntries.push({
					name: null,
					level: null,
				});
			}

			return remainingEntries;
		},
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
