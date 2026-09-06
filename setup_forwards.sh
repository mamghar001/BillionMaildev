#!/bin/bash
# Setup mail forwards for multiple mailboxes

# ============================================
# CONFIGURATION - FILL THESE IN
# ============================================

API_TOKEN="${API_TOKEN:-}"
BASE_URL="${BASE_URL:-http://127.0.0.1}"
DESTINATION="${DESTINATION:-}"

# ============================================
# MAILBOXES LIST
# ============================================

MAILBOXES=(
    "rotationTest0me@moescale.xyz"
    "rotationTest1pz@moescale.xyz"
    "rotationTest2lx@moescale.xyz"
    "rotationTest3lf@moescale.xyz"
    "rotationTest4is@moescale.xyz"
    "rotationTest5ae@moescale.xyz"
    "rotationTest6gh@moescale.xyz"
    "rotationTest7ut@moescale.xyz"
    "rotationTest8di@moescale.xyz"
    "rotationTest9gd@moescale.xyz"
    "rotationTest10wv@moescale.xyz"
    "rotationTest11cd@moescale.xyz"
    "rotationTest12qd@moescale.xyz"
    "rotationTest13uy@moescale.xyz"
    "rotationTest14fg@moescale.xyz"
    "rotationTest15nb@moescale.xyz"
    "rotationTest16nn@moescale.xyz"
    "rotationTest17si@moescale.xyz"
    "rotationTest18yz@moescale.xyz"
    "rotationTest19lh@moescale.xyz"
    "rotationTest20yx@moescale.xyz"
    "rotationTest21rt@moescale.xyz"
    "rotationTest22jz@moescale.xyz"
    "rotationTest23vv@moescale.xyz"
    "rotationTest24kl@moescale.xyz"
    "rotationTest25bs@moescale.xyz"
    "rotationTest26oz@moescale.xyz"
    "rotationTest27xl@moescale.xyz"
    "rotationTest28cg@moescale.xyz"
    "rotationTest29jh@moescale.xyz"
    "rotationTest30uk@moescale.xyz"
    "rotationTest31la@moescale.xyz"
    "rotationTest32nu@moescale.xyz"
    "rotationTest33qs@moescale.xyz"
    "rotationTest34nt@moescale.xyz"
    "rotationTest35zc@moescale.xyz"
    "rotationTest36ae@moescale.xyz"
    "rotationTest37zz@moescale.xyz"
    "rotationTest38fk@moescale.xyz"
    "rotationTest39db@moescale.xyz"
    "rotationTest40ug@moescale.xyz"
    "rotationTest41qc@moescale.xyz"
    "rotationTest42vr@moescale.xyz"
    "rotationTest43fb@moescale.xyz"
    "rotationTest44ly@moescale.xyz"
    "rotationTest45zg@moescale.xyz"
    "rotationTest46ga@moescale.xyz"
    "rotationTest47qv@moescale.xyz"
    "rotationTest48jk@moescale.xyz"
    "rotationTest49mc@moescale.xyz"
)

# ============================================
# SCRIPT
# ============================================

echo "=========================================="
echo "BillionMail Bulk Forward Setup"
echo "=========================================="
echo ""
echo "Destination: $DESTINATION"
echo "Total mailboxes: ${#MAILBOXES[@]}"
echo ""

if [ "$API_TOKEN" == "YOUR_API_TOKEN_HERE" ]; then
    echo "❌ ERROR: Please set your API_TOKEN in the script!"
    exit 1
fi

if [ "$BASE_URL" == "https://YOUR_DOMAIN" ]; then
    echo "❌ ERROR: Please set your BASE_URL in the script!"
    exit 1
fi

echo "Starting in 3 seconds... Press Ctrl+C to cancel"
sleep 3
echo ""

SUCCESS=0
FAILED=0
TOTAL=${#MAILBOXES[@]}

for i in "${!MAILBOXES[@]}"; do
    MAILBOX="${MAILBOXES[$i]}"
    NUM=$((i + 1))
    
    echo -n "[$NUM/$TOTAL] $MAILBOX → ... "
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/api/mail_forward/add" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"address\": \"${MAILBOX}\", \"goto\": \"${DESTINATION}\", \"active\": 1}" 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo "✅ OK"
        ((SUCCESS++))
    else
        echo "❌ FAILED (HTTP $HTTP_CODE)"
        ((FAILED++))
    fi
    
    sleep 0.5
done

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "✅ Successful: $SUCCESS"
echo "❌ Failed: $FAILED"
echo "📊 Total: $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All forwards created successfully!"
else
    echo "⚠️  Some forwards failed. Check errors above."
fi
