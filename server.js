const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const axios = require('axios');
const WebSocket = require('ws');

const app = express();
const port = 3000;
const saltRounds = 10;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// WebSocket server
const wss = new WebSocket.Server({ port: 8080 });

let connectedClients = [];

wss.on('connection', (ws) => {
  console.log('New client connected');
  connectedClients.push(ws);

  ws.on('close', () => {
    console.log('Client disconnected');
    connectedClients = connectedClients.filter(client => client !== ws);
  });
});

// Broadcast function to send messages to all connected clients
function broadcast(data) {
  connectedClients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
}

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/emergency', { useNewUrlParser: true, useUnifiedTopology: true });

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function () {
  console.log('Connected to MongoDB');
});

// User schema
const userSchema = new mongoose.Schema({
  name: String,
  age: Number,
  phoneNumber: String,
  email: String,
  password: String,
  city: String,
  state: String,
  medicalHistory: String,
  isPrivateCommunity: Boolean,
  isPublicCommunity: Boolean,
});

const User = mongoose.model('User', userSchema);

// Community user schema with location as GeoJSON
const communityUserSchema = new mongoose.Schema({
  email: String,
  name: String,
  phoneNumber: String,
  location: {
    type: { type: String, default: 'Point' },
    coordinates: [Number],
  },
  communityName: String,
});

communityUserSchema.index({ location: '2dsphere' });

const CommunityUser = mongoose.model('CommunityUser', communityUserSchema);

// Private community schema
const privateCommunitySchema = new mongoose.Schema({
  communityName: String,
  members: [String], // Array of email addresses
});

const PrivateCommunity = mongoose.model('PrivateCommunity', privateCommunitySchema);

// User signup
app.post('/signup', async (req, res) => {
  const { email, password } = req.body;
  const existingUser = await User.findOne({ email });

  if (existingUser) {
    return res.status(400).json({ message: 'User already exists' });
  }

  const hashedPassword = await bcrypt.hash(password, saltRounds);
  const user = new User({ ...req.body, password: hashedPassword });
  await user.save();
  res.status(201).json({ message: 'User signed up' });
});

// Save medical details
app.post('/saveMedicalDetails', async (req, res) => {
  const { email, city, state, medicalHistory, isPrivateCommunity, isPublicCommunity } = req.body;
  const user = await User.findOne({ email });

  if (!user) {
    return res.status(400).json({ message: 'User not found' });
  }

  user.city = city;
  user.state = state;
  user.medicalHistory = medicalHistory;
  user.isPrivateCommunity = isPrivateCommunity;
  user.isPublicCommunity = isPublicCommunity;

  await user.save();
  res.status(200).json({ message: 'Medical details saved' });
});

// Save community user info
// Save community user info
app.post('/saveUserInfo', async (req, res) => {
  const { email, name, phoneNumber, location, communityName } = req.body;

  console.log("Received /saveUserInfo body:", req.body);

  let coordinates = null;

  // Support both { coordinates: [lng, lat] } and { lat, lng }
  if (location && Array.isArray(location.coordinates) && location.coordinates.length === 2) {
    coordinates = [location.coordinates[0], location.coordinates[1]];
  } else if (location && typeof location.lat === 'number' && typeof location.lng === 'number') {
    coordinates = [location.lng, location.lat];
  } else {
    return res.status(400).json({
      message: 'Invalid or missing location. Expected { coordinates: [lng, lat] } or { lat, lng }.',
    });
  }

  const newCommunityUser = new CommunityUser({
    email,
    name,
    phoneNumber,
    location: {
      type: 'Point',
      coordinates,
    },
    communityName,
  });

  try {
    await newCommunityUser.save();
    res.status(200).json({ message: 'User info saved for community' });
  } catch (error) {
    console.error('Error saving community user info:', error);
    res.status(500).json({ message: 'Failed to save user info' });
  }
});


