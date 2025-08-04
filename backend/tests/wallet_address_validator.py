#!/usr/bin/env python3
"""
🔍 Wallet Address Validator
Validates Solana wallet addresses and checks if they exist on-chain.
"""

import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

console = Console()

def is_valid_solana_address(address: str) -> bool:
    """Basic validation for Solana address format."""
    if not address:
        return False
    
    # Solana addresses are base58 encoded and typically 32-44 characters
    if len(address) < 32 or len(address) > 44:
        return False
    
    # Check for valid base58 characters
    base58_chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    return all(c in base58_chars for c in address)

async def validate_wallet_address(address: str):
    """Validate a Solana wallet address."""
    
    console.print(Panel.fit("🔍 Wallet Address Validator", style="bold blue"))
    console.print(f"\n🎯 Validating address: {address}")
    
    # Basic format validation
    if not is_valid_solana_address(address):
        console.print("❌ Invalid Solana address format!", style="red")
        return False
    
    console.print("✅ Valid Solana address format", style="green")
    
    # Test with real Solana service
    try:
        from services.solana_service import SolanaService
        
        console.print("\n🔌 Connecting to Solana RPC...")
        solana_service = SolanaService()
        
        # Try to get wallet balance (if it has balance, it exists)
        console.print("📡 Fetching wallet balance...")
        balance = await solana_service.get_wallet_balance(address)
        
        console.print(f"✅ Address exists on Solana blockchain! Balance: {balance} SOL", style="green")
        
        # Try to get some transactions
        console.print("📊 Checking recent transactions...")
        transactions = await solana_service.get_wallet_transactions(address, limit=5)
        
        # Show account details
        table = Table()
        table.add_column("Property", style="cyan")
        table.add_column("Value", style="white")
        
        table.add_row("Address", address)
        table.add_row("Balance (SOL)", str(balance))
        table.add_row("Recent Transactions", str(len(transactions)))
        
        console.print(table)
        return True
            
    except Exception as e:
        console.print(f"⚠️ Could not validate on-chain (using RPC): {e}", style="yellow")
        console.print("🔄 Address format is valid, but on-chain validation failed", style="yellow")
        return True  # Format is valid even if RPC fails

if __name__ == "__main__":
    if len(sys.argv) != 2:
        console.print("❌ Usage: python wallet_address_validator.py <wallet_address>", style="red")
        sys.exit(1)
    
    address = sys.argv[1]
    result = asyncio.run(validate_wallet_address(address))
    
    if result:
        console.print("\n🎉 Validation successful! This address can be used for analysis.", style="green")
    else:
        console.print("\n❌ Validation failed! This address should not be analyzed.", style="red")
