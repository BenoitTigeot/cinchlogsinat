#!/usr/bin/env ruby
# require 'sqlite3'

begin
  require 'fileutils'
  # db = SQLite3::Database.open "test_sqlite.db"
  # db.execute "CREATE TABLE IF NOT EXISTS irclogs(Id INTEGER PRIMARY KEY,
  #   Nick TEXT, Message TEXT)"
rescue
  require 'FileUtils'
# ensure
#   db.close if db
end


require 'configru'
require 'cinch'
require File.join(File.dirname(__FILE__), 'logger.rb')


Configru.load(File.join(File.dirname(__FILE__), 'config.yml')) do
  option :nick do
    transform {|n| [n, n + '1'] }
  end

  option :server
  option :port
  option :channels

  option :log_dir, String, './logs'
  option_group :logs do
    option :dir,      String,  './logs'
    option :protocol, String,  'http'
    option :server,   String,  'localhost'
    option :port,     Numeric, 8000
    option :path,     String,  ''
  end
end


Log.setup

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = Configru.server
    c.port     = Configru.port
    c.channels = Configru.channels
    c.nicks    = Configru.nick
  end

  # on :join do |m|
  #   Log << m
  # end

  # on :part do |m|
  #   Log << m
  # end

  # on :quit do |m|
  #   Log << m
  # end

  # on :mode do |m|
  #   Log << m
  # end

  on :message do |m|
    Log << m

    return unless m.message.start_with?('!logs')

    # Yes, this IS hacky...
    url  = Configru.logs.protocol + '://'  + Configru.logs.server
    url += ':' + Configru.logs.port.to_s unless Configru.logs.port == 80
    url += '/' + Configru.logs.path unless Configru.logs.path.empty?
    url += "/#{Log.short_dir}/#{m.channel.name.gsub('#','+')}.txt".gsub('//','/')
    msg = Cinch::Message.new(":#{m.bot.nick}!user@host PRIVMSG #{m.channel} :#{m.user.nick}: #{url}", m.bot)
    m.reply msg.message
    Log << msg
  end
end

bot.start
