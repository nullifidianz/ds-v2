const msgpack = require('@msgpack/msgpack');

class Serializer {
    constructor() {
        this.format = process.env.SERDE || 'JSON';

        if (this.format.toUpperCase() === 'MSGPACK') {
            this.serialize = this._serializeMsgpack;
            this.deserialize = this._deserializeMsgpack;
        } else {
            this.serialize = this._serializeJson;
            this.deserialize = this._deserializeJson;
        }
    }

    _serializeJson(data) {
        return Buffer.from(JSON.stringify(data), 'utf-8');
    }

    _deserializeJson(data) {
        return JSON.parse(data.toString('utf-8'));
    }

    _serializeMsgpack(data) {
        return msgpack.encode(data);
    }

    _deserializeMsgpack(data) {
        return msgpack.decode(data);
    }
}

module.exports = new Serializer();
