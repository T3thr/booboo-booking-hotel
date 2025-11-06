# Night Audit Workflow Diagram

## System Architecture

```mermaid
graph TB
    subgraph "Server Startup"
        A[Server Start] --> B[Load Config]
        B --> C[Connect Database]
        C --> D[Initialize Night Audit Job]
        D --> E[Start Cron Scheduler]
        E --> F[Setup Router]
        F --> G[Start HTTP Server]
    end
    
    subgraph "Scheduled Execution"
        H[02:00 AM Daily] --> I[Cron Triggers Job]
        I --> J[Execute Night Audit]
        J --> K{Success?}
        K -->|Yes| L[Log Success]
        K -->|No| M[Log Error]
        L --> N[Wait for Next Day]
        M --> N
    end
    
    subgraph "Manual Execution"
        O[Manager Request] --> P[POST /api/admin/night-audit/trigger]
        P --> Q[Authenticate]
        Q --> R{Authorized?}
        R -->|Yes| S[Execute Night Audit]
        R -->|No| T[Return 403]
        S --> U[Return Results]
    end
    
    subgraph "Night Audit Process"
        V[Start Audit] --> W[Create Context with Timeout]
        W --> X[Execute SQL Query]
        X --> Y[UPDATE rooms SET housekeeping_status = 'Dirty']
        Y --> Z{Query Success?}
        Z -->|Yes| AA[Count Updated Rooms]
        Z -->|No| AB[Rollback & Log Error]
        AA --> AC[Log Room IDs]
        AC --> AD[Return Success Result]
        AB --> AE[Return Error Result]
    end
    
    G --> H
    G --> O
    J --> V
    S --> V
```

## Detailed Flow

### 1. Server Startup Flow

```
┌─────────────────┐
│  Server Start   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Load Config    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Connect to DB   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ Initialize Night Audit Job  │
│ - Create job instance       │
│ - Setup logger              │
│ - Create cron scheduler     │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│   Start Cron Scheduler      │
│ - Schedule: 0 2 * * *       │
│ - Next run: Tomorrow 02:00  │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────┐
│  Setup Router   │
│ - Add routes    │
│ - Add handlers  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Start HTTP Srv  │
│ Port: 8080      │
└─────────────────┘
```

### 2. Scheduled Execution Flow

```
┌──────────────────┐
│  Wait for 02:00  │
│  (Cron Waits)    │
└────────┬─────────┘
         │
         ▼ (02:00 AM)
┌──────────────────┐
│  Cron Triggers   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│  Log: Starting audit...  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  Execute Night Audit     │
│  (See Process Flow)      │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  Log Results             │
│  - Timestamp             │
│  - Rooms updated         │
│  - Execution time        │
│  - Success/Error         │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────┐
│  Wait 24 hours   │
│  (Next 02:00)    │
└──────────────────┘
```

### 3. Manual Trigger Flow

```
┌─────────────────────┐
│  Manager Login      │
│  Get JWT Token      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────┐
│  POST /api/admin/night-audit/   │
│       trigger                    │
│  Header: Authorization: Bearer  │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────┐
│  Auth Middleware    │
│  - Verify JWT       │
│  - Check role       │
└──────────┬──────────┘
           │
           ▼
      ┌────┴────┐
      │ Valid?  │
      └────┬────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌────────┐   ┌────────┐
│  Yes   │   │   No   │
└───┬────┘   └───┬────┘
    │            │
    │            ▼
    │      ┌──────────┐
    │      │ Return   │
    │      │ 401/403  │
    │      └──────────┘
    │
    ▼
┌─────────────────────┐
│  Execute Audit      │
│  (See Process Flow) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Return JSON        │
│  {                  │
│    message: "..."   │
│    rooms_updated: N │
│    execution_time   │
│  }                  │
└─────────────────────┘
```

### 4. Night Audit Process Flow

```
┌──────────────────────┐
│  Start Audit         │
│  Log: Executing...   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Create Context      │
│  Timeout: 30 seconds │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────────┐
│  Execute SQL Query               │
│  UPDATE rooms                    │
│  SET housekeeping_status='Dirty' │
│  WHERE occupancy_status='Occupied'│
│  AND housekeeping_status!='Dirty'│
│  RETURNING room_id;              │
└──────────┬───────────────────────┘
           │
           ▼
      ┌────┴────┐
      │Success? │
      └────┬────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌────────┐   ┌────────┐
│  Yes   │   │   No   │
└───┬────┘   └───┬────┘
    │            │
    │            ▼
    │      ┌──────────────────┐
    │      │  Log Error       │
    │      │  Return Error    │
    │      │  Result          │
    │      └──────────────────┘
    │
    ▼
┌──────────────────┐
│  Scan Results    │
│  Count rooms     │
│  Collect IDs     │
└──────────┬───────┘
           │
           ▼
┌──────────────────┐
│  Log Success     │
│  - Rooms updated │
│  - Room IDs      │
│  - Duration      │
└──────────┬───────┘
           │
           ▼
┌──────────────────┐
│  Return Success  │
│  Result          │
└──────────────────┘
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Initializing: Server Start
    Initializing --> Scheduled: Cron Started
    Scheduled --> Running: 02:00 AM Trigger
    Scheduled --> Running: Manual Trigger
    Running --> Success: Audit Complete
    Running --> Failed: Error Occurred
    Success --> Scheduled: Wait for Next Run
    Failed --> Scheduled: Wait for Next Run
    Scheduled --> [*]: Server Shutdown
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant M as Manager
    participant A as API
    participant H as Handler
    participant J as Job
    participant D as Database
    
    Note over M,D: Manual Trigger Flow
    
    M->>A: POST /api/admin/night-audit/trigger
    A->>A: Authenticate & Authorize
    A->>H: TriggerManual()
    H->>J: RunManual()
    J->>J: Log: Starting audit
    J->>D: UPDATE rooms SET...
    D-->>J: Return updated room_ids
    J->>J: Count & Log results
    J-->>H: Return NightAuditResult
    H-->>A: JSON Response
    A-->>M: 200 OK with results
    
    Note over M,D: Scheduled Execution Flow
    
    Note over J: Wait until 02:00 AM
    J->>J: Cron Trigger
    J->>J: Log: Starting scheduled audit
    J->>D: UPDATE rooms SET...
    D-->>J: Return updated room_ids
    J->>J: Count & Log results
    J->>J: Log: Audit complete
```

