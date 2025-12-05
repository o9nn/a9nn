# GitHub Actions Workflow Architecture

## Workflow Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Push/PR Event                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┬──────────────┐
         │               │               │              │
         ▼               ▼               ▼              ▼
   ┌─────────┐     ┌─────────┐   ┌──────────┐   ┌──────────┐
   │ lint.yml│     │build.yml│   │ test.yml │   │  e2e.yml │
   │         │     │         │   │          │   │          │
   │ Code    │     │ Multi   │   │ Test     │   │ End-to   │
   │ Quality │     │ Platform│   │ Suites   │   │ End      │
   └────┬────┘     └────┬────┘   └────┬─────┘   └────┬─────┘
        │               │             │              │
        │               │             │              │
        └───────┬───────┴─────┬───────┘              │
                │             │                      │
                ▼             ▼                      ▼
          ┌──────────────────────┐           ┌─────────────┐
          │     ci.yml           │           │  Scheduled  │
          │  (Orchestrator)      │           │  Daily 2AM  │
          │                      │           └─────────────┘
          │ Lint → Build → Test  │
          └──────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                        Tag Push Event                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
                  ┌─────────────┐
                  │ release.yml │
                  │             │
                  │ 1. Create   │
                  │    Release  │
                  │ 2. Build    │
                  │    Binaries │
                  │ 3. Upload   │
                  │    Artifacts│
                  └─────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                   Documentation Push Event                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
                  ┌─────────────┐
                  │  docs.yml   │
                  │             │
                  │ 1. Build    │
                  │    Docs     │
                  │ 2. Deploy   │
                  │    to Pages │
                  └─────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                   Weekly Schedule Event                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
                  ┌─────────────┐
                  │security.yml │
                  │             │
                  │ 1. Deps     │
                  │ 2. Security │
                  │ 3. License  │
                  │ 4. Quality  │
                  └─────────────┘
```

## Workflow Execution Flow

### Standard PR Flow
```
Pull Request Created
       │
       ├─→ lint.yml    (2-3 min)   ✓
       ├─→ build.yml   (5-10 min)  ✓
       ├─→ test.yml    (5-8 min)   ✓
       └─→ ci.yml      (8-12 min)  ✓
                 │
                 ▼
         All Checks Pass
                 │
                 ▼
         Ready to Merge
```

### Main Branch Flow
```
Merge to Main
       │
       ├─→ lint.yml      ✓
       ├─→ build.yml     ✓
       ├─→ test.yml      ✓
       ├─→ e2e.yml       ✓
       ├─→ ci.yml        ✓
       ├─→ docs.yml      ✓ → Deploy to GitHub Pages
       └─→ security.yml  ✓ → Generate Reports
```

### Release Flow
```
Tag Created (v1.0.0)
       │
       ▼
  release.yml
       │
       ├─→ Create Release      ✓
       ├─→ Generate Changelog  ✓
       ├─→ Create Rockspec     ✓
       ├─→ Build Binaries      ✓
       │   ├─→ LuaJIT 2.1     ✓
       │   └─→ Lua 5.1        ✓
       └─→ Upload Artifacts    ✓
                 │
                 ▼
         GitHub Release Published
```

## Caching Architecture

```
┌──────────────────────────────────────────────┐
│              Cache Layer                     │
├──────────────────────────────────────────────┤
│                                              │
│  ┌─────────────┐      ┌──────────────┐     │
│  │  OpenBLAS   │      │    Torch     │     │
│  │   Cache     │      │    Cache     │     │
│  │             │      │              │     │
│  │ Key: OS-    │      │ Key: OS-     │     │
│  │   Compiler  │      │   Compiler-  │     │
│  │   -v1       │      │   Lua-v1     │     │
│  │             │      │              │     │
│  │ ~5-10 min   │      │ ~15-20 min   │     │
│  │ build time  │      │ build time   │     │
│  └─────────────┘      └──────────────┘     │
│                                              │
└──────────────────────────────────────────────┘
         │                      │
         └──────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   Build Workflows     │
        │   (build, test, ci,   │
        │    e2e, release)      │
        └───────────────────────┘
