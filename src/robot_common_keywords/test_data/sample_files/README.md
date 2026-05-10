# Sample files for file-upload self-tests

Each file is 100 bytes of a single ASCII character. **Content is not
meaningful** — browsers infer MIME type from the extension for `<input
type="file">` uploads, so only the extension matters for
`Validate File Type Restriction` tests.

| File        | Intent                     | Size     |
|-------------|----------------------------|----------|
| `tiny.jpg`  | allowed (image)            | 100 B    |
| `tiny.png`  | allowed (image)            | 100 B    |
| `tiny.pdf`  | rejected (document)        | 100 B    |
| `tiny.exe`  | rejected (executable)      | 100 B    |
| `tiny.txt`  | rejected (plain text)      | 100 B    |

Oversize files for negative size-limit testing are **not committed** —
`libraries/file_helpers.py :: Create Oversize File` generates them in
`tempfile.gettempdir()` at test-runtime and tests clean them up in teardown.
