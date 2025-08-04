# NutriPlan System - Professional Deployment Diagram

## 🏗️ System Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              NUTRIPLAN DEPLOYMENT DIAGRAM                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           CLIENT DEVICES                                   │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    MOBILE DEVICES                                   │   │   │
│  │  │                                                                     │   │   │
│  │  │ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐ │   │   │
│  │  │ │   Android       │ │   iOS Device    │ │   Cross-Platform        │ │   │   │
│  │  │ │   Device        │ │                 │ │   Flutter App           │ │   │   │
│  │  │ │                 │ │                 │ │                         │ │   │   │
│  │  │ │ Artifacts:      │ │ Artifacts:      │ │ Artifacts:              │ │   │   │
│  │  │ │ • main.dart     │ │ • main.dart     │ │ • main.dart             │ │   │   │
│  │  │ │ • home_page.dart│ │ • home_page.dart│ │ • home_page.dart        │ │   │   │
│  │  │ │ • login_screen.dart│ • login_screen.dart│ • login_screen.dart   │ │   │   │
│  │  │ │ • recipe_service.dart│ • recipe_service.dart│ • recipe_service.dart│ │   │   │
│  │  │ │ • supabase_flutter│ • supabase_flutter│ • supabase_flutter      │ │   │   │
│  │  │ │ • fl_chart      │ │ • fl_chart      │ │ • fl_chart              │ │   │   │
│  │  │ │ • image_picker  │ │ • image_picker  │ │ • image_picker          │ │   │   │
│  │  │ └─────────────────┘ └─────────────────┘ └─────────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                   DESKTOP DEVICES                                  │   │   │
│  │  │                                                                     │   │   │
│  │  │ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐ │   │   │
│  │  │ │   Windows       │ │   macOS         │ │   Linux                 │ │   │   │
│  │  │ │   Desktop       │ │   Desktop       │ │   Desktop               │ │   │   │
│  │  │ │                 │ │                 │ │                         │ │   │   │
│  │  │ │ Artifacts:      │ │ Artifacts:      │ │ Artifacts:              │ │   │   │
│  │  │ │ • main.dart     │ │ • main.dart     │ │ • main.dart             │ │   │   │
│  │  │ │ • home_page.dart│ │ • home_page.dart│ │ • home_page.dart        │ │   │   │
│  │  │ │ • path_provider │ │ • path_provider │ │ • path_provider         │ │   │   │
│  │  │ │ • fl_chart      │ │ • fl_chart      │ │ • fl_chart              │ │   │   │
│  │  │ │ • supabase_flutter│ • supabase_flutter│ • supabase_flutter      │ │   │   │
│  │  │ └─────────────────┘ └─────────────────┘ └─────────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                               │
│                                    │ HTTPS/REST API                                │
│                                    ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                        SUPABASE CLOUD SERVER                               │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    BACKEND SERVICES                                 │   │   │
│  │  │                                                                     │   │   │
│  │  │ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐ │   │   │
│  │  │ │   Database      │ │   Authentication│ │   Storage Service       │ │   │   │
│  │  │ │   Layer         │ │   Service       │ │                         │ │   │   │
│  │  │ │                 │ │                 │ │                         │ │   │   │
│  │  │ │ Artifacts:      │ │ Artifacts:      │ │ Artifacts:              │ │   │   │
│  │  │ │ • PostgreSQL    │ │ • Supabase Auth │ │ • Supabase Storage      │ │   │   │
│  │  │ │ • users table   │ │ • JWT Tokens    │ │ • User Images           │ │   │   │
│  │  │ │ • recipes table │ │ • OAuth Providers│ │ • Recipe Images        │ │   │   │
│  │  │ │ • meal_plans    │ │ • Session Mgmt  │ │ • File Attachments      │ │   │   │
│  │  │ │ • meal_favorites│ │ • Password Reset│ │ • CDN Delivery          │ │   │   │
│  │  │ │ • nutrition_goals│ │ • Row Security  │ │ • Access Control        │ │   │   │
│  │  │ │ • meal_history  │ │                 │ │                         │ │   │   │
│  │  │ └─────────────────┘ └─────────────────┘ └─────────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    API SERVICES                                    │   │   │
│  │  │                                                                     │   │   │
│  │  │ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐ │   │   │
│  │  │ │   REST API      │ │   GraphQL API   │ │   Real-time             │ │   │   │
│  │  │ │   Gateway       │ │   Service       │ │   Subscriptions         │ │   │   │
│  │  │ │                 │ │                 │ │                         │ │   │   │
│  │  │ │ Artifacts:      │ │ Artifacts:      │ │ Artifacts:              │ │   │   │
│  │  │ │ • CRUD Ops      │ │ • Query/Mutation│ │ • WebSocket Connections │ │   │   │
│  │  │ │ • Data Access   │ │ • Type Safety   │ │ • Live Updates          │ │   │   │
│  │  │ │ • Security      │ │ • Real-time     │ │ • Notifications         │ │   │   │
│  │  │ │ • Rate Limiting │ │ • Subscriptions │ │ • Event Broadcasting    │ │   │   │
│  │  │ │ • HTTPS/TLS     │ │ • Schema        │ │ • Data Synchronization  │ │   │   │
│  │  │ └─────────────────┘ └─────────────────┘ └─────────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                               │
│                                    │ HTTPS/WebSocket                               │
│                                    ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           WEB APPLICATION                                  │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    WEB INTERFACE                                    │   │   │
│  │  │                                                                     │   │   │
│  │  │ ┌─────────────────────────────────────────────────────────────────┐ │   │   │
│  │  │ │                 Flutter Web Application                        │ │   │   │
│  │  │ │                                                               │ │   │   │
│  │  │ │ Artifacts:                                                    │ │   │   │
│  │  │ │ • index.html                                                  │ │   │   │
│  │  │ │ • main.dart                                                   │ │   │   │
│  │  │ │ • home_page.dart                                              │ │   │   │
│  │  │ │ • supabase_flutter                                            │ │   │   │
│  │  │ │ • fl_chart                                                    │ │   │   │
│  │  │ │ • manifest.json                                               │ │   │   │
│  │  │ │ • Progressive Web App (PWA)                                   │ │   │   │
│  │  │ │ • Responsive Design                                           │ │   │   │
│  │  │ └─────────────────────────────────────────────────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           USER ENTITIES                                   │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    USER ROLES                                       │   │   │
│  │  │                                                                     │   │   │
│  │  │ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐ │   │   │
│  │  │ │   Admin User    │ │   Regular User  │ │   System Administrator │ │   │   │
│  │  │ │                 │ │                 │ │                         │ │   │   │
│  │  │ │ Artifacts:      │ │ Artifacts:      │ │ Artifacts:              │ │   │   │
│  │  │ │ • NutriPlan     │ │ • NutriPlan     │ │ • Supabase Dashboard   │ │   │   │
│  │  │ │   Web App       │ │   Mobile App    │ │ • Database Management  │ │   │   │
│  │  │ │ • Analytics     │ │ • Meal Planning │ │ • User Management      │ │   │   │
│  │  │ │ • User Mgmt     │ │ • Recipe Access │ │ • System Monitoring    │ │   │   │
│  │  │ │ • Content Mgmt  │ │ • Nutrition     │ │ • Backup & Recovery    │ │   │   │
│  │  │ │ • Reports       │ │   Tracking      │ │ • Security Management  │ │   │   │
│  │  │ └─────────────────┘ └─────────────────┘ └─────────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Relationships

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              DATA FLOW DIAGRAM                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │   Mobile        │    │   Desktop       │    │   Web           │                │
│  │   Devices       │    │   Devices       │    │   Application   │                │
│  │                 │    │                 │    │                 │                │
│  │ Artifacts:      │    │ Artifacts:      │    │ Artifacts:      │                │
│  │ • Flutter App   │    │ • Flutter App   │    │ • Flutter Web   │                │
│  │ • Local Storage │    │ • Local Storage │    │ • Browser Cache │                │
│  │ • Image Cache   │    │ • File System   │    │ • PWA Storage   │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
│           │                       │                       │                       │
│           │                       │                       │                       │
│           │ HTTPS/REST API        │ HTTPS/REST API        │ HTTPS/REST API        │
│           │                       │                       │                       │
│           └───────────────────────┼───────────────────────┘                       │
│                                   │                                               │
│                                   ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                        SUPABASE CLOUD SERVER                               │   │
│  │                                                                             │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐   │   │
│  │  │   Database      │ │   Authentication│ │   Storage & Real-time       │   │   │
│  │  │   Services      │ │   Services      │ │   Services                   │   │   │
│  │  │                 │ │                 │ │                             │   │   │
│  │  │ • PostgreSQL    │ │ • JWT Auth      │ │ • File Storage              │   │   │
│  │  │ • Data CRUD     │ │ • OAuth         │ │ • Real-time Updates         │   │   │
│  │  │ • Queries       │ │ • Sessions      │ │ • Notifications             │   │   │
│  │  │ • Transactions  │ │ • Security      │ │ • WebSocket                 │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                   │                                               │
│                                   │ HTTPS/WebSocket                               │
│                                   ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           USER INTERFACES                                  │   │
│  │                                                                             │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐   │   │
│  │  │   Admin         │ │   Regular       │ │   System                     │   │   │
│  │  │   Interface     │ │   User          │ │   Administrator              │   │   │
│  │  │                 │ │   Interface     │ │   Interface                   │   │   │
│  │  │ • Web Dashboard │ │ • Mobile App    │ │ • Supabase Console           │   │   │
│  │  │ • Analytics     │ │ • Web App       │ │ • Database Tools             │   │   │
│  │  │ • Management    │ │ • Meal Planning │ │ • Monitoring Tools           │   │   │
│  │  │ • Reports       │ │ • Recipe Access │ │ • Security Tools             │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 🔗 Connection Types and Protocols

