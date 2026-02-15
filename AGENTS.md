# AGENTS.md - Crystal Router Project Guidelines

## Project Overview
A standalone HTTP router for Crystal language with route params, optional segments, grouping, and controller support.

## Build Commands

```bash
# Run all tests
crystal spec

# Run a single test file
crystal spec spec/crouter/router_spec.cr
crystal spec spec/crouter/route_spec.cr

# Run a specific test by line number
crystal spec spec/crouter/router_spec.cr:94

# Format code
crystal tool format

# Check formatting without modifying files
crystal tool format --check

# Build the project (library, no binary)
crystal build src/crouter.cr

# Run example
crystal run src/example.cr

# Install dependencies
shards install
```

## Code Style Guidelines

### Formatting
- 2-space indentation (no tabs)
- Line length: ~100 characters max
- Trailing newline at end of files
- Use single quotes for string literals unless interpolation needed

### Naming Conventions
- **Classes/Modules**: PascalCase (e.g., `Crouter::Router`, `Route::Error`)
- **Methods/Variables**: snake_case (e.g., `call_action`, `combined_params`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `VERSION`, `ROUTES`)
- **Type annotations**: Required on instance variables and method parameters

### Imports
```crystal
# Standard library first
require "spec"
require "http"
require "http/server"

# Then project files
require "./route"
require "../src/crouter"
```

### Type Declarations
Always declare types for instance variables:
```crystal
def initialize(@context : HTTP::Server::Context, @params : HTTP::Params)
end
```

### Error Handling
- Define custom exception classes as nested classes
- Include descriptive error messages
- Use `expect_raises` in specs for error testing

```crystal
class Error < Exception
  def initialize(pattern, message)
    super("failed to parse route pattern `#{pattern}' - #{message}")
  end
end
```

### Testing Conventions
- Use `call_spy` macro for testing method calls
- Reset spies before each test with `Spy.reset!`
- Group related tests in `describe` blocks
- Use `it` with descriptive strings
- Prefer `.should` assertions

### Macro Usage
Macros are used for DSL features. When writing macros:
- Use `\{{}}` escaping inside macro-generated macros
- Validate inputs and raise compile-time errors with meaningful messages
- Document macro behavior with comments

### Documentation
- Keep README.md updated with usage examples
- Include benchmark results if performance-critical

## Project Structure
```
/src/
  crouter.cr           # Main entry point
  crouter/
    router.cr          # Router class with HTTP::Handler
    route.cr           # Route matching and param handling
    version.cr         # Version constant
/spec/
  spec_helper.cr       # Test utilities and macros
  crouter_spec.cr      # Main spec entry
  crouter/
    router_spec.cr     # Router tests
    route_spec.cr      # Route tests
shard.yml              # Dependencies and metadata
.travis.yml            # CI configuration
```
