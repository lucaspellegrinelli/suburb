import logging
from logging import LogRecord

import requests


class SuburbLogHandler(logging.Handler):
    def __init__(self, namespace: str, source: str, host: str, api_key: str):
        super().__init__()
        self.source = source
        self.suburb_client = SuburbClient(namespace, host, api_key)

        format = "%(message)s"
        self.setFormatter(logging.Formatter(format))

    def emit(self, record: LogRecord):
        log_entry = self.format(record)
        self.suburb_client.add_log(self.source, record.levelname, log_entry)


def setup_logger(namespace: str, source: str, host: str, api_key: str):
    logger = logging.getLogger(source)
    if not logger.hasHandlers():
        logger.setLevel(logging.DEBUG)

        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.DEBUG)

        suburb_handler = SuburbLogHandler(namespace, source, host, api_key)
        suburb_handler.setLevel(logging.DEBUG)

        console_handler.setFormatter(
            logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        )

        logger.addHandler(console_handler)
        logger.addHandler(suburb_handler)

    return logger


class SuburbClient:
    def __init__(self, namespace: str, host: str, api_key: str):
        self.namespace = namespace
        self.host = host
        self.headers = {
            "Authorization": f"{api_key}",
            "Content-Type": "application/json",
        }

        if self.host.endswith("/"):
            self.host = self.host[:-1]

    def list_queues(self):
        response = requests.get(f"{self.host}/queues", headers=self.headers)
        return response.json()

    def create_queue(self, queue):
        data = {"namespace": self.namespace, "queue": queue}
        response = requests.post(f"{self.host}/queues", json=data, headers=self.headers)
        return response.json()

    def push_to_queue(self, name, message):
        data = {"message": message}
        response = requests.post(
            f"{self.host}/queues/{self.namespace}/{name}",
            json=data,
            headers=self.headers,
        )
        return response.json()

    def delete_queue(self, name):
        response = requests.delete(
            f"{self.host}/queues/{self.namespace}/{name}", headers=self.headers
        )
        return response.json()

    def peek_queue(self, name):
        response = requests.get(
            f"{self.host}/queues/{self.namespace}/{name}/peek", headers=self.headers
        )
        return response.json()

    def pop_queue(self, name):
        response = requests.post(
            f"{self.host}/queues/{self.namespace}/{name}/pop", headers=self.headers
        )
        return response.json()

    def get_queue_length(self, name):
        response = requests.get(
            f"{self.host}/queues/{self.namespace}/{name}/length", headers=self.headers
        )
        return response.json()

    def list_flags(self):
        response = requests.get(f"{self.host}/flags", headers=self.headers)
        return response.json()

    def get_flag(self, name):
        response = requests.get(
            f"{self.host}/flags/{self.namespace}/{name}", headers=self.headers
        )
        return response.json().get("response", {}).get("value", "false")

    def set_flag(self, name, value):
        data = {"value": value}
        response = requests.post(
            f"{self.host}/flags/{self.namespace}/{name}",
            json=data,
            headers=self.headers,
        )
        return response.json()

    def delete_flag(self, name):
        response = requests.delete(
            f"{self.host}/flags/{self.namespace}/{name}", headers=self.headers
        )
        return response.json()

    def list_logs(self):
        response = requests.get(f"{self.host}/logs", headers=self.headers)
        return response.json()

    def add_log(self, source, level, message):
        data = {"source": source, "level": level, "message": message}
        response = requests.post(
            f"{self.host}/logs/{self.namespace}", json=data, headers=self.headers
        )
        return response.json()
