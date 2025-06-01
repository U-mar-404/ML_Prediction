# main.py

from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # allow all origins (or list ["http://localhost:3000", "http://127.0.0.1:3000"])
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# ───────────────────────────────────────────────────────────────────────────────
# 1) LOAD SAVED ARTIFACTS AT STARTUP
# ───────────────────────────────────────────────────────────────────────────────

# (1a) List of top‐10 cities as used during training
TOP_CITIES = [
    "Los Angeles",
    "New York",
    "Cook",
    "Wayne",
    "Harris",
    "Philadelphia",
    "Dallas",
    "Jefferson",
    "Baltimore city",
    "Dade",
]

# (1b) Load the Random Forest, Logistic Regression, and OneHotEncoder
rf_model = joblib.load("crime_solved_rf_model.joblib")
lr_model = joblib.load("crime_solved_logistic_model.joblib")
ohe: joblib = joblib.load("crime_solved_ohe_encoder.joblib")

# ───────────────────────────────────────────────────────────────────────────────
# 2) DEFINE Pydantic MODEL FOR INPUT
# ───────────────────────────────────────────────────────────────────────────────

class PredictionRequest(BaseModel):
    Victim_Age: int
    Perpetrator_Age: int
    City: str
    State: str
    Crime_Type: str
    Victim_Sex: str
    Perpetrator_Sex: str
    Relationship: str
    Weapon: str

class PredictionResponse(BaseModel):
    rf_prediction: int   # 0 or 1
    lr_prediction: int   # 0 or 1

# ───────────────────────────────────────────────────────────────────────────────
# 3) UTILITY FUNCTION: PREPROCESS A SINGLE EXAMPLE INTO FEATURE VECTOR
# ───────────────────────────────────────────────────────────────────────────────

def build_feature_vector(req: PredictionRequest) -> np.ndarray:
    """
    Takes one PredictionRequest, applies the same preprocessing steps as in the notebook,
    and returns a (1 × num_features) numpy array that both models can consume.
    """
    # 3a) Create a single-row DataFrame with identical column names
    df = pd.DataFrame([{
        "Victim Age": req.Victim_Age,
        "Perpetrator Age": req.Perpetrator_Age,
        # City grouping: if not in TOP_CITIES → "Other"
        "City": req.City if req.City in TOP_CITIES else "Other",
        "State": req.State.strip(),
        "Crime Type": req.Crime_Type.strip(),
        "Victim Sex": req.Victim_Sex.strip(),
        "Perpetrator Sex": req.Perpetrator_Sex.strip(),
        "Relationship": req.Relationship.strip(),
        "Weapon": req.Weapon.strip(),
    }])

    # 3b) Ensure all categorical columns are strings & stripped
    for col in [
        "City",
        "State",
        "Crime Type",
        "Victim Sex",
        "Perpetrator Sex",
        "Relationship",
        "Weapon",
    ]:
        df[col] = df[col].astype(str).str.strip()

    # 3c) One‐hot encode the categorical columns
    X_cat = ohe.transform(df[[
        "City",
        "State",
        "Crime Type",
        "Victim Sex",
        "Perpetrator Sex",
        "Relationship",
        "Weapon",
    ]])

    # 3d) Numeric part: Victim Age & Perpetrator Age
    X_num = df[["Victim Age", "Perpetrator Age"]].to_numpy(dtype=float)

    # 3e) Concatenate numeric + one-hot
    X_new = np.hstack([X_num, X_cat])
    return X_new

# ───────────────────────────────────────────────────────────────────────────────
# 4) DEFINE THE /predict ENDPOINT
# ───────────────────────────────────────────────────────────────────────────────

@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    """
    Expects JSON with keys:
      {
        "Victim_Age": 28,
        "Perpetrator_Age": 32,
        "City": "Los Angeles",
        "State": "California",
        "Crime_Type": "Murder or Manslaughter",
        "Victim_Sex": "Female",
        "Perpetrator_Sex": "Male",
        "Relationship": "Stranger",
        "Weapon": "Handgun"
      }
    Returns:
      {
        "rf_prediction": 1,
        "lr_prediction": 1
      }
    """
    # 4a) Build feature vector (1×num_features)
    X_new = build_feature_vector(request)

    # 4b) Run both models
    rf_pred = int(rf_model.predict(X_new)[0])
    lr_pred = int(lr_model.predict(X_new)[0])

    # 4c) Return as JSON
    return PredictionResponse(rf_prediction=rf_pred, lr_prediction=lr_pred)
