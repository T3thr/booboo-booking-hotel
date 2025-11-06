# Booking Module Flow Diagrams

## Complete Booking Flow

```mermaid
sequenceDiagram
    participant Guest
    participant Frontend
    participant API
    participant Service
    participant Repository
    participant PostgreSQL

    Guest->>Frontend: Search rooms
    Frontend->>API: GET /api/rooms/search
    API->>PostgreSQL: Query availability
    PostgreSQL-->>API: Available rooms
    API-->>Frontend: Room list
    Frontend-->>Guest: Display rooms

    Guest->>Frontend: Select room & click "Book"
    Frontend->>API: POST /api/bookings/hold
    API->>Service: CreateBookingHold()
    Service->>Repository: CreateBookingHold()
    Repository->>PostgreSQL: CALL create_booking_hold()
    PostgreSQL->>PostgreSQL: Lock inventory
    PostgreSQL->>PostgreSQL: Update tentative_count
    PostgreSQL->>PostgreSQL: Create hold records
    PostgreSQL-->>Repository: hold_id, success
    Repository-->>Service: Hold response
    Service-->>API: Hold response
    API-->>Frontend: Hold created (15 min)
    Frontend-->>Guest: Show booking form

    Guest->>Frontend: Fill details & submit
    Frontend->>API: POST /api/bookings
    API->>Service: CreateBooking()
    Service->>Service: Validate data
    Service->>Service: Calculate pricing
    Service->>Service: Apply voucher
    Service->>Repository: CreateBooking()
    Repository->>PostgreSQL: INSERT booking
    Repository->>PostgreSQL: INSERT booking_details
    Repository->>PostgreSQL: INSERT booking_guests
    Repository->>PostgreSQL: INSERT nightly_logs
    PostgreSQL-->>Repository: booking_id
    Repository-->>Service: Booking created
    Service-->>API: Booking response
    API-->>Frontend: Booking ID
    Frontend-->>Guest: Show payment page

    Guest->>Frontend: Complete payment
    Frontend->>API: POST /api/bookings/:id/confirm
    API->>Service: ConfirmBooking()
    Service->>Repository: ConfirmBooking()
    Repository->>PostgreSQL: CALL confirm_booking()
    PostgreSQL->>PostgreSQL: Update status
    PostgreSQL->>PostgreSQL: Move tentative to booked
    PostgreSQL->>PostgreSQL: Delete holds
    PostgreSQL-->>Repository: success
    Repository-->>Service: Confirmed
    Service-->>API: Confirmed
    API-->>Frontend: Success
    Frontend-->>Guest: Booking confirmed!
```

## Booking Hold Flow

```mermaid
graph TD
    A[Guest selects room] --> B[POST /api/bookings/hold]
    B --> C{Validate dates}
    C -->|Invalid| D[Return 400 error]
    C -->|Valid| E[Call create_booking_hold function]
    E --> F{Check availability}
    F -->|Not available| G[Rollback & return error]
    F -->|Available| H[Lock inventory rows]
    H --> I[Update tentative_count + 1]
    I --> J[Create hold records]
    J --> K[Set expiry = NOW + 15 min]
    K --> L[Commit transaction]
    L --> M[Return hold_id & expiry]
    M --> N[Guest has 15 minutes]
    
    style A fill:#e1f5ff
    style M fill:#c8e6c9
    style G fill:#ffcdd2
    style D fill:#ffcdd2
```

## Booking Confirmation Flow

```mermaid
graph TD
    A[Guest completes payment] --> B[POST /api/bookings/:id/confirm]
    B --> C{Verify booking exists}
    C -->|Not found| D[Return 404]
    C -->|Found| E{Check status}
    E -->|Not PendingPayment| F[Return error]
    E -->|PendingPayment| G[Call confirm_booking function]
    G --> H[Update status = Confirmed]
    H --> I[For each date in range]
    I --> J[booked_count + 1]
    J --> K[tentative_count - 1]
    K --> L{More dates?}
    L -->|Yes| I
    L -->|No| M[Delete holds]
    M --> N[Commit transaction]
    N --> O[Return success]
    O --> P[Send confirmation email]
    
    style A fill:#e1f5ff
    style O fill:#c8e6c9
    style D fill:#ffcdd2
    style F fill:#ffcdd2
```

## Booking Cancellation Flow

```mermaid
graph TD
    A[Guest requests cancellation] --> B[POST /api/bookings/:id/cancel]
    B --> C{Verify ownership}
    C -->|Not owner| D[Return 403]
    C -->|Owner| E{Check booking status}
    E -->|Confirmed/CheckedIn| F[Call cancel_confirmed_booking]
    E -->|PendingPayment| G[Call cancel_pending_booking]
    E -->|Other| H[Return error]
    
    F --> I[Get snapshotted policy]
    I --> J[Calculate refund]
    J --> K[Update status = Cancelled]
    K --> L[For each date]
    L --> M[booked_count - 1]
    M --> N{More dates?}
    N -->|Yes| L
    N -->|No| O[Commit transaction]
    O --> P[Return refund amount]
    
    G --> Q[Update status = Cancelled]
    Q --> R[For each date]
    R --> S[tentative_count - 1]
    S --> T{More dates?}
    T -->|Yes| R
    T -->|No| U[Commit transaction]
    U --> V[Return success]
    
    style A fill:#e1f5ff
    style P fill:#c8e6c9
    style V fill:#c8e6c9
    style D fill:#ffcdd2
    style H fill:#ffcdd2
```

## Data Flow Architecture

