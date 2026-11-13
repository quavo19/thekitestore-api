require "rails_helper"

RSpec.describe "Customer hot deals", type: :request do
  it "filters deals, returns condition details, and hides samples outside development" do
    deal = create(:product, name: "Used device", hot_deal: true, condition_notes: "Cracked corner", compare_at_price: 500)
    create(:product, name: "Regular device")
    create(:product, name: "Sample device", hot_deal: true, condition_notes: "Sample", demo: true)

    get "/api/v1/customer/products", params: { hot_deal: true }
    expect(response).to have_http_status(:ok)
    items = response.parsed_body.fetch("data")
    expect(items.map { |item| item["id"] }).to eq([ deal.id ])
    expect(items.first.fetch("attributes")).to include("hot_deal" => true, "condition_notes" => "Cracked corner", "compare_at_price" => 500.0)

    get "/api/v1/customer/products/#{deal.id}"
    expect(response.parsed_body.dig("data", "attributes", "condition_notes")).to eq("Cracked corner")
  end
  it "lets an administrator create and update a deal through the product API" do
    admin = create(:user, :admin)
    post "/api/v1/products/products", headers: auth_headers(admin), params: { product: {
      name: "Used iPhone", bookable_type: "unit", hot_deal: true,
      condition_notes: "Scratch on frame", compare_at_price: 2000, weight_class: "medium"
    } }, as: :json
    expect(response).to have_http_status(:created)
    id = response.parsed_body.dig("data", "id")
    expect(response.parsed_body.dig("data", "attributes", "condition_notes")).to eq("Scratch on frame")

    patch "/api/v1/products/products/#{id}", headers: auth_headers(admin), params: { product: { condition_notes: "Small scratch on screen" } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "attributes", "condition_notes")).to eq("Small scratch on screen")
  end

  it "does not allow sample products into a customer's cart" do
    user = create(:user)
    sample = create(:product, demo: true)
    post "/api/v1/customer/cart", headers: auth_headers(user), params: { product_id: sample.id, quantity: 1 }, as: :json
    expect(response).to have_http_status(:not_found)
  end
end
