##
# SLB Crust

cookbook_file "/etc/nginx/conf.d/logging.conf" do
  source "logging.conf"
end

