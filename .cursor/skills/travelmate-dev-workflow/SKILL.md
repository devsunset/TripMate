---
name: travelmate-dev-workflow
description: Enforces TravelMate development workflow across Flutter app and Node backend: prevents Flutter web dart:io/_Namespace issues, standardizes API query/result logging, and guides safe commit/push when git trailer option breaks. Use when fixing cross-platform bugs, adding upload/search endpoints, adding debug logs, or when the user asks to commit/push.
---

# TravelMate Dev Workflow

## Quick start (always follow in this order)
1. **Identify runtime target**: Web vs Mobile/IO vs Backend.
2. **Pick the right layer**:
   - Flutter UI: `presentation/`
   - Flutter domain: `domain/`
   - Flutter data/API: `data/`
   - Backend routing/controller/model: `travel_mate_backend/src/`
3. **Add logs only in safe places**:
   - Flutter: `kDebugMode` + `debugPrint`
   - Backend: `console.log`/`console.error`
   - Never log tokens / PII.
4. **Validate**:
   - Flutter: `flutter analyze`
   - Backend: start server + hit endpoint once (curl or app)

## A) Flutter Web `_Namespace` / `dart:io` 방지 체크리스트

### Symptoms
- Error: `Unsupported operation: _Namespace`
- Usually caused by **web build loading code that imports/uses `dart:io`**.

### Fix pattern
- **Never** use `dart:io` (`File`, `Directory`, `Platform`) in web code paths.
- Prefer `XFile` (from `image_picker`) and `readAsBytes()` for web upload.

### Mandatory rules
- **Conditional export/import must select web implementation on web**.
  - Pattern to use:
    - `export 'impl_io.dart' if (dart.library.html) 'impl_web.dart';`
  - Verify by grepping for the conditional file and ensuring the web file is the conditional target.
- If a repository/usecase passes “image”:
  - Use `dynamic image` and accept:
    - Mobile/IO: `String path` or `XFile.path`
    - Web: `XFile` → bytes

### Minimal test
- Run:
  - `flutter build web`
- Ensure profile save/upload path does not throw `_Namespace`.

## B) 동행찾기(검색/필터) “실제 쿼리·결과 로그” 표준

### Client (Flutter, Dio)
- Log request query parameters and response summary in `kDebugMode`.
- Format:
  - `[동행 검색] 요청 쿼리: {...}`
  - `[동행 검색] 응답: total=..., returned=..., limit=..., offset=...`

### Server (Express/Sequelize)
- Log (no tokens):
  - `[동행 검색] 수신 쿼리: {...}`
  - `[동행 검색] 질의 조건: { userWhere, profileWhere, ... }`
  - `[동행 검색] 질의 결과: { total, returned, sampleNicknames }`

### Never do
- Don’t log `Authorization` headers / Firebase ID token.

## C) Commit / Push 워크플로우 (git trailer 이슈 포함)

### Symptom
- `git commit` fails with: `error: unknown option 'trailer'`
  - Trace shows: `git commit --trailer 'Made-with: Cursor' ...`

### Fix (preferred)
- Use system git binary directly:
  - `/usr/bin/git commit -m \"...\"`
  - `/usr/bin/git push origin <branch>`

### Safety rules
- Don’t rewrite history unless user explicitly asks.
- Don’t force push to `master/main`.




---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
license: MIT
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.