# NextAuth.js Authentication Flow Diagrams

## 1. Sign In Flow

```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant NextAuth
    participant Backend
    participant Database
    
    User->>Browser: Navigate to /auth/signin
    Browser->>User: Display sign-in form
    
    User->>Browser: Enter email & password
    Browser->>NextAuth: signIn('credentials', {email, password})
    
    NextAuth->>Backend: POST /api/auth/login
    Note over NextAuth,Backend: {email, password}
    
    Backend->>Database: SELECT * FROM guest_accounts WHERE email=?
    Database-->>Backend: User record
    
    Backend->>Backend: Verify password (bcrypt)
    
    alt Password Valid
        Backend->>Backend: Generate JWT token
        Backend-->>NextAuth: {id, email, name, role, accessToken}
        
        NextAuth->>NextAuth: Create JWT session
        NextAuth->>NextAuth: Set session cookie
        
        NextAuth-->>Browser: Session created
        Browser->>Browser: Redirect to callbackUrl
        Browser-->>User: Show dashboard
    else Password Invalid
        Backend-->>NextAuth: 401 Unauthorized
        NextAuth-->>Browser: Error: Invalid credentials
        Browser-->>User: Show error message
    end
```

## 2. Session Management Flow

```mermaid
sequenceDiagram
    participant Component
    participant NextAuth
    participant Cookie
    participant JWT
    
    Component->>NextAuth: useSession()
    NextAuth->>Cookie: Read session cookie
    Cookie-->>NextAuth: Encrypted JWT
    
    NextAuth->>JWT: Decode & verify token
    
    alt Token Valid
        JWT-->>NextAuth: User data
        NextAuth-->>Component: {user, accessToken, expires}
        Component->>Component: Render authenticated UI
    else Token Expired
        JWT-->>NextAuth: Token expired
        NextAuth-->>Component: status: 'unauthenticated'
        Component->>Component: Redirect to /auth/signin
    end
```

## 3. Protected Route Flow

```mermaid
flowchart TD
    A[User visits protected page] --> B{Session exists?}
    B -->|No| C[Redirect to /auth/signin]
    B -->|Yes| D{Role check required?}
    D -->|No| E[Render page]
    D -->|Yes| F{User has required role?}
    F -->|Yes| E
    F -->|No| G[Redirect to /unauthorized]
    
    C --> H[Show sign-in form]
    H --> I[User signs in]
    I --> J[Redirect back to original page]
    J --> B
```

## 4. Registration Flow

```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Backend
    participant Database
    
    User->>Browser: Navigate to /auth/register
    Browser->>User: Display registration form
    
    User->>Browser: Fill form & submit
    Browser->>Browser: Validate input
    
    alt Validation Passes
        Browser->>Backend: POST /api/auth/register
        Note over Browser,Backend: {first_name, last_name, email, phone, password}
        
        Backend->>Database: Check if email exists
        
        alt Email Available
            Database-->>Backend: Email not found
            Backend->>Backend: Hash password (bcrypt)
            Backend->>Database: INSERT INTO guests, guest_accounts
            Database-->>Backend: Success
            Backend-->>Browser: 201 Created
            Browser->>Browser: Redirect to /auth/signin
            Browser-->>User: Show success message
        else Email Exists
            Database-->>Backend: Email found
            Backend-->>Browser: 400 Bad Request
            Browser-->>User: Show error: Email already registered
        end
    else Validation Fails
        Browser-->>User: Show validation errors
    end
```

## 5. Sign Out Flow

```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant NextAuth
    participant Cookie
    
    User->>Browser: Click sign out button
    Browser->>NextAuth: signOut({callbackUrl: '/'})
    
    NextAuth->>Cookie: Delete session cookie
    Cookie-->>NextAuth: Cookie deleted
    
    NextAuth->>NextAuth: Clear session data
    NextAuth-->>Browser: Session cleared
    
    Browser->>Browser: Redirect to callbackUrl
    Browser-->>User: Show home page (logged out)
```

## 6. API Call with Authentication

```mermaid
sequenceDiagram
    participant Component
    participant NextAuth
    participant API
    participant Backend
    
    Component->>NextAuth: useSession()
    NextAuth-->>Component: {accessToken}
    
    Component->>API: fetch('/api/bookings')
    Note over Component,API: Headers: {Authorization: Bearer <token>}
    
    API->>Backend: Forward request with token
    Backend->>Backend: Verify JWT token
    
    alt Token Valid
        Backend->>Backend: Process request
        Backend-->>API: Response data
        API-->>Component: JSON data
        Component->>Component: Render data
    else Token Invalid
        Backend-->>API: 401 Unauthorized
        API-->>Component: Error
        Component->>Component: Redirect to /auth/signin
    end
```

## 7. Session Refresh Flow

```mermaid
flowchart TD
    A[User makes request] --> B{Session expired?}
    B -->|No| C[Continue with request]
    B -->|Yes| D[Clear session]
    D --> E[Redirect to /auth/signin]
    E --> F[User signs in again]
    F --> G[New session created]
    G --> H[Redirect to original page]
    
    C --> I[Use accessToken]
    I --> J[Make API call]
```

