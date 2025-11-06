# Booking History Flow Diagram

## User Journey Flow

```mermaid
graph TD
    A[Guest Login] --> B[Navigate to /bookings]
    B --> C{Has Bookings?}
    
    C -->|No| D[Show Empty State]
    D --> E[Click Search for Rooms]
    E --> F[Navigate to /rooms/search]
    
    C -->|Yes| G[Display Booking List]
    G --> H[Apply Default Filter: All]
    
    H --> I{User Action?}
    
    I -->|Filter| J[Click Filter Button]
    J --> K[Update Filter State]
    K --> L[Filter Bookings]
    L --> G
    
    I -->|Expand| M[Click Show More]
    M --> N[Display Expanded Details]
    N --> O{User Action?}
    
    O -->|Collapse| P[Click Show Less]
    P --> G
    
    O -->|View Details| Q[Click View Full Details]
    Q --> R[Navigate to /booking/confirmation/id]
    
    O -->|Cancel| S{Can Cancel?}
    
    S -->|No| T[Button Hidden]
    T --> G
    
    S -->|Yes| U[Click Cancel Booking]
    U --> V[Show Confirmation Dialog]
    V --> W{User Choice?}
    
    W -->|Keep| X[Click Keep Booking]
    X --> Y[Close Dialog]
    Y --> G
    
    W -->|Cancel| Z[Click Yes, Cancel]
    Z --> AA[Call Cancel API]
    AA --> AB{API Success?}
    
    AB -->|No| AC[Show Error Message]
    AC --> V
    
    AB -->|Yes| AD[Update Booking Status]
    AD --> AE[Invalidate Cache]
    AE --> AF[Refresh Booking List]
    AF --> AG[Show Success Message]
    AG --> G
```

## Component State Flow

```mermaid
stateDiagram-v2
    [*] --> Loading: Component Mount
    Loading --> Error: API Error
    Loading --> Empty: No Bookings
    Loading --> Loaded: Has Bookings
    
    Error --> Loading: Retry
    Empty --> [*]: Navigate Away
    
    Loaded --> Filtered: Apply Filter
    Filtered --> Loaded: Clear Filter
    
    Loaded --> Expanded: Show More
    Expanded --> Loaded: Show Less
    
    Loaded --> Cancelling: Click Cancel
    Cancelling --> ConfirmDialog: Show Dialog
    ConfirmDialog --> Cancelling: Keep Booking
    ConfirmDialog --> Processing: Confirm Cancel
    
    Processing --> Success: API Success
    Processing --> Failed: API Error
    
    Success --> Loaded: Refresh List
    Failed --> ConfirmDialog: Show Error
    
    Loaded --> Details: View Full Details
    Details --> [*]: Navigate Away
```

## Data Flow Architecture

```mermaid
graph LR
    A[User Browser] -->|HTTP Request| B[Next.js Frontend]
    B -->|React Query| C[API Client]
    C -->|REST API| D[Go Backend]
    D -->|SQL Query| E[PostgreSQL]
    
    E -->|Booking Data| D
    D -->|JSON Response| C
    C -->|Cache & State| B
    B -->|Render UI| A
    
    A -->|Cancel Action| B
    B -->|Mutation| C
    C -->|POST /cancel| D
    D -->|Call SP| E
    E -->|Update DB| D
    D -->|Success| C
    C -->|Invalidate| B
    B -->|Refresh| A
```

## Cancel Booking Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Bookings Page
    participant RQ as React Query
    participant API as API Client
    participant BE as Backend
    participant DB as Database
    
    U->>UI: Click Cancel Booking
    UI->>UI: Show Confirmation Dialog
    U->>UI: Confirm Cancellation
    UI->>RQ: Trigger Mutation
    RQ->>API: POST /bookings/:id/cancel
    API->>BE: HTTP Request
    BE->>DB: Call SP_CancelConfirmedBooking
    DB->>DB: Update Status
    DB->>DB: Return Inventory
    DB->>DB: Calculate Refund
    DB-->>BE: Success Response
    BE-->>API: JSON Response
    API-->>RQ: Data
    RQ->>RQ: Invalidate Queries
    RQ->>API: Refetch Bookings
    API->>BE: GET /bookings
    BE->>DB: Query Bookings
    DB-->>BE: Updated Data
    BE-->>API: JSON Response
    API-->>RQ: Fresh Data
    RQ-->>UI: Update State
    UI-->>U: Show Success & Updated List
```

## Filter Logic Flow

```mermaid
graph TD
    A[All Bookings] --> B{Filter Type?}
    
    B -->|All| C[Return All]
    C --> D[Display All Bookings]
    
    B -->|Upcoming| E{Status Check}
    E -->|Confirmed| F[Include]
    E -->|CheckedIn| F
    E -->|Other| G[Exclude]
    F --> H[Display Upcoming]
    
    B -->|Completed| I{Status = Completed?}
    I -->|Yes| J[Include]
    I -->|No| K[Exclude]
    J --> L[Display Completed]
    
    B -->|Cancelled| M{Status = Cancelled?}
    M -->|Yes| N[Include]
    M -->|No| O[Exclude]
    N --> P[Display Cancelled]