```

## Artifact Flow

```
Workflow Execution
       │
       ├─→ Build Artifacts (7 days)
       │   └─→ build-{os}-{compiler}-{lua}
       │
       ├─→ Test Logs (30 days)
       │   ├─→ test-logs-{os}-{lua}
       │   ├─→ test-nnecco-output.log
       │   └─→ test-agent-output.log
       │
       ├─→ Lint Results (30 days)
       │   └─→ luacheck-results
       │
       ├─→ E2E Reports (30 days)
       │   └─→ e2e-test-report
       │
       ├─→ Security Reports (90 days)
       │   ├─→ dependency-report
       │   ├─→ license-report
       │   └─→ code-quality-report
       │
       ├─→ Documentation (90 days)
       │   └─→ documentation
       │
       └─→ Release Binaries (90 days)
           └─→ release-binary-{lua}
```

## Matrix Build Strategy

```
build.yml Matrix:
┌─────────────────────────────────────────────┐
│                                             │
│  Ubuntu 20.04                Ubuntu 22.04  │
│  ├─ gcc                      ├─ gcc        │
│  │  ├─ LuaJIT 2.1           │  ├─ LuaJIT  │
│  │  ├─ Lua 5.1              │  └─ Lua 5.2 │
│  │  └─ Lua 5.2              │             │
│  └─ clang                    └─ clang      │
│     ├─ LuaJIT 2.1              ├─ LuaJIT  │
│     ├─ Lua 5.1                 └─ Lua 5.1 │
│     └─ Lua 5.2                            │
│                                             │
│  Total: 8 concurrent builds                │
└─────────────────────────────────────────────┘

test.yml Matrix:
┌─────────────────────────┐
│  Ubuntu 20.04           │
│  └─ gcc                 │
│     ├─ LuaJIT 2.1       │
│     └─ Lua 5.1          │
│                         │
│  Total: 2 builds        │
└─────────────────────────┘
```

## Scheduled Workflows

```
┌───────────────────────────────────────┐
│        Schedule Timeline              │
├───────────────────────────────────────┤
│                                       │
│  Daily 2:00 AM UTC                   │
│    └─→ e2e.yml (Integration Tests)   │
│                                       │
│  Weekly Monday 0:00 UTC              │
│    └─→ security.yml (Security Scan)  │
│                                       │
└───────────────────────────────────────┘
```

## Status Reporting Flow

```
┌──────────────────────────────────────────┐
│         Workflow Execution               │
└────────────┬─────────────────────────────┘
             │
             ├─→ GitHub Checks API
             │   └─→ PR Status Updates
             │
             ├─→ Artifacts Upload
             │   └─→ Logs, Reports, Binaries
             │
             ├─→ Status Badges
             │   └─→ README.md Updates
             │
             └─→ GitHub Notifications
                 └─→ Email on Failure
```

## Resource Usage Optimization

```
┌──────────────────────────────────────────┐
│     Resource Optimization Strategy       │
├──────────────────────────────────────────┤
│                                          │
│  1. Parallel Execution                  │
│     └─→ Matrix builds run concurrently  │
│                                          │
│  2. Smart Caching                       │
│     └─→ 90% build time reduction        │
│                                          │
│  3. Conditional Execution               │
│     └─→ Skip on doc-only changes        │
│                                          │
│  4. Artifact Cleanup                    │
│     └─→ Retention periods by importance  │
│                                          │
│  5. Continue on Error                   │
│     └─→ Non-critical steps don't block   │
│                                          │
└──────────────────────────────────────────┘
```

## Security Architecture

```
┌──────────────────────────────────────────┐
│        Security Layers                   │
├──────────────────────────────────────────┤
│                                          │
│  Layer 1: Code Quality                  │
│    └─→ lint.yml (Style & Standards)     │
│                                          │
│  Layer 2: Dependency Check              │
│    └─→ security.yml (Dependencies)      │
│                                          │
│  Layer 3: Vulnerability Scan            │
│    └─→ security.yml (Pattern Matching)  │
│                                          │
│  Layer 4: License Compliance            │
│    └─→ security.yml (License Check)     │
│                                          │
│  Layer 5: Integration Testing           │
│    └─→ e2e.yml (Security Features)      │
│                                          │
└──────────────────────────────────────────┘
```

## Legend

```
Symbols:
  ─→  : Flow direction
  ├─→ : Branch/parallel execution
  └─→ : Final step
  ▼   : Continues to
  ✓   : Success state

Duration:
  Quick    : < 5 minutes
  Medium   : 5-15 minutes
  Long     : 15-60 minutes

Retention:
  Short    : 7 days
  Medium   : 30 days
  Long     : 90 days
```
