##
# Cookbook Name:: bakery
# Recipe:: crust
#
# Copyright 2013, KSONSoftware.com
# All rights reserved - Do Not Redistribute
# @author krogebry ( bryan.kroger@gmail.com )

#begin
  ## Deploy the zenoss user and pub key.
  #pub_key = Base64.decode64( node["zenoss"]["pub_key"] )
  #pub_key = node["zenoss"]["pub_dsa_key"]

  #user "zenoss" do
  #end

  #directory "/home/zenoss/.ssh/" do
    #mode "0644"
    #owner "zenoss"
    #group "zenoss"
    #action :create
    #recursive true
  #end

  #template "/home/zenoss/.ssh/authorized_keys" do
    #mode "0644"
    #owner "zenoss"
    #group "zenoss"
    #source "authorized_keys.erb"
    #variables({
      #:key => ""
    #})
  #end

#rescue => e
#end
