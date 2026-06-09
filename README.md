# HEALTH DATA ANALYTICS & PERFORMANCE MONITORING SYSTEM (HDAPMS)

## Overview

HDAPMS is an enterprise-grade web application designed for Ministries of Health, Regional Health Bureaus, Zonal Health Offices, Woreda Health Offices, Public and Private Health Facilities, NGOs, and International Organizations.

## Features

### Core Modules
- **Health Data Collection**: Professional forms with validation and bulk upload
- **Data Management**: Hierarchical organization structure with recursive access control
- **Indicator Management**: Support for percentages, ratios, counts, and composite indicators
- **Performance Monitoring**: Real-time tracking and achievement monitoring
- **Analytics**: Trend analysis, gap analysis, forecasting, and benchmarking
- **Reporting**: PDF, Excel, and PowerPoint report generation
- **Dashboard Visualization**: Executive dashboards with KPI cards and charts
- **Decision Support**: Data-driven insights and recommendations

### Technology Stack

**Frontend:**
- Next.js 15
- React
- TypeScript
- Tailwind CSS
- ShadCN UI
- Recharts
- React Query
- Leaflet/Mapbox (GIS)

**Backend:**
- NestJS
- TypeScript
- PostgreSQL
- JWT Authentication
- RBAC Authorization

**Deployment:**
- Docker & Docker Compose
- Nginx
- Cloud-ready (AWS, Azure, Google Cloud)

## Organizational Hierarchy

```
National
├── Region
│   ├── Zone
│   │   ├── Woreda
│   │   │   ├── Health Facility
│   │   │   │   ├── Department
```

Users access only their own level and lower levels.

## User Roles

1. **Super Admin** - Complete system access
2. **National Admin** - National level management
3. **Regional Admin** - Regional level management
4. **Zone Admin** - Zonal level management
5. **Woreda Admin** - Woreda level management
6. **Facility User** - Data entry and facility management
7. **Data Analyst** - Analytics and reporting
8. **Viewer** - Read-only access
9. **Auditor** - Audit trail access

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+
- PostgreSQL 14+

### Development Setup

```bash
# Clone the repository
git clone https://github.com/Addisuu/HDAPMS.git
cd HDAPMS

# Copy environment file
cp .env.example .env

# Start services with Docker Compose
docker-compose up -d

# Backend will be available at http://localhost:3000
# Frontend will be available at http://localhost:3001
# PostgreSQL will be available at localhost:5432
```

### Manual Setup

#### Backend
```bash
cd backend
npm install
npm run migration:run
npm run seed:run
npm run start:dev
```

#### Frontend
```bash
cd frontend
npm install
npm run dev
```

## Project Structure

```
HDAPMS/
├── backend/                 # NestJS Backend
├── frontend/                # Next.js Frontend
├── database/                # PostgreSQL Schema
├── deployment/              # Deployment Guides
├── docker-compose.yml       # Multi-container setup
├── nginx.conf              # Nginx configuration
└── README.md
```

## Security Features

- ✅ JWT Authentication with Refresh Tokens
- ✅ Role-Based Access Control (RBAC)
- ✅ Password Hashing (bcrypt)
- ✅ Session Timeout Management
- ✅ API Rate Limiting
- ✅ CSRF Protection
- ✅ Secure Headers
- ✅ OWASP Best Practices

## API Documentation

Full Swagger/OpenAPI documentation available at:
- **Development**: `http://localhost:3000/api/docs`

## License

Enterprise License - Proprietary Software

---

**Version**: 1.0.0  
**Status**: Development