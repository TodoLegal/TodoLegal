class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :trackable
  
  has_many :user_permissions, :dependent => :destroy
  has_many :permissions, through: :user_permissions

  protected
  def confirmation_required?
    false
  end
end
