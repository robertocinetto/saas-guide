# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

plans = Stripe::Plan.all

plans.each do |plan|
  Plan.create stripe_id: plan.id, name: plan.name, price: plan.amount, interval: plan.interval
end
