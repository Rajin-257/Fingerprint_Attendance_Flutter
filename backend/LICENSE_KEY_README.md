# API License Key Authentication

## Problem: "Invalid license key" Error

If you're seeing this error:

```json
{
  "success": false,
  "message": "Invalid license key"
}
```

This means your API requests are missing the required license key header or using an incorrect license key.

## Solution

All API requests to this backend require a license key for authentication. This is implemented through the `checkLicenseKey` middleware.

### How to Include the License Key

For all API requests, you must include the `x-license-key` header with the correct license key value.

```javascript
// Example using fetch
fetch('http://localhost:3000/api/auth/super-admin/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-license-key': 'DEMO-LICENSE-KEY-2025' // This must match the value in your .env file
  },
  body: JSON.stringify({
    username: 'admin',
    password: 'password'
  })
})
```

### Using Axios

If you're using Axios, you can set up a default instance with the license key:

```javascript
const axios = require('axios');

const apiClient = axios.create({
  baseURL: 'http://localhost:3000',
  headers: {
    'Content-Type': 'application/json',
    'x-license-key': 'DEMO-LICENSE-KEY-2025' // This must match the value in your .env file
  }
});

// Now use apiClient for all requests
apiClient.post('/api/auth/super-admin/login', {
  username: 'admin',
  password: 'password'
});
```

## License Key Configuration

The license key is configured in the `.env` file with the variable `LICENSE_KEY`. The default value is `DEMO-LICENSE-KEY-2025` as specified in `auth.config.js`.

If you want to change the license key:

1. Update the `LICENSE_KEY` value in your `.env` file
2. Make sure to use the same value in your API requests

## Example Client

A complete example client implementation is available in the `client-example.js` file. You can run it with:

```bash
npm install axios  # If you don't have axios installed
node client-example.js
```

## Authentication Flow

1. Include the license key header in all requests
2. For protected endpoints, you also need to include a JWT token
3. To get a JWT token, first login using one of the auth endpoints
4. Include the token in subsequent requests using the `Authorization: Bearer <token>` header

Remember: The license key check happens before any other authentication, so it's required for all endpoints including login.