```mermaid
graph LR
    A[HTTP Request] --> B[Handler Layer]
    B --> C[Service Layer]
    C --> D[Repository Layer]
    D --> E[PostgreSQL]
    
    B -->|Validation| B1[Input Validation]
    B -->|Auth| B2[JWT Verification]
    
    C -->|Business Logic| C1[Pricing Calculation]
    C -->|Business Logic| C2[Voucher Application]
    C -->|Business Logic| C3[Authorization Check]
    
    D -->|Database| D1[CRUD Operations]
    D -->|Database| D2[Function Calls]
    D -->|Database| D3[Transaction Management]
    
    E -->|Constraints| E1[Inventory Checks]
    E -->|Constraints| E2[Foreign Keys]
    E -->|Functions| E3[Business Rules]
    
    style A fill:#e1f5ff
    style B fill:#fff9c4
    style C fill:#c8e6c9
    style D fill:#b2dfdb
    style E fill:#b39ddb
```

## Inventory State Changes

```mermaid
stateDiagram-v2
    [*] --> Available: Initial state
    Available --> Tentative: Create hold
    Tentative --> Available: Hold expires
    Tentative --> Booked: Confirm booking
    Booked --> Available: Cancel booking
    Available --> [*]: End
    
    note right of Tentative
        tentative_count + 1
        15 minute timer
    end note
    
    note right of Booked
        booked_count + 1
        tentative_count - 1
    end note
```

## Booking Status Lifecycle

```mermaid
stateDiagram-v2
    [*] --> PendingPayment: Create booking
    PendingPayment --> Confirmed: Payment success
    PendingPayment --> Cancelled: Cancel or timeout
    Confirmed --> CheckedIn: Guest checks in
    Confirmed --> Cancelled: Cancel before checkin
    Confirmed --> NoShow: Guest doesn't arrive
    CheckedIn --> Completed: Guest checks out
    Cancelled --> [*]
    Completed --> [*]
    NoShow --> [*]
    
    note right of PendingPayment
        Waiting for payment
        Hold is active
    end note
    
    note right of Confirmed
        Payment received
        Inventory booked
    end note
    
    note right of CheckedIn
        Guest in room
        Cannot cancel
    end note
```

## Error Handling Flow

```mermaid
graph TD
    A[Request] --> B{Validation}
    B -->|Fail| C[400 Bad Request]
    B -->|Pass| D{Authentication}
    D -->|Fail| E[401 Unauthorized]
    D -->|Pass| F{Authorization}
    F -->|Fail| G[403 Forbidden]
    F -->|Pass| H{Business Logic}
    H -->|Fail| I[400 Bad Request]
    H -->|Pass| J{Database Operation}
    J -->|Not Found| K[404 Not Found]
    J -->|Constraint Violation| L[400 Bad Request]
    J -->|Other Error| M[500 Internal Error]
    J -->|Success| N[200/201 Success]
    
    style N fill:#c8e6c9
    style C fill:#ffcdd2
    style E fill:#ffcdd2
    style G fill:#ffcdd2
    style I fill:#ffcdd2
    style K fill:#ffcdd2
    style L fill:#ffcdd2
    style M fill:#ffcdd2
```

## Concurrent Booking Scenario

```mermaid
sequenceDiagram
    participant User1
    participant User2
    participant API
    participant DB
    
    Note over DB: Last room available
    
    User1->>API: Create hold
    User2->>API: Create hold
    
    API->>DB: Lock inventory (User1)
    API->>DB: Lock inventory (User2)
    
    DB->>DB: Check availability (User1)
    DB->>DB: tentative_count + 1 (User1)
    DB-->>API: Success (User1)
    API-->>User1: Hold created
    
    DB->>DB: Check availability (User2)
    Note over DB: No rooms left!
    DB-->>API: Fail (User2)
    API-->>User2: No rooms available
    
    Note over DB: Race condition prevented!
```

## Database Transaction Flow

```mermaid
graph TD
    A[BEGIN TRANSACTION] --> B[Lock rows FOR UPDATE]
    B --> C{Check constraints}
    C -->|Fail| D[ROLLBACK]
    C -->|Pass| E[Execute operations]
    E --> F{All success?}
    F -->|No| D
    F -->|Yes| G[COMMIT]
    G --> H[Release locks]
    D --> I[Release locks]
    
    style G fill:#c8e6c9
    style D fill:#ffcdd2
```

## Key Design Principles

### 1. Atomicity
All critical operations use database transactions to ensure all-or-nothing execution.

### 2. Isolation
Row-level locks prevent race conditions during concurrent bookings.

### 3. Consistency
Database constraints and functions enforce business rules.

### 4. Durability
Committed transactions are permanently stored.

### 5. Authorization
Service layer checks ensure users can only access their own data.

### 6. Immutability
Policy and pricing snapshots preserve historical accuracy.

## Performance Considerations

```mermaid
graph LR
    A[Request] --> B[Connection Pool]
    B --> C[Prepared Statements]
    C --> D[Indexed Queries]
    D --> E[Transaction]
    E --> F[Response]
    
    B -->|Reuse| B
    C -->|Cache| C
    D -->|Fast Lookup| D
    
    style F fill:#c8e6c9
```

## Security Layers

```mermaid
graph TD
    A[HTTP Request] --> B[CORS Check]
    B --> C[Input Validation]
    C --> D[JWT Verification]
    D --> E[Authorization Check]
    E --> F[SQL Injection Prevention]
    F --> G[Business Logic]
    G --> H[Database Constraints]
    H --> I[Response]
    
    style I fill:#c8e6c9
```

These diagrams illustrate the complete booking flow, state transitions, error handling, and security measures implemented in the booking module.
