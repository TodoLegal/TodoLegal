require "google/apis/drive_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Drive API Ruby Quickstart".freeze
CREDENTIALS_PATH = "/home/deploy/TodoLegal/credentials.json".freeze

# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
drive_service = Google::Apis::DriveV3::DriveService.new
drive_service.client_options.application_name = APPLICATION_NAME
drive_service.authorization = authorize

def update_files drive_service, folder_id
  puts folder_id
  
  response = drive_service.list_files(page_size: 1000,
                                        q: "'#{folder_id}' in parents",
                                        fields: "files")

  result = []

  response.files.each do |file|
    if file.mime_type == 'application/vnd.google-apps.folder'
      subdirectory = update_files drive_service, file.id
      file_count = 0
      subdirectory.each do |sub_file|
        if sub_file[:type] == 'application/vnd.google-apps.folder'
          file_count += sub_file[:file_count].to_i
        else
          file_count += 1
        end
      end
      result.push({type: file.mime_type, name: file.name, files: subdirectory, file_count: file_count, link: file.web_view_link})
    else
      result.push({type: file.mime_type, name: file.name, link: file.web_view_link})
    end
  end
  return result
end

response = drive_service.list_files(page_size: 1000,
                                        q: "'15WjHMcU2_QOukmbOyRJAFmOPxZpa0O9k' in parents",
                                        fields: "files")
puts "Files:"
puts "No files found" if response.files.empty?

data = update_files drive_service, '15WjHMcU2_QOukmbOyRJAFmOPxZpa0O9k'
file_count = 0
data.each do |file|
  if file[:type] == 'application/vnd.google-apps.folder'
    file_count += file[:file_count]
  else
    file_count += 1
  end
end
google_drive_covid_data = {file_count: file_count, datetime: Time.now.to_s, data: data}

open('public/google_drive_covid_data.json', 'w') { |f|
  f.write(google_drive_covid_data.to_json)
}