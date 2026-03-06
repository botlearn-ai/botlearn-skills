# @botlearn/botlearn-certify

OpenClaw Agent Capability Certification System — compares assessment history, evaluates growth, and generates professional capability certificates in HTML + MD.

## How It Works

The certification process has 3 flows that run in sequence:

```
Flow 1: Historical Assessment Retrieval
    → Check if botlearn-assessment is installed
    → Read INDEX.md for past exam records
    → Parse the most recent full-exam report as baseline

Flow 2: Fresh Assessment Execution
    → Invoke botlearn-assessment full exam (5 dimensions)
    → Agent takes the exam autonomously (no user interaction)
    → Capture new exam report

Flow 3: Certificate Generation
    → Compare historical vs fresh scores
    → Calculate improvement per dimension
    → Classify professional profile based on overall score
    → Generate HTML certificate (rich visual, printable)
    → Generate MD certificate (portable, lightweight)
```

## Use Cases

| Scenario | What Happens |
|----------|-------------|
| First certification | Runs a baseline exam, generates an initial certificate |
| Repeat certification | Compares with previous results, highlights growth areas |
| After self-optimization | Measures improvement from targeted practice |
| Periodic review | Tracks capability trajectory over time |

## Key Principles

- **Data-driven**: All conclusions based on actual assessment scores, never fabricated
- **Dynamic comparison**: Dimension names parsed from result files via regex, never hardcoded
- **Emotional value**: Certificates are celebratory and encouraging, highlighting growth
- **Dual format**: Always generates both HTML and MD certificates

## Output Files

```
results/
├── certificate-{YYYYMMDD}-{HHmm}.html    ← Rich visual certificate (printable)
└── certificate-{YYYYMMDD}-{HHmm}.md      ← Portable Markdown certificate
```

## Triggers

```
certify / certificate / 认证 / 证书 / 生成证书
能力认证 / 教育证书 / 毕业证 / 我要拿证 / 给我发证
```

## Dependencies

Requires `botlearn-assessment` — the certification system needs exam results to evaluate.

## File Structure

```
botlearn-certify/
├── SKILL.md                              # Entry point: roles, 3-flow pipeline
├── flows/
│   ├── flow1-historical.md               # Historical assessment retrieval
│   ├── flow2-fresh-exam.md               # Fresh exam invocation
│   └── flow3-certificate.md              # Certificate generation logic
├── knowledge/
│   └── comparison-methodology.md         # Dynamic comparison methodology
├── strategies/
│   └── classification.md                 # Professional profile classification
├── assets/
│   ├── certificate-html-template.md      # HTML certificate template
│   └── certificate-md-template.md        # MD certificate template
├── scripts/
│   └── check-assessment.sh               # Verify assessment dependency
└── results/                              # Generated certificates (runtime)
```

## Install

```bash
clawhub install @botlearn/botlearn-certify --force
```

## Version

Current: 0.1.5

## License

MIT
