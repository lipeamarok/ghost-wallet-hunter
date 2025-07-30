# SpadeAgent (Sam Spade)

## Overview

**SpadeAgent** is inspired by Sam Spade, the hard-boiled detective famous for his direct, no-nonsense approach to risk and threat assessment. In Ghost Wallet Hunter, SpadeAgent specializes in classifying risk, identifying threat levels, and recommending immediate actions for suspicious wallets.

## Responsibilities

- Quick and accurate risk assessment of wallets
- Threat level classification (criminal, organized crime, etc.)
- Actionable recommendations for investigation or escalation
- Final risk reporting for law enforcement or compliance
- Numeric risk scoring and level mapping

## How it works

- Initializes by testing AI service connectivity
- Assesses wallet risk using evidence and AI-powered analysis
- Classifies threat level and sophistication
- Recommends actions (immediate, short-term, long-term, contingency)
- Compiles a final risk report with verdict, evidence, risk, and action plan
- Calculates numeric risk score and maps to risk level

## Strengths

- Extremely direct and actionable output
- Focuses on real-world risk and threat classification
- Provides clear, jury-ready reports and recommendations
- Numeric scoring for easy integration with dashboards

## Weaknesses / Gaps

- Relies on AI and evidence quality for accuracy
- May overlap with Poirot/Marple in some behavioral analysis (refactor shared logic?)
- Does not perform deep pattern analysis (focuses on risk, not detection)

## Suggestions for Improvement

- Refactor shared risk/threat logic with other agents to a utility module
- Enhance evidence gathering and cross-agent integration
- Add more automated alerting/escalation hooks

## Example Usage

```python
from agents.spade_agent import SpadeAgent
spade = SpadeAgent()
await spade.initialize()
risk = await spade.assess_wallet_risk('wallet_address_here', evidence)
```

---
*This document is auto-generated. Please expand with more technical details as needed.*
