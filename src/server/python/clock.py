class LamportClock:
    def __init__(self):
        self.time = 0

    def tick(self):
        """Incrementa o relógio antes de enviar uma mensagem"""
        self.time += 1
        return self.time

    def update(self, received_time: int):
        """Atualiza o relógio ao receber uma mensagem"""
        self.time = max(self.time, received_time) + 1
        return self.time

    def get_time(self):
        """Retorna o tempo atual sem modificar"""
        return self.time
