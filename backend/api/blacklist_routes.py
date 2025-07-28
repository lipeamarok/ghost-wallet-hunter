"""
Blacklist API Routes
Endpoints for wallet blacklist verification and management
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Any
import logging

from services.blacklist_checker import check_wallet_blacklist, check_wallets_blacklist, blacklist_checker

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/blacklist", tags=["blacklist"])

@router.get("/check/{wallet_address}")
async def check_single_wallet(wallet_address: str) -> Dict[str, Any]:
    """
    🛡️ Check if a single wallet address is blacklisted

    Returns comprehensive blacklist information including:
    - Blacklist status
    - Threat level
    - Warning messages
    - Recommendations
    """
    try:
        logger.info(f"🔍 Checking blacklist for wallet: {wallet_address}")
        result = await check_wallet_blacklist(wallet_address)
        return {
            "success": True,
            "data": result
        }
    except Exception as e:
        logger.error(f"❌ Blacklist check error: {e}")
        raise HTTPException(status_code=500, detail=f"Error checking blacklist: {str(e)}")

@router.post("/check-multiple")
async def check_multiple_wallets(wallet_addresses: List[str]) -> Dict[str, Any]:
    """
    🛡️ Check multiple wallet addresses against blacklist

    Body: ["address1", "address2", "address3"]

    Returns summary with individual results for each address
    """
    try:
        if len(wallet_addresses) > 50:
            raise HTTPException(status_code=400, detail="Maximum 50 addresses per request")

        logger.info(f"🔍 Checking blacklist for {len(wallet_addresses)} wallets")
        result = await check_wallets_blacklist(wallet_addresses)
        return {
            "success": True,
            "data": result
        }
    except Exception as e:
        logger.error(f"❌ Multiple blacklist check error: {e}")
        raise HTTPException(status_code=500, detail=f"Error checking blacklist: {str(e)}")

@router.get("/stats")
async def get_blacklist_stats() -> Dict[str, Any]:
    """
    📊 Get blacklist statistics and status

    Returns information about:
    - Total addresses in blacklist
    - Last update time
    - Sources active
    - Cache status
    """
    try:
        stats = await blacklist_checker.get_stats()
        return {
            "success": True,
            "data": stats
        }
    except Exception as e:
        logger.error(f"❌ Stats error: {e}")
        raise HTTPException(status_code=500, detail=f"Error getting stats: {str(e)}")

@router.post("/update")
async def force_update_blacklist() -> Dict[str, Any]:
    """
    🔄 Force update of blacklist from all sources

    Admin endpoint to manually trigger blacklist refresh
    """
    try:
        logger.info("🔄 Manual blacklist update triggered")
        success = await blacklist_checker.update_blacklists()

        if success:
            stats = await blacklist_checker.get_stats()
            return {
                "success": True,
                "message": "Blacklist updated successfully",
                "data": stats
            }
        else:
            return {
                "success": False,
                "message": "Blacklist update failed",
                "data": {}
            }
    except Exception as e:
        logger.error(f"❌ Update error: {e}")
        raise HTTPException(status_code=500, detail=f"Error updating blacklist: {str(e)}")

@router.get("/search/{query}")
async def search_blacklist(query: str) -> Dict[str, Any]:
    """
    🔍 Search blacklist for addresses containing query string

    Useful for finding related addresses or checking partial matches
    """
    try:
        if len(query) < 4:
            raise HTTPException(status_code=400, detail="Query must be at least 4 characters")

        # Search through blacklisted addresses
        matching_addresses = []
        for address in blacklist_checker.scam_addresses:
            if query.lower() in address.lower():
                matching_addresses.append(address)
                if len(matching_addresses) >= 20:  # Limit results
                    break

        return {
            "success": True,
            "data": {
                "query": query,
                "matches_found": len(matching_addresses),
                "addresses": matching_addresses[:20]  # Limit to 20 results
            }
        }
    except Exception as e:
        logger.error(f"❌ Search error: {e}")
        raise HTTPException(status_code=500, detail=f"Error searching blacklist: {str(e)}")
