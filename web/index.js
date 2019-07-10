var app = new Vue({
  el: "#app",
  data: {
    loading: false,
    preference: {
      showTranslation: true,
      commitWordWithSpace: true
    }
  },
  methods: {
    getPreference: function(argument) {
      fetch("http://localhost:62718/preference")
        .then(function(res) {
          return res.json();
        })
        .then(preference => {
          console.log(preference);
          this.preference = preference;
        });
    },
    updatePreference: function() {
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
          console.log(preference);
        });
    }
  }
});

app.getPreference();
