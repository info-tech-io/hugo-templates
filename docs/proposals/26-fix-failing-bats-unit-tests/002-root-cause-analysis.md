# Stage 2: Root Cause Analysis

**Objective**: Understand the fundamental reason why the BATS tests are failing since their creation.
**Duration**: Estimated 2 hours
**Dependencies**: Stage 1 completed

## Detailed Steps

### Step 2.1: Detailed Test Failure Analysis

**Action**: Run the failing tests with maximum verbosity and analyze the output to understand the exact point of failure.

**Implementation**:
```bash
# Run the unit test suite with verbose output and redirect stderr to stdout
./scripts/test-bash.sh --suite unit --verbose
```

**Verification**:
- [ ] Capture the full output of the test run.
- [ ] For each failing test, identify the exact assertion that fails.
- [ ] Document the error messages and the state of variables at the time of failure.

**Success Criteria**:
- ✅ A clear understanding of *what* is failing in each test (e.g., wrong status code, missing output).

### Step 2.2: Analyze `error-handling.sh` Logic

**Action**: Review the `error-handling.sh` script, which is implicated in almost all test failures. The focus is on the `error_trap_handler` and `log_structured` functions.

**Implementation**:
```bash
# No command to run, this is a code review task.
# Key functions to analyze:
# - error_trap_handler: How does it catch errors? Does it exit correctly?
# - log_structured: Does it interfere with the script's exit code?
# - safe_execute: How does it report failures?
```

**Verification**:
- [ ] Trace the execution flow when an error is triggered in a test.
- [ ] Analyze how exit codes are propagated through the logging functions.
- [ ] Form a hypothesis about why the expected exit codes are not being returned.

**Success Criteria**:
- ✅ A clear hypothesis explaining why the error handling mechanism causes tests to fail. For example: "The `log_structured` function returns `0` even after logging an ERROR, which masks the original non-zero exit code and breaks tests that assert a failure."

### Step 2.3: Cross-Reference Failing Tests with Script Logic

**Action**: Pick 2-3 failing tests and manually trace their execution against the actual shell scripts to confirm the hypothesis from Step 2.2.

**Implementation**:
- **Test Case 1: `validate_parameters handles missing Hugo`**:
    - Review `tests/bash/unit/build-functions.bats`.
    - Review the `validate_parameters` function in the build script.
    - Manually simulate the condition (Hugo command not found) and trace how the error is handled.
- **Test Case 2: `load_module_config handles missing config file`**:
    - Review the same test file.
    - Review the `load_module_config` function.
    - Trace the error path when the config file is not found.

**Verification**:
- [ ] Confirm that the behavior observed in the test output matches the code logic.
- [ ] Document the step-by-step flow of how the error is generated and then incorrectly handled.

**Success Criteria**:
- ✅ Concrete proof that the hypothesis from Step 2.2 is correct, with specific examples from the code.

### Step 2.4: Document Findings

**Action**: Summarize the root cause in the stage progress report.

**Implementation**:
- Write a clear, concise explanation of the core problem.
- Provide code snippets and test outputs as evidence.
- Propose a high-level strategy for the fix (to be detailed in Stage 3).

**Verification**:
- [ ] The summary is easy to understand for other developers.
- [ ] The evidence provided is compelling.

**Success Criteria**:
- ✅ A complete and documented root cause analysis, ready for Stage 3 (Fix Implementation).

## Definition of Done

- [ ] All steps are completed.
- [ ] The root cause of the test failures is identified and documented in `002-progress.md`.
- [ ] A clear, evidence-based hypothesis is formulated and verified.
- [ ] The team can now proceed to Stage 3 with a precise understanding of what needs to be fixed.