```

## Refund Calculation Flow

```mermaid
graph TD
    A[Start Refund Calculation] --> B[Get Check-in Date]
    B --> C[Get Current Date]
    C --> D[Calculate Days Until Check-in]
    D --> E[Parse Policy Description]
    E --> F{Regex Match?}
    
    F -->|Yes| G[Extract Percentage]
    F -->|No| H[Return Null]
    
    G --> I[Calculate Refund Amount]
    I --> J[Amount = Total × Percentage / 100]
    J --> K[Return Object]
    K --> L{Display Refund}
    
    L --> M[Show Percentage]
    L --> N[Show Amount]
    L --> O[Show Days Until Check-in]
```

## Component Hierarchy

```
BookingsPage
├── Header
│   ├── Title
│   └── Description
├── StatusFilter
│   ├── AllButton
│   ├── UpcomingButton
│   ├── CompletedButton
│   └── CancelledButton
├── BookingsList
│   └── BookingCard (multiple)
│       ├── BookingHeader
│       │   ├── BookingID
│       │   └── StatusBadge
│       ├── BookingInfo
│       │   ├── CheckInDate
│       │   ├── CheckOutDate
│       │   ├── Guests
│       │   └── TotalAmount
│       ├── ExpandedDetails (conditional)
│       │   ├── RoomDetails
│       │   ├── GuestInformation
│       │   ├── CancellationPolicy
│       │   ├── RefundCalculation
│       │   └── NightlyBreakdown
│       └── ActionButtons
│           ├── ShowMoreButton
│           ├── ViewDetailsButton
│           └── CancelButton (conditional)
└── CancelDialog (conditional)
    ├── DialogHeader
    ├── WarningMessage
    ├── RefundDisplay
    └── DialogActions
        ├── KeepButton
        └── ConfirmButton
```

## State Management

```mermaid
graph TD
    A[Component State] --> B[statusFilter: string]
    A --> C[expandedBooking: number | null]
    A --> D[cancellingBooking: number | null]
    
    E[React Query State] --> F[bookings: Booking[]]
    E --> G[isLoading: boolean]
    E --> H[error: Error | null]
    
    I[Mutation State] --> J[cancelBooking.isPending]
    I --> K[cancelBooking.isSuccess]
    I --> L[cancelBooking.isError]
```

## Error Handling Flow

```mermaid
graph TD
    A[API Call] --> B{Success?}
    
    B -->|Yes| C[Update State]
    C --> D[Show Success Message]
    D --> E[Refresh Data]
    
    B -->|No| F{Error Type?}
    
    F -->|Network| G[Show Network Error]
    G --> H[Offer Retry]
    
    F -->|401 Unauthorized| I[Redirect to Login]
    
    F -->|400 Bad Request| J[Show Validation Error]
    J --> K[Keep Dialog Open]
    
    F -->|500 Server Error| L[Show Server Error]
    L --> M[Log to Console]
    M --> H
    
    H --> N{User Action?}
    N -->|Retry| A
    N -->|Cancel| O[Close Dialog]
```

## Responsive Layout Flow

```mermaid
graph TD
    A[Screen Size Detection] --> B{Width?}
    
    B -->|< 640px| C[Mobile Layout]
    C --> D[Single Column]
    C --> E[Stacked Buttons]
    C --> F[2-Column Grid]
    
    B -->|640-1024px| G[Tablet Layout]
    G --> H[Flexible Columns]
    G --> I[Side-by-Side Buttons]
    G --> J[2-Column Grid]
    
    B -->|> 1024px| K[Desktop Layout]
    K --> L[Max Width Container]
    K --> M[Horizontal Buttons]
    K --> N[4-Column Grid]
```

## Performance Optimization Flow

```mermaid
graph TD
    A[Component Render] --> B[React Query Cache Check]
    B --> C{Cache Hit?}
    
    C -->|Yes| D[Use Cached Data]
    D --> E[Render Immediately]
    
    C -->|No| F[Fetch from API]
    F --> G[Show Loading State]
    G --> H[Receive Data]
    H --> I[Update Cache]
    I --> J[Render with Data]
    
    K[User Action] --> L{Mutation?}
    
    L -->|Yes| M[Optimistic Update]
    M --> N[Call API]
    N --> O{Success?}
    
    O -->|Yes| P[Invalidate Queries]
    P --> Q[Refetch Data]
    
    O -->|No| R[Rollback Update]
    R --> S[Show Error]
```

## Summary

These diagrams illustrate:

1. **User Journey**: Complete flow from login to cancellation
2. **Component State**: State transitions and management
3. **Data Flow**: How data moves through the system
4. **Cancel Sequence**: Detailed cancellation process
5. **Filter Logic**: How filtering works
6. **Refund Calculation**: Refund computation process
7. **Component Hierarchy**: UI structure
8. **State Management**: State organization
9. **Error Handling**: Error flow and recovery
10. **Responsive Layout**: Layout adaptation
11. **Performance**: Optimization strategies

Use these diagrams as reference for understanding the booking history implementation.
