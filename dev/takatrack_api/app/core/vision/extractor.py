import logging
import os
from io import BytesIO
from typing import List

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image

logger = logging.getLogger(__name__)


class FabricFeatureExtractor:
    """
    ResNet18-based 512-dimensional feature extractor for jacquard fabric patterns.
    Uses the penultimate layer (avgpool output) to get texture/structure features.
    """

    def __init__(self, model_cache_dir: str = "./model_cache") -> None:
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info(f"FabricFeatureExtractor using device: {self.device}")
        self._load_model(model_cache_dir)
        self._setup_transforms()

    def _load_model(self, cache_dir: str) -> None:
        os.makedirs(cache_dir, exist_ok=True)
        os.environ["TORCH_HOME"] = cache_dir

        # Load pretrained ResNet18 — output of avgpool layer is 512-dim
        base_model = models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)

        # Remove final classification head — keep everything up to (and including) avgpool.
        # ResNet18 avgpool output: [batch, 512, 1, 1]  -> flatten -> [batch, 512]
        self.model = nn.Sequential(*list(base_model.children())[:-1])
        self.model.eval()
        self.model.to(self.device)

        # Disable gradient computation for inference
        for param in self.model.parameters():
            param.requires_grad = False

        logger.info("ResNet18 feature extractor loaded successfully (512-dim output)")

    def _setup_transforms(self) -> None:
        # Standard ImageNet normalisation for pretrained ResNet18
        self.transform = transforms.Compose(
            [
                transforms.Resize((224, 224)),  # ResNet18 input size
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406],
                    std=[0.229, 0.224, 0.225],
                ),
            ]
        )

    def extract(self, image_bytes: bytes) -> List[float]:
        """
        Extract a 512-dimensional feature vector from raw image bytes.
        Returns a list of 512 floats that are L2-normalised (cosine-similarity ready).
        """
        try:
            # Load image from bytes
            image = Image.open(BytesIO(image_bytes)).convert("RGB")

            # Apply transforms and add batch dimension
            tensor = self.transform(image).unsqueeze(0).to(self.device)

            # Forward pass through ResNet18 (up to avgpool)
            with torch.no_grad():
                features = self.model(tensor)  # [1, 512, 1, 1]
                features = features.squeeze()   # [512]

            # L2 normalise for cosine-similarity compatibility
            features = features / (features.norm() + 1e-8)

            return features.cpu().numpy().tolist()

        except Exception as exc:
            logger.error(f"Feature extraction failed: {exc}")
            raise ValueError(f"Failed to extract features from image: {exc}") from exc


def cosine_similarity(vec_a: List[float], vec_b: List[float]) -> float:
    """
    Compute cosine similarity between two L2-normalised vectors.
    Since both vectors are already normalised, dot product == cosine similarity.
    Returns a value in [-1.0, 1.0]; clamped to [0.0, 1.0] for confidence display.
    """
    a = np.array(vec_a, dtype=np.float32)
    b = np.array(vec_b, dtype=np.float32)
    dot = float(np.dot(a, b))
    # Clamp to [0, 1] for confidence percentage
    return max(0.0, min(1.0, dot))


# ---------------------------------------------------------------------------
# Global singleton — loaded once during application startup
# ---------------------------------------------------------------------------
_extractor: FabricFeatureExtractor | None = None


def get_extractor() -> FabricFeatureExtractor:
    """Return the already-initialised singleton extractor."""
    global _extractor
    if _extractor is None:
        raise RuntimeError(
            "Feature extractor not initialised. Call init_extractor() first."
        )
    return _extractor


def init_extractor(cache_dir: str = "./model_cache") -> FabricFeatureExtractor:
    """Initialise (or reinitialise) the global extractor singleton."""
    global _extractor
    _extractor = FabricFeatureExtractor(cache_dir)
    return _extractor
