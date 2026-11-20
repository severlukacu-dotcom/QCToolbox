const express = require('express');
const { MongoClient } = require('mongodb');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;
const DB_NAME = process.env.DB_NAME || 'qcvideo';

if (!MONGO_URI) {
  console.error('Missing MONGO_URI environment variable');
  process.exit(1);
}

let db;

async function connectDB() {
  const client = new MongoClient(MONGO_URI);
  await client.connect();
  db = client.db(DB_NAME);
  console.log('Connected to MongoDB');
}

app.use(express.json());

// Health check for Render
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'qc-video-backend' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.mp4';
    cb(null, Date.now() + '-' + Math.random().toString(36).slice(2) + ext);
  }
});
const upload = multer({ storage, limits: { fileSize: 100 * 1024 * 1024 } });

app.post('/api/register', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password || username.length < 3) {
      return res.status(400).json({ error: 'Invalid input' });
    }
    const existing = await db.collection('users').findOne({ username });
    if (existing) return res.status(400).json({ error: 'User exists' });
    await db.collection('users').insertOne({ username, password, createdAt: new Date() });
    res.json({ success: true, username });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await db.collection('users').findOne({ username, password });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    res.json({ success: true, username });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/videos', upload.single('video'), async (req, res) => {
  try {
    const { title, channel, description } = req.body;
    if (!req.file || !title) return res.status(400).json({ error: 'Missing data' });
    const video = {
      title,
      channel: channel || 'User',
      description: description || '',
      filename: req.file.filename,
      createdAt: new Date()
    };
    const result = await db.collection('videos').insertOne(video);
    res.json({ success: true, id: result.insertedId, ...video });
  } catch (err) {
    res.status(500).json({ error: 'Upload failed' });
  }
});

app.get('/api/videos', async (req, res) => {
  try {
    const videos = await db.collection('videos').find().sort({ createdAt: -1 }).toArray();
    res.json(videos);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

connectDB()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch(err => {
    console.error('DB connection failed:', err);
    process.exit(1);
  });
