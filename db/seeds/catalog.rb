# Product-family taxonomy only: does not invent prices, stock, or products.
# Safe to rerun; existing products and categories are preserved.
catalog = [
  {
    name: "Phones",
    description: "Every iPhone family, from iPhone 5 onward.",
    image_url: "/catalog/phones.svg",
    sub_categories: [
      "iPhone 5",
      "iPhone 5c",
      "iPhone 5s",
      "iPhone 6",
      "iPhone 6 Plus",
      "iPhone 6s",
      "iPhone 6s Plus",
      "iPhone SE (1st generation)",
      "iPhone 7",
      "iPhone 7 Plus",
      "iPhone 8",
      "iPhone 8 Plus",
      "iPhone X",
      "iPhone XR",
      "iPhone XS",
      "iPhone XS Max",
      "iPhone 11",
      "iPhone 11 Pro",
      "iPhone 11 Pro Max",
      "iPhone 12 mini",
      "iPhone 12",
      "iPhone 12 Pro",
      "iPhone 12 Pro Max",
      "iPhone SE (2nd generation)",
      "iPhone 13 mini",
      "iPhone 13",
      "iPhone 13 Pro",
      "iPhone 13 Pro Max",
      "iPhone SE (3rd generation)",
      "iPhone 14",
      "iPhone 14 Plus",
      "iPhone 14 Pro",
      "iPhone 14 Pro Max",
      "iPhone 15",
      "iPhone 15 Plus",
      "iPhone 15 Pro",
      "iPhone 15 Pro Max",
      "iPhone 16",
      "iPhone 16 Plus",
      "iPhone 16 Pro",
      "iPhone 16 Pro Max",
      "iPhone 16e",
      "iPhone 17",
      "iPhone 17 Pro",
      "iPhone 17 Pro Max",
      "iPhone Air",
      "iPhone 17e",
      "iPhone 18 Pro",
      "iPhone 18 Pro Max",
      "iPhone Duo"
    ]
  },
  {
    name: "iPads",
    description: "iPad, iPad mini, iPad Air and iPad Pro.",
    image_url: "/catalog/ipads.svg",
    sub_categories: [
      "iPad",
      "iPad mini",
      "iPad Air",
      "iPad Pro"
    ]
  },
  {
    name: "MacBooks",
    description: "MacBook, MacBook Air and MacBook Pro.",
    image_url: "/catalog/macbooks.svg",
    sub_categories: [
      "MacBook",
      "MacBook Air",
      "MacBook Pro"
    ]
  },
  {
    name: "Desktops & Displays",
    description: "iMac, Mac mini, Mac Studio, Mac Pro and displays.",
    image_url: "/catalog/desktops-displays.svg",
    sub_categories: [
      "iMac",
      "iMac Pro",
      "Mac mini",
      "Mac Studio",
      "Mac Pro",
      "Studio Display",
      "Pro Display XDR",
      "Thunderbolt Display"
    ]
  },
  {
    name: "AirPods & Audio",
    description: "AirPods, AirPods Pro, AirPods Max and EarPods.",
    image_url: "/catalog/airpods-audio.svg",
    sub_categories: [
      "AirPods (1st generation)",
      "AirPods (2nd generation)",
      "AirPods (3rd generation)",
      "AirPods 4",
      "AirPods 4 with Active Noise Cancellation",
      "AirPods Pro (1st generation)",
      "AirPods Pro (2nd generation, Lightning)",
      "AirPods Pro (2nd generation, USB-C)",
      "AirPods Pro 3",
      "AirPods Max (Lightning)",
      "AirPods Max (USB-C)",
      "AirPods Max 2",
      "AirPods 5",
      "AirPods 5 with Wireless Charging Case",
      "Beats headphones & speakers",
      "EarPods"
    ]
  },
  {
    name: "Watches",
    description: "Apple Watch, SE, Ultra, bands and charging accessories.",
    image_url: "/catalog/watches.svg",
    sub_categories: [
      "Apple Watch Series",
      "Apple Watch SE",
      "Apple Watch Ultra",
      "Watch bands",
      "Watch chargers"
    ]
  },
  {
    name: "Chargers & Cables",
    description: "Power adapters, MagSafe, cables and charging docks.",
    image_url: "/catalog/chargers-cables.svg",
    sub_categories: [
      "USB-C power adapters",
      "MagSafe chargers",
      "Lightning cables",
      "USB-C cables",
      "Wireless charging",
      "Charging docks"
    ]
  },
  {
    name: "Cases & Protection",
    description: "Cases, sleeves, screen protection and wallets.",
    image_url: "/catalog/cases-protection.svg",
    sub_categories: [
      "iPhone cases",
      "iPad cases & covers",
      "MacBook sleeves",
      "Screen protectors",
      "MagSafe wallets",
      "AirPods cases"
    ]
  },
  {
    name: "Keyboards & Mice",
    description: "Magic Keyboard, Magic Mouse, Magic Trackpad and input accessories.",
    image_url: "/catalog/keyboards-mice.svg",
    sub_categories: [
      "Magic Keyboard for Mac",
      "Magic Keyboard for iPad",
      "Smart Keyboard",
      "Magic Mouse",
      "Magic Trackpad"
    ]
  },
  {
    name: "AirTags & Find My",
    description: "AirTag trackers, holders, loops and key rings.",
    image_url: "/catalog/airtags-find-my.svg",
    sub_categories: [
      "AirTag",
      "AirTag packs",
      "AirTag holders & key rings"
    ]
  },
  {
    name: "TV & Home",
    description: "Apple TV, HomePod, HomePod mini and remotes.",
    image_url: "/catalog/tv-home.svg",
    sub_categories: [
      "Apple TV",
      "HomePod",
      "HomePod mini",
      "Siri Remote"
    ]
  },
  {
    name: "Vision & Accessories",
    description: "Apple Vision Pro, Apple Pencil, adapters, storage and more.",
    image_url: "/catalog/vision-accessories.svg",
    sub_categories: [
      "Apple Vision Pro",
      "Vision Pro accessories",
      "Apple Pencil (1st generation)",
      "Apple Pencil (2nd generation)",
      "Apple Pencil (USB-C)",
      "Apple Pencil Pro",
      "Adapters & hubs",
      "Storage & drives",
      "Cleaning & care",
      "AirPort & networking (legacy)",
      "iPod & legacy devices"
    ]
  }
]
ActiveRecord::Base.transaction do
  catalog.each do |entry|
    category = Category.find_or_initialize_by(name: entry[:name])
    category.update!(description: entry[:description], image_url: entry[:image_url])
    entry[:sub_categories].each do |name|
      sub_category = category.sub_categories.find_or_initialize_by(name: name)
      sub_category.image_url ||= entry[:image_url]
      sub_category.save!
    end
  end
end
puts "Seeded #{catalog.size} device categories and their product families"
