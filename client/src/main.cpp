#include "DHT.h"
#include <WiFi.h>
#include <HTTPClient.h>

// change depending on which sensor in the grid this is
#define SENSOR_X 1
#define SENSOR_Y 1
// change to fit the network being used (in the real world, this would be connected via satellite)
#define WIFI_SSID ""
#define WIFI_PASS ""
// change to the endpoint that the data should be uploaded to
#define UPLOAD_ENDPOINT "http://192.168.1.171:8000/upload-sensor-data/"

DHT dht(27, DHT22);

void setup() {
  Serial.begin(9600);
  Serial.println("connecting");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while(WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(WiFi.status());
  }

  Serial.print("Acquired local wifi ip address: ");
  Serial.println(WiFi.localIP());

  dht.begin();
}

void report_data() {
  float humidity = dht.readHumidity();
  float temp = dht.readTemperature();
  if (isnan(humidity) or isnan(temp) or WiFi.status() != WL_CONNECTED) return;
  HTTPClient httpc;
  httpc.begin(UPLOAD_ENDPOINT);
  if (httpc.POST("{\"grid_x\":" + String(SENSOR_X) + ",\"grid_y\":" + String(SENSOR_Y) + ",\"temperature\":" + String(temp) + ",\"humidity\":" + String(humidity) + ", \"wind_speed\": 12}") > 0) {
    Serial.println("Data sent successfully");
  } else {
    Serial.println("Failed to send data");  
  }
}

void loop() {
  delay(2000);


report_data();
  // float h = dht.readHumidity();
  // float t = dht.readTemperature();

  // if (isnan(h) or isnan(t)) {
  //   Serial.println(F("Failed to read from DHT sensor!"));
  //   return;
  // }

  // Serial.print(F("Humidity: "));
  // Serial.print(h);
  // Serial.print(F("%  Temperature: "));
  // Serial.print(t);
  // Serial.print(F("°C "));
}
