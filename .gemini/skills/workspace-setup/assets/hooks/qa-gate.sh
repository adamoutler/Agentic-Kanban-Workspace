#!/bin/bash
PAYLOAD=$(cat -)
STATE=$(echo "$PAYLOAD" | jq -r '.tool_input.state // empty')
WORK_ITEM_ID=$(echo "$PAYLOAD" | jq -r '.tool_input.work_item_id // empty')

if [[ "$STATE" == *"Done"* ]]; then
  RESULT=$(gemini -p "@reality-checker Please verify if work item $WORK_ITEM_ID is completed and has evidence. If yes, respond with EXACT_WORD_PASS. Otherwise, respond with NEEDS WORK." 2>&1)
  
  if echo "$RESULT" | grep -q "EXACT_WORD_PASS"; then
    echo '{"decision": "allow"}'
    exit 0
  else
    jq -c -n --arg reason "Reality checker blocked the transition to Done. Result: $RESULT" '{"decision": "deny", "reason": $reason}'
    exit 0
  fi
fi

echo '{"decision": "allow"}'
