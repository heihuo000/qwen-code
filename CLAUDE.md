# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Commands

**Install & Build**
```bash
npm install                    # Install dependencies
npm run build                  # Build all packages
npm run build:all              # Build CLI + sandbox + VSCode
npm run start                  # Run the CLI
npm run dev                    # Development mode
```

**Test & Lint**
```bash
npm run test                   # Run unit tests
npm run test:e2e               # Run integration tests
npm run lint                   # Run ESLint
npm run format                 # Format with Prettier
npm run typecheck              # TypeScript type checking
npm run preflight              # Full CI check (lint + test + build)
```

**Debug**
```bash
npm run debug                  # Start with --inspect-brk
```

## Architecture Overview

Qwen Code is a terminal-based AI agent built with TypeScript/React. It consists of two main packages plus supporting libraries:

### Core Packages

```
packages/
├── cli/                          # Frontend: Terminal UI (Ink/React)
│   ├── src/
│   │   ├── ui/                   # React components for TUI
│   │   ├── commands/             # Slash command implementations
│   │   └── services/             # CLI-level services
│   └── package.json              # Main entry point (@qwen-code/qwen-code)
│
├── core/                         # Backend: Agent logic & tool execution
│   ├── src/
│   │   ├── core/                 # Core agent & session management
│   │   ├── tools/                # Built-in tools (file, shell, search, web)
│   │   ├── mcp/                  # Model Context Protocol integration
│   │   ├── skills/               # Pre-built skill definitions
│   │   ├── subagents/            # Multi-agent orchestration
│   │   ├── services/             # Backend services (auth, config, telemetry)
│   │   ├── utils/                # Shared utilities
│   │   └── index.ts              # Core package entry point
│   └── package.json              # @qwen-code/qwen-code-core
│
├── sdk-typescript/               # TypeScript SDK for external use
├── sdk-java/                     # Java SDK
├── vscode-ide-companion/         # VS Code extension
├── webui/                        # Web-based UI
├── web-templates/                # Shared web templates
└── test-utils/                   # Shared testing utilities
```

### Request Flow

1. **CLI** (`packages/cli`) captures user input (text, `/commands`, `@files`)
2. **Core** (`packages/core`) receives input, constructs prompt with context
3. **Model API** processes prompt, may request tool execution
4. **Tools** execute with user approval for write/dangerous operations
5. **Core** sends results back to CLI for display

### Configuration System

Configuration layers (highest to lowest precedence):
1. CLI arguments
2. Environment variables
3. Project: `.qwen/settings.json`
4. User: `~/.qwen/settings.json`
5. System defaults

Key configuration file: `~/.qwen/settings.json` for model providers and API keys.

### Key Technologies

- **TypeScript** with strict mode, ES2022 target, NodeNext modules
- **React 19 + Ink 6** for terminal UI rendering
- **esbuild** for bundling
- **Vitest** for testing
- **ESLint + Prettier** for code quality
- **MCP SDK** for Model Context Protocol integration

### Contributing Guidelines

- All changes require a linked issue (open one first if needed)
- Keep PRs small and focused on a single change
- Use Draft PRs for work-in-progress
- Run `npm run preflight` before submitting
- Update `/docs` for user-facing changes
- Follow Conventional Commits format

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full details.
