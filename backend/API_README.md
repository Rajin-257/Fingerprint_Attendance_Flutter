# Educational Institute Management System API Documentation

This document provides information on how to use and test the API endpoints for the Educational Institute Management System.

## Setup

1. Make sure you have installed all required dependencies:
   ```
   cd backend
   npm install
   ```

2. Create a `.env` file in the backend directory with the following content:
   ```
   DB_HOST=localhost
   DB_USER=your_mysql_username
   DB_PASS=your_mysql_password
   DB_NAME=institute_management_system
   JWT_SECRET=your_secret_key
   PORT=3000
   LICENSE_KEY=DEMO-LICENSE-KEY-2025
   ```

3. Set up the database:
   ```
   npm run setup-db
   ```

4. Start the server:
   ```
   npm start
   ```

## Postman Setup

1. Download and install [Postman](https://www.postman.com/downloads/).
2. Create a new collection named "Institute Management System".
3. Set up environment variables for testing:
   - Create a new environment (e.g., "Development")
   - Add the following variables:
     - `baseUrl`: `http://localhost:3000/api`
     - `superAdminToken`: (leave empty for now)
     - `instituteToken`: (leave empty for now)
     - `teacherToken`: (leave empty for now)
     - `licenseKey`: `DEMO-LICENSE-KEY-2025`

## Authentication Testing

### 1. Super Admin Login

**Endpoint:** `POST {{baseUrl}}/auth/super-admin/login`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Post-request Script:**
```javascript
// Save the token to environment variables
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("superAdminToken", jsonData.data.token);
}
```

### 2. Create Institute (as Super Admin)

**Endpoint:** `POST {{baseUrl}}/super-admin/institutes`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{superAdminToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "name": "Sample Institute",
  "code": "SINST001",
  "email": "institute@example.com",
  "password": "password123",
  "address": "123 Education Street",
  "contactPerson": "John Doe",
  "contactNumber": "1234567890",
  "licenseExpiry": "2026-12-31"
}
```

### 3. Institute Login

**Endpoint:** `POST {{baseUrl}}/auth/institute/login`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "email": "institute@example.com",
  "password": "password123"
}
```

**Post-request Script:**
```javascript
// Save the token to environment variables
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("instituteToken", jsonData.data.token);
}
```

### 4. Create Teacher (as Institute)

**Endpoint:** `POST {{baseUrl}}/institutes/teachers`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{instituteToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "employeeId": "EMP001",
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "teacher@example.com",
  "password": "password123",
  "phone": "9876543210",
  "qualification": "Ph.D. in Computer Science",
  "joiningDate": "2023-01-01"
}
```

### 5. Teacher Login

**Endpoint:** `POST {{baseUrl}}/auth/teacher/login`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "email": "teacher@example.com",
  "password": "password123"
}
```

**Post-request Script:**
```javascript
// Save the token to environment variables
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("teacherToken", jsonData.data.token);
}
```

## Institute Management Testing

### 1. Create Department

**Endpoint:** `POST {{baseUrl}}/institutes/departments`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{instituteToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "name": "Computer Science",
  "code": "CS",
  "description": "Department of Computer Science and Engineering"
}
```

### 2. Create Section

**Endpoint:** `POST {{baseUrl}}/sections`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{instituteToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "name": "Section A",
  "code": "CS-A",
  "capacity": 40,
  "description": "Computer Science Section A",
  "departmentId": 1
}
```

### 3. Create Course

**Endpoint:** `POST {{baseUrl}}/courses`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{instituteToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "name": "Introduction to Programming",
  "code": "CS101",
  "description": "Basics of programming and algorithms",
  "creditHours": 3,
  "departmentId": 1,
  "sectionId": 1,
  "teacherId": 1,
  "schedule": {
    "day": "Monday",
    "startTime": "09:00",
    "endTime": "10:30"
  }
}
```

## Teacher-Student Management Testing

### 1. Create Student (as Teacher)

**Endpoint:** `POST {{baseUrl}}/teachers/students`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{teacherToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "registrationNumber": "2023CS001",
  "firstName": "Robert",
  "lastName": "Johnson",
  "email": "student@example.com",
  "dateOfBirth": "2000-05-15",
  "gender": "Male",
  "contactNumber": "5556667777",
  "address": "456 Student Housing",
  "departmentId": 1,
  "sectionId": 1,
  "courseIds": [1]
}
```

### 2. Take Attendance (as Teacher)

**Endpoint:** `POST {{baseUrl}}/teachers/attendance`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{teacherToken}}`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "studentId": 1,
  "courseId": 1,
  "date": "2023-06-01",
  "status": "Present",
  "timeIn": "09:05:00",
  "remarks": "On time",
  "fingerprintVerified": true
}
```

