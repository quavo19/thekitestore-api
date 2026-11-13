class Product < ApplicationRecord
  enum :bookable_type, { bulk: "bulk", unit: "unit" }
  enum :status, { available: "available", partial: "partial" }
  enum :shipping_type, { bulk: "bulk", high_value: "high_value" }, prefix: :shipping

  WEIGHT_CLASS_KG = {
    "light" => BigDecimal("0.3"),
    "medium" => BigDecimal("1.0"),
    "heavy" => BigDecimal("3.0")
  }.freeze

  belongs_to :category, optional: true
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories
  has_many :product_sub_categories, dependent: :destroy
  has_many :sub_categories, through: :product_sub_categories
  has_many :product_meta, class_name: "ProductMeta", dependent: :destroy
  has_many :variant_types, dependent: :destroy
  has_many :variant_options, through: :variant_types
  has_many :variant_stocks, dependent: :destroy
  has_many :images, as: :owner, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :cart_users, through: :cart_items, source: :user
  has_many :wishlist_items, dependent: :destroy
  has_many :wishlist_users, through: :wishlist_items, source: :user
  has_many :affiliate_clicks, dependent: :destroy
  has_many :affiliate_attributions, dependent: :destroy
  has_many :affiliate_earnings, dependent: :restrict_with_error

  before_validation :normalize_shipping_fields
  before_destroy :destroy_related_variant_stocks
  after_save :update_status_if_needed

  validates :condition_notes, presence: true, if: :hot_deal?
  validates :compare_at_price, numericality: { greater_than: 0 }, allow_nil: true
  validate :hot_deal_must_be_one_unit
  validates :name, presence: true
  validates :bookable_type, presence: true
  validates :shipping_type, presence: true, inclusion: { in: shipping_types.keys }
  validates :weight_class, inclusion: { in: WEIGHT_CLASS_KG.keys }, allow_blank: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :shipping_category, presence: true, if: :shipping_high_value?
  validate :bulk_shipping_has_weight_source
  validates :bonus_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :affiliate_commission_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :matching_search, lambda { |query|
    term = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where(
      <<~SQL.squish,
        products.name ILIKE :term
        OR products.description ILIKE :term
        OR EXISTS (
          SELECT 1 FROM unnest(products.search_keywords) AS keyword
          WHERE keyword ILIKE :term
        )
      SQL
      term: term
    )
  }

  def calculate_status
    has_active_downtime = variant_stocks.any? do |variant_stock|
      variant_stock.downtime_active?
    end

    has_active_downtime ? :partial : :available
  end

  def update_status
    new_status = calculate_status
    update_column(:status, new_status) if status != new_status.to_s
  end

  def base_price
    base_variant_type = variant_types.base.first
    return BigDecimal("0") unless base_variant_type

    base_variant_type.variant_options.minimum(:price) || BigDecimal("0")
  end

  def estimated_shipping_weight_kg
    return weight_kg if weight_kg.present?

    WEIGHT_CLASS_KG[weight_class.to_s]
  end

  private

  def hot_deal_must_be_one_unit
    return unless hot_deal?

    errors.add(:bookable_type, "must be unit for a hot deal") unless unit?
    if persisted? && variant_stocks.sum(:quantity) > 1
      errors.add(:hot_deal, "requires no more than one unit across all warehouses")
    end
  end

  def normalize_shipping_fields
    self.shipping_type = shipping_type.to_s.strip.presence || "bulk"
    self.weight_class = weight_class.to_s.strip.downcase.presence
    self.shipping_category = shipping_category.to_s.strip.downcase.presence
    self.search_keywords = Array(search_keywords)
      .flat_map { |keyword| keyword.to_s.split(",") }
      .map { |keyword| keyword.strip.downcase }
      .reject(&:blank?)
      .uniq
  end

  def bulk_shipping_has_weight_source
    return unless shipping_bulk?
    return if weight_kg.present? || weight_class.present?

    errors.add(:base, "Bulk shipping requires weight kg or weight class")
  end

  def update_status_if_needed
    # Only update status if variant_stocks changed or product was just created
    return unless saved_change_to_id? || saved_change_to_active?

    update_status
  end

  def destroy_related_variant_stocks
    variant_stock_ids = variant_stocks.pluck(:id)

    Downtime.where(variant_stock_id: variant_stock_ids).find_each do |downtime|
      if downtime.active?
        AvailabilityStore.toggle_downtime_off(downtime.variant_stock_id)
      end

      service = DowntimeService.new(downtime)
      Sidekiq::ScheduledSet.new.select do |job|
        service.matches_downtime_job?(job, downtime.id)
      end.each(&:delete)
    end

    # Nullify order_items instead of destroying them to preserve order data
    variant_stocks.each do |variant_stock|
      variant_stock.order_items.update_all(variant_stock_id: nil)
    end

    variant_stocks.destroy_all
  end
end
