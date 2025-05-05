#!/bin/bash

# WORK IN PROGRESS!

# Path to the minishell executable to test
MINISHELL_PATH="/home/dlippelt/codam/github/dplippelt/projects/minishell"
OUTPUT_FILE="/tmp/minishell_test_output"

make -s -C $MINISHELL_PATH

# Function to run a simple ls test
minishell_test()
{
	local session_name="minishell_test_$$"

	# Check if tmux is available
	if ! command -v tmux &> /dev/null; then
		echo "Error: tmux is not installed or not in the PATH."
		return 1
	fi

	# Check if a tmux server is running
	echo "Checking tmux server status..."
	tmux list-sessions &> /dev/null
	if [ $? -ne 0 ]; then
		echo "Starting new tmux server..."
		# Start a tmux server if none is running
		tmux start-server
	fi

	echo "Creating tmux session: $session_name"
	# Create a new tmux session in detached mode
	tmux new-session -d -s "$session_name"
	if [ $? -ne 0 ]; then
		echo "Error: Failed to create tmux session."
		return 1
	fi

	echo "Starting minishell in tmux session..."
	# Start minishell in the tmux session
	tmux send-keys -t "$session_name" "$MINISHELL_PATH/minishell" C-m
	sleep 1  # Wait for minishell to start

	# Send 'ls' command to minishell
	tmux send-keys -t "$session_name" "ls" C-m
	sleep 0.2  # Wait for command to execute

	# Send 'echo $?' command to minishell
	tmux send-keys -t "$session_name" "echo \$?" C-m

	# Send exit command
	tmux send-keys -t "$session_name" "exit" C-m
	sleep 0.2

	# Capture the output from the tmux pane and trim empty lines
	tmux capture-pane -p -t "$session_name" | awk 'NF{p=1} p' > "$OUTPUT_FILE"

	# Display the output (for debugging)
	echo "=== Minishell 'ls' test output ==="
	cat "$OUTPUT_FILE"
	echo "=================================="

	#

	# Kill the tmux session
	tmux kill-session -t "$session_name"

	# Clean up
	rm -f "$OUTPUT_FILE"
}

minishell_test

# make -C $MINISHELL_PATH fclean

exit 0
