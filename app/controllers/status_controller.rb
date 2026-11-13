class StatusController < ApplicationController
  def index
    render json: {
      name: "The Kite Store API",
      version: "v1",
      status: "ok",
      links: { api: "/api/v1", categories: "/api/v1/categories", products: "/api/v1/customer/products" },
      retailer: { independent: true, authorized_apple_reseller: false }
    }
  end
end
