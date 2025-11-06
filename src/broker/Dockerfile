FROM python:3.12-slim

WORKDIR /app

RUN pip install pyzmq msgpack

COPY broker/python/main.py .

CMD ["python", "main.py"]
