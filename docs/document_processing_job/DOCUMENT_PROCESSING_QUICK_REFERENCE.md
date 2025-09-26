# DocumentProcessingJob Quick Reference

## 🚨 Emergency Commands

### Stop Stuck Job
```bash
# Find and kill stuck Sidekiq process
ps aux | grep sidekiq
sudo kill -9 <pid>

# Restart Sidekiq service
sudo systemctl restart sidekiq
sudo systemctl status sidekiq
```

### Check Job Status
```bash
# Monitor active jobs
tail -f log/production.log | grep DocumentProcessingJob

# Check for stuck Python processes
ps aux | grep python | grep -E "(slice_gazette|process_gazette)"

# Monitor memory usage
ps -o pid,user,%mem,rss,command ax | grep -E "(sidekiq|ruby)"
```

## 🔧 Common Issues & Solutions

| Issue | Quick Fix | Investigation |
|-------|-----------|---------------|
| **Mailer Template Missing** | `sudo systemctl restart sidekiq` | Check template exists in `app/views/document_processing_mailer/` |
| **Python Script Empty Output** | Test script manually: `python3 ~/GazetteSlicer/slice_gazette.py` | Check permissions, dependencies, input file |
| **Job Timeout** | Check PDF size | Consider increasing timeout limits |
| **High Memory Usage** | Restart Sidekiq | Look for zombie processes |
| **Redis Connection Issues** | Check Redis status: `redis-cli ping` | Monitor connection pool usage |

## 📊 Monitoring Commands

### Check Python Scripts
```bash
# Test slice_gazette.py
cd /home/deploy/TodoLegal/current
python3 ~/GazetteSlicer/slice_gazette.py /path/to/test.pdf /tmp/test 123

# Test process_gazette.py  
python3 ~/GazetteSlicer/process_gazette.py /path/to/test.pdf
```

### Check File Permissions
```bash
ls -la ~/GazetteSlicer/slice_gazette.py
ls -la ~/GazetteSlicer/process_gazette.py
chmod +x ~/GazetteSlicer/*.py
```

### Monitor Job Queues
```ruby
# Rails console
Sidekiq::Queue.new('default').size
Sidekiq::RetrySet.new.size
Sidekiq::DeadSet.new.size

# Clear failed jobs
Sidekiq::DeadSet.new.clear
Sidekiq::RetrySet.new.clear
```

### Check Redis Health
```bash
redis-cli ping                    # Should return PONG
redis-cli info memory            # Memory usage
redis-cli CONFIG GET maxmemory   # Memory limits
redis-cli keys sidekiq:*         # Sidekiq data
```

## ⚠️ Warning Signs

### High Memory Usage
- Sidekiq process > 1GB RAM
- Multiple stuck Python processes
- Redis memory approaching limits

### Performance Issues
- Jobs taking > 20 minutes consistently
- Multiple jobs in retry queue
- Python scripts returning empty output

### System Issues
- Disk space < 1GB available
- High CPU usage on Python processes
- Redis connection timeouts

## 📋 Deployment Checklist

### Before Deployment
- [ ] Test Python scripts manually
- [ ] Verify gazette directory exists: `public/gazettes/`
- [ ] Check Redis connection: `redis-cli ping`
- [ ] Ensure adequate disk space
- [ ] Verify mailer templates exist

### After Deployment
- [ ] Restart Sidekiq: `sudo systemctl restart sidekiq`
- [ ] Check Sidekiq status: `sudo systemctl status sidekiq`
- [ ] Monitor first few jobs in logs
- [ ] Test with sample document
- [ ] Verify email notifications work

## 🔍 Debug a Failing Job

### 1. Check Rails Logs
```bash
tail -100 log/production.log | grep -A 10 -B 5 DocumentProcessingJob
```

### 2. Inspect Python Script Output
```bash
# Run with same arguments as failing job
cd /home/deploy/TodoLegal/current
python3 ~/GazetteSlicer/slice_gazette.py /path/to/failing.pdf public/gazettes 12345 2>&1
```

### 3. Check Job in Sidekiq Web UI
- Navigate to Sidekiq Web interface
- Look in Dead, Retry, or Processing tabs
- Note error messages and stack traces

### 4. Test Mailer
```ruby
# Rails console
user = User.first
DocumentProcessingMailer.document_processing_complete(user, "https://test.com", "error").deliver_now
```

## 📈 Performance Baselines

### Normal Operation
- Job duration: 2-15 minutes
- Memory usage: 200-500MB per worker
- Success rate: >95%
- Python script response: <2 minutes

### Alert Thresholds
- Job duration: >20 minutes
- Memory usage: >1GB per worker  
- Success rate: <90%
- Multiple jobs in dead queue

## 🛠️ Configuration Files

### Key Files to Monitor
- `app/jobs/document_processing_job.rb` - Main job logic
- `config/initializers/sidekiq.rb` - Sidekiq configuration
- `app/mailers/document_processing_mailer.rb` - Email notifications
- `app/views/document_processing_mailer/` - Email templates

### Python Scripts Location
- `~/GazetteSlicer/slice_gazette.py` - PDF slicing and content extraction
- `~/GazetteSlicer/process_gazette.py` - Metadata extraction

## 📞 Escalation

### When to Escalate
1. Multiple jobs failing consistently (>3 in 1 hour)
2. System memory usage >80%
3. Sidekiq unable to restart
4. Python scripts corrupted or missing
5. Redis connection completely failed

### Information to Collect
- Sidekiq process status and logs
- Recent job failure details
- System resource usage
- Python script test results
- Redis connectivity status

---

**Last Updated**: September 25, 2025  
**Quick Access**: Keep this guide bookmarked for production issues