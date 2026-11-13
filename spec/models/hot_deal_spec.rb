require "rails_helper"

RSpec.describe "Hot Deal inventory" do
  let(:warehouse) { Warehouse.create!(name: "Test warehouse", latitude: 5.6, longitude: -0.2) }
  let(:other_warehouse) { Warehouse.create!(name: "Other warehouse", latitude: 5.7, longitude: -0.3) }
  let(:deal) { create(:product, bookable_type: "unit", hot_deal: true, condition_notes: "Small scratch on frame") }

  it "requires a unit product and a description of its condition" do
    product = build(:product, bookable_type: "bulk", hot_deal: true, condition_notes: "")
    expect(product).not_to be_valid
    expect(product.errors[:bookable_type]).to be_present
    expect(product.errors[:condition_notes]).to be_present
  end

  it "limits the combined stock across warehouses to one and prevents quantity increases" do
    first = VariantStock.create!(product: deal, warehouse: warehouse, quantity: 1, option_ids: [])
    expect(VariantStock.new(product: deal, warehouse: other_warehouse, quantity: 1, option_ids: [])).not_to be_valid
    first.quantity = 2
    expect(first).not_to be_valid
  end

  it "does not let a bulk-stocked product become a deal" do
    product = create(:product, bookable_type: "unit")
    VariantStock.create!(product: product, warehouse: warehouse, quantity: 2, option_ids: [])
    product.assign_attributes(hot_deal: true, condition_notes: "Scuffed case")
    expect(product).not_to be_valid
  end

  it "never allows sample products to carry purchasable stock" do
    sample = create(:product, demo: true)
    expect(VariantStock.new(product: sample, warehouse: warehouse, quantity: 1, option_ids: [])).not_to be_valid
  end
end
