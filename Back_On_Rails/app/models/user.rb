class User < ApplicationRecord
  has_many :items
  has_many :places
  has_many :friendships
  has_many :friends, through: :friendships

  has_one :profile, dependent: :destroy

  #user has_many borrows through the lender fk in borrow model
  has_many :borrow_transactions, class_name: 'Transaction', foreign_key: 'borrower_id', inverse_of: 'borrower', dependent: :destroy
  #user has_many borrows through the lender fk in borrow model
  has_many :lend_transactions, class_name: 'Transaction', foreign_key: 'lender_id', inverse_of: 'lender', dependent: :destroy

  # Reviews that the user wrote
  has_many :item_reviews, dependent: :destroy
  has_many :user_reviews, dependent: :destroy

  # Reviews that were written about the user
  has_many :reviews_of_self, class_name: 'UserReview', foreign_key: 'reviewee_id', inverse_of: 'reviewee', dependent: :destroy

  has_secure_password

  validates :username, presence: true, uniqueness: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, uniqueness: true, format: {with: VALID_EMAIL_REGEX}
  validates :password, presence: true, length: {minimum: 8}

  #after_commit :create_follow_notifications, on: [:add_friend]

  def self.search(param)
    param.strip!
    param.downcase!
    to_send_back = (username_matches(param) + email_matches(param)).uniq
    return nil unless to_send_back
    to_send_back
  end

  def self.username_matches(param)
    matches('username', param)
  end

  def self.email_matches(param)
    matches('email', param)
  end

  def self.matches(field_name, param)
    where("#{field_name} like ?", "%#{param}%")
  end

  def except_current_user(users)
    users.reject { |user| user.id == self.id }
  end

  def not_friends_with?(friend_id)
    friendships.where(friend_id: friend_id).count < 1
  end

	def create_follow_notifications
        Notification.create do |notification|
            notification.notify_type = 'friendship'
            notification.tag = 'follow'
            notification.actor = self.user
            notification.user = self.friend
            notification.target = self
            notification.second_target = self.item
        end
    end


    def get_average_rating
        total_ratings = 0
        n = 0
        all_reviews = self.reviews_of_self
        all_reviews.each do |review|
            n = n + 1
            total_ratings = total_ratings + review.rating
        end
        if n==0
            n=1
        end
        return total_ratings.to_f/n
    end

    def get_rating_breakdown
        rating_hash = Hash.new { |hash, key| hash[key] = 0 }
        all_reviews = self.reviews_of_self
        all_reviews.each do |review|
            if review.rating == 1
                rating_hash[1] = rating_hash[1] + 1
            elsif review.rating == 2
                rating_hash[2] = rating_hash[2] + 1
            elsif review.rating == 3
                rating_hash[3] = rating_hash[3] + 1
            elsif review.rating == 4
                rating_hash[4] = rating_hash[4] + 1
            elsif review.rating == 5
                rating_hash[5] = rating_hash[5] + 1
            end
        end
        return rating_hash
    end

end
