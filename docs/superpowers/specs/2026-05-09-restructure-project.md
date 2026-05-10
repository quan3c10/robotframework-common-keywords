I want to refactor `robotframework-common-keywords` to a standard `src/` layout                                                                       
  before publishing it to PyPI. The PyPI publishing itself is a follow-up                                               
  cycle — out of scope here.                                                                                                                            
                                                                
  ## Goal & motivation                                                                                                                                  
                                                                                                                                                        
  Today the project uses a flat layout: keyword domain directories
  (`form_validation/`, `api_validation/`, `ui_validation/`,                                                                                             
  `data_generators/`, `libraries/`, `test_data/`) and `__init__.py` /              
  `__version__.py` sit at the repo root, and `pyproject.toml`'s                                                                                         
  `[tool.setuptools]` table uses a `package-dir` mapping to virtually                                                                                   
  re-root them under a `robot_common_keywords` namespace.                                                                                               
                                                                                                                                                        
  Move to a `src/` layout so:                                                      
  - `pyproject.toml` drops the `package-dir` mapping and uses                                                                                           
    `[tool.setuptools.packages.find] where = ["src"]`
  - The on-disk path matches the installed import path                                                                                                  
    (`src/robot_common_keywords/form_validation/email_field.resource` →                                                                                 
    `site-packages/robot_common_keywords/form_validation/email_field.resource`)                                                                         
  - New contributors don't have to mentally apply the virtual mapping                                                                                   
                                                                                                                                                        
  ## Required reading before you start                                                                                                                  
                                                                                                                                                        
  - `PROJECT_CONTEXT.md` — especially §2 (architectural layers) and §3                                                                                  
    (conventions). Do not violate the project-agnosticism gate or the                                                                                   
    underscore-helper convention.    
  - Current `pyproject.toml` — the `[tool.setuptools]` and                                                                                              
    `[tool.setuptools.package-data]` blocks.                                       
  - `scripts/new_keyword.py` — the scaffolder writes to                                                                                                 
    `<domain>/<module>.resource` and `tests/test_<module>.robot`; it must          
    be updated for the new layout.                                                                                                                      
                                                                                                                                                        
  ## Current → target                    
                                                                                                                                                        
  ```                                                                              
  # Current                                                                                                                                             
  robotframework-common-keywords/
  ├── __init__.py, __version__.py                                                                                                                       
  ├── form_validation/, api_validation/, ui_validation/, data_generators/                                                                               
  ├── libraries/                                                                                                                                        
  ├── test_data/{schemas,sample_files}/                                                                                                                 
  ├── tests/, docs/, scripts/                                                      
  └── pyproject.toml                                                                                                                                    
                                                                                   
  # Target                           
  robotframework-common-keywords/
  ├── src/robot_common_keywords/
  │   ├── __init__.py, __version__.py                                                                                                                   
  │   ├── form_validation/, api_validation/, ui_validation/, data_generators/
  │   ├── libraries/                                                                                                                                    
  │   └── test_data/{schemas,sample_files}/                                                                                                             
  ├── tests/, docs/, scripts/   # stay; their path references update
  └── pyproject.toml             # simplified                                                                                                           
  ```                                                                              
                              
  ## Change-impact map       
                                                                                                                                                        
  Use `grep -rn` to find every reference. Categories:
                                                                                                                                                        
  1. **Move source files** with `git mv` to preserve history:                                                                                           
     `form_validation/`, `api_validation/`, `ui_validation/`,                                                                                           
     `data_generators/`, `libraries/`, `test_data/`, `__init__.py`,                                                                                     
     `__version__.py` → all into `src/robot_common_keywords/`.                                                                                          
                                                                                   
  2. **`pyproject.toml`** — drop the entire `[tool.setuptools]` block with
     `package-dir`/`packages` lists. Replace with:                                                                                                      
     ```toml                         
     [tool.setuptools.packages.find]                                                                                                                    
     where = ["src"]                                                               
                                                                                                                                                        
     [tool.setuptools.package-data]
     robot_common_keywords = [                                                                                                                          
         "**/*.resource",                                                                                                                               
         "**/*.yaml",                                                                                                                                   
         "**/*.json",                                                                                                                                   
         "test_data/sample_files/*",                                               
     ]                                                                                                                                                  
     ```                      
     Verify `[tool.pytest.ini_options]` `pythonpath` still makes sense.                                                                                 
                                                                                   
  3. **Resource imports inside moved `.resource` files** — relative paths
     stay valid because the relative tree under `src/robot_common_keywords/`
     is preserved. Verify: `grep -rn '^Resource' src/`.
                                                                                                                                                        
  4. **`tests/*.robot` Resource/Library imports** — these currently use
     `../form_validation/...`, `../libraries/...`. **Open question for                                                                                  
     brainstorming**: switch to PYTHONPATH-style imports                           
     (`Resource  robot_common_keywords/form_validation/...`) which                                                                                      
     requires `pip install -e .` in dev — recommended because it exercises
     the install path users will see — or keep relative                                                                                                 
     (`../src/robot_common_keywords/form_validation/...`)?                                                                                              
                                                                                                                                                        
  5. **Python cross-imports in `libraries/*.py`** — check for                                                                                           
     `from libraries.foo` or `import libraries.foo`. Find:                                                                                              
     `grep -rn '^from libraries\|^import libraries' src/`.                                                                                              
                                     
  6. **`scripts/new_keyword.py`** — update the directory it writes                                                                                      
     keyword files to and the `Resource` path it writes into the                                                                                        
     self-test stub.                                                                                                                                    
                                                                                                                                                        
  7. **`scripts/generate-keyword-catalog.sh`** (if it exists) — likely                                                                                  
     has hardcoded scan paths.                                                                                                                          
                                                                                                                                                        
  8. **Docs**: `PROJECT_CONTEXT.md` §4 Module Dictionary table; also                                                                                    
     `docs/COVERAGE.md`, `docs/INTEGRATION.md`, `docs/EXAMPLES.md`,                                                                                     
     `README.md` for any path references.                                                                                                               
                                                                                                                                                        
  9. **`.gitignore`** — confirm `__pycache__/` and `*.egg-info/` still                                                                                  
     match.                                                                                                                                             
                                                                                                                                                        
  10. **Untracked work — DO NOT MOVE**: `browser/`, `tests/common_testcases/`,
      `tests/phone_validation/`, `scripts/excel_to_markdown.py`,                                                                                        
      `scripts/run-excel-to-markdown.sh`, `playwright-log.txt`,                                                                                         
      `docs/EXCEL_TO_MARKDOWN.md`. Leave in place; confirm with me if                                                                                   
      anything seems to depend on them being moved.                                                                                                     
                                                                                                                                                        
  ## Invariants                                                                                                                                         
                                                                                                                                                        
  - Refactor only — no behavior changes, no new keywords, no edits to
    keyword bodies.                                                                                                                                     
  - `robot --dryrun tests/` and `robot -d results --exclude network tests/`                                                                             
    must produce the same pass counts before and after.
  - Public API surface in PROJECT_CONTEXT §4 unchanged.                                                                                                 
  - Underscore-prefixed `_helpers.resource` files stay internal.                   
  - Project-agnosticism gate preserved (no app-specific stuff                                                                                           
    introduced).                                                                   
                                         
  ## Out of scope                                                                                                                                       
                              
  - PyPI publishing workflow (author info, URLs, twine, TestPyPI). Next                                                                                 
    cycle.                                                                                                                                              
  - New keywords or feature changes.                                                                                                                    
  - Migrating the untracked work listed above.                                                                                                          
                                                                                   
  ## Verification protocol                                                                                                                              
                                                                                   
  1. Capture baseline: run `robot --dryrun tests/` and                                                                                                  
     `robot -d results --exclude network tests/` BEFORE any change; record         
     pass counts.                        
  2. Implement the move + edits.                                                                                                                        
  3. `pip install -e .` in a clean venv (or rebuild current venv).
  4. Re-run the same two robot commands; pass counts must match step 1.                                                                                 
  5. `python -m build` succeeds; both sdist and wheel produced.                    
  6. `tar -tzf dist/*.tar.gz | grep '\.resource$' | wc -l` matches the                                                                                  
     number of `.resource` files under `src/robot_common_keywords/`.
  7. Fresh-venv smoke install:                                                                                                                          
     ```bash                                                                                                                                            
     python -m venv /tmp/restructure-smoke
     source /tmp/restructure-smoke/bin/activate                                                                                                         
     pip install dist/*.whl                                                                                                                             
     python -c "import robot_common_keywords; print(robot_common_keywords.__version__)"                                                                 
     ```                                                                                                                                                
     then create `/tmp/smoke.robot`:                                                                                                                    
     ```robot                                                                                                                                           
     *** Settings ***                                                                                                                                   
     Resource    robot_common_keywords/form_validation/required_field.resource     
     Library     robot_common_keywords.libraries.phone_helpers                                                                                          
                                                                                   
     *** Test Cases ***              
     Smoke                                                                                                                                              
         Log    Smoke OK
     ```                                                                                                                                                
     and run `robot --dryrun /tmp/smoke.robot` — must exit 0.                      
  8. Final stale-path sweep:                                                                                                                            
     `grep -rn 'form_validation/\|api_validation/\|ui_validation/\|data_generators/\|libraries/\|test_data/' --include='*.md' --include='*.toml' 
  --include='*.sh' --include='*.py'`                                                                                                                    
     — every hit should be either inside `src/` or correctly point at
     `src/robot_common_keywords/...`.                                                                                                                   
                                                                                   
  ## Suggested commit shape (one commit per logical category)
                                         
  1. `refactor: move package source under src/robot_common_keywords/`
     (the bulk `git mv`)                 
  2. `build: simplify pyproject.toml for src layout`                                                                                                    
  3. `test: update Resource/Library paths after src restructure`
  4. `tooling: update scripts/new_keyword.py for src layout`                                                                                            
  5. `docs: update path references in PROJECT_CONTEXT and friends`                 
                                                                                                                                                        
  Brainstorm any open questions (especially the test-import style choice                                                                                
  in §4 above), write a plan, then implement and verify.