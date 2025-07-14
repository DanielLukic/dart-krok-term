# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

dart-krok-term is a Terminal User Interface (TUI) application for interacting with the Kraken cryptocurrency exchange API. It's written in Dart and provides a keyboard-driven interface for trading, monitoring, and managing cryptocurrency assets directly from the terminal.

## Common Development Commands

```bash
# Run the application
dart run bin/krok_term.dart

# Run tests
dart test

# Analyze code for issues
dart analyze

# Format code
dart format .

# Get dependencies
dart pub get

# Run a specific test file
dart test test/path/to/test_file.dart
```

## Architecture Overview

The application follows a layered architecture with clear separation of concerns:

### Core Structure
- **Entry Point**: `bin/krok_term.dart` - Main application entry
- **Core Layer** (`lib/src/krok_term/core/`):
  - `api_client.dart`: Kraken API integration with rate limiting
  - `state.dart`: Global application state management
  - `model.dart`: Core domain models

### Feature Windows
Each window in `lib/src/krok_term/feature/` is a self-contained UI component:
- `chart/`: Price charting with technical indicators
- `orders/`: Order management (place, edit, cancel)
- `balances.dart`: Account balance display
- `alerts.dart`: Price alert management
- `portfolio.dart`: Portfolio overview
- `ticker.dart`: Live price ticker
- `bots.dart`: Automated trading bots

### Key Design Patterns
1. **State Management**: Combines RxDart streams with signals_core for reactive updates
2. **Window System**: Each feature extends `Window` from dart_consul
3. **Repository Pattern**: Data access through repositories in `lib/src/krok_term/repository/`
4. **Keyboard Navigation**: Vim-style shortcuts (j/k for scrolling, "/" for search)

### Important Implementation Details
- **API Rate Limiting**: Built-in throttling (1-4 seconds between requests) in `api_client.dart`
- **Order Types**: Supports market, limit, stop-loss, take-profit, and complex orders
- **Price Updates**: Real-time price data through WebSocket subscriptions
- **Configuration**: API keys from `~/.config/clikraken/kraken.key`
- **Local Storage**: Data persisted in `krok/` directory
- **Logging**: Debug logs written to `krok.log`

### UI/UX Conventions
- Modal dialogs for order placement use `ModalDialog` from dart_consul
- Shortcuts are registered in each window's constructor
- Help text accessible via `gh` or `Ctrl+?`
- Asset pair selection via "/" from any window
- Window navigation shortcuts (e.g., "gb" for balances, "gc" for chart)

### Testing Approach
- Unit tests for core components (settings, orders, notifications)
- Test files follow the pattern `test/*/test_*.dart`
- Mock API responses for testing order functionality

## Dependencies

Key external packages:
- `krok`: Kraken API wrapper
- `dart_consul`: TUI framework for window management
- `termlib`: Terminal interaction primitives
- `rxdart`: Reactive extensions
- `signals_core`: State management