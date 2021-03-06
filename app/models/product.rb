class Product < ApplicationRecord

  enum condition: {
    brand_new: 0,
    mint: 1,
    excellent: 2,
    very_good: 3,
    good: 4,
    fair: 5,
    poor: 6,
    non_functioning: 7
  }

  before_save :price_to_cents
  before_save :shipping_to_cents

  mount_uploader :image, ProductImageUploader
  mount_uploader :image2, ProductImageUploader
  mount_uploader :image3, ProductImageUploader
  mount_uploader :image4, ProductImageUploader
  mount_uploader :display_image, DisplayProductImageUploader

  validates :name, :description, :price, presence: true
  validates :price, numericality: { greater_than: 0 }

  extend FriendlyId
  friendly_id :name, use: :slugged

  include PgSearch
  pg_search_scope :search,
                  :against => [:name],
                  :using => {
                    :tsearch => {:dictionary => "english"}
                  }

  belongs_to :user
  has_many :grouped_orders
  has_many :order_products
  has_many :orders, through: :order_products
  has_many :product_categories
  has_many :categories#, through: :product_categories
  belongs_to :brand

  scope :user_products, -> (user) {
    where(user_id: user).order('created_at DESC')
  }

  scope :positive_inventory, -> { where("inventory > ?", 0) }
  scope :ordered, -> { all.order('created_at DESC') }
  scope :freshwater_brand, -> (brand) { where(water_type: "fresh", brand_id: brand ) }
  scope :saltwater_brand, -> (brand) { where(water_type: "salt", brand_id: brand ) }

  def accept_paypal?
    true if self.user.paypal_email != nil || self.user.paypal_email_the_same == true
  end

  def accept_stripe?
    true if self.user.provider == "stripe_connect"
  end

  def cart_action(current_user_id)
    if $redis.sismember "cart#{current_user_id}", slug
      'Remove from'
    else
      'Add to'
    end
  end

  def set_inventory_to_zero
    reset_number = self.inventory - 1
    self.update(inventory: reset_number)
  end

  class << self
    def ordered_and_instock
      positive_inventory.ordered
    end
  end

  private

    def price_to_cents
      self.price_in_cents = self.price * 100
    end

    def shipping_to_cents
      if self.shipping == nil
        self.shipping = 0
        self.shipping_in_cents = 0
      else
        self.shipping_in_cents = self.shipping * 100
      end
    end
end
