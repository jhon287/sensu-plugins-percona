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
require 'inifile'

class CheckWsrepReady < Sensu::Plugin::Check::CLI
  option :hostname,
         description: 'Hostname to login to',
         short: '-h HOST',
         long: '--hostname HOST',
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

  def run
    begin
      db =
        if config[:ini]
          Mysql2::Client.new(
            default_file: config[:ini],
            default_group: config[:ini_section]
          )
        else
          Mysql2::Client.new(
            host: config[:hostname],
            username: config[:user],
            password: config[:password],
            port: config[:port].to_i,
            socket: config[:socket]
          )
        end
      wsrep_ready = db.query("SHOW STATUS LIKE 'wsrep_ready';").first['Value']
      critical "WSREP Ready is not ON. Is #{wsrep_ready}" if wsrep_ready != 'ON'
      ok 'Cluster is OK!' if wsrep_ready == 'ON'
    end
  rescue Mysql2::Error => e
    critical "Percona MySQL wsrep ready failed: #{e.error}"
  ensure
    db&.close
    # db.close if db
  end
end
