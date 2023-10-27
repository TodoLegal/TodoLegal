class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :trackable
  
  acts_as_token_authenticatable

  # validate :email_uniqueness, on: create

  has_many :user_permissions, :dependent => :destroy
  has_many :permissions, through: :user_permissions
  has_one :users_preference, :dependent => :destroy
  has_one :user_notifications_history, :dependent => :destroy
  has_one :user_trial, :dependent => :destroy

  def remember_me
    true
  end

  def email_uniqueness
    self.errors.clear
    self.errors.add(:base, I18n.t(:email_taken)) if User.where(:email => self.email).exists?
  end

  def admin?
    @permissionid = UserPermission.find_by(:user_id => self.id)
    if !@permissionid
      return false
    elsif @permissionid.permission.name=="Admin" 
      return true
    else
      return false
    end
   end

   def self.ignore_users_whith_free_trial
    where.not("EXISTS(SELECT 1 from user_trials where users.id = user_trials.user_id)")
   end
  
  protected
  def confirmation_required?
    false
  end
end
