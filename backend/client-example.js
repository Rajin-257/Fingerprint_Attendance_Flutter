// Example client code to demonstrate how to make API requests with the license key
const axios = require('axios');

// Configuration
const API_BASE_URL = 'http://localhost:3000';
const LICENSE_KEY = 'DEMO-LICENSE-KEY-2025'; // This should match the value in your .env file

// Create axios instance with default headers
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'x-license-key': LICENSE_KEY // This header is required for all API requests
  }
});

// Example: Super Admin login
async function loginSuperAdmin() {
  try {
    const response = await apiClient.post('/api/auth/super-admin/login', {
      username: 'admin', // Replace with your actual username
      password: 'password' // Replace with your actual password
    });
    
    console.log('Login successful:', response.data);
    
    // Store the token for future requests
    const token = response.data.token;
    
    // Update headers with the token for authenticated requests
    apiClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    
    return token;
  } catch (error) {
    console.error('Login failed:', error.response ? error.response.data : error.message);
    throw error;
  }
}

// Example: Get all institutes (requires authentication)
async function getAllInstitutes() {
  try {
    const response = await apiClient.get('/api/super-admin/institutes');
    console.log('Institutes:', response.data);
    return response.data;
  } catch (error) {
    console.error('Failed to get institutes:', error.response ? error.response.data : error.message);
    throw error;
  }
}

// Example usage
async function main() {
  try {
    // First login to get the token
    await loginSuperAdmin();
    
    // Then make authenticated requests
    await getAllInstitutes();
    
  } catch (error) {
    console.error('Error in main function:', error.message);
  }
}

// Uncomment to run the example
// main();

/*
  IMPORTANT: How to use this example
  
  1. Make sure your server is running
  2. Install axios if not already installed: npm install axios
  3. Run this file: node client-example.js
  
  Common issues:
  - If you get "Invalid license key" error, make sure the LICENSE_KEY here matches the one in your .env file
  - For all API requests, you must include the 'x-license-key' header
  - After login, include the 'Authorization' header with the JWT token for authenticated endpoints
*/