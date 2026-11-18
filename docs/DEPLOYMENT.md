# Deployment & Environment Configuration Guide

**Project:** P_174 — Occupational Safety & Health Monitoring System  
**Document Ref:** `docs/DEPLOYMENT.md`

---

## 1. System Requirements

### Production / Development Host:
* **Operating System:** Windows 10/11, Ubuntu 22.04 LTS, or macOS 12+
* **Java Runtime:** OpenJDK 17 or 21
* **Node.js:** Node.js 18+ (tested with v26) & npm 10+
* **PostgreSQL:** Version 14, 15, or 16
* **MQTT Broker:** Eclipse Mosquitto or HiveMQ Cloud / Community Edition
* **(Optional) Docker:** Docker Desktop 4.20+ with Docker Compose v2

---

## 2. Docker Compose Deployment (Recommended for Local Dev)

The repository provides a `docker-compose.yml` to launch the entire ecosystem with a single command:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: safety_postgres
    environment:
      POSTGRES_DB: safety_wearable_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgrespassword
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backend/src/main/resources/schema.sql:/docker-entrypoint-initdb.d/init.sql

  mosquitto:
    image: eclipse-mosquitto:2.0
    container_name: safety_mqtt
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config

  backend:
    build: ./backend
    container_name: safety_backend
    depends_on:
      - postgres
      - mosquitto
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/safety_wearable_db
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgrespassword
      MQTT_BROKER_URL: tcp://mosquitto:1883
    ports:
      - "8080:8080"

  frontend:
    build: ./frontend
    container_name: safety_frontend
    depends_on:
      - backend
    ports:
      - "3000:80"

volumes:
  pgdata:
```

---

## 3. Manual Native Deployment

### Step A: PostgreSQL Database
1. Launch PostgreSQL and connect using `psql` or pgAdmin.
2. Create database:
   ```sql
   CREATE DATABASE safety_wearable_db;
   ```
3. Run DDL script from `backend/src/main/resources/schema.sql`.

### Step B: MQTT Broker
* **Local:** Install Eclipse Mosquitto or run `mosquitto -p 1883`.
* **Cloud (HiveMQ):** Create a free HiveMQ Cloud cluster; note the cluster URL, TLS port (8883), and credentials.

### Step C: Java Spring Boot Backend
1. Configure `backend/src/main/resources/application.properties` or set environment variables:
   ```bash
   export DB_HOST=localhost
   export DB_PORT=5432
   export DB_NAME=safety_wearable_db
   export DB_USER=postgres
   export DB_PASSWORD=your_password
   export MQTT_BROKER_URL=tcp://localhost:1883
   ```
2. Build and launch:
   ```bash
   mvn clean spring-boot:run
   ```
   Backend listens at `http://localhost:8080`.

### Step D: React Frontend
1. Navigate to `frontend/`:
   ```bash
   cd frontend
   npm install
   npm run dev
   ```
2. Frontend opens at `http://localhost:5173` (or configured port).

### Step E: ESP32 Wearable Node
1. Open `firmware/SafetyWearable_MQTT/SafetyWearable_MQTT.ino` in Arduino IDE.
2. Configure Wi-Fi SSID/password and MQTT Broker IP.
3. Select board `ESP32 Dev Module`, compile, and flash via USB.

---

## 4. Netlify Frontend + Render Backend

The repository includes a root `netlify.toml` and `render.yaml` for the frontend and backend deployments. The Render Blueprint creates the Spring Boot web service and PostgreSQL database. The MQTT broker remains external; use a hosted broker such as HiveMQ Cloud and enter its connection details in Render.

### Deploy the backend to Render

1. Push this repository to GitHub and create a new Blueprint in the Render Dashboard using that repository and its root `render.yaml`.
2. During Blueprint setup, provide `MQTT_BROKER_URL` (for example, the hosted broker's TLS URL), `MQTT_USERNAME`, `MQTT_PASSWORD`, and `CORS_ALLOWED_ORIGINS`. The CORS value must be the exact Netlify site origin, such as `https://your-site.netlify.app`; update it in the Render service environment after creating the Netlify site.
3. Wait for the backend health check at `/api/dashboard/summary` to pass. Copy the service URL, for example `https://safety-wearable-api.onrender.com`.

### Deploy the frontend to Netlify

1. Create a Netlify site from the same GitHub repository. The root `netlify.toml` sets the build base to `frontend`, runs `npm run build`, publishes `dist`, and enables SPA routing.
2. In the Netlify site environment variables, set `VITE_API_BASE_URL` to the Render URL plus `/api`, for example `https://safety-wearable-api.onrender.com/api`, then trigger a new deploy.
3. Copy the Netlify site origin and set it as `CORS_ALLOWED_ORIGINS` in Render, then redeploy the backend.

The free Render web service may sleep when idle, and the free Render PostgreSQL plan is temporary. Use paid plans for continuous availability and durable production data. Never commit database or MQTT credentials to the repository.
