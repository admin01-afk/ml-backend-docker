import os
import logging

from label_studio_ml.model import LabelStudioMLBase
from label_studio_ml.response import ModelResponse

from typing import List, Dict, Optional

from PIL import Image
from urllib.parse import urlparse, parse_qs

logger = logging.getLogger(__name__)
if not os.getenv("LOG_LEVEL"):
    logger.setLevel(logging.INFO)


class NewModel(LabelStudioMLBase):
    """YOLO-v8 detector that returns RectangleLabels for 'UAV'.Resolves Label Studio local-file URLs to absolute URLs."""
    def __init__(self, project_id=None, model_dir=None, **kwargs):
        self.project_id = project_id
        self.model_dir = model_dir

        from ultralytics import YOLO
        self.model = YOLO("/app/best_s_v8.pt")


    def predict(self, tasks: List[Dict], context: Optional[Dict] = None, **kwargs) -> ModelResponse:
        logger.info(f"Run prediction on {len(tasks)} tasks, project ID = {self.project_id}")

        predictions = []

        for task in tasks:
            image_url = task["data"]["image"]
            parsed = urlparse(image_url)
            query = parse_qs(parsed.query)
            relative_path = query.get("d", [None])[0]
            if not relative_path:
                raise ValueError("Cannot parse image path from task")
            abs_image_path = os.path.join("/datasets", os.path.relpath(relative_path, start="datasets"))
            logger.info(f"Trying to open image at path: {abs_image_path}")

            image = Image.open(abs_image_path).convert("RGB")
            width, height = image.size

            results = self.model.predict(image)[0]

            regions = []
            for box in results.boxes:
                x_min, y_min, x_max, y_max = box.xyxy[0].tolist()
                score = float(box.conf[0])
                label_index = int(box.cls[0])
                label_name = self.model.names[label_index]

                # Skip if label isn't "UAV"
                if label_name != "UAV":
                    continue

                region = {
                    "from_name": "label",
                    "to_name": "image",
                    "type": "rectanglelabels",
                    "value": {
                        "x": (x_min / width) * 100,
                        "y": (y_min / height) * 100,
                        "width": ((x_max - x_min) / width) * 100,
                        "height": ((y_max - y_min) / height) * 100,
                        "rectanglelabels": ["UAV"]
                    },
                    "score": score
                }
                regions.append(region)

            avg_score = sum([r["score"] for r in regions]) / max(len(regions), 1)

            prediction = {
                "result": regions,
                "score": avg_score,
            }

            predictions.append(prediction)

        return ModelResponse(predictions=predictions)
    
    def fit(self, event, data, **kwargs):
        """
        This method is called each time an annotation is created or updated.
        Or it's called when "Start training" clicked on the model in the project settings.
        """
        results = {}
        control_models = self.detect_control_models()
        for model in control_models:
            training_result = model.fit(event, data, **kwargs)
            results[model.from_name] = training_result

        return results