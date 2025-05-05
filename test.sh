#!/bin/bash

# WORK IN PROGRESS!

# Path to the minishell executable to test
MINISHELL_FOLDER="/home/dlippelt/codam/github/dplippelt/projects/minishell"
TEST_FOLDER="$PWD"
OUTPUT_FILE="/tmp/minishell_test_output"

cd $MINISHELL_FOLDER

make -s

# Function to run a simple ls test
minishell_test()
{
	start_tmux_session

	run_minishell_command "ls"

	# Capture the output from the tmux pane and trim empty lines
	tmux capture-pane -p -t "$session_name" | awk 'NF{p=1} p' > "$OUTPUT_FILE"

	# Display the output (for debugging)
	echo "=== Minishell test output ==="
	cat "$OUTPUT_FILE"
	echo "=================================="

	# Kill the tmux session
	tmux kill-session -t "$session_name"

	# Clean up
	rm -f "$OUTPUT_FILE"
}

start_tmux_session()
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
	tmux send-keys -t "$session_name" "./minishell" C-m
	sleep 1  # Wait for minishell to start
}

run_minishell_command()
{
	# Send 'ls' command to minishell
	tmux send-keys -t "$session_name" "$1" C-m
	sleep 0.2  # Wait for command to execute

	# Send 'echo $?' command to minishell
	tmux send-keys -t "$session_name" "echo \$?" C-m

	# Send exit command
	tmux send-keys -t "$session_name" "exit" C-m
	sleep 0.2
}

minishell_test

cd $MINISHELL_FOLDER
# make -s fclean
cd $TEST_FOLDER


exit 0
