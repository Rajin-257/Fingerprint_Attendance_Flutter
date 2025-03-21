-- Create the database
CREATE DATABASE IF NOT EXISTS institute_management_system;
USE institute_management_system;

-- Create super_admins table
CREATE TABLE IF NOT EXISTS super_admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  fullName VARCHAR(100) NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  lastLogin DATETIME,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create institutes table
CREATE TABLE IF NOT EXISTS institutes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  address VARCHAR(200),
  contactPerson VARCHAR(100),
  contactNumber VARCHAR(20),
  licenseExpiry DATE,
  active BOOLEAN DEFAULT TRUE,
  lastLogin DATETIME,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  createdBy INT,
  FOREIGN KEY (createdBy) REFERENCES super_admins(id)
);

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(20) NOT NULL,
  description TEXT,
  active BOOLEAN DEFAULT TRUE,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  instituteId INT NOT NULL,
  FOREIGN KEY (instituteId) REFERENCES institutes(id),
  UNIQUE KEY unique_dept_code_per_institute (code, instituteId)
);

-- Create sections table
CREATE TABLE IF NOT EXISTS sections (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(20) NOT NULL,
  capacity INT DEFAULT 50,
  description TEXT,
  active BOOLEAN DEFAULT TRUE,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  departmentId INT NOT NULL,
  instituteId INT NOT NULL,
  FOREIGN KEY (departmentId) REFERENCES departments(id),
  FOREIGN KEY (instituteId) REFERENCES institutes(id),
  UNIQUE KEY unique_section_code_per_dept (code, departmentId)
);

-- Create teachers table
CREATE TABLE IF NOT EXISTS teachers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employeeId VARCHAR(50) NOT NULL,
  firstName VARCHAR(50) NOT NULL,
  lastName VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  qualification VARCHAR(100),
  joiningDate DATE,
  fingerprint TEXT COMMENT 'Encrypted fingerprint data of the teacher',
  deviceId VARCHAR(100) COMMENT 'Unique identifier for the teacher\'s device',
  active BOOLEAN DEFAULT TRUE,
  lastLogin DATETIME,
  lastSync DATETIME COMMENT 'Last time teacher data was synced with server',
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  instituteId INT NOT NULL,
  FOREIGN KEY (instituteId) REFERENCES institutes(id),
  UNIQUE KEY unique_employee_id_per_institute (employeeId, instituteId)
);

-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(20) NOT NULL,
  description TEXT,
  creditHours FLOAT DEFAULT 3.0,
  schedule JSON COMMENT 'JSON object containing course schedule information',
  active BOOLEAN DEFAULT TRUE,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  instituteId INT NOT NULL,
  departmentId INT NOT NULL,
  sectionId INT NOT NULL,
  teacherId INT,
  FOREIGN KEY (instituteId) REFERENCES institutes(id),
  FOREIGN KEY (departmentId) REFERENCES departments(id),
  FOREIGN KEY (sectionId) REFERENCES sections(id),
  FOREIGN KEY (teacherId) REFERENCES teachers(id),
  UNIQUE KEY unique_course_per_section_dept (code, sectionId, departmentId)
);

-- Create students table
CREATE TABLE IF NOT EXISTS students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  registrationNumber VARCHAR(50) NOT NULL,
  firstName VARCHAR(50) NOT NULL,
  lastName VARCHAR(50) NOT NULL,
  email VARCHAR(100),
  dateOfBirth DATE,
  gender ENUM('Male', 'Female', 'Other'),
  contactNumber VARCHAR(20),
  address TEXT,
  fingerprint TEXT COMMENT 'Encrypted fingerprint data of the student',
  active BOOLEAN DEFAULT TRUE,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  instituteId INT NOT NULL,
  departmentId INT NOT NULL,
  sectionId INT NOT NULL,
  addedBy INT NOT NULL,
  FOREIGN KEY (instituteId) REFERENCES institutes(id),
  FOREIGN KEY (departmentId) REFERENCES departments(id),
  FOREIGN KEY (sectionId) REFERENCES sections(id),
  FOREIGN KEY (addedBy) REFERENCES teachers(id),
  UNIQUE KEY unique_reg_number_per_institute (registrationNumber, instituteId)
);

