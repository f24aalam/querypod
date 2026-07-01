CREATE DATABASE IF NOT EXISTS querypod_lab
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'querypod'@'%' IDENTIFIED WITH mysql_native_password BY 'querypod';
ALTER USER 'querypod'@'%' IDENTIFIED WITH mysql_native_password BY 'querypod';
GRANT ALL PRIVILEGES ON querypod_lab.* TO 'querypod'@'%';
FLUSH PRIVILEGES;

USE querypod_lab;
