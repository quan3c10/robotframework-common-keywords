# Test cases — <feature / batch name>

> Copy this file, fill it in, and ask Claude to "extend the library from
> `<your-file>.md`". The `extend-common-keywords` skill will pick it up.
>
> One H2 per validation behavior. Skip attributes that don't apply.

---

## <Title Case Keyword Name — e.g. "Validate Postal Code Field">

- **Domain**: form_validation | api_validation | ui_validation | data_generators
- **Layer hint** (optional): .resource | python — leave blank if unsure
- **Input shape**: HTML element / API response shape / data structure being validated
- **Validation rules** (each becomes a negative case in the self-test):
  - rule 1
  - rule 2
  - ...
- **Positive case**: an input that should be accepted
- **Error surface**: how the error is exposed
  - `error_locator`-friendly: a stable selector for the error element, OR
  - `error_message`-friendly: a substring that appears in visible text
- **Trigger**: blur (default) | submit | change | none (API)
- **Reference data** (optional): existing or new YAML under `test_data/`
- **Country / policy / locale variants** (optional): list values that should
  cycle through the same keyword without code change
- **Backward-compat note** (optional): if this replaces or extends an existing
  keyword, say which one and reference §5.4

---

## <Next keyword name>

- ...

---

## Notes for the AI

If any of the above look app-specific (specific URLs, label strings, error
messages unique to one product), flag them. They belong in a consuming
project's `keywords/business/`, not here. Per `PROJECT_CONTEXT.md` §2:
**"Would Team B use this keyword as-is?"**
