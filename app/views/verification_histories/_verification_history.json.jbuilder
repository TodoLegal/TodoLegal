json.extract! verification_history, :id, :datapoint_id, :document_id, :user_id, :is_verified, :verification_dt, :comments, :is_active, :created_at, :updated_at
json.url verification_history_url(verification_history, format: :json)
