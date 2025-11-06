# Hotel Booking System - Frontend

Next.js 16 frontend application for the Hotel Booking System.

## Tech Stack

- **Next.js 16** - React framework with App Router
- **React 19** - UI library with React Compiler
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **NextAuth.js v5** - Authentication
- **TanStack Query (React Query)** - Data fetching and caching
- **Zustand** - State management
- **Axios** - HTTP client

## Project Structure

```
frontend/
├── src/
│   ├── app/                    # Next.js App Router pages
│   │   ├── (guest)/           # Guest routes
│   │   ├── (staff)/           # Staff routes (receptionist, housekeeper)
│   │   ├── (manager)/         # Manager routes
│   │   ├── api/               # API routes
│   │   │   └── auth/          # NextAuth configuration
│   │   ├── layout.tsx         # Root layout
│   │   └── page.tsx           # Home page
│   ├── components/            # React components
│   │   ├── ui/                # Reusable UI components
│   │   └── providers.tsx      # App providers
│   ├── lib/                   # Utility libraries
│   │   ├── api.ts             # API client
│   │   ├── auth.ts            # NextAuth configuration
│   │   └── query-client.ts    # React Query client
│   ├── store/                 # Zustand stores
│   │   ├── useAuthStore.ts    # Auth state
│   │   └── useBookingStore.ts # Booking state
│   └── types/                 # TypeScript types
│       └── index.ts           # Type definitions
├── public/                    # Static assets
├── .env.example              # Environment variables template
├── next.config.js            # Next.js configuration
├── tailwind.config.js        # Tailwind CSS configuration
└── tsconfig.json             # TypeScript configuration
```

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn/pnpm
- Backend API running on port 8080

### Installation

1. Copy environment variables:
```bash
cp .env.example .env.local
```

2. Update `.env.local` with your configuration:
```env
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key
BACKEND_URL=http://backend:8080
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

3. Install dependencies:
```bash
npm install
# or
yarn install
# or
pnpm install
```

4. Run the development server:
```bash
npm run dev
# or
yarn dev
# or
pnpm dev
```

5. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Development

### Running with Docker

```bash
# Development mode with hot reload
docker-compose up frontend

# Production build
docker-compose -f docker-compose.prod.yml up frontend
```

### Building for Production

```bash
npm run build
npm run start
```

## Features

### Authentication
- Login/Register with NextAuth.js
- JWT-based authentication
- Role-based access control (Guest, Receptionist, Housekeeper, Manager)
- Protected routes

### State Management
- **React Query**: Server state management, caching, and data fetching
- **Zustand**: Client state management for auth and booking flow

### API Integration
- Axios client with interceptors
- Automatic token injection
- Error handling and retry logic

### UI Components
- Reusable UI components with Tailwind CSS
- Responsive design
- Loading states and error boundaries

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXTAUTH_URL` | Application URL | `http://localhost:3000` |
| `NEXTAUTH_SECRET` | Secret for NextAuth | Random string |
| `BACKEND_URL` | Backend API URL (server-side) | `http://backend:8080` |
| `NEXT_PUBLIC_API_URL` | Backend API URL (client-side) | `http://localhost:8080/api` |

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## Next Steps

After setting up the project, you can start implementing:

1. **Guest Features** (Task 17-21)
   - Room search and booking
   - Booking history
   - Profile management

2. **Staff Features** (Task 22-29)
   - Check-in/check-out
   - Room status dashboard
   - Housekeeping tasks

3. **Manager Features** (Task 30-36)
   - Pricing management
   - Inventory management
   - Reports and analytics

## Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [NextAuth.js Documentation](https://next-auth.js.org/)
- [TanStack Query Documentation](https://tanstack.com/query/latest)
- [Zustand Documentation](https://zustand-demo.pmnd.rs/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