-- Create student_courses table (junction table for many-to-many relationship)
CREATE TABLE IF NOT EXISTS student_courses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  enrollmentDate DATE DEFAULT (CURRENT_DATE),
  status ENUM('Active', 'Dropped', 'Completed') DEFAULT 'Active',
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  studentId INT NOT NULL,
  courseId INT NOT NULL,
  FOREIGN KEY (studentId) REFERENCES students(id),
  FOREIGN KEY (courseId) REFERENCES courses(id),
  UNIQUE KEY unique_student_course (studentId, courseId)
);

-- Create attendance table
CREATE TABLE IF NOT EXISTS attendance (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date DATE NOT NULL,
  status ENUM('Present', 'Late', 'Absent') NOT NULL,
  timeIn TIME,
  remarks TEXT,
  fingerprintVerified BOOLEAN DEFAULT FALSE,
  verified BOOLEAN DEFAULT FALSE,
  syncedFromOffline BOOLEAN DEFAULT FALSE,
  offlineId VARCHAR(100) COMMENT 'ID used in offline mode before syncing',
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  studentId INT NOT NULL,
  courseId INT NOT NULL,
  teacherId INT NOT NULL,
  instituteId INT NOT NULL,
  FOREIGN KEY (studentId) REFERENCES students(id),
  FOREIGN KEY (courseId) REFERENCES courses(id),
  FOREIGN KEY (teacherId) REFERENCES teachers(id),
  FOREIGN KEY (instituteId) REFERENCES institutes(id),
  INDEX attendance_date_student_course_idx (date, studentId, courseId),
  INDEX attendance_teacher_date_idx (teacherId, date)
);

-- Insert initial super admin
INSERT INTO super_admins (username, email, password, fullName, active)
VALUES ('admin', 'admin@example.com', '$2a$10$JwYO/6Jb6CTxg69MIgChzOkH0QhbLdPj9IoifV2O1X2vj7YM0eLX.', 'System Administrator', TRUE);
-- Password: admin123

-- Insert sample institute
INSERT INTO institutes (name, code, email, password, address, contactPerson, contactNumber, licenseExpiry, active, createdBy)
VALUES (
  'Demo Institute', 
  'DEMO001', 
  'demo@example.com', 
  '$2a$10$JwYO/6Jb6CTxg69MIgChzOkH0QhbLdPj9IoifV2O1X2vj7YM0eLX.', 
  '123 Education Street, Demo City', 
  'John Doe', 
  '1234567890', 
  '2025-12-31', 
  TRUE, 
  1
);
-- Password: admin123

-- Insert sample departments
INSERT INTO departments (name, code, description, active, instituteId)
VALUES 
('Computer Science', 'CS', 'Department of Computer Science and Engineering', TRUE, 1),
('Electrical Engineering', 'EE', 'Department of Electrical Engineering', TRUE, 1),
('Business Administration', 'BA', 'Department of Business Administration', TRUE, 1);

-- Insert sample sections
INSERT INTO sections (name, code, capacity, description, active, departmentId, instituteId)
VALUES 
('Section A', 'CS-A', 40, 'Computer Science Section A', TRUE, 1, 1),
('Section B', 'CS-B', 45, 'Computer Science Section B', TRUE, 1, 1),
('Section A', 'EE-A', 35, 'Electrical Engineering Section A', TRUE, 2, 1),
('Section A', 'BA-A', 50, 'Business Administration Section A', TRUE, 3, 1);

-- Insert sample teacher
INSERT INTO teachers (employeeId, firstName, lastName, email, password, phone, qualification, joiningDate, active, instituteId)
VALUES 
('EMP001', 'Jane', 'Smith', 'teacher1@example.com', '$2a$10$JwYO/6Jb6CTxg69MIgChzOkH0QhbLdPj9IoifV2O1X2vj7YM0eLX.', '9876543210', 'Ph.D. in Computer Science', '2023-01-01', TRUE, 1),
('EMP002', 'Robert', 'Johnson', 'teacher2@example.com', '$2a$10$JwYO/6Jb6CTxg69MIgChzOkH0QhbLdPj9IoifV2O1X2vj7YM0eLX.', '8765432109', 'M.Sc. in Electrical Engineering', '2023-02-15', TRUE, 1),
('EMP003', 'Emily', 'Davis', 'teacher3@example.com', '$2a$10$JwYO/6Jb6CTxg69MIgChzOkH0QhbLdPj9IoifV2O1X2vj7YM0eLX.', '7654321098', 'MBA in Finance', '2023-03-01', TRUE, 1);
-- Password: admin123