### 3. Get Attendance Report (as Teacher)

**Endpoint:** `GET {{baseUrl}}/teachers/attendance/report?courseId=1&startDate=2023-06-01&endDate=2023-06-30`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{teacherToken}}`

## Report Generation Testing

### 1. Get Attendance Statistics (as Institute)

**Endpoint:** `GET {{baseUrl}}/attendance/institute/statistics?departmentId=1&startDate=2023-06-01&endDate=2023-06-30`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{instituteToken}}`

### 2. Get Daily Attendance Summary (as Institute)

**Endpoint:** `GET {{baseUrl}}/attendance/institute/daily?date=2023-06-01`

**Headers:**
- `x-license-key`: `{{licenseKey}}`
- `Authorization`: `Bearer {{instituteToken}}`

## Common API Response Format

All API responses follow a standard format:

```json
{
  "success": true/false,
  "message": "Description of the response",
  "data": {
    // Response data...
  }
}
```

For errors:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

For validation errors:

```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    {
      "field": "fieldName",
      "message": "Field-specific error message"
    }
  ]
}
```

## Full API List

Here's a complete list of the API endpoints organized by user type:

### Authentication
- `POST /api/auth/super-admin/login` - Super Admin login
- `POST /api/auth/institute/login` - Institute login
- `POST /api/auth/teacher/login` - Teacher login

### Super Admin
- `POST /api/super-admin/institutes` - Create institute
- `GET /api/super-admin/institutes` - Get all institutes
- `GET /api/super-admin/institutes/:id` - Get institute by ID
- `PUT /api/super-admin/institutes/:id` - Update institute
- `DELETE /api/super-admin/institutes/:id` - Delete institute
- `GET /api/super-admin/profile` - Get super admin profile
- `PUT /api/super-admin/profile` - Update super admin profile
- `GET /api/super-admin/dashboard` - Get dashboard statistics

### Institute
- `POST /api/institutes/teachers` - Create teacher
- `GET /api/institutes/teachers` - Get all teachers
- `GET /api/institutes/teachers/:id` - Get teacher by ID
- `PUT /api/institutes/teachers/:id` - Update teacher
- `DELETE /api/institutes/teachers/:id` - Delete teacher
- `POST /api/institutes/departments` - Create department
- `GET /api/institutes/departments` - Get all departments
- `GET /api/institutes/profile` - Get institute profile
- `PUT /api/institutes/profile` - Update institute profile
- `GET /api/institutes/dashboard` - Get dashboard statistics

### Department
- `GET /api/departments/:id` - Get department by ID
- `PUT /api/departments/:id` - Update department
- `DELETE /api/departments/:id` - Delete department

### Section
- `POST /api/sections` - Create section
- `GET /api/sections` - Get all sections
- `GET /api/sections/:id` - Get section by ID
- `PUT /api/sections/:id` - Update section
- `DELETE /api/sections/:id` - Delete section

### Course
- `POST /api/courses` - Create course
- `GET /api/courses` - Get all courses
- `GET /api/courses/:id` - Get course by ID
- `PUT /api/courses/:id` - Update course
- `DELETE /api/courses/:id` - Delete course
- `POST /api/courses/:id/students` - Add students to course
- `DELETE /api/courses/:id/students` - Remove students from course
- `GET /api/courses/:id/students` - Get students in course

### Student
- `GET /api/students/institute` - Get all students (Institute)
- `GET /api/students/institute/:id` - Get student by ID (Institute)
- `PUT /api/students/institute/:id` - Update student (Institute)
- `DELETE /api/students/institute/:id` - Delete student (Institute)
- `GET /api/students/institute/attendance/report` - Get attendance report (Institute)

### Attendance
- `GET /api/attendance/institute` - Get attendance (Institute)
- `GET /api/attendance/institute/daily` - Get daily attendance summary (Institute)
- `GET /api/attendance/institute/statistics` - Get attendance statistics (Institute)
- `GET /api/attendance/teacher` - Get attendance (Teacher)
- `GET /api/attendance/teacher/daily` - Get daily attendance summary (Teacher)

### Teacher
- `POST /api/teachers/students` - Create student
- `GET /api/teachers/students` - Get all students
- `GET /api/teachers/students/:id` - Get student by ID
- `PUT /api/teachers/students/:id` - Update student
- `POST /api/teachers/attendance` - Take attendance
- `POST /api/teachers/attendance/sync` - Sync offline attendance
- `GET /api/teachers/attendance/report` - Get attendance report
- `GET /api/teachers/profile` - Get teacher profile
- `PUT /api/teachers/profile` - Update teacher profile
- `GET /api/teachers/dashboard` - Get dashboard statistics