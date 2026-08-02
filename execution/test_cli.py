import asyncio

async def test():
    p = await asyncio.create_subprocess_exec(
        'claude', '-p', '--model', 'sonnet',
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await p.communicate(b'say hi')
    print(f"stdout: {stdout.decode()}")
    print(f"stderr: {stderr.decode()}")
    print(f"return code: {p.returncode}")

asyncio.run(test())
