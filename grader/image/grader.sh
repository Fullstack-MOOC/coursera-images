#!/bin/bash
cd /shared/submission
rm -rf results

# Run Cypress tests
export TERM=dumb

echo "Running component tests..."
# Don't capture output - let it run directly so we can see what's happening
npm run test:component
COMPONENT_EXIT_CODE=$?

echo "Component tests completed with exit code: $COMPONENT_EXIT_CODE"

echo "Starting development server..."
npm run dev &
DEV_PID=$!

echo "Waiting for server to be ready..."
# Wait for server to start on port 8080
for i in {1..30}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo "Server is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Server failed to start within 30 seconds"
        kill $DEV_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

echo "Running E2E tests..."
npm run test:e2e
E2E_EXIT_CODE=$?

echo "E2E tests completed with exit code: $E2E_EXIT_CODE"

# Stop development server
echo "Stopping development server..."
kill $DEV_PID 2>/dev/null || true
wait $DEV_PID 2>/dev/null || true

# Parse results
TOTAL_E2E_TESTS=$(jq -r '.results.summary.tests' ./results/e2e_feedback.json)
TOTAL_E2E_TESTS_PASSED=$(jq -r '.results.summary.passed' ./results/e2e_feedback.json)

TOTAL_COMPONENT_TESTS=$(jq -r '.results.summary.tests' ./results/component_feedback.json)
TOTAL_COMPONENT_TESTS_PASSED=$(jq -r '.results.summary.passed' ./results/component_feedback.json)

# Handle null/missing values
TOTAL_E2E_TESTS=${TOTAL_E2E_TESTS:-0}
TOTAL_E2E_TESTS_PASSED=${TOTAL_E2E_TESTS_PASSED:-0}
TOTAL_COMPONENT_TESTS=${TOTAL_COMPONENT_TESTS:-0}
TOTAL_COMPONENT_TESTS_PASSED=${TOTAL_COMPONENT_TESTS_PASSED:-0}

TOTAL_TESTS=$((TOTAL_E2E_TESTS + TOTAL_COMPONENT_TESTS))

if [ $TOTAL_TESTS -eq 0 ]; then
    SCORE="0"
else
    SCORE=$(echo "scale=4; ($TOTAL_E2E_TESTS_PASSED + $TOTAL_COMPONENT_TESTS_PASSED) / $TOTAL_TESTS" | bc)
fi

# Add leading zero if needed
if [[ $SCORE =~ ^\. ]]; then
    SCORE="0$SCORE"
fi

mkdir -p /shared
echo "{\"fractionalScore\": $SCORE, \"feedback\": \"\", \"feedbackType\": \"HTML\"}" > /shared/feedback.json
echo "<b>Your score: $(echo "$SCORE * 100" | bc)%</b>" > /shared/htmlFeedback.html

echo "Grading completed. Score: $SCORE"