from fastapi import FastAPI, HTTPException, Path
from pydantic import BaseModel
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from typing import List, Dict
import numpy as np
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
app = FastAPI()
df = pd.read_csv('forestfires.csv')
features = df[['X', 'Y', 'temp', 'RH', 'wind']]
labels_probability = df['area'].apply(lambda x: 1 if x > 0 else 0)
X_train, X_test, y_train, y_test = train_test_split(features, labels_probability, test_size=0.2, random_state=42)
model_prob = RandomForestClassifier()
model_prob.fit(X_train, y_train)

# NOTE: !! THESE ARE TESTING VALUES !! When an actual sensor reports data, it's value is replaced with that one.
# This is done because we don't have a whole grid to demonstrate yet.
sensor_data_storage = [
    {"grid_x": 1, "grid_y": 1, "temperature": 23.2, "humidity": 50, "wind_speed": 5},
    {"grid_x": 1, "grid_y": 2, "temperature": 23.5, "humidity": 52, "wind_speed": 5.2},
    {"grid_x": 1, "grid_y": 3, "temperature": 23.1, "humidity": 51, "wind_speed": 5.1},
    {"grid_x": 2, "grid_y": 1, "temperature": 23.3, "humidity": 53, "wind_speed": 5.3},
    {"grid_x": 2, "grid_y": 2, "temperature": 23.4, "humidity": 54, "wind_speed": 5.4},
    {"grid_x": 2, "grid_y": 3, "temperature": 23.0, "humidity": 50, "wind_speed": 5.0},
    {"grid_x": 3, "grid_y": 1, "temperature": 23.6, "humidity": 55, "wind_speed": 5.5},
    {"grid_x": 3, "grid_y": 2, "temperature": 23.7, "humidity": 56, "wind_speed": 5.6},
    {"grid_x": 3, "grid_y": 3, "temperature": 23.8, "humidity": 57, "wind_speed": 5.7}
]
class SensorData(BaseModel):
    grid_x: int
    grid_y: int
    temperature: float
    humidity: float
    wind_speed: float

# for that one html page that lets u put in dummy values
@app.get("/")
async def read_root():
    with open("static/index.html", "r") as file:
        return HTMLResponse(content=file.read())

@app.post("/upload-sensor-data/")
async def upload_sensor_data(data: SensorData):
    sensor_data_storage.append(data.dict())
    return {"message": "Sensor data uploaded successfully", "data": data}

# tell all the things for a sensor individually
@app.get("/sensor-data/{grid_x}/{grid_y}")
async def get_sensor_data(
    grid_x: int = Path(..., description="The X coordinate of the sensor"),
    grid_y: int = Path(..., description="The Y coordinate of the sensor")
):
    for entry in sensor_data_storage:
        if entry['grid_x'] == grid_x and entry['grid_y'] == grid_y:
            return entry

    raise HTTPException(status_code=404)

@app.post("/predict-wildfire/")
async def predict_wildfire():
    if len(sensor_data_storage) != 9: raise HTTPException(status_code=404)

    grid_data = []
    for entry in sensor_data_storage:
        grid_data.append([
            entry['grid_x'],
            entry['grid_y'],
            entry['temperature'],
            entry['humidity'],
            entry['wind_speed']
        ])

    # Convert to a DataFrame for easier processing
    grid_df = pd.DataFrame(grid_data, columns=['X', 'Y', 'temp', 'RH', 'wind'])

    # Predict probability of wildfire for each sensor
    grid_df['probability'] = model_prob.predict_proba(grid_df[['X', 'Y', 'temp', 'RH', 'wind']])[:, 1]

    # Calculate overall probability for the entire area
    overall_probability = grid_df['probability'].mean()

    # Predict direction (centroid of high-risk sensors)
    high_risk_threshold = 0.3  # Adjust this threshold as needed
    high_risk_sensors = grid_df[grid_df['probability'] > high_risk_threshold]
    
    if not high_risk_sensors.empty:
        # Weighted centroid calculation
        total_probability = high_risk_sensors['probability'].sum()
        weighted_x = (high_risk_sensors['X'] * high_risk_sensors['probability']).sum() / total_probability
        weighted_y = (high_risk_sensors['Y'] * high_risk_sensors['probability']).sum() / total_probability
        direction = (weighted_x, weighted_y)
    else:
        direction = (grid_df['X'].mean(), grid_df['Y'].mean())

    return {
        "overall_probability_of_wildfire": overall_probability,
        "predicted_direction": direction,
        "sensor_probabilities": grid_df[['X', 'Y', 'probability']].to_dict(orient='records')
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)