import os
import json
try:
    import msgpack
    MSGPACK_AVAILABLE = True
except ImportError:
    MSGPACK_AVAILABLE = False

class Serializer:
    def __init__(self):
        self.format = os.getenv('SERDE', 'JSON').upper()

        if self.format == 'MSGPACK':
            if not MSGPACK_AVAILABLE:
                raise ImportError("MessagePack não disponível. Instale msgpack-python ou use SERDE=JSON")
            self.serialize = self._serialize_msgpack
            self.deserialize = self._deserialize_msgpack
        else:
            self.serialize = self._serialize_json
            self.deserialize = self._deserialize_json

    def _serialize_json(self, data):
        return json.dumps(data, ensure_ascii=False).encode('utf-8')

    def _deserialize_json(self, data):
        return json.loads(data.decode('utf-8'))

    def _serialize_msgpack(self, data):
        return msgpack.packb(data)

    def _deserialize_msgpack(self, data):
        return msgpack.unpackb(data, raw=False)

# Instância global
serializer = Serializer()
