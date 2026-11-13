require "rails_helper"

RSpec.describe Api::V1::Auth::OmniauthCallbacksController, type: :controller do
  before do
    request.env["devise.mapping"] = Devise.mappings[:api_v1_user]
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("AFFILIATE_FRONTEND_URL").and_return("http://localhost:3003/")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("FRONTEND_URL", anything).and_return("http://localhost:3002")
    allow(ENV).to receive(:fetch).with("CUSTOMER_FRONTEND_URL", anything).and_return("http://localhost:3002")
  end

  def callback_url(params)
    request.env["omniauth.params"] = params
    controller.send(:frontend_callback_url)
  end

  it "returns affiliate login from a LAN address to the configured affiliate app" do
    expect(callback_url("frontend" => "affiliate", "origin" => "http://172.20.10.13:3003"))
      .to eq("http://localhost:3003/auth/google/callback")
  end

  it "uses the configured deployed affiliate URL, rather than the browser's origin" do
    allow(ENV).to receive(:[]).with("AFFILIATE_FRONTEND_URL").and_return("https://affiliates.example.com/")
    expect(callback_url("frontend" => "affiliate", "origin" => "https://attacker.example"))
      .to eq("https://affiliates.example.com/auth/google/callback")
  end

  it "defaults affiliate login to port 3003 when its URL is blank" do
    allow(ENV).to receive(:[]).with("AFFILIATE_FRONTEND_URL").and_return("")
    expect(callback_url("frontend" => "affiliate")).to eq("http://localhost:3003/auth/google/callback")
  end

  it "preserves legacy allowlisted affiliate origins" do
    expect(callback_url("origin" => "http://localhost:3003"))
      .to eq("http://localhost:3003/auth/google/callback")
  end

  it "preserves customer login when no affiliate selector is present" do
    expect(callback_url("origin" => "http://localhost:3002"))
      .to eq("http://localhost:3002/auth/google/callback")
  end

  it "rejects arbitrary destinations and unknown frontend selectors" do
    expect(callback_url("frontend" => "https://attacker.example", "origin" => "https://attacker.example"))
      .to eq("http://localhost:3002/auth/google/callback")
  end

  it "uses the affiliate destination on Google authentication failure too" do
    request.env["omniauth.params"] = { "frontend" => "affiliate", "origin" => "http://172.20.10.13:3003" }
    begin
      routes.draw { get "oauth_failure", to: "api/v1/auth/omniauth_callbacks#failure" }
      get :failure, params: { message: "access_denied" }
      expect(response).to redirect_to("http://localhost:3003/auth/google/callback?error=access_denied")
    ensure
      Rails.application.reload_routes!
    end
  end
end
