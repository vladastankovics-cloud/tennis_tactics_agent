#!/usr/bin/env python3
"""
Telegram Coding Agent
Remote coding assistant accessible via Telegram messenger.

Run this on your local machine to enable remote code editing from your phone.
"""

import os
import re
import json
import asyncio
import subprocess
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Telegram imports
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    filters,
)

# Configuration
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_USER_ID = int(os.getenv("TELEGRAM_USER_ID", "0"))
CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
PROJECT_PATH = os.getenv("PROJECT_PATH", os.getcwd())

# Validate configuration
if not TELEGRAM_BOT_TOKEN:
    raise ValueError("TELEGRAM_BOT_TOKEN not set in .env")
if not TELEGRAM_USER_ID:
    raise ValueError("TELEGRAM_USER_ID not set in .env")
if not CLAUDE_API_KEY and not GEMINI_API_KEY:
    raise ValueError("Either CLAUDE_API_KEY or GEMINI_API_KEY must be set in .env")

# AI Provider setup
USE_CLAUDE = bool(CLAUDE_API_KEY)

if USE_CLAUDE:
    import anthropic
    claude_client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)
    print("Using Claude API")
else:
    import google.generativeai as genai
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel("gemini-2.5-flash")
    print("Using Gemini API")

# System prompt for the AI
SYSTEM_PROMPT = """You are a coding assistant that helps with a Flutter/Dart tennis tactics app.
You have access to tools to read files, write files, search code, and run commands.

CRITICAL RULES:
1. When a task requires file operations, START your response with the JSON tool call
2. Do NOT explain or describe - just output the JSON directly
3. Example: If user says "show me main.dart", respond with: {"tool": "read_file", "path": "lib/main.dart"}
4. You can include multiple JSON objects if needed
5. Only add explanation text AFTER the JSON tool calls

Available tools (START your response with one of these JSON objects):

1. READ_FILE: Read a file's contents
   {"tool": "read_file", "path": "lib/main.dart"}

2. WRITE_FILE: Write/overwrite a file
   {"tool": "write_file", "path": "lib/utils/helper.dart", "content": "// file content here"}

3. EDIT_FILE: Replace text in a file
   {"tool": "edit_file", "path": "lib/main.dart", "old_text": "old code", "new_text": "new code"}

4. SEARCH_CODE: Search for text in files
   {"tool": "search_code", "pattern": "GeminiService", "file_pattern": "*.dart"}

5. LIST_FILES: List files matching a pattern
   {"tool": "list_files", "pattern": "lib/**/*.dart"}

6. RUN_COMMAND: Run a shell command
   {"tool": "run_command", "command": "flutter analyze"}

7. GIT_STATUS: Get git status
   {"tool": "git_status"}

8. GIT_DIFF: Get git diff
   {"tool": "git_diff"}

9. GIT_COMMIT: Commit changes
   {"tool": "git_commit", "message": "Your commit message"}

Respond with a JSON tool call OR a text response. You can chain multiple tool calls.
When you're done with tools, provide a summary of what you did.

Project path: """ + PROJECT_PATH


def is_authorized(user_id: int) -> bool:
    """Check if user is authorized to use this bot."""
    return user_id == TELEGRAM_USER_ID


def read_file(path: str) -> str:
    """Read a file's contents."""
    full_path = Path(PROJECT_PATH) / path
    if not full_path.exists():
        return f"Error: File not found: {path}"
    try:
        return full_path.read_text(encoding="utf-8")
    except Exception as e:
        return f"Error reading file: {e}"


def write_file(path: str, content: str) -> str:
    """Write content to a file."""
    full_path = Path(PROJECT_PATH) / path
    try:
        full_path.parent.mkdir(parents=True, exist_ok=True)
        full_path.write_text(content, encoding="utf-8")
        return f"Successfully wrote {len(content)} chars to {path}"
    except Exception as e:
        return f"Error writing file: {e}"


def edit_file(path: str, old_text: str, new_text: str) -> str:
    """Replace text in a file."""
    full_path = Path(PROJECT_PATH) / path
    if not full_path.exists():
        return f"Error: File not found: {path}"
    try:
        content = full_path.read_text(encoding="utf-8")
        if old_text not in content:
            return f"Error: Text not found in {path}"
        new_content = content.replace(old_text, new_text, 1)
        full_path.write_text(new_content, encoding="utf-8")
        return f"Successfully edited {path}"
    except Exception as e:
        return f"Error editing file: {e}"


def search_code(pattern: str, file_pattern: str = "*.dart") -> str:
    """Search for pattern in files."""
    try:
        # Use grep/findstr depending on OS
        if os.name == "nt":  # Windows
            cmd = f'findstr /s /n /c:"{pattern}" {file_pattern}'
        else:
            cmd = f'grep -rn "{pattern}" --include="{file_pattern}" .'

        result = subprocess.run(
            cmd,
            shell=True,
            cwd=PROJECT_PATH,
            capture_output=True,
            text=True,
            timeout=30,
        )
        output = result.stdout[:3000]  # Limit output
        if not output:
            return f"No matches found for '{pattern}'"
        return output
    except Exception as e:
        return f"Error searching: {e}"


