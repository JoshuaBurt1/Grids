const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

// Serves the files from the build/web folder created by Flutter
app.use(express.static(path.join(__dirname, 'build/web')));

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web', 'index.html'));
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});