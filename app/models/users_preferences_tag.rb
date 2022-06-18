class UsersPreferencesTag < ApplicationRecord
    belongs_to :tag
    belongs_to :users_preference
end