def list_files(pattern: str) -> str:
    """List files matching a glob pattern."""
    try:
        matches = list(Path(PROJECT_PATH).glob(pattern))
        if not matches:
            return f"No files found matching '{pattern}'"
        # Limit to 50 files
        result = "\n".join(str(p.relative_to(PROJECT_PATH)) for p in matches[:50])
        if len(matches) > 50:
            result += f"\n... and {len(matches) - 50} more files"
        return result
    except Exception as e:
        return f"Error listing files: {e}"


def run_command(command: str) -> str:
    """Run a shell command."""
    # Safety check - block dangerous commands
    dangerous = ["rm -rf", "del /", "format", "mkfs", ":(){", "fork bomb"]
    if any(d in command.lower() for d in dangerous):
        return "Error: Dangerous command blocked"

    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=PROJECT_PATH,
            capture_output=True,
            text=True,
            timeout=120,
        )
        output = result.stdout + result.stderr
        return output[:3000] if output else "Command completed (no output)"
    except subprocess.TimeoutExpired:
        return "Error: Command timed out (120s limit)"
    except Exception as e:
        return f"Error running command: {e}"


def git_status() -> str:
    """Get git status."""
    return run_command("git status --short")


def git_diff() -> str:
    """Get git diff."""
    diff = run_command("git diff --stat")
    if len(diff) < 100:
        # Short diff, include actual changes
        diff += "\n\n" + run_command("git diff")[:2000]
    return diff


def git_commit(message: str) -> str:
    """Commit all changes."""
    run_command("git add -A")
    return run_command(f'git commit -m "{message}"')


def execute_tool(tool_data: dict) -> str:
    """Execute a tool based on the JSON data."""
    tool = tool_data.get("tool", "").lower()

    if tool == "read_file":
        return read_file(tool_data.get("path", ""))
    elif tool == "write_file":
        return write_file(tool_data.get("path", ""), tool_data.get("content", ""))
    elif tool == "edit_file":
        return edit_file(
            tool_data.get("path", ""),
            tool_data.get("old_text", ""),
            tool_data.get("new_text", ""),
        )
    elif tool == "search_code":
        return search_code(
            tool_data.get("pattern", ""),
            tool_data.get("file_pattern", "*.dart"),
        )
    elif tool == "list_files":
        return list_files(tool_data.get("pattern", "*"))
    elif tool == "run_command":
        return run_command(tool_data.get("command", ""))
    elif tool == "git_status":
        return git_status()
    elif tool == "git_diff":
        return git_diff()
    elif tool == "git_commit":
        return git_commit(tool_data.get("message", "Auto commit"))
    else:
        return f"Unknown tool: {tool}"


def extract_json(text: str) -> list:
    """Extract JSON objects from text."""
    json_objects = []
    # Find all JSON-like structures
    pattern = r'\{[^{}]*\}'
    matches = re.findall(pattern, text)
    for match in matches:
        try:
            obj = json.loads(match)
            if "tool" in obj:
                json_objects.append(obj)
        except json.JSONDecodeError:
            continue
    return json_objects


async def process_with_claude_cli(user_message: str, context: str = "") -> str:
    """Process user message using Claude Code CLI (uses Pro subscription)."""
    try:
        # Simpler prompt for CLI - it already has access to tools
        if context:
            full_prompt = f"Previous context:\n{context}\n\nUser request: {user_message}"
        else:
            full_prompt = user_message

        # Run Claude CLI with the prompt via stdin
        result = subprocess.run(
            ["claude", "-p", "--model", "sonnet"],
            input=full_prompt,
            capture_output=True,
            text=True,
            timeout=180,
            cwd=PROJECT_PATH,
        )

        output = result.stdout or ""
        error = result.stderr or ""

        if result.returncode == 0 and output:
            return output.strip()
        elif error:
            return f"Claude CLI Error: {error}"
        else:
            return "Claude CLI returned no output"
    except subprocess.TimeoutExpired:
        return "Error: Claude CLI timed out (180s limit)"
    except Exception as e:
        return f"Claude CLI Error: {e}"


async def process_with_ai(user_message: str, context: str = "") -> str:
    """Process user message with Claude CLI, Claude API, or Gemini."""

    # Prefer Claude CLI (uses Pro subscription)
    USE_CLAUDE_CLI = os.getenv("USE_CLAUDE_CLI", "true").lower() == "true"

    if USE_CLAUDE_CLI:
        return await process_with_claude_cli(user_message, context)
    elif USE_CLAUDE:
        try:
            message = claude_client.messages.create(
                model="claude-opus-4-5-20251101",
                max_tokens=4096,
                system=SYSTEM_PROMPT,
                messages=[
                    {"role": "user", "content": f"Previous context:\n{context}\n\nUser request: {user_message}"}
                ]
            )
            return message.content[0].text
        except Exception as e:
            return f"Claude Error: {e}"
    else:
        prompt = f"{SYSTEM_PROMPT}\n\nPrevious context:\n{context}\n\nUser: {user_message}\n\nAssistant:"
        try:
            response = gemini_model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Gemini Error: {e}"


