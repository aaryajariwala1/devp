import json
import logging
from typing import List

from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages active WebSocket connections and broadcasts inventory updates."""

    def __init__(self) -> None:
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(
            f"WebSocket connected. Total connections: {len(self.active_connections)}"
        )

    def disconnect(self, websocket: WebSocket) -> None:
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        logger.info(
            f"WebSocket disconnected. Total connections: {len(self.active_connections)}"
        )

    async def broadcast(self, message: dict) -> None:
        """Send a JSON message to all currently connected clients."""
        payload = json.dumps(message)
        stale: List[WebSocket] = []
        for connection in self.active_connections:
            try:
                await connection.send_text(payload)
            except Exception as exc:
                logger.warning(f"Failed to send to WebSocket client, marking stale: {exc}")
                stale.append(connection)
        # Clean up broken connections
        for ws in stale:
            self.disconnect(ws)

    async def send_personal_message(self, message: dict, websocket: WebSocket) -> None:
        """Send a JSON message to a single specific client."""
        payload = json.dumps(message)
        await websocket.send_text(payload)


# Singleton — imported throughout the application
manager = ConnectionManager()