-- Insert sample courses
INSERT INTO courses (name, code, description, creditHours, active, instituteId, departmentId, sectionId, teacherId)
VALUES 
('Introduction to Programming', 'CS101', 'Basics of programming and algorithms', 3.0, TRUE, 1, 1, 1, 1),
('Data Structures', 'CS201', 'Study of data structures and algorithms', 4.0, TRUE, 1, 1, 1, 1),
('Database Systems', 'CS301', 'Design and implementation of database systems', 3.0, TRUE, 1, 1, 2, 1),
('Circuit Theory', 'EE101', 'Introduction to electrical circuits', 3.0, TRUE, 1, 2, 3, 2),
('Principles of Management', 'BA101', 'Introduction to management principles', 3.0, TRUE, 1, 3, 4, 3);

-- Insert sample students
INSERT INTO students (registrationNumber, firstName, lastName, email, dateOfBirth, gender, contactNumber, active, instituteId, departmentId, sectionId, addedBy)
VALUES 
('2023CS001', 'Alex', 'Wilson', 'student1@example.com', '2000-05-15', 'Male', '5556667777', TRUE, 1, 1, 1, 1),
('2023CS002', 'Sophia', 'Garcia', 'student2@example.com', '2001-08-22', 'Female', '4445556666', TRUE, 1, 1, 1, 1),
('2023CS003', 'Oliver', 'Brown', 'student3@example.com', '2000-11-10', 'Male', '3334445555', TRUE, 1, 1, 2, 1),
('2023EE001', 'Emma', 'Martinez', 'student4@example.com', '2001-02-28', 'Female', '2223334444', TRUE, 1, 2, 3, 2),
('2023BA001', 'Noah', 'Lee', 'student5@example.com', '2000-07-19', 'Male', '1112223333', TRUE, 1, 3, 4, 3);

-- Insert student course enrollments
INSERT INTO student_courses (studentId, courseId, enrollmentDate, status)
VALUES 
(1, 1, '2023-09-01', 'Active'),
(1, 2, '2023-09-01', 'Active'),
(2, 1, '2023-09-01', 'Active'),
(2, 2, '2023-09-01', 'Active'),
(3, 3, '2023-09-01', 'Active'),
(4, 4, '2023-09-01', 'Active'),
(5, 5, '2023-09-01', 'Active');

-- Insert sample attendance records
INSERT INTO attendance (date, status, timeIn, fingerprintVerified, verified, studentId, courseId, teacherId, instituteId)
VALUES 
-- CS101 attendance for two days
('2023-09-05', 'Present', '09:00:00', TRUE, TRUE, 1, 1, 1, 1),
('2023-09-05', 'Present', '09:05:00', TRUE, TRUE, 2, 1, 1, 1),
('2023-09-07', 'Present', '09:02:00', TRUE, TRUE, 1, 1, 1, 1),
('2023-09-07', 'Late', '09:20:00', TRUE, TRUE, 2, 1, 1, 1),

-- CS201 attendance for one day
('2023-09-06', 'Present', '11:00:00', TRUE, TRUE, 1, 2, 1, 1),
('2023-09-06', 'Absent', NULL, FALSE, TRUE, 2, 2, 1, 1),

-- CS301 attendance
('2023-09-05', 'Present', '14:00:00', TRUE, TRUE, 3, 3, 1, 1),

-- EE101 attendance
('2023-09-05', 'Present', '10:00:00', TRUE, TRUE, 4, 4, 2, 1),

-- BA101 attendance
('2023-09-05', 'Present', '13:00:00', TRUE, TRUE, 5, 5, 3, 1);