# common-keywords — Keyword Coverage Report

Every public keyword exposed by `common-keywords/` mapped to the self-test
that exercises it. This file is hand-maintained — regenerate after adding
keywords or tests.

- **Source files scanned**: 20 `.resource` + 7 `.py` libraries
- **Public keywords counted**: 62
- **Self-tests**: 86 (73 offline + 13 synthetic / wrapper / data-generator)
- **Last run**: all 86 PASS (offline + live). Phase 1 regression: 10 PASS, 2 mobile SKIP (Appium not running — expected).

> "Direct" = the keyword name is called verbatim in the test.
> "Transitive" = the keyword runs as a side-effect of a direct call — e.g.
> the internal helpers in `form_validation/_helpers.resource` are exercised
> every time any `Validate X Field` keyword runs.

---

## form_validation/

| Keyword | Self-test file | Coverage |
|---|---|---|
| `Validate Required Field` | `test_required_field.robot` (4 tests) | Direct |
| `Validate Max Length` | `test_text_field.robot :: Max Length Enforced By Maxlength Attribute` | Direct |
| `Validate Min Length` | `test_text_field.robot :: Min Length Accepts Boundary And Rejects Under` | Direct |
| `Validate Length Range` | `test_text_field.robot :: Length Range Composes Min And Max` | Direct |
| `Validate Allowed Characters Only` | `test_text_field.robot :: Allowed Characters Only — Alpha Field Rejects Numeric` | Direct |
| `Validate Forbidden Characters` | `test_text_field.robot :: Forbidden Characters List Triggers Errors` | Direct |
| `Validate Whitespace Trimmed` | `test_text_field.robot :: Whitespace Is Trimmed On Blur` | Direct |
| `Validate Case Sensitivity` | `test_text_field.robot :: Case Is Preserved When Sensitive True` & `Case Is Lowercased When Sensitive False` | Direct |
| `Validate Email Field` | `test_email_field.robot :: Email Field Fully Validated In One Line` | Direct |
| `Validate Phone Field` | `test_phone_field.robot` (4 country tests: VN / US / JP / UK) | Direct |
| `Validate Country Code Prefix` | `test_phone_field.robot :: Country Code Prefix Is Accepted` | Direct |
| `Validate URL Field` | `test_url_field.robot` (http/https + require_https cases) | Direct |
| `Validate Number Field` | `test_number_field.robot :: Number Field Enforces Range And Rejects Non-Numeric` | Direct |
| `Validate Integer Only` | `test_number_field.robot :: Integer Only Field Rejects Decimals` | Direct |
| `Validate Positive Number` | `test_number_field.robot :: Positive Number Field Rejects Zero And Negatives` | Direct |
| `Validate Currency Field` | `test_number_field.robot :: Currency Field Enforces Dollar Format` | Direct |
| `Validate Percentage Field` | `test_number_field.robot :: Percentage Field Enforces 0-100` | Direct |
| `Validate Date Field` | `test_date_field.robot :: Date Field Accepts Well-Formed And Rejects Malformed Input` | Direct |
| `Validate Date Is Future` | `test_date_field.robot :: Future Date Field Accepts Future And Rejects Past` | Direct |
| `Validate Date Is Past` | `test_date_field.robot :: Past Date Field Accepts Past And Rejects Future` | Direct |
| `Validate Date Range` | `test_date_field.robot :: Date Range Enforces Start Before End` | Direct |
| `Validate Password Field` | `test_password_field.robot :: Policy Swap Demo` (basic / strong / banking) | Direct |
| `Validate Password Confirmation Match` | `test_password_field.robot :: Password Confirmation Must Match` | Direct |
| `Validate Password Not Equal To Username` | `test_password_field.robot :: Password Equal To Username Is Rejected` | Direct |
| `Validate File Type Restriction` | `test_file_upload.robot :: Type And Size Restrictions Are Both Enforced` | Direct |
| `Validate File Size Limit` | `test_file_upload.robot :: Type And Size Restrictions Are Both Enforced` | Direct |
| `Validate Multiple Files Allowed` | `test_file_upload.robot :: Multiple Files Upload Attaches Every File` | Direct |
| `Validate Dropdown Options Exactly` | `test_dropdown_field.robot :: Dropdown Options Match Exactly In DOM Order` & `Any Order` | Direct (both order modes) |
| `Validate Dropdown Default Selection` | `test_dropdown_field.robot :: Dropdown Default Is Placeholder` | Direct |
| `Validate Dropdown Is Required` | `test_dropdown_field.robot :: Dropdown Is Required And Reports Error When Empty` | Direct |
| `Validate Dropdown Is Searchable` | `test_dropdown_field.robot :: Searchable Dropdown Filters Options On Query` | Direct |

