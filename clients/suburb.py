import requests


class SuburbClient:
    def __init__(self, host, api_key):
        self.host = host
        self.headers = {
            "Authorization": f"{api_key}",
            "Content-Type": "application/json",
        }

    def list_queues(self):
        response = requests.get(f"{self.host}/queues", headers=self.headers)
        return response.json()

    def create_queue(self, namespace, queue):
        data = {"namespace": namespace, "queue": queue}
        response = requests.post(f"{self.host}/queues", json=data, headers=self.headers)
        return response.json()

    def push_to_queue(self, ns, name, message):
        data = {"message": message}
        response = requests.post(
            f"{self.host}/queues/{ns}/{name}", json=data, headers=self.headers
        )
        return response.json()

    def delete_queue(self, ns, name):
        response = requests.delete(
            f"{self.host}/queues/{ns}/{name}", headers=self.headers
        )
        return response.json()

    def peek_queue(self, ns, name):
        response = requests.get(
            f"{self.host}/queues/{ns}/{name}/peek", headers=self.headers
        )
        return response.json()

    def pop_queue(self, ns, name):
        response = requests.post(
            f"{self.host}/queues/{ns}/{name}/pop", headers=self.headers
        )
        return response.json()

    def get_queue_length(self, ns, name):
        response = requests.get(
            f"{self.host}/queues/{ns}/{name}/length", headers=self.headers
        )
        return response.json()

    def list_flags(self):
        response = requests.get(f"{self.host}/flags", headers=self.headers)
        return response.json()

    def get_flag(self, ns, name):
        response = requests.get(f"{self.host}/flags/{ns}/{name}", headers=self.headers)
        return response.json()

    def set_flag(self, ns, name, value):
        data = {"value": value}
        response = requests.post(
            f"{self.host}/flags/{ns}/{name}", json=data, headers=self.headers
        )
        return response.json()

    def delete_flag(self, ns, name):
        response = requests.delete(
            f"{self.host}/flags/{ns}/{name}", headers=self.headers
        )
        return response.json()

    def list_logs(self):
        response = requests.get(f"{self.host}/logs", headers=self.headers)
        return response.json()

    def add_log(self, ns, source, level, message):
        data = {"source": source, "level": level, "message": message}
        response = requests.post(
            f"{self.host}/logs/{ns}", json=data, headers=self.headers
        )
        return response.json()
