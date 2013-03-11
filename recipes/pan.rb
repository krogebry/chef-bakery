##
# Cookbook Name:: bakery
# Recipe:: pan
#
# Copyright 2013, KSONSoftware.com
# All rights reserved - Do Not Redistribute
# @author krogebry ( bryan.kroger@gmail.com )

## The pan is defined as the generic collection of things that every node has.
##  This is where we put things like ldap.conf and rsyslog for syslog.

include_recipe 'rsyslog::default'



begin
  ## Locate the logging agent for the syslog service
  #input = search( :node, "role:logstash_syslog_input" ).sort{|a,b| a["fqdn"]<=>b["fqdn"] }.first
  input = search( :node, "role:logstash_syslog_input" ).first

  ## Create the rsyslog entry to point at our syslog logging agent.
  template "/etc/rsyslog.d/60-syslog.conf" do
    mode 0644
    owner node["rsyslog"]["user"]
    group node["rsyslog"]["group"]
    source "rsyslog.conf.erb"
    notifies :restart, "service[rsyslog]"
    variables(
      :port => 5610,
      :server => input["ipaddress"],
      :condition => "*.*;auth,authpriv.none"
    )
  end

rescue => e
  Chef::Log.fatal( "Caught error while creating syslog config for rsyslog: %s" % e )
  Chef::Log.info(e.backtrace.join( "\n" ))

end



begin
  #input = search( :node, "role:logstash_authlog_input" ).sort{|a,b| a["fqdn"]<=>b["fqdn"] }.first
  input = search( :node, "role:logstash_authlog_input" ).first

  ## Create the rsyslog entry to point at our auth logging agent.
  template "/etc/rsyslog.d/61-auth.conf" do
    mode 0644
    owner node["rsyslog"]["user"]
    group node["rsyslog"]["group"]
    source "rsyslog.conf.erb"
    notifies :restart, "service[rsyslog]"
    variables(
      :port => 5611,
      :server => input["ipaddress"],
      :condition => "auth,authpriv.*"
    )
  end

rescue => e
  Chef::Log.fatal( "Caught error while creating auth config for rsyslog" )
  Chef::Log.debug(e.backtrace.join( "\n" ))

end


## Chef bits
directory "/mnt/log/chef" do
  mode "0655"
  owner "syslog"
  group "adm"
  action :create
  recursive true
end

template "/etc/chef/client.rb" do
  mode "0644"
  owner "root"
  group "root"
  source "chef_client.rb.erb"
  variables({
  })
end

begin
  input = search( :node, "role:logstash_chef_client_input AND chef_environment:prod" ).first

  template "/etc/rsyslog.d/70-chef_client.conf" do
    mode "0644"
    owner "root"
    group "root"
    source "service.rsyslog.conf.erb"
    cookbook "log_pie"
    notifies :restart, "service[rsyslog]"
    variables({
      :port => 5670,
      :server => input["ipaddress"]
    })
  end

rescue => e
  Chef::Log.fatal( "Caught error while creating auth config for rsyslog" )
  Chef::Log.debug(e.backtrace.join( "\n" ))

end

