class Product < ApplicationRecord

  before_save :times_100

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
  belongs_to :grouped_order
  has_many :order, through: :order_products
  has_many :categories, through: :product_categories
  belongs_to :brand

  scope :user_products, -> (user) {
    where(user_id: user).order('created_at DESC')
  }

  scope :positive_inventory, -> { where("inventory > ?", 0) }

  scope :ordered, -> { all.order('created_at DESC') }

  scope :freshwater_brand, -> (brand) { where(category_id: 8, brand_id: brand ) }

  def times_100
    self.price = self.price * 100
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
end
