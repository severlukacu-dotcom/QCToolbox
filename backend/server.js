const express = require('express');
const { MongoClient } = require('mongodb');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Thay bằng connection string của bạn (nên dùng biến môi trường)
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://quocchienn:chien207@cluster0.0swxhya.mongodb.net/?appName=Cluster0';
const DB_NAME = 'qcvideo';

let db;

async function connectDB() {
  const client = new MongoClient(MONGO_URI);
  await client.connect();
  db = client.db(DB_NAME);
  console.log('Connected to MongoDB');
}

app.use(express.json());

// Upload video (lưu file local trên server, metadata vào MongoDB)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage });

// Đăng ký
app.post('/api/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password || username.length < 3) {
    return res.status(400).json({ error: 'Invalid input' });
  }
  const existing = await db.collection('users').findOne({ username });
  if (existing) return res.status(400).json({ error: 'User exists' });
  await db.collection('users').insertOne({ username, password, createdAt: new Date() });
  res.json({ success: true, username });
});

// Đăng nhập
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await db.collection('users').findOne({ username, password });
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  res.json({ success: true, username });
});

// Upload video
app.post('/api/videos', upload.single('video'), async (req, res) => {
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
});

// Lấy danh sách video
app.get('/api/videos', async (req, res) => {
  const videos = await db.collection('videos').find().sort({ createdAt: -1 }).toArray();
  res.json(videos);
});

// Serve video files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

connectDB().then(() => {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}).catch(err => {
  console.error('DB connection failed:', err);
  process.exit(1);
});
