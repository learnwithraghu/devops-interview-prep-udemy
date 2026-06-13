const express = require('express');
const redis = require('redis');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

// Config
const redisHost = process.env.REDIS_HOST || 'redis';
const redisPort = process.env.REDIS_PORT || 6379;
const dbPassword = process.env.DB_PASSWORD || 'default_secret';

// Redis Client
const client = redis.createClient({
    url: `redis://${redisHost}:${redisPort}`
});

client.on('error', (err) => console.log('Redis Client Error', err));

app.get('/', async (req, res) => {
    res.send('Docker Debug API is running!');
});

// Scenario 06: Memory Leak Trigger
const memoryLeakArray = [];
app.get('/leak', (req, res) => {
    console.log('Triggering memory leak...');
    for (let i = 0; i < 100000; i++) {
        memoryLeakArray.push(new Array(10000).join('x'));
    }
    res.send('Leaking memory!');
});

// Scenario 10: Disk Write Trigger
app.get('/log-spam', (req, res) => {
    console.log('Writing to local disk...');
    const data = new Array(100000).join('DEBUG LOG DATA LINE\n');
    fs.appendFileSync('/app/debug.log', data);
    res.send('Wrote massively to local disk layer!');
});

async function start() {
    try {
        await client.connect();
        console.log('Connected to Redis!');
    } catch (e) {
        console.error('Failed to connect to Redis on startup');
    }
    
    app.listen(port, () => {
        console.log(`App listening on port ${port}`);
        console.log(`Using DB Password: ${dbPassword}`); // For scenario 09
    });
}

start();
