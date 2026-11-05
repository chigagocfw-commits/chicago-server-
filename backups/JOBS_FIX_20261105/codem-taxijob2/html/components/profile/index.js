import importTemplate from "../../utils/importTemplate.js";

export default {
  template: await importTemplate("./components/profile/index.html"),
  methods: {
    secondsToDate(seconds) {
      const s = Number(seconds);
      if (!Number.isFinite(s) || s <= 0) return "--.--.----";

      const date = new Date(s * 1000);
      const day = String(date.getDate()).padStart(2, "0");
      const month = String(date.getMonth() + 1).padStart(2, "0");
      return `${day}.${month}.${date.getFullYear()}`;
    },
  },
  computed: {
    ...Vuex.mapState({
      playerData: (state) => state.playerData,
      xp: (state) => state.xp,
      locales: (state) => state.locales,
    
    }),
  }
}