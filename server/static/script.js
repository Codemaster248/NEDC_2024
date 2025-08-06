document.getElementById('upload-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const formData = {
        grid_x: parseInt(document.getElementById('grid-x').value),
        grid_y: parseInt(document.getElementById('grid-y').value),
        temperature: parseFloat(document.getElementById('temperature').value),
        humidity: parseFloat(document.getElementById('humidity').value),
        wind_speed: parseFloat(document.getElementById('wind-speed').value)
    };

    const response = await fetch('/upload-sensor-data/', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    });

    const result = await response.json();
    document.getElementById('upload-status').textContent = result.message;
});

document.getElementById('predict-button').addEventListener('click', async () => {
    const response = await fetch('/predict-wildfire/', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    });

    const result = await response.json();
    document.getElementById('overall-probability').textContent = result.overall_probability_of_wildfire.toFixed(2)* 100 + '%';
    document.getElementById('predicted-direction').textContent = result.predicted_direction.join(', ');

    const tableBody = document.querySelector('#sensor-probabilities tbody');
    tableBody.innerHTML = ''; // Clear previous results
    result.sensor_probabilities.forEach(sensor => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${sensor.X}</td>
            <td>${sensor.Y}</td>
            <td>${sensor.probability.toFixed(2) * 100}%</td>
        `;
        tableBody.appendChild(row);
    });
});