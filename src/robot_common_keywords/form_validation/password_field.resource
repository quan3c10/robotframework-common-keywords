*** Settings ***
Documentation    Policy-driven password-field validation. Policies live in
...              ``test_data/password_policies.yaml``. Adding a policy is a
...              YAML edit; the keyword picks it up by name.
Library          Browser
Library          Collections
Library          String
Library          robot_common_keywords.libraries.password_helpers
Library          robot_common_keywords.libraries.boundary_generator
Resource         _helpers.resource
Resource         required_field.resource


*** Keywords ***
Validate Password Field
    [Documentation]    Asserts the target field enforces every rule in the
    ...                named policy.
    ...
    ...                Steps (each skipped if its rule is off in the policy):
    ...                1. Compliant password is accepted.
    ...                2. Required check (if ``required=${True}``).
    ...                3. Too-short password rejected.
    ...                4. Missing-uppercase rejected.
    ...                5. Missing-lowercase rejected.
    ...                6. Missing-number rejected.
    ...                7. Missing-special rejected.
    ...                8. Common password rejected.
    ...                9. Sequential-chars rejected (e.g. ``Abcd...``).
    ...                10. Password containing the username rejected
    ...                    (requires ``username`` argument).
    [Arguments]    ${field_locator}    ${policy}=basic
    ...            ${username}=${EMPTY}
    ...            ${required}=${True}
    ...            ${required_error}=This field is required
    ...            ${invalid_format_error}=does not meet
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}

    ${p}=    Load Password Policy    ${policy}

    # 1. Happy: a compliant password must pass validation.
    ${good}=    Generate Compliant Password    ${p}    ${username}
    Accept Sample    ${field_locator}    ${good}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${invalid_format_error}

    # 2. Required.
    IF    ${required}
        Validate Required Field    ${field_locator}
        ...    error_message=${required_error}    error_locator=${error_locator}
        ...    trigger=${trigger}    submit_locator=${submit_locator}
    END

    # 3. Too short.
    IF    ${p.min_length} > 0
        ${short}=    Generate String With Length    ${p.min_length - 1}    alphanumeric
        Reject Sample    ${field_locator}    ${short}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 4. Missing uppercase — all lowercase + digits + special.
    IF    ${p.require_uppercase}
        Reject Sample    ${field_locator}    alllower1234!xy    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 5. Missing lowercase — all uppercase + digits + special.
    IF    ${p.require_lowercase}
        Reject Sample    ${field_locator}    ALLUPPER1234!XY    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 6. Missing digit.
    IF    ${p.require_number}
        Reject Sample    ${field_locator}    NoDigitsHere!XY    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 7. Missing special.
    IF    ${p.require_special}
        Reject Sample    ${field_locator}    NoSpecials123AbcXy    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 8. Common password.
    IF    ${p.forbid_common_passwords}
        Reject Sample    ${field_locator}    password123    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 9. Sequential chars.
    IF    ${p.forbid_sequential_chars}
        Reject Sample    ${field_locator}    Abcdef123456!Wx    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END

    # 10. Password containing the username.
    ${has_username}=    Evaluate    bool($username)
    IF    ${p.forbid_username_substring} and ${has_username}
        Reject Sample    ${field_locator}    Str0ng${username}Pass!Wx    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${invalid_format_error}
    END


Validate Password Confirmation Match
    [Documentation]    Types the same strong password into both fields and
    ...                asserts no error; then types a different value into
    ...                the confirmation field and asserts an error.
    [Arguments]    ${password_locator}    ${confirm_locator}
    ...            ${mismatch_error}=do not match    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    ${sample}=    Set Variable    Str0ngPass!Qwrt

    Type Text    ${password_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${password_locator}    ${trigger}    ${submit_locator}
    Type Text    ${confirm_locator}     ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${confirm_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${mismatch_error}    error_locator=${error_locator}

    Type Text    ${confirm_locator}    WrongPass!Qwrt    delay=0 ms    clear=True
    Trigger Field Validation    ${confirm_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${mismatch_error}    error_locator=${error_locator}


Validate Password Not Equal To Username
    [Documentation]    Types ``${username}`` verbatim into the password field
    ...                and asserts an error (whatever rule the app uses to
    ...                detect username-based passwords).
    [Arguments]    ${password_locator}    ${username}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Reject Sample    ${password_locator}    ${username}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}


# --- Internal ---

Accept Sample
    [Arguments]    ${field_locator}    ${sample}    ${trigger}    ${submit_locator}
    ...            ${error_locator}    ${error_message}
    Type Text    ${field_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

Reject Sample
    [Arguments]    ${field_locator}    ${sample}    ${trigger}    ${submit_locator}
    ...            ${error_locator}    ${error_message}
    Type Text    ${field_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}