### **Solid Arrows (Data Flow):**
- **Client Devices → Supabase Cloud Server**: `HTTPS/REST API - Supabase SDK`
- **Web Application → Supabase Cloud Server**: `HTTPS/REST API - Supabase SDK`
- **Supabase Cloud Server → Database Services**: `Internal SQL/NoSQL`
- **Supabase Cloud Server → Storage Services**: `Internal File I/O`

### **Dashed Arrows (Usage Relationships):**
- **Admin User → Web Application**: `uses - NutriPlan Web App`
- **Regular User → Mobile Application**: `uses - NutriPlan Mobile App`
- **System Administrator → Supabase Dashboard**: `manages - System Console`

## 📊 Component Details

### **Client Devices**
- **Mobile Devices**: Android and iOS devices running Flutter applications
- **Desktop Devices**: Windows, macOS, and Linux systems running Flutter desktop apps
- **Artifacts**: Core Flutter application files, dependencies, and platform-specific configurations

### **Supabase Cloud Server**
- **Database Layer**: PostgreSQL with structured tables for user data, recipes, meal plans
- **Authentication Service**: JWT-based authentication with OAuth providers
- **Storage Service**: File storage for images and attachments with CDN delivery
- **API Services**: REST and GraphQL APIs with real-time subscriptions

### **Web Application**
- **Flutter Web**: Progressive Web App with responsive design
- **Artifacts**: HTML, Dart, and JavaScript files for web deployment
- **Features**: Cross-browser compatibility and offline capabilities

### **User Entities**
- **Admin User**: Manages system content, users, and analytics
- **Regular User**: Uses meal planning and nutrition tracking features
- **System Administrator**: Manages infrastructure and system health

## 🔐 Security and Communication

### **Data Transmission**
- **HTTPS/TLS**: All client-server communications are encrypted
- **API Keys**: Secure authentication using Supabase API keys
- **JWT Tokens**: Stateless authentication with automatic refresh

### **Access Control**
- **Row Level Security**: Database-level access control
- **Role-based Access**: Different permissions for different user types
- **Input Validation**: Client and server-side validation
