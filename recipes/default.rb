#
# Cookbook Name:: hostname
# Recipe:: default
#
# Copyright 2010, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# restart/forking help from: 
# http://github.com/dreamcat4/site-cookbooks/tree/COOK-245/restart/

ruby_block "restart_chef" do
  block do
    if fork
      # i am the parent
      Chef::log "Restarting chef..."
      exit 0
    else
      # i am the child
      sleep 0.1 until(Process.ppid() == 1)
      quoted_args = "'" << $*.join("' '") << "'" unless $*.empty?
      exec %Q{'#{$0}' #{quoted_args}}
    end
  end
  action :nothing
end

service "hostname" do
  if platform?("ubuntu")
    if node.platform_version.to_f >= 10.04
      provider Chef::Provider::Service::Upstart
      service_name "hostname"
    else
      service_name "hostname.sh"
    end
    supports :status => false, :restart => false, :reload => false
    action :nothing
    notifies :create, "ruby_block[restart_chef]", :immediately
  end
end

template "/etc/hostname" do
  source "hostname.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :start, "service[hostname]", :immediately
end

