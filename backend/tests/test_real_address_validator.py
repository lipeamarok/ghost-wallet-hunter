#!/usr/bin/env python3
"""
🔍 Real Wallet Address Validator & Tester
Validates Solana addresses and tests with REAL wallet data only.
"""

import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
import re
from services.enhanced_solana_service import get_solana_service

console = Console()

class RealAddressValidator:
    """Validates and tests only with real Solana addresses."""
    
    @staticmethod
    def is_valid_solana_address(address: str) -> bool:
        """Validate Solana address format (Base58, 32-44 chars)."""
        if not address or len(address) < 32 or len(address) > 44:
            return False
        
        # Base58 alphabet (no 0, O, I, l)
        base58_pattern = r'^[1-9A-HJ-NP-Za-km-z]+$'
        return bool(re.match(base58_pattern, address))
    
    @staticmethod
    async def verify_real_address(address: str) -> dict:
        """Verify if address exists on Solana blockchain."""
        try:
            solana_service = await get_solana_service()
            
            # Try to get real data
            result = await solana_service.get_wallet_analysis(address, limit=1)
            
            # Check if we got real data or mock data
            transactions = result.get("transactions", [])
            
            # Detect mock data patterns
            mock_indicators = [
                "mock_tx_",
                "wallet_0", "wallet_1", "wallet_2",  # Mock counterparties
                "DemoWallet", "Testing", "Fake"
            ]
            
            is_mock = False
            if transactions:
                for tx in transactions:
                    tx_str = str(tx)
                    if any(indicator in tx_str for indicator in mock_indicators):
                        is_mock = True
                        break
            
            return {
                "address": address,
                "exists": len(transactions) > 0,
                "is_real": not is_mock,
                "transaction_count": len(transactions),
                "analysis_safe": not is_mock and len(transactions) > 0
            }
            
        except Exception as e:
            return {
                "address": address,
                "exists": False,
                "is_real": False,
                "transaction_count": 0,
                "analysis_safe": False,
                "error": str(e)
            }

async def test_addresses():
    """Test various addresses to demonstrate the validator."""
    
    console.print(Panel.fit("🔍 Real Wallet Address Validator", style="bold blue"))
    
    validator = RealAddressValidator()
    
    # Test addresses
    test_addresses = [
        # Fake/Demo addresses that should be rejected
        "DemoWalletAddressForTesting123456789012345",
        "FakeWallet123",
        "TestAddress",
        
        # Real Solana addresses (famous ones)
        "11111111111111111111111111111111",  # System Program
        "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",  # Token Program
        "So11111111111111111111111111111111111111112",  # Wrapped SOL
        "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",  # Example wallet
        
        # Invalid format addresses
        "123",
        "invalid_address_with_invalid_chars!@#",
        ""
    ]
    
    console.print("\n📋 Address Validation Results:")
    
    table = Table()
    table.add_column("Address", style="cyan")
    table.add_column("Format Valid", style="yellow")
    table.add_column("Real Address", style="green")
    table.add_column("Analysis Safe", style="red")
    table.add_column("Transactions")
    
    for address in test_addresses:
        # Format validation
        format_valid = validator.is_valid_solana_address(address)
        
        if format_valid:
            # Real address check
            verification = await validator.verify_real_address(address)
            
            real_status = "✅ Real" if verification["is_real"] else "❌ Mock/Fake"
            safe_status = "✅ Safe" if verification["analysis_safe"] else "❌ Unsafe"
            tx_count = str(verification["transaction_count"])
            
        else:
            real_status = "❌ Invalid Format"
            safe_status = "❌ Unsafe"
            tx_count = "0"
        
        # Truncate long addresses for display
        display_address = address[:25] + "..." if len(address) > 28 else address
        
        table.add_row(
            display_address,
            "✅ Valid" if format_valid else "❌ Invalid",
            real_status,
            safe_status,
            tx_count
        )
    
    console.print(table)
    
    # Recommendation
    console.print("\n💡 Recommendations:")
    console.print("✅ Only analyze addresses marked as 'Analysis Safe'")
    console.print("❌ Reject any address that returns mock/fake data")
    console.print("🔍 Always validate format before checking blockchain")

async def suggest_real_addresses():
    """Suggest some real Solana addresses for testing."""
    
    console.print("\n🎯 Real Solana Addresses for Testing:")
    
    real_addresses = [
        {
            "address": "So11111111111111111111111111111111111111112",
            "description": "Wrapped SOL (wSOL) - Native token wrapper",
            "type": "Token Program"
        },
        {
            "address": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", 
            "description": "SPL Token Program",
            "type": "Program"
        },
        {
            "address": "11111111111111111111111111111111",
            "description": "System Program",
            "type": "Program"
        }
    ]
    
    for addr_info in real_addresses:
        console.print(Panel(
            f"Address: {addr_info['address']}\n"
            f"Description: {addr_info['description']}\n"
            f"Type: {addr_info['type']}",
            title=f"Real Address - {addr_info['type']}"
        ))

if __name__ == "__main__":
    asyncio.run(test_addresses())
    asyncio.run(suggest_real_addresses())
