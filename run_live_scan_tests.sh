#!/bin/bash
set -e

# ==============================================================================
# 🍷 CHATMELIER LIVE SCAN & MENU ANTI-REGRESSION RUNNER
# ==============================================================================
# Runs live or simulated benchmark audits for bottle scans, menu OCR, and
# zero-shot procedural bottle generators.
#
# Usage:
#   ./run_live_scan_tests.sh [options]
#
# Examples:
#   ./run_live_scan_tests.sh                              # Simulated dry-run (offline)
#   ./run_live_scan_tests.sh --key=AIzaSy...              # Live Gemini benchmarking
#   ./run_live_scan_tests.sh --full --key=AIzaSy...       # Full catalog audit (13 bottles, 4 menus)
#   ./run_live_scan_tests.sh --mode=bottle                # Only test bottle scans
#   ./run_live_scan_tests.sh --mode=menu                  # Only test restaurant menus
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

API_KEY="${GEMINI_API_KEY:-}"
MODEL="gemini-2.5-flash"
MODE="all"
LIMIT=3

for arg in "$@"; do
  case $arg in
    --key=*)
      API_KEY="${arg#*=}"
      shift
      ;;
    --model=*)
      MODEL="${arg#*=}"
      shift
      ;;
    --mode=*)
      MODE="${arg#*=}"
      shift
      ;;
    --limit=*)
      LIMIT="${arg#*=}"
      shift
      ;;
    --full)
      LIMIT=50
      shift
      ;;
    --offline|--dry-run)
      API_KEY=""
      shift
      ;;
    --help|-h)
      echo "Usage: ./run_live_scan_tests.sh [options]"
      echo ""
      echo "Options:"
      echo "  --key=<API_KEY>    Google Gemini API key (or export GEMINI_API_KEY)"
      echo "  --model=<MODEL>    Model ID (default: gemini-2.5-flash)"
      echo "  --mode=<MODE>      Scope: all (default), bottle, menu, generator"
      echo "  --limit=<N>        Max samples per category (default: 3)"
      echo "  --full             Audit all 13 canonical bottles and 4 menus"
      echo "  --offline          Run offline simulated dry-run (zero API cost)"
      echo "  --help, -h         Show this message"
      exit 0
      ;;
  esac
done

cd "$APP_DIR"

echo "================================================================================"
echo "🍷 Starting Chatmelier Anti-Regression Benchmark..."
echo "Mode: $MODE | Limit: $LIMIT | Model: $MODEL"
if [ -n "$API_KEY" ]; then
  echo "Endpoint: LIVE Google Gemini API"
else
  echo "Endpoint: SIMULATED / DRY-RUN (Offline verification)"
fi
echo "================================================================================"

flutter test test/live/live_scan_runner_test.dart \
  --dart-define=GEMINI_API_KEY="$API_KEY" \
  --dart-define=GEMINI_MODEL="$MODEL" \
  --dart-define=BENCHMARK_MODE="$MODE" \
  --dart-define=BENCHMARK_LIMIT="$LIMIT"

echo ""
echo "✅ Benchmark execution completed successfully!"