## Data Flow

```
┌─────────────┐
│   Rooms     │
│   Table     │
└──────┬──────┘
       │
       │ SELECT (Identify)
       ▼
┌─────────────────────────┐
│  Occupied Rooms         │
│  (occupancy='Occupied') │
│  (housekeeping!='Dirty')│
└──────┬──────────────────┘
       │
       │ UPDATE
       ▼
┌─────────────────────────┐
│  Set Status to Dirty    │
│  housekeeping='Dirty'   │
└──────┬──────────────────┘
       │
       │ RETURN
       ▼
┌─────────────────────────┐
│  Updated Room IDs       │
│  [101, 102, 103, ...]   │
└──────┬──────────────────┘
       │
       │ LOG
       ▼
┌─────────────────────────┐
│  Audit Log              │
│  - Timestamp            │
│  - Count                │
│  - Room IDs             │
│  - Duration             │
└─────────────────────────┘
```

## Error Handling Flow

```
┌──────────────────┐
│  Execute Query   │
└────────┬─────────┘
         │
         ▼
    ┌────┴────┐
    │ Error?  │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────────┐
│   No   │ │     Yes      │
└───┬────┘ └──────┬───────┘
    │             │
    │             ▼
    │      ┌──────────────────┐
    │      │  Identify Error  │
    │      │  - Connection    │
    │      │  - Timeout       │
    │      │  - SQL Error     │
    │      └──────┬───────────┘
    │             │
    │             ▼
    │      ┌──────────────────┐
    │      │  Log Error       │
    │      │  - Type          │
    │      │  - Message       │
    │      │  - Stack trace   │
    │      └──────┬───────────┘
    │             │
    │             ▼
    │      ┌──────────────────┐
    │      │  Return Error    │
    │      │  Result          │
    │      │  - Success=false │
    │      │  - ErrorMessage  │
    │      └──────────────────┘
    │
    ▼
┌──────────────────┐
│  Process Results │
│  Return Success  │
└──────────────────┘
```

## Component Interaction

```
┌─────────────────────────────────────────────────────┐
│                    Server Process                    │
│                                                      │
│  ┌──────────────┐         ┌──────────────┐         │
│  │   HTTP       │         │   Cron       │         │
│  │   Server     │         │   Scheduler  │         │
│  └──────┬───────┘         └──────┬───────┘         │
│         │                        │                  │
│         │                        │                  │
│         ▼                        ▼                  │
│  ┌──────────────┐         ┌──────────────┐         │
│  │   Router     │         │  Night Audit │         │
│  │              │         │     Job      │         │
│  └──────┬───────┘         └──────┬───────┘         │
│         │                        │                  │
│         ▼                        │                  │
│  ┌──────────────┐                │                  │
│  │   Handler    │◄───────────────┘                  │
│  │              │                                   │
│  └──────┬───────┘                                   │
│         │                                           │
│         ▼                                           │
│  ┌──────────────┐                                   │
│  │   Database   │                                   │
│  │   Pool       │                                   │
│  └──────────────┘                                   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Logging Flow

```
┌──────────────┐
│  Log Event   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  Format Message  │
│  [NIGHT-AUDIT]   │
│  Timestamp       │
│  Message         │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Write to Log    │
│  - Console       │
│  - File (if cfg) │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Log Stored      │
│  Available for   │
│  Monitoring      │
└──────────────────┘
```

## Summary

The night audit system follows a clean, predictable workflow:

1. **Initialization**: Job is created and scheduled when server starts
2. **Scheduling**: Cron waits for 02:00 AM daily
3. **Execution**: Updates occupied rooms to dirty status
4. **Logging**: Records all activities with timestamps
5. **Manual Control**: Managers can trigger anytime via API
6. **Error Handling**: Comprehensive error catching and logging
7. **Graceful Shutdown**: Stops cleanly when server stops

All flows are designed for reliability, observability, and maintainability.
