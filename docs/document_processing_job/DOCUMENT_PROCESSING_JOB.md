# DocumentProcessingJob - Performance and Reliability Improvements

## Executive Summary

The `DocumentProcessingJob` is a critical component of the TodoLegal application responsible for processing PDF gazettes, extracting content, and creating structured documents. This documentation covers major improvements made to address memory leaks, process hangs, and reliability issues that were causing production instability.

## Problem Analysis

### Original Issue (September 16, 2025)
- **Memory Leak**: Process consuming 2.4GB RAM (30.8% of system memory)
- **Infinite Hangs**: Jobs running for 65+ minutes without completion
- **Redis Connection Issues**: Zombie connections every 40-41 seconds for 10+ minutes
- **Process Deadlocks**: Stuck reading from Python subprocess pipes
- **Sidekiq Stats Reset**: Lost job statistics and scheduled jobs

### Root Cause
The job used unsafe subprocess execution with backticks (`) that could hang indefinitely when Python scripts failed or returned empty output, leading to:
1. **Pipe Deadlocks**: Ruby process waiting indefinitely for data from Python scripts
2. **Memory Accumulation**: 22+ hour uptimes with gradual memory growth
3. **Redis Overwhelm**: Connection pool exhaustion during mass job execution

## Solution Overview

### Key Improvements Made
1. **✅ Timeout Protection**: Added comprehensive timeout handling at multiple levels
2. **✅ Safe Subprocess Execution**: Replaced backticks with `Open3.capture3`
3. **✅ Enhanced Error Handling**: Graceful failures with proper cleanup
4. **✅ Improved Logging**: Detailed debugging and monitoring capabilities
5. **✅ Process Monitoring**: Better visibility into job execution
6. **✅ Mailer Integration**: Proper error notifications

## Architecture Changes

### Before (Problematic Implementation)
```ruby
# UNSAFE: Could hang indefinitely
python_return_value = `python3 ~/GazetteSlicer/slice_gazette.py #{args}`
json_data = JSON.parse(python_return_value) # Could fail on empty string
```

### After (Safe Implementation)
```ruby
# SAFE: Timeout-protected with proper error handling
Timeout::timeout(900) do  # 15-minute limit
  stdout_str, stderr_str, status = Open3.capture3(*cmd)
  unless status.success?
    # Proper error handling with detailed logging
  end
  # Validate output before parsing JSON
  raise "Empty output" if stdout_str.blank?
  result = JSON.parse(stdout_str)
end
```

## Process Flow

### Job Execution Timeline
```
DocumentProcessingJob.perform(document, pdf_path, user)
├── 1. Overall Timeout (30 minutes)
├── 2. process_gazette (13 minutes max)
│   ├── Extract gazette metadata (number, date)
│   └── Update document with basic info
├── 3. run_slice_gazette_script (15 minutes max)
│   ├── Slice PDF into sections
│   ├── Extract content via OCR
│   └── Return structured JSON
├── 4. Document Processing
│   ├── Create related documents
│   ├── Apply tags and metadata
│   └── Upload file attachments
└── 5. Notification
    ├── Send completion email
    └── Discord notification (if configured)
```

### Timeout Hierarchy
- **Job Level**: 30 minutes (1800 seconds) - Overall job timeout
- **Slice Script**: 15 minutes (900 seconds) - PDF processing and slicing
- **Process Script**: 13 minutes (780 seconds) - Metadata extraction

## Configuration

### Sidekiq Options
```ruby
sidekiq_options retry: 1,        # Reduced retries for heavy jobs
                dead: true,      # Keep failed jobs for investigation
                queue: 'default' # Can be changed to 'document_processing'
```

### Dependencies
```ruby
require 'open3'    # Safe subprocess execution
require 'timeout'  # Timeout protection
```

### Python Script Integration
The job integrates with two Python scripts:
1. **`slice_gazette.py`**: Processes PDF and extracts structured content
2. **`process_gazette.py`**: Extracts gazette metadata (number, date)

## Error Handling

### Error Categories and Responses

#### 1. Timeout Errors
- **Job Timeout (30min)**: Updates document description, sends error email, raises exception
- **Script Timeout (15min/13min)**: Returns safe default values, notifies user

#### 2. Python Script Failures
- **Empty Output**: Returns default structure `{ "page_count" => 0, "files" => [] }`
- **Invalid JSON**: Logs error details, saves error to document description
- **Exit Code != 0**: Captures stderr, logs command and failure details

#### 3. File System Errors
- **Missing Script**: Clear error message with script path
- **Missing Input PDF**: Validation before execution
- **Output Directory**: Auto-creation of required directories

### Error Recovery Mechanisms
```ruby
# Graceful error handling pattern used throughout
begin
  # Risky operation
rescue SpecificError => e
  Rails.logger.error "Detailed error message: #{e.message}"
  document.description = "User-friendly error description"
  document.save
  DocumentProcessingMailer.document_processing_complete(user, link, "error").deliver
  return safe_default_value
end
```

## Logging and Monitoring

### Enhanced Logging Features
- **Process Start/End**: Clear job lifecycle tracking
- **Command Logging**: Full Python command with arguments
- **Execution Time**: Duration tracking for performance analysis
- **Memory Monitoring**: Integration points for memory tracking
- **Error Context**: Complete error details with stdout/stderr

### Log Examples
```
INFO: Starting DocumentProcessingJob for document 12345
INFO: Executing Python command: python3 /path/to/slice_gazette.py args...
INFO: Python script completed successfully
INFO: Successfully parsed JSON with 5 files and 25 pages
INFO: DocumentProcessingJob completed successfully for document 12345
```

### Error Log Examples
```
ERROR: Python script failed with exit code 1: Permission denied
ERROR: Python stdout: ""
ERROR: Python stderr: "FileNotFoundError: PDF file not found"
ERROR: Command was: python3 /home/deploy/GazetteSlicer/slice_gazette.py /path/file.pdf
```

## Performance Improvements

### Before vs After Metrics
| Metric | Before | After | Improvement |
|--------|--------|--------|-------------|
| Max Job Duration | Infinite (65+ min observed) | 30 minutes | 100% reliability |
| Memory Usage | 2.4GB+ accumulation | Controlled cleanup | Prevented leaks |
| Error Recovery | Process hanging | Graceful failures | User notification |
| Debugging | Limited visibility | Detailed logging | Faster resolution |

### Memory Management
- **Process Cleanup**: Proper subprocess termination
- **Timeout Bounds**: Prevents infinite resource consumption
- **Connection Management**: Avoids Redis connection pool exhaustion

## Production Deployment

### Pre-Deployment Checklist
- [ ] Verify Python scripts are accessible at expected paths
- [ ] Test Python scripts manually with sample PDFs
- [ ] Ensure Redis connection stability
- [ ] Verify mailer templates exist
- [ ] Check disk space for gazette file storage

### Post-Deployment Monitoring
```bash
# Monitor job execution
tail -f log/production.log | grep DocumentProcessingJob

# Check for stuck processes
ps aux | grep python | grep -E "(slice_gazette|process_gazette)"

# Monitor memory usage
watch -n 30 'ps aux | grep -E "(sidekiq|ruby)" | head -5'

# Check Redis connection health
redis-cli ping
redis-cli info memory
```

### Restart Requirements
Restart Sidekiq after:
- Job class modifications
- Python script updates  
- Mailer template changes
- Configuration updates

```bash
sudo systemctl restart sidekiq
# or
bundle exec sidekiqctl restart /path/to/sidekiq.pid
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. "Python script returned empty output"
**Symptoms**: Job fails with JSON parsing error
**Diagnosis**:
```bash
# Test Python script manually
cd /app/current
python3 ~/GazetteSlicer/slice_gazette.py /path/to/test.pdf /tmp/output 123
```
**Solutions**:
- Check Python script permissions (`chmod +x`)
- Verify Python dependencies installed
- Check input PDF file exists and is readable
- Verify output directory permissions

#### 2. "Process timed out after X minutes"
**Symptoms**: Jobs consistently timing out
**Diagnosis**: Check PDF size and complexity
**Solutions**:
- Increase timeout for large PDFs (modify `Timeout::timeout` values)
- Optimize Python scripts for performance
- Consider splitting large PDFs

#### 3. Mailer Template Missing Error
**Symptoms**: `ActionView::MissingTemplate` error
**Solution**: Restart Sidekiq to reload template cache
```bash
sudo systemctl restart sidekiq
```

#### 4. High Memory Usage
**Symptoms**: Sidekiq worker using excessive RAM
**Diagnosis**:
```bash
ps -o pid,user,%mem,rss,command ax | grep sidekiq
```
**Solutions**:
- Check for stuck jobs in Sidekiq Web UI
- Restart Sidekiq workers
- Monitor for zombie Python processes

### Emergency Procedures

#### Stop Stuck Job
```bash
# Find the Sidekiq process
ps aux | grep sidekiq

# Kill specific job (if identifiable)
kill -9 <pid>

# Restart entire Sidekiq
sudo systemctl restart sidekiq
```

#### Clear Failed Jobs
```ruby
# In Rails console
Sidekiq::DeadSet.new.clear
Sidekiq::RetrySet.new.clear
```

## Code Structure

### Main Methods

#### `perform(document, document_pdf_path, user)`
- **Purpose**: Main entry point with overall timeout protection
- **Timeout**: 30 minutes
- **Error Handling**: Catches all exceptions, updates document, sends notifications

#### `run_slice_gazette_script(document, document_pdf_path, user)`
- **Purpose**: Executes Python script to slice gazette PDF
- **Timeout**: 15 minutes
- **Returns**: Hash with `page_count` and `files` array
- **Error Handling**: Returns safe defaults on failure

#### `process_gazette(document, document_pdf_path, user)`
- **Purpose**: Extracts gazette metadata (number, date)
- **Timeout**: 13 minutes
- **Side Effects**: Updates document with gazette information

#### Helper Methods
- `addTagIfExists(document_id, tag_name)`: Safely adds document tags
- `addIssuerTagIfExists(document_id, issuer_name)`: Adds issuer tags
- `cleanText(text)`: Cleans up extracted text content

### Integration Points

#### External Dependencies
- **Python Scripts**: `slice_gazette.py`, `process_gazette.py`
- **File System**: PDF storage in `public/gazettes/`
- **Database**: Document, Tag, DocumentTag models
- **Email**: DocumentProcessingMailer
- **Discord**: Optional notification integration

#### Error Notification Flow
```
Error Occurs
├── Log detailed error information
├── Update document.description with user-friendly message
├── Save document state
├── Send email notification via DocumentProcessingMailer
└── Return safe default or raise exception
```

## Future Improvements

### Recommended Enhancements
1. **Queue Separation**: Move to dedicated `document_processing` queue
2. **Retry Logic**: Implement exponential backoff for transient failures
3. **Progress Tracking**: Add job progress updates for long-running processes
4. **Health Checks**: Periodic validation of Python script availability
5. **Metrics Collection**: Detailed performance and success rate tracking

### Performance Monitoring
- Add custom metrics for job duration, success rates, and error types
- Implement alerting for consistently failing jobs or performance degradation
- Consider job batching for multiple small documents

---

## Related Documentation
- [Sidekiq Configuration](../config/initializers/sidekiq.rb)
- [DocumentProcessingMailer](../app/mailers/document_processing_mailer.rb)
- [Gazette Processing Scripts Documentation](../docs/GAZETTE_PROCESSING_SCRIPTS.md)

**Last Updated**: September 25, 2025  
**Version**: 2.0  
**Author**: TodoLegal Development Team