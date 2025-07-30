# Clone and Sync Script Implementation

A script that clones a GitHub repository and runs sync-user-rules within that repository. This tool streamlines the process of applying user rules to multiple repositories.

## Completed Tasks

- [x] Create script file with appropriate shebang and permissions
- [x] Implement parameter parsing for required GitHub SSH path
- [x] Implement optional parameter parsing for clone directory path
- [x] Add default directory path logic (~/Documents/wavelength/spotify-wide)
- [x] Implement git clone functionality with error handling
- [x] Implement sync-user-rules execution in cloned repository
- [x] Add proper error handling and validation
- [x] Add usage documentation and help text
- [x] Test script with various input scenarios (basic validation tested)
- [x] Set up global installation to make script accessible as `ai-clone`
- [x] Create symlink or copy script to global PATH location
- [x] Test global command accessibility from any directory

## In Progress Tasks

_(No tasks in progress)_

## Future Tasks

- [ ] Add cleanup logic for failed clones (optional - can be implemented later if needed)

## Bug Fixes Applied

- [x] **sync-user-rules.sh not found**: Added script directory to search path so sync-user-rules.sh can be found when ai-clone is installed globally via symlink
- [x] **Symlink resolution**: Fixed script directory detection when ai-clone is run via symlink by properly resolving the symlink chain

## Enhancements Added

- [x] **Directory navigation**: Script now provides the exact `cd` command to enter the cloned repository and changes to that directory for any final operations

## Implementation Plan

The script will be implemented as a bash script that:

1. **Parameter Handling**: Parse command line arguments where:

   - First parameter (required): GitHub SSH path (e.g., `git@ghe.spotify.net:anchor/lambda-spotify-episode-uri-writer.git`)
   - Second parameter (optional): Target directory for cloning (defaults to `~/Documents/wavelength/spotify-wide`)

2. **Directory Management**:

   - Create target directory if it doesn't exist
   - Navigate to the specified directory
   - Extract repository name from SSH path for local directory naming

3. **Git Operations**:

   - Execute git clone command with the provided SSH path
   - Handle potential clone failures (repository already exists, network issues, etc.)

4. **Sync Execution**:

   - Navigate into the cloned repository
   - Execute the sync-user-rules script
   - Handle potential sync failures

5. **Error Handling**:

   - Validate GitHub SSH path format
   - Check if git and sync-user-rules are available
   - Provide meaningful error messages
   - Exit with appropriate status codes

6. **Global Installation**:
   - Name the script file as `ai-clone` (without .sh extension)
   - Make script executable with proper permissions
   - Install to a global PATH location (e.g., `/usr/local/bin/` or `~/bin/`)
   - Create symlink or copy script to enable global access
   - Test accessibility from any directory

### Technical Components Needed

- Bash script with parameter validation
- Git clone command execution
- Directory navigation and creation
- Error handling and logging
- Help/usage text functionality

### Environment Configuration

- Requires git to be installed and configured
- Requires sync-user-rules script to be accessible
- SSH keys must be configured for GitHub Enterprise access

## Relevant Files

- `ai-clone` - Main script file ✅ (completed)
- `sync-user-rules.sh` - Existing script that will be executed in cloned repos
- `~/bin/ai-clone` - Global symlink installation ✅ (completed - uses symlink for automatic updates)

## Usage Example

```bash
# After global installation - basic usage with default directory
ai-clone git@ghe.spotify.net:anchor/lambda-spotify-episode-uri-writer.git

# Usage with custom directory
ai-clone git@ghe.spotify.net:anchor/lambda-spotify-episode-uri-writer.git ~/my-projects

# Can be run from any directory after global installation
cd /anywhere
ai-clone git@ghe.spotify.net:anchor/lambda-spotify-episode-uri-writer.git
```

## Global Installation Steps

The script is installed globally using a symlink approach for automatic updates:

```bash
# Make script executable
chmod +x ai-clone

# Create symlink to ~/bin (recommended - automatic updates)
rm ~/bin/ai-clone 2>/dev/null || true  # Remove any existing copy
ln -s $(pwd)/ai-clone ~/bin/ai-clone

# Alternative options:
# Option 1: Copy to /usr/local/bin (requires sudo, manual updates needed)
sudo cp ai-clone /usr/local/bin/

# Option 2: Create symlink to /usr/local/bin (requires sudo)
sudo ln -s $(pwd)/ai-clone /usr/local/bin/ai-clone
```

**Benefits of Symlink Approach:**

- ✅ Updates to the source script automatically apply globally
- ✅ Single source of truth - edit in project directory
- ✅ No need to remember to copy after changes
- ✅ Version control tracks the actual script being used
