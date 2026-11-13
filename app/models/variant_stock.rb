class VariantStock < ApplicationRecord
  belongs_to :warehouse
  belongs_to :product, optional: true
  has_many :order_items, dependent: :nullify
  has_many :orders, through: :order_items
  has_many :downtimes, dependent: :destroy

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :warehouse_id, presence: true
  validate :hot_deal_stock_is_single_unit
  validate :option_ids_is_array
  validate :options_belong_to_same_product, if: -> { option_ids.present? && option_ids.any? }

  before_validation :set_product_id_from_options, if: -> { product_id.blank? && option_ids.present? && option_ids.any? }
  after_save :update_product_status
  after_destroy :update_product_status_after_destroy

  def option_ids_is_array
    unless option_ids.is_a?(Array)
      errors.add(:option_ids, "must be an array")
    end
    # Unit products have exactly one option_id (implicit variant_option)
    # Bulk products have one or more option_ids
  end

  def variant_options
    return VariantOption.none if option_ids.empty?
    VariantOption.where(id: option_ids)
  end


  def unit_product?
    option_ids.empty?
  end

  def available_quantity(start_at, end_at)
    checker = AvailabilityChecker.new(self, start_at, end_at)
    checker.available_quantity
  end

  def check_availability(requested_quantity, start_at, end_at)
    checker = AvailabilityChecker.new(self, start_at, end_at)
    checker.check_availability(requested_quantity)
  end

  def downtime_active?(at_time = Time.current)
    downtimes.active(at_time).exists?
  end

  def price
    return BigDecimal("0") if option_ids.empty?
    VariantOption.where(id: option_ids).sum(:price)
  end

  # Calculate available quantity considering downtime and active orders
  # Returns 0 if in downtime, otherwise total - reserved
  # Reconciles Redis with database to handle Redis restarts
  def processed_available_quantity
    # Check if currently in downtime
    return 0 if downtime_active?

    # Initialize Redis if needed
    total_quantity = AvailabilityStore.get_total_quantity(id)
    if total_quantity.nil?
      AvailabilityStore.initialize_from_db(self)
      total_quantity = quantity
    elsif total_quantity != quantity
      # Keep Redis "total" in sync with the DB quantity so edits (e.g. 3 -> 10)
      # immediately reflect in available_quantity calculations.
      AvailabilityStore.set_total_quantity(id, quantity)
      total_quantity = quantity
    end

    # For e-commerce orders, ordered quantities remain committed after
    # fulfillment/return status changes and are not automatically restocked.
    db_reserved_quantity = Order
      .joins(:order_items)
      .where(order_items: { variant_stock_id: id })
      .sum("order_items.quantity")

    # Reconcile Redis reserved quantity with database
    # If Redis was restarted, it might have incorrect reserved quantity
    redis_reserved_quantity = AvailabilityStore.get_reserved_quantity(id)
    if redis_reserved_quantity != db_reserved_quantity
      # Redis is out of sync, update it to match database
      AvailabilityStore.set_reserved_quantity(id, db_reserved_quantity)
      # Also ensure downtime flag is correct
      downtime_active = downtime_active?
      AvailabilityStore.set_downtime_flag(id, downtime_active)
    end

    available = total_quantity - db_reserved_quantity
    [ available, 0 ].max # Ensure non-negative
  end

  private

  def hot_deal_stock_is_single_unit
    if product&.demo? && quantity.to_i > 0
      errors.add(:quantity, "must be zero for a sample listing")
    end
    return unless product&.hot_deal? && quantity.present?

    other_stock = product.variant_stocks.where.not(id: id).sum(:quantity)
    if quantity.to_i + other_stock > 1
      errors.add(:quantity, "cannot exceed one unit across all warehouses for a hot deal")
    end
  end

  def update_product_status
    product&.update_status
  end

  def update_product_status_after_destroy
    product&.update_status
  end

  def set_product_id_from_options
    return if option_ids.empty?

    product = variant_options.first&.variant_type&.product
    self.product_id = product.id if product
  end

  def options_belong_to_same_product
    return if option_ids.empty?

    options = VariantOption.where(id: option_ids)
    products = options.joins(variant_type: :product).distinct.pluck("products.id")

    if products.size > 1
      errors.add(:option_ids, "cannot mix options from different products")
    end
  end
end
