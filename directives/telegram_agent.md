# Telegram Coding Agent

Remote coding assistant accessible via Telegram messenger.

## Overview

This agent allows you to chat with an AI coding assistant from your phone. Send messages to your Telegram bot, and the agent running on your local machine will:
- Read and search your codebase
- Make code changes
- Run commands (build, test, git)
- Report back results

## Setup

### 1. Create Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow prompts
3. Copy the bot token (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
4. Send `/setcommands` to BotFather and set:
   ```
   start - Start the agent
   status - Check agent status
   diff - Show git diff
   commit - Commit changes
   ```

### 2. Get Your Telegram User ID

1. Search for `@userinfobot` on Telegram
2. Send any message to it
3. Copy your user ID (numeric)

### 3. Configure Environment

Add to your `.env` file:
```
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_USER_ID=your_user_id_here
GEMINI_API_KEY=your_gemini_key_here
PROJECT_PATH=C:\Users\Vlada\projects\tennis_tactics_agent
```

### 4. Run the Agent

```bash
cd execution
python telegram_agent.py
```

Keep this running on your PC. You can now message your bot from anywhere!

## Usage

### Code Operations

- **Read file**: "Show me the contents of lib/main.dart"
- **Search code**: "Find where GeminiService is used"
- **Edit file**: "Add a TODO comment at the top of main.dart"
- **Create file**: "Create a new utility file for date formatting"

### Git Operations

- **Status**: "What files have changed?"
- **Diff**: "Show me the diff"
- **Commit**: "Commit with message 'Fix login bug'"

### Build/Run

- **Analyze**: "Run flutter analyze"
- **Build**: "Build the app"
- **Test**: "Run the tests"

### Commands

- `/start` - Initialize and show help
- `/status` - Show agent status and project info
- `/diff` - Quick git diff
- `/commit` - Interactive commit

## Security

- Only responds to YOUR Telegram user ID (configured in .env)
- Runs locally on your machine
- No code leaves your network (except to Gemini API for reasoning)

## Limitations

- Agent must be running on your PC
- Your PC must have internet access
- Long operations may timeout (Telegram has message limits)

## Troubleshooting

### Bot not responding
- Check if `telegram_agent.py` is running
- Verify TELEGRAM_BOT_TOKEN is correct
- Check internet connection

### Permission denied
- Verify TELEGRAM_USER_ID matches your ID
- Only you can use this bot

### Changes not working
- Check PROJECT_PATH is correct
- Verify file paths in messages
