#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Percona Cluster Size Plugin
# ===
#
# This plugin checks the number of servers in the Percona cluster and warns you according to specified limits
#
# Copyright 2012 Chris Alexander <chris.alexander@import.io>, import.io
# Based on the MySQL Health Plugin by Panagiotis Papadomitsos
#
# Depends on mysql:
# gem install ruby-mysql
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'mysql2'
require 'inifile'

class CheckPerconaClusterSize < Sensu::Plugin::Check::CLI
  option :hostname,
         description: 'Hostname to login to',
         short: '-h',
         long: '--hostname VALUE',
         default: 'localhost'

  option :username,
         description: 'MySQL User',
         short: '-u',
         long: '--username VALUE',
         default: 'root'

  option :password,
         description: 'MySQL Password',
         short: '-p',
         long: '--password VALUE'

  option :ini,
         description: 'ini file',
         short: '-i',
         long: '--ini VALUE'

  option :ini_section,
         description: 'Section in my.cnf ini file',
         long: '--ini-section VALUE',
         default: 'client'

  option :port,
         description: 'Port to connect to',
         short: '-P PORT',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 3306

  option :socket,
         description: 'Socket to use',
         short: '-s SOCKET',
         long: '--socket SOCKET'

  option :expected,
         description: 'Number of servers expected in the cluster',
         short: '-e NUMBER',
         long: '--expected NUMBER',
         proc: proc(&:to_i),
         default: 1

  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini[config[:ini_section]]
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:user]
      db_pass = config[:password]
    end

    begin
      db = Mysql2::Client.new(
        host: config[:hostname],
        username: db_user,
        password: db_pass,
        port: config[:port].to_i,
        socket: config[:socket]
      )
      cluster_size = db.query("SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size'").first['Value'].to_i
      critical "Expected to find #{config[:expected]} nodes, found #{cluster_size}" if cluster_size != config[:expected].to_i
      ok "Expected to find #{config[:expected]} nodes and found those #{cluster_size}" if cluster_size == config[:expected].to_i
    end
  rescue Mysql2::Error => e
    critical "Percona MySQL check failed: #{e.error}"
  ensure
    db&.close
    # db.close if db
  end
end
