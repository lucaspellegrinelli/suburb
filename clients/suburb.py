import json

import requests


class SuburbClient:
    def __init__(self, host: str, namespace: str, api_key: str):
        self.host = host
        self.namespace = namespace
        self.api_key = api_key

    @property
    def headers(self):
        return {"Authorization": f"{self.api_key}"}

    def queue_length(self, name: str) -> int:
        url = f"{self.host}/queue/{self.namespace}/{name}/length"
        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        return response.json()["response"]

    def queue_push(self, name: str, data: dict) -> int:
        url = f"{self.host}/queue/{self.namespace}/{name}"
        response = requests.post(
            url, headers=self.headers, json={"value": json.dumps(data)}
        )
        response.raise_for_status()
        return response.json()["response"]

    def queue_pop(self, name: str) -> dict:
        url = f"{self.host}/queue/{self.namespace}/{name}"
        response = requests.delete(url, headers=self.headers)
        response.raise_for_status()
        return json.loads(response.json()["response"])
