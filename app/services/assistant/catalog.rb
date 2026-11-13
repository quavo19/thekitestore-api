require "digest"
require "uri"

module Assistant
  # Safe customer projection. No warehouse IDs, cost or commission fields leave Rails.
  class Catalog
    def self.product(product)
      origin = ENV.fetch("ASSISTANT_STOREFRONT_ORIGIN", "")
      uri = URI.parse(origin)
      raise ArgumentError unless uri.is_a?(URI::HTTPS) && uri.host && uri.userinfo.nil? &&
        [nil, ""].include?(uri.path) && uri.query.nil? && uri.fragment.nil?
      { product_id: product.id.to_s, title: product.name.to_s.first(160),
        price: { amount_minor: (product.base_price * 100).round.to_i, currency: "GHS" },
        availability: "unknown", product_url: "#{origin}/products/#{product.id}",
        observed_at: Time.current.iso8601 }
    end

    def self.variants(product)
      stocks = product.variant_stocks.order(:id).limit(101).to_a
      raise ArgumentError if stocks.size > 100
      groups = stocks.group_by { |stock| stock.option_ids.map(&:to_s).sort }
      raise ArgumentError if groups.size > 10
      groups.map do |ids, rows|
        options = product.variant_options.where(id: ids).includes(:variant_type).order(:id).to_a
        raise ArgumentError unless options.size == ids.size
        # An opaque public combination ID avoids exposing warehouse/stock identity.
        key = ids.empty? ? "standard" : Digest::SHA256.hexdigest(ids.join(":"))[0, 24]
        { variant_id: key, title: (options.map(&:name).join(" / ").presence || "Standard").first(160),
          price: { amount_minor: (options.sum(&:price) * 100).round.to_i, currency: "GHS" },
          availability: "unknown", stocks: rows }
      end
    end

    def self.detail(product)
      product(product).merge(variants: variants(product).map { |variant| variant.except(:stocks) }, variants_complete: true)
    end

    def self.availability(product, variant_id, quantity)
      choices = variants(product)
      selected = choices.find { |variant| variant[:variant_id] == variant_id } if variant_id
      raise AssistantDelegation::Denied if variant_id && selected.nil?
      ambiguous = variant_id.nil? && choices.size > 1
      selected ||= choices.first unless ambiguous
      status = "unknown"
      if selected
        # Match existing committed-order/downtime semantics without mutating Redis,
        # acquiring commerce locks, reserving stock or exposing internal counts.
        remaining = selected[:stocks].sum do |stock|
          next 0 if stock.downtime_active?
          committed = Order.joins(:order_items).where(order_items: { variant_stock_id: stock.id }).sum("order_items.quantity")
          [stock.quantity - committed, 0].max
        end
        status = remaining >= quantity ? "in_stock" : "out_of_stock"
      end
      { product_id: product.id.to_s, variant_id: ambiguous ? nil : selected&.dig(:variant_id),
        quantity: quantity, availability: status, unreserved: true,
        observed_at: Time.current.iso8601, requires_variant: ambiguous }
    end
  end
end
