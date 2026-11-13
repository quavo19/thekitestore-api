# The Kite Store API

Rails API template for The Kite Store, with customer, affiliate, staff, admin and super admin roles.

Install dependencies with `bundle install`. Configure the ignored `.env` for local database credentials and integrations. Development and test databases are `thekitestore_api_development` and `thekitestore_api_test`; production uses the `thekitestore_api_production` family in `config/database.yml`.

Run `bundle exec rails db:create db:migrate db:seed` to initialize development. Set `SEED_ADMIN_PASSWORD` to a strong password (at least 16 characters) before seeding. The default `SEED_ADMIN_EMAIL` is `donaldakite27@mail.com`, with role `SUPER_ADMIN`. Seeds create roles, permissions and this administrator, without demo customers or orders. Repeated seeding preserves the existing password.

Run `RAILS_ENV=test bundle exec rails db:create db:migrate` to initialize test, then `bundle exec rspec` to run tests. Production database credentials use `DATABASE_USERNAME` and `THEKITESTORE_API_DATABASE_PASSWORD`; local credentials use `DATABASE_USERNAME` and `DATABASE_PASSWORD`.

The optional assistant service endpoints remain disabled unless explicitly configured. The CMS has no assistant interface. Configure your own email, payment, OAuth and object-storage integrations before using those features.

Application servers and background workers are started manually by the project owner.

### Hot Deals and development samples

In the CMS, create a product and select **Hot Deal**. Enter the condition and known faults, a unit price, and an optional comparison price. Choose stock totalling at most one across all warehouses. The store shows available Hot Deals on the homepage; sold-out items leave that section.

For local development only, run `SEED_DEMO_PRODUCTS=1 bin/rails db:seed` after migrating and seeding categories, or `bin/rails runner 'load Rails.root.join("db/seeds/demo_products.rb")'`. The seed is repeatable and creates sample-labelled listings with no sellable stock. Samples are excluded from customer catalogues outside development.
