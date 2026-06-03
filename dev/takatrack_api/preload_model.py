"""
preload_model.py
~~~~~~~~~~~~~~~~
Downloads and caches ResNet18 ImageNet weights at Docker build time.
This avoids a cold-download on first container startup.
"""
import os

os.makedirs("./model_cache", exist_ok=True)
os.environ["TORCH_HOME"] = "./model_cache"

import torchvision.models as models  # noqa: E402

print("Downloading ResNet18 weights …")
models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)
print("ResNet18 weights cached successfully at ./model_cache")
