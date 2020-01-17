#!/usr/bin/env ruby
# frozen_string_literal: true

#
#  check-wsrep-ready
#
# DESCRIPTION:
#   This plugin checks the wsrep_ready status of the cluster.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: mysql2
#
# USAGE:
#
# NOTES:
#   Based on the Percona Cluster Size Plugin by Chris Alexander <chris.alexander@import.io>, import.io; which is based on
#   Based on the MySQL Health Plugin by Panagiotis Papadomitsos
#
# LICENSE:
#   Copyright 2016 Antonio Berrios aberrios@psiclik.plus.com
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'mysql2'

class CheckWsrepReady < Sensu::Plugin::Check::CLI
  option :user,
         description: 'MySQL User',
         short: '-u USER',
         long: '--user USER',
         default: 'root'

  option :password,
         description: 'MySQL Password',
         short: '-p PASS',
         long: '--password PASS'

  option :ini,
         description: 'ini file',
         short: '-i',
         long: '--ini VALUE'

  option :ini_section,
         description: 'Section in my.cnf ini file',
         long: '--ini-section VALUE',
         default: 'client'

  option :hostname,
         description: 'Hostname to login to',
         short: '-h HOST',
         long: '--hostname HOST',
         default: 'localhost'

  option :port,
         description: 'Port to connect to',
         short: '-P PORT',
         long: '--port PORT',
         default: '3306'

  option :socket,
         description: 'Socket to use',
         short: '-s SOCKET',
         long: '--socket SOCKET'

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

    mysql = Mysql2::Client.new(
      host: config[:hostname],
      username: db_user,
      password: db_pass,
      port: config[:port].to_i,
      socket: config[:socket]
    )
    wsrep_ready = mysql.query("SHOW STATUS LIKE 'wsrep_ready';").fetch_hash.fetch('Value')
    critical "WSREP Ready is not ON. Is #{wsrep_ready}" if wsrep_ready != 'ON'
    ok 'Cluster is OK!' if wsrep_ready == 'ON'
  rescue Mysql2::Error => e
    critical "Percona MySQL check failed: #{e.error}"
  ensure
    mysql&.close
    # db.close if db
  end
end
