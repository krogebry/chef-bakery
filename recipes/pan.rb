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

## Can't live wihtout this
package "sysstat"

## Custom sources.list
cookbook_file "/etc/apt/sources.list" do
  mode "0644"
  owner "root"
  group "root"
  source "sources.list"
end

## SNMP bits
directory "/etc/snmp" do
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/etc/snmp/snmpd.conf" do
  mode "0644"
  owner "root"
  group "root"
  source "snmpd.conf"
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
    :server_url => node["chef"]["server_url"]
  })
end



## Loggers
## TODO: move this to something more dynamic and awesome.
begin
  ## Locate the logging agent for the syslog service
  input = search( :node, "role:logstash_input AND chef_environment:prod AND tags:sys-log" ).first 

  if(input != nil)
    ## Create the rsyslog entry to point at our syslog logging agent.
    template "/etc/rsyslog.d/11-syslog.conf" do
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
  end

rescue => e
  Chef::Log.fatal( "Caught error while creating syslog config for rsyslog: %s" % e )
  Chef::Log.info(e.backtrace.join( "\n" ))

end

begin
  ## Create the rsyslog entry to point at our auth logging agent.
  input = search( :node, "role:logstash_input AND chef_environment:prod AND tags:auth-log" ).first

  template "/etc/rsyslog.d/12-auth.conf" do
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

begin
  input = search( :node, "role:logstash_input AND chef_environment:prod AND tags:chef-client" ).first

  fs_spool_dir = "/var/spool/rsyslog"
  directory fs_spool_dir do
    owner node["rsyslog"]["user"]
    group node["rsyslog"]["group"]
    action :create
    recursive true
  end

  template "/etc/rsyslog.d/05-chef_client.conf" do
    mode "0644"
    owner "root"
    group "root"
    source "service.rsyslog.conf.erb"
    cookbook "log_pie"
    notifies :restart, "service[rsyslog]"
    variables({
      :port => 5671,
      :server => input["ipaddress"],
      :log_tag => "chef-log",
      :log_file => "/mnt/log/chef/client.log",
      :state_file => "%s/chef-log-state" % fs_spool_dir
    })
  end

rescue => e
  Chef::Log.fatal( "Caught error while creating chef-log config rsyslog" )
  Chef::Log.debug(e.backtrace.join( "\n" ))

end

