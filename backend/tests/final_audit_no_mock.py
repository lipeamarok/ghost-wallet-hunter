#!/usr/bin/env python3
"""
🔍 Final Audit: No Mock Data Test
Complete test to ensure NO mock data is being used anywhere in the system.
"""

import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from agents.marple_agent import MarpleAgent
from agents.poirot_agent import PoirotAgent
from services.solana_service import SolanaService

console = Console()

async def audit_no_mock_data():
    """Complete audit to ensure no mock data is used."""
    
    console.print(Panel.fit("🔍 Final Audit: No Mock Data Test", style="bold blue"))
    
    # Real wallet address with actual transactions
    real_wallet = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    
    console.print(f"\n🎯 Testing with REAL wallet: {real_wallet}")
    console.print("Expected: Real blockchain data only, NO mock signatures")
    
    results = Table()
    results.add_column("Agent/Service", style="cyan")
    results.add_column("Status", style="green")
    results.add_column("Data Type", style="yellow")
    results.add_column("Validation", style="magenta")
    
    try:
        # Test 1: Direct SolanaService
        console.print("\n📡 Testing SolanaService directly...")
        solana = SolanaService()
        transactions = await solana.get_wallet_transactions(real_wallet, limit=5)
        
        has_mock_sigs = any("mock_" in str(tx.get('signature', '')) for tx in transactions)
        
        if has_mock_sigs:
            results.add_row("SolanaService", "❌ FAIL", "Mock Data", "Contains mock signatures")
        else:
            results.add_row("SolanaService", "✅ PASS", "Real Data", f"{len(transactions)} real transactions")
        
        # Test 2: Marple Agent
        console.print("\n👵 Testing Miss Marple...")
        marple = MarpleAgent()
        await marple.initialize()
        marple_txs = await marple.solana.get_wallet_transactions(real_wallet, limit=3)
        
        marple_mock = any("mock_" in str(tx.get('signature', '')) for tx in marple_txs)
        
        if marple_mock:
            results.add_row("Marple Agent", "❌ FAIL", "Mock Data", "Still using mock data")
        else:
            results.add_row("Marple Agent", "✅ PASS", "Real Data", f"{len(marple_txs)} real transactions")
        
        # Test 3: Poirot Agent
        console.print("\n🕵️ Testing Hercule Poirot...")
        poirot = PoirotAgent()
        await poirot.initialize()
        poirot_txs = await poirot.solana_service.get_wallet_transactions(real_wallet, limit=3)
        
        poirot_mock = any("mock_" in str(tx.get('signature', '')) for tx in poirot_txs)
        
        if poirot_mock:
            results.add_row("Poirot Agent", "❌ FAIL", "Mock Data", "Still using mock data")
        else:
            results.add_row("Poirot Agent", "✅ PASS", "Real Data", f"{len(poirot_txs)} real transactions")
        
        # Test 4: Check for mock signatures specifically
        console.print("\n🔍 Checking for mock signature patterns...")
        all_transactions = transactions + marple_txs + poirot_txs
        mock_patterns = ["mock_", "fake_", "demo_", "test_"]
        
        mock_count = 0
        for tx in all_transactions:
            sig = str(tx.get('signature', ''))
            for pattern in mock_patterns:
                if pattern in sig.lower():
                    mock_count += 1
                    console.print(f"⚠️ Found mock signature: {sig}", style="red")
        
        if mock_count == 0:
            results.add_row("Signature Check", "✅ PASS", "Real Data", "No mock signatures found")
        else:
            results.add_row("Signature Check", "❌ FAIL", "Mock Data", f"{mock_count} mock signatures found")
        
        console.print("\n")
        console.print(results)
        
        # Final verdict
        all_passed = not any([has_mock_sigs, marple_mock, poirot_mock, mock_count > 0])
        
        if all_passed:
            console.print("\n🎉 AUDIT PASSED: No mock data found! System using real blockchain data only.", style="bold green")
        else:
            console.print("\n❌ AUDIT FAILED: Mock data still present in system!", style="bold red")
        
        return all_passed
        
    except Exception as e:
        console.print(f"❌ Audit error: {e}", style="red")
        return False

if __name__ == "__main__":
    asyncio.run(audit_no_mock_data())