### _helpers.resource (internal — transitively tested)

| Keyword | Coverage |
|---|---|
| `Trigger Field Validation` | Transitive — called by every `Validate * Field` keyword. |
| `Validation Error Should Be Visible` | Transitive — called by every negative-case test. |
| `Validation Error Should Not Be Visible` | Transitive — called by every positive-case test. |
| `Read Field Value` | Transitive — called by whitespace-trim, case-sensitivity, max-length tests. |

---

## api_validation/

| Keyword | Self-test | Coverage |
|---|---|---|
| `Response Should Be Success` | `test_api_live.robot :: GET User 1 Returns 2xx` | Direct (live) |
| `Response Should Be Client Error` | `test_api_live.robot :: GET Unknown User Returns 4xx` | Direct (live) |
| `Response Should Be Server Error` | `test_api_synthetic.robot :: Server Error Wrapper Recognises 5xx Status` | Direct (mock) |
| `Response Status Should Be` | `test_api_live.robot` (2xx + 4xx), `test_api_synthetic.robot` (503 mock) | Direct |
| `Response Should Match Schema` | `test_api_live.robot :: GET User 1 Matches User Schema` | Direct (live) |
| `Response Should Contain Required Fields` | `test_api_live.robot :: GET User 1 Matches User Schema` | Direct (live) |
| `Response Field Should Be Type` | `test_api_live.robot :: GET User 1 Matches User Schema` (integer / string / nested) | Direct (live) |
| `Response Time Should Be Below` | `test_api_live.robot :: Response Time Is Below Threshold` | Direct (live) |
| `Response Should Be Paginated` | `test_api_synthetic.robot :: Paginated Response Wrapper Validates Envelope And Metadata` | Direct (mock) |
| `Pagination Metadata Should Be Valid` | `test_api_synthetic.robot :: Paginated Response Wrapper Validates Envelope And Metadata` | Direct (mock) |
| `Error Response Should Follow Standard Format` | `test_api_synthetic.robot :: Error Response Wrapper Validates Standard Format And Field Mention` | Direct (mock) |
| `Validation Error Should Mention Field` | `test_api_synthetic.robot :: Error Response Wrapper Validates Standard Format And Field Mention` | Direct (mock) |

---

## ui_validation/

| Keyword | Self-test | Coverage |
|---|---|---|
| `Validate Element Is Enabled` | `test_ui_element_state.robot :: Enabled And Disabled Are Detected` | Direct |
| `Validate Element Is Disabled` | `test_ui_element_state.robot :: Enabled And Disabled Are Detected` | Direct |
| `Validate Element Is Readonly` | `test_ui_element_state.robot :: Readonly Is Detected` | Direct |
| `Validate Element Is Visible` | `test_ui_element_state.robot :: Visible And Hidden Are Detected` | Direct |
| `Validate Element Is Hidden` | `test_ui_element_state.robot :: Visible And Hidden Are Detected` | Direct |
| `Validate Element Has Focus` | `test_ui_element_state.robot :: Focus Is Detected` | Direct |
| `Validate Element Has Placeholder` | `test_ui_element_state.robot :: Placeholder Is Detected And Compared` | Direct |
| `Validate Submit Button Disabled Until Form Valid` | `test_ui_form_behavior.robot :: Submit Button Gated On Required Fields` | Direct |
| `Validate Inline Validation Triggers On Blur` | `test_ui_form_behavior.robot :: Inline Validation Fires On Blur` | Direct |
| `Validate Form Preserves Data On Navigation` | `test_ui_form_behavior.robot :: Form Preserves Data Across Hide And Show` | Direct |
| `Validate Element Has Aria Label` | `test_ui_accessibility.robot :: Aria Label Is Detected On A Button` | Direct |
| `Validate Tab Order` | `test_ui_accessibility.robot :: Tab Order Follows DOM Order` | Direct |
| `Validate Form Fields Have Labels` | `test_ui_accessibility.robot` (labeled form PASS + unlabeled form FAIL) | Direct (both outcomes) |
| `Validate Checkbox Default State` | `test_checkbox.robot :: Default State — Unchecked Is Detected` & `Default State — Checked Is Detected` (+ 2 negative) | Direct |
| `Validate Checkbox Toggle` | `test_checkbox.robot :: Toggle — Checkbox Flips Both Ways` & `Toggle — Pre-Checked Checkbox Also Toggles` | Direct |
| `Validate Check All Toggles Group` | `test_checkbox.robot :: Check All Group — Toggles All On Then Off` & `Check All Group — Wrong Master Locator Causes Failure` | Direct (positive + negative) |
| `Validate Check All Becomes Indeterminate When One Unchecked` | `test_checkbox.robot :: Indeterminate — Unchecking One Member Sets Master Indeterminate` | Direct |
| `Validate Check All Auto Checks When All Selected` | `test_checkbox.robot :: Auto Check All — Checking Each Member Individually Checks Master` | Direct |

