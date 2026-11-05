import importTemplate from "../../utils/importTemplate.js";

export default {
  template: await importTemplate("./components/bill/index.html"),
  data: () => ({
    showBill: false,
    billData: {
      passengers: 0,
      amount: 0,
      billOwner: '',
      date: 0,
    },

  }),
  methods: {
    payBill(){
      this.showBill = false
      postNUI("payBill", this.billData);
    },
    secondsToDate(seconds) {
      const s = Number(seconds);
      if (!Number.isFinite(s) || s <= 0) return "--.--.----";

      const date = new Date(s * 1000);
      const day = String(date.getDate()).padStart(2, "0");
      const month = String(date.getMonth() + 1).padStart(2, "0");
      return `${day}.${month}.${date.getFullYear()}`;
    },
    eventHandler(event) {
      switch (event.data.action) {
        case "ShowBill":
          this.showBill = true
          this.billData = event.data.payload
          break;
        default:
          break
      }
    }
  },
  computed: {
    totalAmount(){
      return this.billData.amount + this.cabFee + this.tax
    },
    ...Vuex.mapState({
      cabFee: (state) => state.cabFee,
      tax: (state) => state.tax,
      locales: (state) => state.locales,

    }),
  },
  mounted() {
    window.addEventListener("message", this.eventHandler);
  },
  beforeDestroy() {
    window.removeEventListener("message", this.eventHandler);

  }
}