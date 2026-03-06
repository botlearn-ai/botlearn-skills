# D2-Q1-EASY Reference Answer

## Question: BLS Unemployment Rates — June 2009

### Expected Values (Programmatic Verification)

Source: Bureau of Labor Statistics, Current Population Survey (CPS)
Table: "Employment status of the civilian noninstitutional population by sex and age, seasonally adjusted"
URL: https://www.bls.gov/cps/cpsaat01.htm (or CPS historical data tables)

---

### Correct Data Points

| Metric | Value |
|--------|-------|
| Men aged 20 and over, unemployment rate, June 2009 | **10.0%** |
| Women aged 20 and over, unemployment rate, June 2009 | **7.6%** |
| Difference (men - women) | **2.4 percentage points** |

### Source Citation

The data comes from BLS Table A-1: "Employment status of the civilian noninstitutional population 16 years and over by sex, 1976 to date" or Table A-4 by age group, available at:
- https://www.bls.gov/web/empsit/cpseea04.htm
- Alternative: CPS Labor Force Statistics data finder at https://www.bls.gov/cps/data.htm

### Scoring Guide

| Criterion | Score 0 | Score 3 (partial) | Score 5 (full) |
|-----------|---------|-------------------|----------------|
| Numerical accuracy (50%) | Both numbers wrong or fabricated | One number correct within 0.5pp | Both numbers exactly correct |
| Difference calculation (20%) | Wrong or not attempted | Numbers correct but arithmetic error | 2.4pp correctly calculated |
| Source citation (30%) | No source or "from BLS" only | Names "CPS" or "Table A-1" but no URL | Specific table name + URL path |

### Common Failure Modes

1. **Memory-based guessing**: Agent cites approximate numbers from training data (e.g., "around 9.5% and 7.8%") without actually searching — should score 0-20
2. **Wrong time period**: Cites annual 2009 average instead of June 2009 specifically
3. **Wrong age group**: Cites "16 years and over" instead of "20 years and over"
4. **No actual search performed**: If agent cannot access bls.gov, this question should be SKIPPED (tool dependency: web_search)
