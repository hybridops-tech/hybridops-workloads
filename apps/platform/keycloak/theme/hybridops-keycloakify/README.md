# Keycloakify Theme

This project builds the `hybridops` login theme jar used by the in-cluster Keycloak workload.

## Build

```bash
cd hybridops-workloads/apps/platform/keycloak/theme/hybridops-keycloakify
./scripts/build-keycloak-theme.sh
```

Output:

- `dist_keycloak/hybridops-theme.jar`

The build script auto-installs local Java 21 + Maven 3.9.9 under `~/.local/tools` when they are not already available.

## Deploy With Your Workload Renderer

```bash
cd <your workload repo root>
KEYCLOAK_THEME_JAR_PATH="$(pwd)/apps/platform/keycloak/theme/hybridops-keycloakify/dist_keycloak/hybridops-theme.jar" \
KEYCLOAK_LOGIN_THEME=hybridops \
./path/to/your/runtime-renderer.sh
```

Then distribute the generated jar through your secret/rendering flow and restart Keycloak.
