import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Callable, List, Optional

import rel
import requests
import websocket

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class Namespace:
    name: str


@dataclass
class Queue:
    queue: str


@dataclass
class FeatureFlag:
    flag: str
    value: bool


@dataclass
class Log:
    source: str
    level: str
    message: str
    created_at: datetime


class SuburbClient:
    def __init__(self, host: str, api_key: str, namespace: Optional[str] = None):
        self.host = host.rstrip("/")
        self.namespace = namespace
        self.headers = {
            "Authorization": f"{api_key}",
            "Content-Type": "application/json",
        }

    def _request(self, method: str, endpoint: str, **kwargs):
        url = f"{self.host}{endpoint}"
        response = requests.request(method, url, headers=self.headers, **kwargs)

        if response.status_code not in range(200, 300):
            logger.error(
                f"Request to {url} failed with status {response.status_code}: {response.text}"
            )
            response.raise_for_status()

        return response.json().get("response", {})

    def list_namespaces(self) -> List[Namespace]:
        response_obj = self._request("GET", "/namespaces")
        return [Namespace(name=ns.get("name")) for ns in response_obj]

    def create_namespace(self, name: str) -> Namespace:
        data = {"name": name}
        response_obj = self._request("POST", "/namespaces", json=data)
        return Namespace(name=response_obj.get("name"))

    def delete_namespace(self, name: str) -> None:
        self._request("DELETE", f"/namespaces/{name}")
        if self.namespace == name:
            self.namespace = None

    def select_namespace(self, name: str) -> None:
        if name not in [ns.name for ns in self.list_namespaces()]:
            raise ValueError(f"Namespace {name} does not exist")
        self.namespace = name

    def list_queues(self) -> List[Queue]:
        self._check_namespace_selected()
        response_obj = self._request("GET", f"/queues/{self.namespace}")
        return [Queue(queue=q.get("queue")) for q in response_obj]

    def create_queue(self, name: str) -> Queue:
        self._check_namespace_selected()
        data = {"queue": name}
        response_obj = self._request("POST", f"/queues/{self.namespace}", json=data)
        return Queue(queue=response_obj.get("queue"))

    def delete_queue(self, name: str) -> None:
        self._check_namespace_selected()
        self._request("DELETE", f"/queues/{self.namespace}/{name}")

    def push_to_queue(self, name: str, message: str) -> None:
        self._check_namespace_selected()
        data = {"message": message}
        self._request("POST", f"/queues/{self.namespace}/{name}", json=data)

    def peek_queue(self, name: str) -> str:
        self._check_namespace_selected()
        response_obj = self._request("GET", f"/queues/{self.namespace}/{name}/peek")
        return response_obj

    def pop_queue(self, name: str) -> str:
        self._check_namespace_selected()
        response_obj = self._request("POST", f"/queues/{self.namespace}/{name}/pop")
        return response_obj

    def get_queue_length(self, name: str) -> int:
        self._check_namespace_selected()
        response_obj = self._request("GET", f"/queues/{self.namespace}/{name}/length")
        return response_obj

    def list_flags(self) -> List[FeatureFlag]:
        self._check_namespace_selected()
        response_obj = self._request("GET", f"/flags/{self.namespace}")
        return [
            FeatureFlag(flag=f.get("flag"), value=f.get("value")) for f in response_obj
        ]

    def get_flag(self, name: str) -> bool:
        self._check_namespace_selected()
        response_obj = self._request("GET", f"/flags/{self.namespace}/{name}")
        return response_obj.get("value", False)

    def set_flag(self, name: str, value: bool) -> None:
        self._check_namespace_selected()
        data = {"value": value}
        self._request("POST", f"/flags/{self.namespace}/{name}", json=data)

    def delete_flag(self, name: str) -> None:
        self._check_namespace_selected()
        self._request("DELETE", f"/flags/{self.namespace}/{name}")

    def list_logs(self) -> List[Log]:
        self._check_namespace_selected()
        response_obj = self._request("GET", f"/logs/{self.namespace}")
        return [
            Log(
                source=log.get("source"),
                level=log.get("level"),
                message=log.get("message"),
                created_at=datetime.fromisoformat(log.get("created_at")),
            )
            for log in response_obj
        ]

    def add_log(self, source: str, level: str, message: str) -> None:
        self._check_namespace_selected()
        data = {"source": source, "level": level, "message": message}
        self._request("POST", f"/logs/{self.namespace}", json=data)

    def pubsub_publish(self, channel: str, message: str) -> None:
        self._check_namespace_selected()
        data = {"message": message}
        self._request("POST", f"/pubsub/{channel}/publish", json=data)

    def pubsub_listen(
        self,
        channel: str,
        on_open: Callable[[websocket.WebSocketApp], None],
        on_message: Callable[[websocket.WebSocketApp, str], None],
        on_error: Callable[[websocket.WebSocketApp, Exception], None],
        on_close: Callable[[websocket.WebSocketApp, int, str], None],
    ) -> None:
        ws_url = f"{self.host.replace('http', 'ws')}/pubsub/{channel}/listen"
        ws = websocket.WebSocketApp(
            ws_url,
            header=self.headers,
            on_open=on_open,
            on_message=on_message,
            on_error=on_error,
            on_close=on_close,
        )
        ws.run_forever(dispatcher=rel, reconnect=5)
        rel.signal(2, rel.abort)
        rel.dispatch()

    def _check_namespace_selected(self):
        if self.namespace is None:
            raise ValueError("No namespace selected")
