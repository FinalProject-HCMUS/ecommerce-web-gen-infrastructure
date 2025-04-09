const express = require('express');
const app = express();

app.use(express.json());

app.post('/api/preview', (req, res) => {
    const code = req.body.code || {};
    // Placeholder: Simulate preview generation
    const preview = {
        message: "Preview placeholder",
        htmlSnippet: code.html || "No HTML provided",
        status: "Generated"
    };
    res.json({ preview });
});

app.listen(3000, () => {
    console.log('Preview service running on port 3000');
});