app_name = 'twilio-test'
dir = "/var/www/apps/#{app_name}"

working_directory dir

listen "#{dir}/tmp/sockets/.unicorn.sock", backlog: 64
listen 8100, tcp_nopush: true
timeout 30

pid "#{dir}/run/unicorn.pid"

stderr_path "#{dir}/log/unicorn.stderr.log"
stdout_path "#{dir}/log/unicorn.stdout.log"
