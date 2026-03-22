Branch the current conversation and open the original in a tmux split pane.

## Instructions

1. First, check if we're running inside tmux by running: `tmux display-message -p '#{session_name}' 2>/dev/null`. If this fails, tell the user they need to be in a tmux session and stop.

2. Look at the conversation history for the most recent `/branch` command output. It will contain a line like:
   ```
   To resume the original: claude -r <session-id>
   ```
   Extract the session ID (UUID).

3. If no recent `/branch` output is found in the conversation, tell the user to run `/branch <name>` first, then re-run this command.

4. Open the original conversation in a tmux split pane by running:
   ```
   tmux split-window -h "claude -r <session-id>"
   ```

5. Confirm to the user that the original conversation is now open in the split pane.
