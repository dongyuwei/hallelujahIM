var app = new Vue({
  el: "#app",
  data: {
    loading: false,
    subLoading: false,
    newKey: "",
    newValue: "",
    preference: {
      showTranslation: true,
      commitWordWithSpace: true
    },
    substitutions: {}
  },
  methods: {
    getPreference() {
      fetch("http://localhost:62718/preference")
        .then(function(res) {
          return res.json();
        })
        .then(preference => {
          this.preference = preference;
        });
    },
    updatePreference() {
      this.loading = true;
      fetch("http://localhost:62718/preference", {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json"
        },
        body: JSON.stringify(this.preference)
      })
        .then(function(res) {
          return res.json();
        })
        .then(preference => {
          this.loading = false;
        });
    },
    loadSubstitutions() {
      fetch("http://localhost:62718/substitutions")
        .then(function(res) {
          return res.json();
        })
        .then(data => {
          this.substitutions = data;
        });
    },
    addSubstitution() {
      if (!this.newKey || !this.newValue) return;
      this.subLoading = true;
      fetch("http://localhost:62718/substitutions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ key: this.newKey, value: this.newValue })
      })
        .then(function(res) {
          return res.json();
        })
        .then(data => {
          this.substitutions = data;
          this.newKey = "";
          this.newValue = "";
          this.subLoading = false;
        });
    },
    removeSubstitution(key) {
      this.subLoading = true;
      fetch("http://localhost:62718/substitutions/" + encodeURIComponent(key), {
        method: "DELETE"
      })
        .then(function(res) {
          return res.json();
        })
        .then(data => {
          this.substitutions = data;
          this.subLoading = false;
        });
    }
  }
});

app.getPreference();
app.loadSubstitutions();
