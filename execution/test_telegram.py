#!/usr/bin/env python3
"""Test Telegram API connectivity."""
import asyncio
import httpx

async def test():
    async with httpx.AsyncClient(timeout=30.0) as c:
        r = await c.get('https://api.telegram.org/bot8803597504:AAHZ4KKasqGBz_LrgXYqx2YtqtpsZOn7QxQ/getMe')
        print(f"Status: {r.status_code}")
        print(f"Response: {r.text}")

if __name__ == "__main__":
    asyncio.run(test())
