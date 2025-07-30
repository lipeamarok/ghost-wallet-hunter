# DupinAgent (C. Auguste Dupin)

## Overview

**DupinAgent** is inspired by C. Auguste Dupin, the analytical detective from Poe's stories, specializing in compliance, AML, and regulatory intelligence. In Ghost Wallet Hunter, DupinAgent applies methodical reasoning to detect money laundering, sanctions exposure, and regulatory risks.

## Responsibilities

- Anti-Money Laundering (AML) analysis
- Sanctions screening and compliance
- Regulatory risk assessment (multi-jurisdictional)
- Financial intelligence gathering and network analysis
- Compiling comprehensive compliance and regulatory reports

## How it works

- Initializes by testing AI service connectivity
- Performs AML analysis using established frameworks (FATF, EU, US, etc.)
- Conducts sanctions screening against global lists (OFAC, EU, UN, etc.)
- Assesses regulatory compliance across jurisdictions (KYC, tax, data, etc.)
- Analyzes financial intelligence and network patterns
- Compiles all findings into a detailed compliance report with risk and recommendations

## Strengths

- Highly methodical and analytical approach
- Covers full compliance, AML, and regulatory spectrum
- Uses AI for deep pattern and typology detection
- Tracks frameworks, sanctions lists, and risk indicators

## Weaknesses / Gaps

- Relies on AI and data quality for accuracy
- May overlap with MarloweAgent in network/obfuscation analysis (refactor shared logic?)
- Does not directly classify threat/risk (focuses on compliance, not risk assessment)

## Suggestions for Improvement

- Refactor shared compliance/network logic to a utility module
- Enhance cross-agent evidence/context sharing
- Add more automated detection of new/emerging regulations

## Example Usage

```python
from agents.dupin_agent import DupinAgent
dupin = DupinAgent()
await dupin.initialize()
result = await dupin.perform_aml_analysis('wallet_address_here', transaction_data)
```

---
*This document is auto-generated. Please expand with more technical details as needed.*
