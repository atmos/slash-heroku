# An message action a user has triggered
class MessageAction < ApplicationRecord
  belongs_to :user
end
