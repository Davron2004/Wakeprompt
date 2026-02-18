# AI Alarm App - PRD v2 (Reliability-First Phase Model)

## 1) Product Context

### Problem
People dismiss traditional alarms unconsciously and oversleep. A passive ringtone is easy to ignore.

### Product Direction
Build an alarm app where AI interaction helps wakefulness. Reliability comes first: the app must never fail silently.

### Core Principles
1. No silent failures, ever.
2. Reliability before intelligence.
3. Clear degradation paths (conversation -> pre-generated AI audio -> ringtone).
4. User must know which mode fired (for trust and debugging).

## 2) Platform Constraints (iOS)

1. iOS does not allow arbitrary always-on background execution for apps.
2. Live Activities / Dynamic Island do not keep an app process running continuously.
3. AlarmKit provides reliable system alarm delivery but does not guarantee strict "unbypassable" behavior.

### Product Implication
Strict "no bypass" cannot be guaranteed on iOS.  
Practical target: make bypass difficult, and guarantee audible fallback so alarms never fail silently.

## 3) Goals and Non-Goals by Horizon

### Immediate Goal (Phase 0 Gate)
Prove that an alarm always produces audible output at fire time on device.

### Near-Term Goal (Phase 1)
Require conscious wake-complete actions after alarm fire.

### Mid-Term Goal (Phase 2)
Add foreground realtime voice conversation to wake the user.

### Non-Goals (Phase 0)
1. Repeating alarms.
2. Full conversation loop.
3. Advanced personalization.
4. App Store monetization/backend architecture.

## 4) Success Metrics

1. Silent-fail rate: 0 in test suite.
2. Alarm audibility success: >= 99% in controlled test runs.
3. Time-to-audible after scheduled fire: <= 2 seconds median for fallback alarm path.
4. Clear mode attribution in logs/UI for 100% of alarm events.

## 5) Operating Modes and Fallback Ladder

### Mode A: Conversation Alarm (Primary, future)
Foreground app experience with mic + AI dialogue.

### Mode B: Pre-Generated AI Audio Alarm (Reliability fallback)
AI text + TTS generated before alarm, played by system alarm path.

### Mode C: Standard Ringtone Alarm (Hard fallback)
Bundled ringtone if any AI generation/scheduling path fails.

### Hard Policy
At least one reliable audible path must always be armed before user leaves setup flow.

## 6) Functional Requirements

1. User can create one-time alarm (Phase 0).
2. Alarm creation requires API key in prototype mode.
3. AI speech generation uses 2-step pipeline:
   - Text generation model -> wake-up script.
   - TTS model/provider -> speech audio.
4. Max generated audio duration: 60 seconds.
5. Multiple alarms supported.
6. Time behavior uses wall-clock expectation for future recurring alarms.
7. If AI path fails at any point, fallback alarm is scheduled.
8. No silent failure under offline, API, permission, or timeout conditions.

## 7) State Machine (Reliability-Critical)

1. `Draft`
2. `GeneratingText`
3. `GeneratingAudio`
4. `ArmingPrimaryAlarm`
5. `ArmingFallbackAlarm`
6. `Armed`
7. `FiredPrimary`
8. `FiredFallback`
9. `WakeFlowActive` (Phase 1+)
10. `Completed`
11. `FailedAudibly` (audible fallback triggered, primary failed)
12. `ErrorBlocked` (only valid before arming; user must resolve)

### State Invariants
1. App cannot reach `Armed` unless at least one audible alarm path is valid.
2. Any transition failure after draft must route to fallback arming.
3. `ErrorBlocked` is only allowed if user has not confirmed scheduling.

## 8) Failure-Handling Matrix

| Failure Point | Behavior | User Feedback | Logging |
|---|---|---|---|
| Missing API key at setup | Block creation (prototype policy) | Inline blocking error + Settings deep-link | `alarm_create_blocked_no_api_key` |
| Text generation fails | Arm fallback path immediately | Non-blocking warning | `text_gen_failed_fallback_armed` |
| TTS generation fails | Arm fallback path immediately | Non-blocking warning | `tts_failed_fallback_armed` |
| Audio file write fails | Arm ringtone fallback | Warning + recover action | `audio_persist_failed_ringtone_armed` |
| AlarmKit permission denied | Prompt settings path; do not silently proceed | Blocking alert | `alarmkit_permission_denied` |
| Conversation launch fails (Phase 2) | Trigger/escalate fallback alarm | Full-screen failure notice when app opens | `conversation_launch_failed_fallback` |
| Mic permission denied (Phase 2) | Switch to non-mic wake challenge flow | Clear permission prompt + fallback | `mic_denied_non_mic_mode` |

