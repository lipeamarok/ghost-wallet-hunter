#!/usr/bin/env python3
"""
🧪 Ghost Wallet Hunter - Test Runner
Executa todos os testes críticos do sistema em sequência.
"""

import asyncio
import sys
import os
import subprocess
from pathlib import Path

# Add the backend path
backend_path = Path(__file__).parent.parent
sys.path.append(str(backend_path))

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()

def run_test(test_file: str, description: str) -> dict:
    """Run a single test file and return results."""
    try:
        console.print(f"\n🧪 Running: {description}")

        result = subprocess.run(
            [sys.executable, test_file],
            cwd=backend_path,
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            return {
                "status": "✅ PASS",
                "test": test_file,
                "description": description,
                "output": result.stdout[-200:] if result.stdout else ""  # Last 200 chars
            }
        else:
            return {
                "status": "❌ FAIL",
                "test": test_file,
                "description": description,
                "output": result.stderr[-200:] if result.stderr else ""
            }
    except subprocess.TimeoutExpired:
        return {
            "status": "⏰ TIMEOUT",
            "test": test_file,
            "description": description,
            "output": "Test timed out after 60 seconds"
        }
    except Exception as e:
        return {
            "status": "💥 ERROR",
            "test": test_file,
            "description": description,
            "output": str(e)
        }

def main():
    """Run all critical tests."""
    console.print(Panel.fit("🧪 Ghost Wallet Hunter - Complete Test Suite", style="bold blue"))

    # Define critical tests in order of importance
    critical_tests = [
        ("tests/final_audit_no_mock.py", "Final Audit: No Mock Data"),
        ("tests/test_real_address_validator.py", "Address Validator"),
        ("tests/test_real_apis.py", "Real API Integration"),
        ("tests/test_basic.py", "Basic System Functionality"),
        ("tests/test_legendary_squad.py", "Detective Squad"),
        ("tests/test_real_investigation.py", "Real Investigation"),
        ("tests/test_risk_scoring_system.py", "Risk Scoring System"),
        ("tests/test_frontend_integration.py", "Frontend Integration"),
    ]

    results = []

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console,
    ) as progress:

        for test_file, description in critical_tests:
            task = progress.add_task(f"Running {description}...", total=None)

            # Check if test file exists
            test_path = backend_path / test_file
            if not test_path.exists():
                results.append({
                    "status": "🔍 NOT FOUND",
                    "test": test_file,
                    "description": description,
                    "output": f"Test file {test_file} not found"
                })
                continue

            result = run_test(test_file, description)
            results.append(result)

            progress.remove_task(task)

    # Display results table
    console.print("\n")
    table = Table(title="🧪 Test Results Summary")
    table.add_column("Status", style="bold")
    table.add_column("Test", style="cyan")
    table.add_column("Description", style="green")
    table.add_column("Notes", style="yellow")

    passed = 0
    failed = 0

    for result in results:
        table.add_row(
            result["status"],
            result["test"].split("/")[-1],  # Just filename
            result["description"],
            result["output"][:50] + "..." if len(result["output"]) > 50 else result["output"]
        )

        if "PASS" in result["status"]:
            passed += 1
        elif "FAIL" in result["status"]:
            failed += 1

    console.print(table)

    # Final summary
    console.print(f"\n📊 Test Summary:")
    console.print(f"✅ Passed: {passed}")
    console.print(f"❌ Failed: {failed}")
    console.print(f"📋 Total: {len(results)}")

    if failed == 0:
        console.print("\n🎉 ALL TESTS PASSED! System is ready for production.", style="bold green")
        return 0
    else:
        console.print(f"\n⚠️ {failed} tests failed. Please review and fix issues.", style="bold red")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
