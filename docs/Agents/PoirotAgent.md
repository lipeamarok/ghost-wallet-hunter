# PoirotAgent (Hercule Poirot)

## Overview

**PoirotAgent** is inspired by the legendary detective Hercule Poirot, focusing on meticulous transaction analysis and behavioral pattern detection on the blockchain. This agent applies methodical logic and psychological profiling to uncover suspicious activity, using real AI (OpenAI/Grok) for deep analysis.

## Responsibilities

- Transaction analysis with high attention to detail
- Behavioral pattern detection
- Related wallet clustering
- Identification of temporal anomalies
- Produces detailed explanations and risk assessments

## How it works

- Initializes by testing AI service connectivity
- Investigates a wallet by:
  1. Generating a behavioral profile prompt for the AI
  2. Fetching all transactions for the wallet
  3. Analyzing behavioral patterns and temporal anomalies
  4. Producing a risk assessment and detailed explanation

## Strengths

- Very strong at psychological and behavioral analysis
- Leverages AI for nuanced, human-like deduction
- Provides detailed, narrative-style explanations

## Weaknesses / Gaps

- Relies heavily on the quality of AI responses and transaction data
- May duplicate some pattern logic with MarpleAgent (pattern/anomaly detection)
- Does not directly classify threats or recommend actions (handled by SpadeAgent)

## Suggestions for Improvement

- Consider refactoring shared pattern/anomaly logic with MarpleAgent to a utility module
- Enhance cross-agent communication for richer context
- Add more direct threat classification or action recommendations

## Example Usage

```python
from agents.poirot_agent import PoirotAgent
poirot = PoirotAgent()
await poirot.initialize()
result = await poirot.investigate_wallet('wallet_address_here')
```

---
*This document is auto-generated. Please expand with more technical details as needed.*
