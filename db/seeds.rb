# Create Roles
roles_data = [
  { name: 'CUSTOMER', description: 'Default user role with basic access' },
  { name: 'AFFILIATE', description: 'Affiliate marketer with customer shopping access and affiliate selling privileges' },
  { name: 'STAFF', description: 'Staff member with limited administrative access' },
  { name: 'ADMIN', description: 'Administrator with full system access' },
  { name: 'SUPER_ADMIN', description: 'Super administrator with complete system control' }
]

roles_data.each do |role_data|
  Role.find_or_create_by(name: role_data[:name]) do |role|
    role.description = role_data[:description]
  end
end

# Create Permissions
permissions_data = [
  'CAN_PAY_ON_DELIVERY'
]

permissions_data.each do |permission_name|
  Permission.find_or_create_by(name: permission_name)
end

puts "Seeded #{Role.count} roles and #{Permission.count} permissions"

# Keep the template seed minimal and safe to run repeatedly.
admin = User.find_or_initialize_by(email: ENV.fetch("SEED_ADMIN_EMAIL", "donaldakite27@mail.com").downcase)
admin.assign_attributes(first_name: "Donald", last_name: "Akite", role: Role.find_by!(name: "SUPER_ADMIN"))
if admin.new_record? || admin.encrypted_password.blank?
  password = ENV.fetch("SEED_ADMIN_PASSWORD")
  raise "SEED_ADMIN_PASSWORD must contain at least 16 characters" if password.length < 16
  admin.password = password
  admin.password_confirmation = password
end
admin.save!
puts "Seeded super admin #{admin.email} (#{admin.role.name}); #{User.count} users total"
