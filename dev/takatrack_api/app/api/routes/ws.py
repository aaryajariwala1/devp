import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.websocket_manager import manager

logger = logging.getLogger(__name__)

router = APIRouter()


@router.websocket("/ws/inventory")
async def websocket_endpoint(websocket: WebSocket) -> None:
    """
    WebSocket endpoint for real-time inventory updates.

    - On connect: client is registered with the ConnectionManager.
    - Keeps connection alive.
    - Responds to 'ping' text frames with 'pong'.
    - On disconnect: client is removed from the ConnectionManager.
    - Inventory update events are pushed by the transaction route after each adjustment.
    """
    await manager.connect(websocket)
    logger.info("New WebSocket client connected to /ws/inventory")
    try:
        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
            else:
                # Echo unknown messages back for debugging/diagnostics
                await websocket.send_text(f"echo: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("WebSocket client disconnected from /ws/inventory")
    except Exception as exc:
        logger.error(f"WebSocket error: {exc}")
        manager.disconnect(websocket)
