# Explicitly local, non-purchasable sample listings for testing and layout review.
raise "Demo products may only be seeded in development" unless Rails.env.development?

samples = [
  { name: "iPhone 16 Pro — Sample", category: "Phones", image: "iphone16pro.png", price: 6500, compare: 8000, hot_deal: true, notes: "Example condition: light scratches on the frame. Sample listing only." },
  { name: "MacBook Air — Sample", category: "MacBooks", image: "macbook.png", price: 5600, compare: 7000, hot_deal: true, notes: "Example condition: small mark on the lid. Sample listing only." },
  { name: "AirPods Max — Sample", category: "AirPods & Audio", image: "airpodmax.png", price: 2800, compare: 3500, hot_deal: true, notes: "Example condition: wear on the ear cushions. Sample listing only." },
  { name: "iPhone 16 — Sample", category: "Phones", image: "iphone16.png", price: 7200, hot_deal: false },
  { name: "AirTag — Sample", category: "AirTags & Find My", image: "airtag.png", price: 450, hot_deal: false },
  { name: "Vision Pro — Sample", category: "Vision & Accessories", image: "visionpro.png", price: 48000, hot_deal: false }
]

ActiveRecord::Base.transaction do
  samples.each do |data|
    product = Product.find_or_initialize_by(name: data[:name], demo: true)
    next if product.persisted?

    product.assign_attributes(
      description: "Sample product for testing the store layout. Not available for purchase.",
      category: Category.find_by!(name: data[:category]), bookable_type: "unit", active: true,
      hot_deal: data[:hot_deal], condition_notes: data[:notes], compare_at_price: data[:compare],
      weight_class: "medium"
    )
    product.save!
    product.categories << product.category
    base = product.variant_types.create!(name: "Base", pricing_role: "base")
    base.variant_options.create!(name: "Standard", price: data[:price])
    product.images.create!(url: "/demo-products/#{data[:image]}")
  end
end
puts "Seeded #{Product.where(demo: true).count} sample products (no stock; cannot be purchased)"
