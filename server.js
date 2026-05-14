const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('DR Application Running');
});

app.get('/health', (req, res) => {
  res.status(200).send('Healthy');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});