# Conversation history per user (simple in-memory)
conversation_history = {}


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle incoming messages."""
    user_id = update.effective_user.id

    # Security check
    if not is_authorized(user_id):
        await update.message.reply_text("Unauthorized. This bot is private.")
        return

    user_message = update.message.text

    # Send typing indicator
    await update.message.chat.send_action("typing")

    # Get conversation history
    history = conversation_history.get(user_id, "")

    # Process with AI
    ai_response = await process_with_ai(user_message, history)

    # Check for tool calls
    tool_calls = extract_json(ai_response)
    tool_results = []

    for tool_call in tool_calls:
        result = execute_tool(tool_call)
        tool_results.append(f"Tool: {tool_call.get('tool')}\nResult: {result}")

    # If there were tool calls, get a summary from AI
    if tool_results:
        tool_context = "\n\n".join(tool_results)
        summary_prompt = f"You executed these tools:\n{tool_context}\n\nProvide a brief summary for the user."
        summary = await process_with_ai(summary_prompt, "")
        final_response = summary
    else:
        final_response = ai_response

    # Update conversation history (keep last 5 exchanges)
    history_entry = f"User: {user_message}\nAssistant: {final_response}\n\n"
    conversation_history[user_id] = (history + history_entry)[-5000:]

    # Send response (split if too long)
    if len(final_response) > 4000:
        # Split into chunks
        chunks = [final_response[i:i+4000] for i in range(0, len(final_response), 4000)]
        for chunk in chunks:
            await update.message.reply_text(chunk)
    else:
        await update.message.reply_text(final_response)


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /start command."""
    if not is_authorized(update.effective_user.id):
        await update.message.reply_text("Unauthorized.")
        return

    await update.message.reply_text(
        "Tennis Tactics Coding Agent\n\n"
        "I can help you with your Flutter project remotely!\n\n"
        "Commands:\n"
        "/status - Project status\n"
        "/diff - Git diff\n"
        "/commit - Quick commit\n\n"
        "Or just tell me what you want to do:\n"
        "- 'Show me main.dart'\n"
        "- 'Find where sync happens'\n"
        "- 'Add a comment to line 50 of main.dart'\n"
        "- 'Run flutter analyze'"
    )


async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /status command."""
    if not is_authorized(update.effective_user.id):
        return

    status = git_status()
    dart_files = len(list(Path(PROJECT_PATH).glob("lib/**/*.dart")))

    await update.message.reply_text(
        f"Project: {Path(PROJECT_PATH).name}\n"
        f"Dart files: {dart_files}\n"
        f"Time: {datetime.now().strftime('%H:%M:%S')}\n\n"
        f"Git Status:\n{status}"
    )


async def cmd_diff(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /diff command."""
    if not is_authorized(update.effective_user.id):
        return

    diff = git_diff()
    if len(diff) > 4000:
        diff = diff[:4000] + "\n... (truncated)"

    await update.message.reply_text(f"Git Diff:\n```\n{diff}\n```", parse_mode="Markdown")


async def cmd_commit(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /commit command."""
    if not is_authorized(update.effective_user.id):
        return

    # Get commit message from command args
    args = context.args
    if args:
        message = " ".join(args)
    else:
        message = f"Quick commit at {datetime.now().strftime('%Y-%m-%d %H:%M')}"

    result = git_commit(message)
    await update.message.reply_text(f"Commit result:\n{result}")


def main():
    """Start the bot."""
    use_cli = os.getenv("USE_CLAUDE_CLI", "true").lower() == "true"
    print(f"Starting Telegram Coding Agent...")
    print(f"Project: {PROJECT_PATH}")
    print(f"Authorized user: {TELEGRAM_USER_ID}")
    print(f"Bot token: {TELEGRAM_BOT_TOKEN[:10]}...")
    if use_cli:
        print(f"AI: Claude Code CLI (Pro subscription)")
    elif USE_CLAUDE:
        print(f"AI: Claude API")
    else:
        print(f"AI: Gemini API")
    print()
    print("Bot is running! Send messages to your Telegram bot.")
    print("Press Ctrl+C to stop.")

    # Create application with extended timeouts
    from telegram.request import HTTPXRequest
    request = HTTPXRequest(
        connection_pool_size=8,
        connect_timeout=60.0,
        read_timeout=60.0,
        write_timeout=60.0,
        pool_timeout=60.0,
    )
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).request(request).build()

    # Add handlers
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("diff", cmd_diff))
    app.add_handler(CommandHandler("commit", cmd_commit))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    # Start polling with bootstrap retries
    app.run_polling(
        allowed_updates=Update.ALL_TYPES,
        bootstrap_retries=5,
        drop_pending_updates=True,
    )


if __name__ == "__main__":
    main()
