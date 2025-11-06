FROM python:3.12-slim

WORKDIR /app

RUN pip install pyzmq msgpack

COPY server/python/ .

CMD ["python", "main.py"]