## 9) Architecture (Target)

### Client-Only Prototype (Current)
1. `AlarmOrchestrator` (state machine + fallback ladder)
2. `MessageGenerationService` (LLM text)
3. `SpeechSynthesisService` (provider abstraction: OpenAI now, replaceable later)
4. `AlarmBackboneService` (AlarmKit scheduling/cancel)
5. `FallbackAudioService` (bundled ringtone and fallback mapping)
6. `WakeFlowCoordinator` (Phase 1+ challenge flow)
7. `KeychainService` (API key storage)
8. `TelemetryService` (local logs; key redaction always on)

### Provider Interfaces
1. `WakeTextProvider` -> returns text only.
2. `TTSProvider` -> returns audio only.

This keeps LLM and voice engine independently swappable (e.g., OpenAI, ElevenLabs).

## 10) Phase Plan

## Phase 0: Reliability Gate (Pre-MVP)

### Objective
Prove no-silent-fail behavior with one-time alarms.

### Scope
1. Alarm creation UI (minimal).
2. 2-step AI generation pipeline.
3. Pre-generated audio scheduling.
4. Hard fallback arming.
5. Distinct voices/sounds by mode for debugging.
6. Basic local telemetry.

### Out of Scope
1. Repeating alarms.
2. Realtime conversation.
3. Wake-complete challenge enforcement.
4. Snooze customization.

### Exit Criteria (Must Pass)
1. 50+ on-device test alarms across normal + failure scenarios.
2. 0 silent failures.
3. Documented fallback trigger in each forced failure case.

## Phase 1: Wake-Complete Enforcement

### Objective
Require conscious user action after alarm fire.

### Scope
1. Wake-complete challenge system.
2. Default policy: complete 2 of 3 checks:
   - QR code scan at remote location.
   - Step challenge (pedometer threshold).
   - Spoken passphrase (non-conversational).
3. Escalation: if incomplete within window, schedule follow-up alarm bursts.
4. Repeating alarms support.

### Exit Criteria
1. Challenge completion and escalation both verified on-device.
2. No silent failures during challenge or escalation.

## Phase 2: Realtime Conversation Wake Mode

### Objective
Foreground AI conversation for wake-up.

### Scope
1. Realtime voice session in app foreground.
2. Conversation orchestrated with wake challenges.
3. Permission-aware routing:
   - Mic granted -> conversation mode.
   - Mic denied/fails -> Phase 1 challenge + fallback alarm path.

### Exit Criteria
1. Stable foreground voice loop under expected network conditions.
2. Deterministic fallback on every conversation failure path.

## Phase 3: Adaptive Policies and Personalization

### Objective
Improve wake effectiveness and user control.

### Scope
1. User-configurable wake-complete policies.
2. Personal context prompts (calendar/tasks), privacy-gated.
3. Adaptive escalation by user history.

## 11) Data and Privacy (Prototype)

1. BYO API key is temporary prototype-only.
2. Never log API keys.
3. Prompt/content logging allowed only in debug builds.
4. Release builds must disable raw prompt logging by default.

## 12) Open Decisions (To Lock Before Phase 1/2)

1. Exact follow-up alarm cadence during incomplete wake flow.
2. Max escalation duration before marking failed wake.
3. Default wake window length (e.g., 3, 5, or 10 minutes).
4. Challenge difficulty defaults (step count, QR timeout, passphrase complexity).
5. Minimum acceptable wake-complete rate for shipping.

## 13) Verification Plan

### Phase 0 Test Matrix
1. Normal network, valid key -> AI audio arms and fires.
2. Offline at generation -> fallback arms and fires.
3. Invalid key/rate limit -> fallback arms and fires.
4. App killed/device locked/silent mode -> audible alarm still fires.
5. Distinct mode voice/sound correctly identifies execution path.

### Phase 1+ Additions
1. Challenge flow under lock/unlock transitions.
2. Mic denied path (Phase 2) correctly routes to non-mic challenge.
3. Escalation alarms fire if wake-complete not achieved.

---

## Summary
This PRD prioritizes reliability first (Phase 0), then conscious wake enforcement (Phase 1), then realtime conversation (Phase 2), while preserving a strict no-silent-fail policy through a mandatory fallback ladder.