## 8. Role-Based Access Control

```mermaid
flowchart TD
    A[User accesses page] --> B{Authenticated?}
    B -->|No| C[Redirect to /auth/signin]
    B -->|Yes| D{Role check required?}
    
    D -->|No| E[Grant access]
    D -->|Yes| F{Check user role}
    
    F -->|Guest| G{Page requires guest?}
    F -->|Receptionist| H{Page requires receptionist?}
    F -->|Housekeeper| I{Page requires housekeeper?}
    F -->|Manager| J{Page requires manager?}
    
    G -->|Yes| E
    G -->|No| K[Redirect to /unauthorized]
    
    H -->|Yes| E
    H -->|No| K
    
    I -->|Yes| E
    I -->|No| K
    
    J -->|Yes| E
    J -->|No| K
```

## 9. Complete Authentication Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Unauthenticated
    
    Unauthenticated --> Registering: Click register
    Registering --> Unauthenticated: Registration complete
    Registering --> Unauthenticated: Registration failed
    
    Unauthenticated --> SigningIn: Click sign in
    SigningIn --> Authenticated: Credentials valid
    SigningIn --> Unauthenticated: Credentials invalid
    
    Authenticated --> AccessingProtected: Navigate to page
    AccessingProtected --> Authorized: Role check passed
    AccessingProtected --> Unauthorized: Role check failed
    
    Authorized --> Authenticated: Continue session
    Unauthorized --> Authenticated: Return to dashboard
    
    Authenticated --> SigningOut: Click sign out
    SigningOut --> Unauthenticated: Session cleared
    
    Authenticated --> Unauthenticated: Session expired
```

## 10. Error Handling Flow

```mermaid
flowchart TD
    A[Authentication Error] --> B{Error Type}
    
    B -->|Invalid Credentials| C[Show error message]
    C --> D[Stay on sign-in page]
    
    B -->|Network Error| E[Show connection error]
    E --> F[Retry button]
    
    B -->|Backend Down| G[Show service unavailable]
    G --> F
    
    B -->|Token Expired| H[Clear session]
    H --> I[Redirect to /auth/signin]
    
    B -->|CSRF Error| J[Refresh page]
    J --> K[Retry authentication]
    
    B -->|Unknown Error| L[Show generic error]
    L --> M[Log error to console]
    M --> N[Redirect to /auth/error]
```

## Component Interaction Diagram

```mermaid
graph TB
    subgraph "Frontend Components"
        A[Sign In Page]
        B[Register Page]
        C[Protected Route]
        D[Session Provider]
        E[Auth Test Page]
    end
    
    subgraph "NextAuth Layer"
        F[NextAuth Config]
        G[API Route Handler]
        H[JWT Callbacks]
        I[Session Callbacks]
    end
    
    subgraph "Backend API"
        J[Auth Handler]
        K[JWT Generator]
        L[Password Verifier]
    end
    
    subgraph "Database"
        M[(PostgreSQL)]
    end
    
    A --> F
    B --> J
    C --> D
    D --> F
    E --> D
    
    F --> G
    G --> H
    H --> I
    
    F --> J
    J --> K
    J --> L
    
    K --> M
    L --> M
```

## Data Flow Diagram

```mermaid
flowchart LR
    A[User Input] --> B[Form Validation]
    B --> C[NextAuth Provider]
    C --> D[Backend API]
    D --> E[Database Query]
    E --> F[Password Check]
    F --> G[JWT Generation]
    G --> H[Session Creation]
    H --> I[Cookie Storage]
    I --> J[User Dashboard]
    
    style A fill:#e1f5ff
    style J fill:#c8e6c9
    style F fill:#fff9c4
    style G fill:#fff9c4
```

## Security Flow

```mermaid
flowchart TD
    A[User Credentials] --> B{Client Validation}
    B -->|Pass| C[Send to Backend]
    B -->|Fail| D[Show Error]
    
    C --> E{Backend Validation}
    E -->|Pass| F[Check Database]
    E -->|Fail| G[Return 400]
    
    F --> H{User Exists?}
    H -->|Yes| I[Verify Password]
    H -->|No| G
    
    I --> J{Password Match?}
    J -->|Yes| K[Generate JWT]
    J -->|No| L[Return 401]
    
    K --> M[Sign Token]
    M --> N[Return to Frontend]
    N --> O[Store in Session]
    O --> P[Set Secure Cookie]
    
    style K fill:#c8e6c9
    style M fill:#c8e6c9
    style P fill:#c8e6c9
```

## Notes

- All diagrams use Mermaid syntax for easy rendering
- Flows show both success and error paths
- Security considerations are highlighted
- Role-based access control is clearly defined
- Session management lifecycle is complete

## Usage

These diagrams can be rendered in:
- GitHub (native Mermaid support)
- VS Code (with Mermaid extension)
- Documentation sites (with Mermaid plugin)
- Markdown viewers (with Mermaid support)
