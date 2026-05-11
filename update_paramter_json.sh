IMAGE_TAG="${1}"
PARAMS_FILE="${2}"
environment="${3}"
 
if [[ -z "$IMAGE_TAG" ]]; then
  echo "ERROR: image tag is required. Usage: $0 <image-tag> [parameters.json]"
  exit 1
fi
 
for var in POSTGRES_ADMIN_PASSWORD AZURE_CLIENT_SECRET PRIVATE_REGISTRY_PASSWORD; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: environment variable '$var' is not set"
    exit 1
  fi
done
 
if [[ ! -f "$PARAMS_FILE" ]]; then
  echo "ERROR: file '$PARAMS_FILE' not found"
  exit 1
fi
 
# Write to a temp file first, then move it over the original (atomic & safe)
tmp=$(mktemp)
jq \
  --arg pg_pass   "$POSTGRES_ADMIN_PASSWORD" \
  --arg az_secret "$AZURE_CLIENT_SECRET" \
  --arg reg_pass  "$PRIVATE_REGISTRY_PASSWORD" \
  --arg tag       "$IMAGE_TAG" \
  '
  .parameters.postgresAdminPassword.value   = $pg_pass   |
  .parameters.azureClientSecret.value       = $az_secret  |
  .parameters.privateRegistryPassword.value = $reg_pass   |
  .parameters.mainSourceImage.value         |= gsub("<tag>"; $tag)
  ' \
  "$PARAMS_FILE" > "$tmp" && mv "$tmp" "infrastructure/environments/$environment.parameters.json"
 
echo "Updated infrastructure/environments/$environment.parameters.json"
echo "$(ls -lrt infrastructure/environments)"
