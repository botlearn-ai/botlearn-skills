# D1-Q1-EASY Reference Answer

## Question: DeepSeek-R1 vs GPT-4 API for SME Local Deployment

### Key Points Checklist

A qualified answer MUST cover these points. Use this checklist during self-evaluation.

---

### Advantages of DeepSeek-R1 (minimum 3 required)

1. **Cost efficiency**: Training cost ~1/20 of GPT-4. No per-token API fees for local deployment. Total cost of ownership significantly lower for sustained usage.

2. **Open-source flexibility**: Full model weights available. Enterprise can fine-tune on proprietary data, customize for domain-specific tasks, and audit the model internals.

3. **Data sovereignty / privacy**: Local deployment means sensitive data never leaves the enterprise network. Critical for regulated industries (finance, healthcare, government).

4. **No vendor lock-in**: Not dependent on OpenAI API availability, pricing changes, or terms of service updates. Enterprise controls the entire stack.

5. **Competitive reasoning capability**: Outscored GPT-4o on AIME 2024 math competition, demonstrating strong reasoning — the core capability an SME would need.

### Disadvantages of DeepSeek-R1 (minimum 2 required)

1. **Infrastructure and maintenance burden**: Requires enterprise to provision and maintain GPU servers. Needs dedicated DevOps/ML engineering staff. Hardware costs (A100/H100 GPUs) are significant upfront investment.

2. **Ecosystem and tooling gap**: GPT-4 API has mature ecosystem — function calling, fine-tuning API, assistants API, extensive documentation, third-party integrations. DeepSeek-R1's open-source ecosystem is less mature.

3. **No SLA or commercial support**: GPT-4 API comes with uptime guarantees, enterprise support, and compliance certifications. Self-hosted DeepSeek-R1 has no vendor support — the enterprise bears all operational risk.

4. **Update cadence**: OpenAI continuously improves GPT-4 via API — enterprise gets improvements automatically. Self-hosted model requires manual updates, redeployment, and testing.

### Recommendation (must be conditional)

A strong recommendation distinguishes by company profile:

- **For SMEs with ML engineering capacity and data privacy requirements**: DeepSeek-R1 local deployment is recommended. The cost savings and data control outweigh the operational overhead.
- **For SMEs without GPU infrastructure or ML ops team**: GPT-4 API is more practical. The total cost (API fees + zero infrastructure) may actually be lower than building local GPU capacity.
- **Hybrid approach**: Use DeepSeek-R1 locally for sensitive/high-volume workloads, GPT-4 API for occasional tasks or as a fallback.

### Scoring Anchors

| Criterion | Score 3 anchor | Score 5 anchor |
|-----------|---------------|---------------|
| Advantages | Lists 3 but misses data sovereignty or vendor lock-in | Covers cost + open-source + privacy + at least one more |
| Disadvantages | Lists 2 but stays surface-level (e.g., "harder to set up") | Specifically names infrastructure cost, ecosystem gap, or SLA absence |
| Reasoning chain | Conclusions stated but not derived from the given facts | Each advantage/disadvantage traces back to facts (1), (2), or (3) |
| Recommendation | Generic "it depends" without conditions | Distinguishes by company size, capability, and use case |
