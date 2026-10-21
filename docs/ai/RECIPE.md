# AIGC Service Example with RTC

## Overview

Connect an AIGC service workflow to an Agora RTC media session for interactive AI-assisted experiences.

Repository: [AgoraIO-Community/Agora-AIGCService-Example](https://github.com/AgoraIO-Community/Agora-AIGCService-Example)

## Prerequisites and Setup

1. Open `Android/Agora-AIGCService-Example` in Android Studio.
2. Use the service dependency recorded by the Android README: `io.github.winskyan:Agora-AIGCService:1.3.0-alpha-7`. Confirm the artifact and service access are available.
3. Set `APP_ID` and `APP_CERTIFICATE` in that project's `local.properties`, sync Gradle and run on a device.
4. Inspect the separate `iOS/AIGCService-Example/` workspace when working on the iOS variant; its dependency and signing setup are separate from Android.

## What To Check

- Initialize the AIGC service and validate the sample's input/response flow.
- Stop the service and reopen the screen to check that capture and callbacks do not continue after teardown.

## Integration Notes

This reference depends on a historical alpha SDK and service entitlement. An App ID alone is insufficient.

Keep App Certificates, customer secrets and privileged token generation on a trusted backend for production. Use only your own test credentials while configuring historical demos; do not commit them. Preserve the sample's existing dependency versions and lifecycle until a separate migration is tested.

## Source References

- [Android/Agora-AIGCService-Example/README.md](../../Android/Agora-AIGCService-Example/README.md)
- [iOS/AIGCService-Example/AIGC-Examples.xcworkspace/contents.xcworkspacedata](../../iOS/AIGCService-Example/AIGC-Examples.xcworkspace/contents.xcworkspacedata)

## Validation Status

This recipe was checked against the repository's source and setup documents. The platform build and live service/device flow have not been run as part of this documentation change. Complete the checks above in an environment with the required SDKs, hardware and service access before treating it as a validated deployment.

## Implementation Prompt

```text
You are working in AgoraIO-Community/Agora-AIGCService-Example. Use docs/ai/RECIPE.md and its linked source files to adapt the AIGC Service Example with RTC reference to this project.

Start by inspecting the actual sample directory and configuration described above. Resolve its listed missing prerequisites before claiming it is runnable. Preserve the existing architecture and compatible dependency versions. Implement the recipe's feature-specific flow, permissions and resource cleanup. Use a trusted backend for privileged credentials and tokens in production.

Run the repository-specific build or launch flow, then perform each What To Check item. Report the commands run, the observed results and anything blocked by service access, hardware or incomplete sample code. Do not claim live validation from a documentation or catalog build alone.
```