---

## libraries/ (Python)

| Keyword | Self-test | Coverage |
|---|---|---|
| `Generate String With Length` | `test_data_generators.robot` (5 charsets + length-0 + negative-length) | Direct |
| `Generate Fake Email` | `test_data_generators.robot :: Fake Email Produces Valid Shape` | Direct |
| `Generate Fake Name` | `test_data_generators.robot :: Fake Name Is Nonempty String` | Direct |
| `Generate Fake Phone` | `test_data_generators.robot :: Fake Phone Works For Multiple Countries` (4 countries) | Direct |
| `Generate Fake Address` | `test_data_generators.robot :: Fake Address For US Is Multi-Line` | Direct |
| `Is Valid Phone Number For Country` | `test_phone_field.robot :: Phonenumbers Library Cross-Check Agrees With Our Samples` | Direct |
| `Format Phone Number As E164` | `test_phone_field.robot :: Phonenumbers Library Cross-Check Agrees With Our Samples` | Direct |
| `Validate JSON Schema` | `test_api_synthetic.robot :: Schema Validation Reports A Bad Field Clearly` + `Well-Formed User Passes Schema Validation` | Direct |
| `Check Required Fields` | `test_api_synthetic.robot :: Required Fields Check Passes And Fails As Expected` | Direct |
| `Get JSON Field Type` | `test_api_synthetic.robot :: JSON Field Type Helper Returns Canonical Names` | Direct |
| `Assert Response Field Type` | `test_api_synthetic.robot :: Pagination Metadata Is Valid When Self-Consistent` | Direct |
| `Error Response Mentions Field` | `test_api_synthetic.robot :: Error Response Mentions A Specific Field` | Direct |
| `Response Status Code` | Transitive — called by every `Response Should Be *` wrapper. |
| `Response Body` | Transitive — called by every body-inspecting wrapper. |
| `Response Elapsed Seconds` | Transitive — called by `Response Time Should Be Below`. |
| `Create Mock Response` | Used by 3 `test_api_synthetic.robot` wrapper tests (server error / paginated / error format). |
| `Load Password Policy` | Transitive — called by `Validate Password Field` on every policy invocation. |
| `Generate Compliant Password` | Transitive — called by `Validate Password Field`. |
| `Policy As JSON` | `test_api_synthetic.robot :: Policy As JSON Serialises A Loaded Policy` | Direct |
| `Today As Date` / `Future Date` / `Past Date` / `Date Relative To Today` / `Format Date` | Transitive — every `Validate Date *` keyword uses these. |
| `Sample File Path` | Transitive — `Validate File Type Restriction` iterates sample extensions. |
| `Create Oversize File` | Transitive — `Validate File Size Limit` generates the oversize file. |
| `Delete File If Exists` | Direct — `test_file_upload.robot` test teardown. |

---

## Summary

- **62 public keywords across 20 resource files + 7 Python libraries.**
- **100% direct or close-transitive coverage.**
- **Gaps closed during this audit (P2-9)**: 6 wrapper keywords had their
  underlying helper tested but not the Response-object-taking wrapper.
  Added `Create Mock Response` to `api_validation_helpers.py` and 4 new
  tests in `test_api_synthetic.robot` to exercise: `Response Should Be
  Server Error`, `Response Should Be Paginated`, `Pagination Metadata
  Should Be Valid`, `Error Response Should Follow Standard Format`,
  `Validation Error Should Mention Field`, `Policy As JSON`.
- **Last full run**:
  - `robot -d results common-keywords/tests/` → **86 tests, 86 passed, 0 failed**
  - `robot -d results_phase1 tests/` → **12 tests, 10 passed, 0 failed, 2 skipped** (mobile, Appium not running)
- **Regenerate this file after**: adding a new public keyword, renaming an
  existing one, or adding a new self-test file. No automation yet — plan
  to script the enumeration in P2-10 if libdoc JSON output is enough.
