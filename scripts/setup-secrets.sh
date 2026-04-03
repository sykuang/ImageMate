#!/bin/bash
#
# setup-secrets.sh — Configure remaining GitHub Actions secrets for ImageMate release pipeline
#
# Prerequisites:
#   1. Generate an App-Specific Password at https://account.apple.com
#      (Sign-In and Security → App-Specific Passwords → Generate)
#
#   2. Create a "Developer ID Application" certificate at
#      https://developer.apple.com/account/resources/certificates/add
#      Upload the CSR: /tmp/CertificateSigningRequest.certSigningRequest
#      Download the .cer file
#
# Usage:
#   bash scripts/setup-secrets.sh <path-to-downloaded.cer> <app-specific-password>
#
# Example:
#   bash scripts/setup-secrets.sh ~/Downloads/developerID_application.cer "xxxx-xxxx-xxxx-xxxx"
#

set -euo pipefail

CER_FILE="${1:-}"
APP_PASSWORD="${2:-}"

if [ -z "$CER_FILE" ] || [ -z "$APP_PASSWORD" ]; then
    echo "❌ Usage: bash scripts/setup-secrets.sh <path-to.cer> <app-specific-password>"
    echo ""
    echo "Steps to get these:"
    echo "  1. App-Specific Password: https://account.apple.com → Sign-In and Security → App-Specific Passwords"
    echo "  2. Developer ID cert: https://developer.apple.com/account/resources/certificates/add"
    echo "     → Select 'Developer ID Application'"
    echo "     → Upload CSR: /tmp/CertificateSigningRequest.certSigningRequest"
    echo "     → Download the .cer file"
    exit 1
fi

if [ ! -f "$CER_FILE" ]; then
    echo "❌ Certificate file not found: $CER_FILE"
    exit 1
fi

PRIVATE_KEY="/tmp/dev_id_private_key.key"
if [ ! -f "$PRIVATE_KEY" ]; then
    echo "❌ Private key not found at $PRIVATE_KEY"
    echo "   Re-run CSR generation or check if the file was deleted."
    exit 1
fi

echo "🔐 Converting .cer to .p12..."

# Convert .cer (DER) to PEM
openssl x509 -inform DER -in "$CER_FILE" -out /tmp/dev_id_cert.pem 2>/dev/null

# Prompt for .p12 export password
read -sp "Enter a password for the .p12 file (remember this): " P12_PASSWORD
echo ""

# Create .p12 with cert + private key
openssl pkcs12 -export \
    -out /tmp/dev_id_certificate.p12 \
    -inkey "$PRIVATE_KEY" \
    -in /tmp/dev_id_cert.pem \
    -passout "pass:$P12_PASSWORD" 2>/dev/null

echo "✅ Created /tmp/dev_id_certificate.p12"

# Base64 encode
CERT_BASE64=$(base64 -i /tmp/dev_id_certificate.p12)

echo ""
echo "🔑 Setting GitHub secrets..."

# Set APPLE_CERTIFICATE_BASE64
echo "$CERT_BASE64" | gh secret set APPLE_CERTIFICATE_BASE64
echo "  ✅ APPLE_CERTIFICATE_BASE64"

# Set APPLE_CERTIFICATE_PASSWORD
echo "$P12_PASSWORD" | gh secret set APPLE_CERTIFICATE_PASSWORD
echo "  ✅ APPLE_CERTIFICATE_PASSWORD"

# Set APPLE_APP_PASSWORD
echo "$APP_PASSWORD" | gh secret set APPLE_APP_PASSWORD
echo "  ✅ APPLE_APP_PASSWORD"

# Cleanup sensitive files
rm -f /tmp/dev_id_private_key.key /tmp/dev_id_cert.pem /tmp/dev_id_certificate.p12 /tmp/CertificateSigningRequest.certSigningRequest
echo ""
echo "🧹 Cleaned up temporary files"

echo ""
echo "✅ All 6 secrets configured! Verify with: gh secret list"
echo ""
echo "Your release pipeline is ready. Push a tag to trigger it:"
echo "  git tag v1.0.0 && git push origin v1.0.0"
