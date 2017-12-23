const releases = require('./releases.json');
const totalCount = releases.reduce((acc, release) => {
    acc += release.assets[0].download_count;
    return acc;
}, 0);
console.log(`totalCount: ${totalCount}`);
