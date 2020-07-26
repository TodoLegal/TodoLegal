class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :trackable
  
  validate :email_uniqueness, on: create

  has_many :user_permissions, :dependent => :destroy
  has_many :permissions, through: :user_permissions

  def remember_me
    true
  end

  def email_uniqueness
    self.errors.clear
    self.errors.add(:base, I18n.t(:email_taken)) if User.where(:email => self.email).exists?
  end
  
  protected
  def confirmation_required?
    false
  end
end
