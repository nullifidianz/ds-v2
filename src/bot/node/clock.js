class LamportClock {
    constructor() {
        this.time = 0;
    }

    tick() {
        this.time += 1;
        return this.time;
    }

    update(receivedTime) {
        this.time = Math.max(this.time, receivedTime) + 1;
        return this.time;
    }

    getTime() {
        return this.time;
    }
}

module.exports = LamportClock;
