var app = new Vue({
    el: '#app',
    data: {
        preference: {
            showTranslation: true,
            pinyinApi: 'baidu'
        }
    },
    methods: {
        getPreference: function (argument) {
            var self = this;
            fetch('http://localhost:62718/preference')
            .then(function (res) {
                return res.json()
            })
            .then(function (preference) {
                console.log(preference);
                self.preference = preference;
            })
        },
        updatePreference: function () {
            fetch('http://localhost:62718/preference', {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(this.preference)
            })
            .then(function (res) {
                return res.json()
            })
            .then(function (preference) {
                console.log("updated preference:", preference);
            })
        }
    }
})

app.getPreference();