// User signin
app.post('/signin', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  const user = await User.findOne({ email });

  if (!user) {
    return res.status(400).json({ message: 'Invalid credentials' });
  }

  const match = await bcrypt.compare(password, user.password);

  if (!match) {
    return res.status(400).json({ message: 'Invalid credentials' });
  }

  res.status(200).json({ message: 'User signed in', name: user.name, isPublicCommunity: user.isPublicCommunity, isPrivateCommunity: user.isPrivateCommunity });
});

// Get all users
app.get('/users', async (req, res) => {
  const users = await User.find();
  res.status(200).json(users);
});

// Get user details
app.post('/getUserDetails', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });

  if (!user) {
    return res.status(400).json({ message: 'User not found' });
  }

  res.status(200).json(user);
});

// Emergency endpoint to get location and notify nearest community members with a delay
app.post('/emergency', async (req, res) => {
  const wifiData = req.body.wifiAccessPoints;
  console.log('Received Wi-Fi data:', wifiData);

  const googleApiKey = 'AIzaSyCaeuDNhkBe6k5xVV43gNucvYdDLdlsiJ8'; // Replace with your actual Google API key
  const googleGeolocationUrl = `https://www.googleapis.com/geolocation/v1/geolocate?key=${googleApiKey}`;

  try {
    // Add a 5-second delay before making the request to Google Geolocation API
    setTimeout(async () => {
      // Get the user's location from Google Geolocation API
      const response = await axios.post(googleGeolocationUrl, { wifiAccessPoints: wifiData });
      const location = response.data.location;
      console.log('Location:', location);

      // Find the nearest community members
      const nearestMembers = await CommunityUser.find({
        location: {
          $near: {
            $geometry: { type: 'Point', coordinates: [location.lng, location.lat] },
            $maxDistance: 5000, // 5 km radius
          },
        },
      });

      console.log('Nearest members:', nearestMembers);

      // Notify the nearest community members via WebSocket
      const notification = {
        type: 'emergency',
        location,
        nearestMembers,
      };

      broadcast(notification);

      res.json({ location, nearestMembers });
    }, 5000); // 5-second delay

  } catch (error) {
    console.error('Error while getting location or finding nearest members:', error);
    res.status(500).send('Failed to process the request');
  }
});

// Check membership status
app.post('/checkMembership', async (req, res) => {
  const { email, communityName } = req.body;

  try {
    const communityUser = await CommunityUser.findOne({ email, communityName });

    if (communityUser) {
      res.status(200).json({ isMember: true });
    } else {
      res.status(200).json({ isMember: false });
    }
  } catch (error) {
    console.error('Error checking membership:', error);
    res.status(500).json({ message: 'Failed to check membership' });
  }
});

// Get community members by community name
app.post('/communityMembers', async (req, res) => {
  const { communityName } = req.body;

  try {
    const members = await CommunityUser.find({ communityName });
    res.status(200).json(members);
  } catch (error) {
    console.error('Error fetching community members:', error);
    res.status(500).json({ message: 'Failed to fetch community members' });
  }
});

// Create a new private community
app.post('/createPrivateCommunity', async (req, res) => {
  const { communityName, email } = req.body;

  try {
    // Check if the community already exists
    const existingCommunity = await PrivateCommunity.findOne({ communityName });

    if (existingCommunity) {
      return res.status(400).json({ message: 'Private community already exists' });
    }

    // Create a new private community
    const privateCommunity = new PrivateCommunity({
      communityName,
      members: [email], // Initialize with the creator as the first member
    });

    await privateCommunity.save();
    res.status(201).json({ message: 'Private community created' });
  } catch (error) {
    console.error('Error creating private community:', error);
    res.status(500).json({ message: 'Failed to create private community' });
  }
});

// Add members to a private community
app.post('/savePrivateCommunityInfo', async (req, res) => {
  const { communityName, members } = req.body;

  try {
    const privateCommunity = await PrivateCommunity.findOne({ communityName });

    if (!privateCommunity) {
      return res.status(400).json({ message: 'Private community not found' });
    }

    // Add the new members to the community
    privateCommunity.members.push(...members);

    await privateCommunity.save();
    res.status(200).json({ message: 'Private community members added' });
  } catch (error) {
    console.error('Error saving private community members:', error);
    res.status(500).json({ message: 'Failed to save private community members' });
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
