AdvRoutingDemo.urls do
  map(:test).to("/test/:id/action")
  map(:admin, :settings).to("/admin/settings/action")
  map :admin do |admin|
    admin.map(:dashboard).to("/admin/:id/the/dashboard")
  end
end