cron "chronograph" do
  user "ubuntu"
  command "#{node.project}/scripts/chronograph.sh #{node.project}"
end

template "/etc/supervisor/conf.d/sentry_server.conf" do
  local true
  source "#{node.project}/conf/sentry/sentry.conf"
  owner "root"
  group "root"
  notifies :run, resources(:execute => "supervisor update")
end