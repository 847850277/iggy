#!/bin/bash

# shellcheck disable=SC1091

set -euo pipefail

# Load utility functions
source "$(dirname "$0")/utils.sh"

# Trap SIGINT (Ctrl+C) and execute the on_exit function, do the same on script exit
trap on_exit_bench SIGINT
trap on_exit_bench EXIT

# Remove old local_data
echo "Cleaning old local_data..."
rm -rf local_data

# Build the project
echo "Building project..."
cargo build --release

# Start iggy-server
echo "Running iggy-server..."
target/release/iggy-server &> /dev/null &
sleep 1

# Start tcp send bench
echo "Running iggy-bench pinned-producer tcp..."
send_results=$(target/release/iggy-bench pinned-producer tcp | grep -e "Results:")
sleep 1

# Display results
echo
echo "Send results:"
echo "${send_results}"
echo

# Start tcp poll bench
echo "Running iggy-bench pinned-consumer tcp..."
poll_results=$(target/release/iggy-bench pinned-consumer tcp | grep -e "Results: total throughput")

echo "Poll results:"
echo "${poll_results}"
echo

# Gracefully stop the server
send_signal "iggy-server" "TERM"
wait_for_process "iggy-server" 5

exit 0
