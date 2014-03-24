#!/usr/bin/env ruby

require 'sequel'

if ARGV.size != 3
  program_name = File.basename($PROGRAM_NAME)
  puts <<EOS
usage: #{program_name} USERFILE GROUPFILE DATABASE_URL

Examples:
#{program_name} users.ldif groups.ldif sqlite:///var/lib/ldumbd/ldumbd.sqlite3
#{program_name} users.ldif groups.ldif postgres://user:password@host:port/ldumbd
#{program_name} users.ldif groups.ldif mysql2://user:password@host:port/ldumbd
EOS
  exit false
end

USER_FILE=ARGV[0]
GROUP_FILE=ARGV[1]
DATABASE_URL=ARGV[2]

def empty_line?(line)
  line.empty? || line.start_with?('#')
end

def attribute_value(ldif_line)
  unless /\A(?<attribute>\w+):\s*(?<value>.*)\z/ =~ ldif_line
    fail %Q{Invalid LDIF line: "#{ldif_line}"}
  end
  return attribute, value
end

def ldif_hash(filename)
  hash = {}
  last_dn = nil
  File.readlines(filename).each do |line|
    line.chomp!
    next if empty_line?(line)

    attribute, value = attribute_value(line)
    if attribute == 'dn'
      last_dn = value
    else
      fail "Invalid DN" if last_dn.nil?
      hash[last_dn] ||= {}
      hash[last_dn][attribute] ||= []
      hash[last_dn][attribute] << value
    end
  end
  hash
end

def users_from_ldif(user_file)
  ldif_hash(user_file).map do |dn, avs|
    {
      id: avs['uidNumber'].first.to_i,
      name: avs['uid'].first,
      realname: avs['cn'].first,
      shell: avs['loginShell'].first,
      homedir: avs['homeDirectory'].first,
      group_id: avs['gidNumber'].first.to_i,
      # mail: avs['mail'].first
    }
  end
end

def groups_from_ldif(group_file)
  ldif_hash(group_file).map do |dn, avs|
    {
      name: avs['cn'].first,
      id: avs['gidNumber'].first.to_i,
      members: avs['memberUid'] || []
    }
  end
end

def skip(reason)
  $stderr.puts "#{reason}, skipping..."
end

def add_groups(groups, database)
  groups.each do |group|
    puts %Q{Adding group "#{group[:name]}..."}
    database[:groups].insert(group.reject { |k, v| k == :members })
  end
end

def add_users(users, database)
  users.each do |user|
    gid = user[:group_id]
    name = user[:name]
    unless database[:groups].where(id: gid).any?
      skip %Q{Invalid gid #{gid} for user "#{name}"}
      next
    end
    puts %Q{Adding user "#{name}"...}
    database[:users].insert(user.reject { |k, v| k == :mail })
  end
end

def add_group_members(groups, database)
  groups.each do |group|
    group[:members].each do |member|
      unless database[:users].where(name: member).any?
        skip %Q{Invalid member "#{member}" for group "#{group[:name]}"}
        next
      end
      uid = database[:users].where(name: member).first[:id]
      gid = group[:id]
      database[:groups_users].insert(group_id: gid, user_id: uid)
    end
  end
end

begin
  users  = users_from_ldif(USER_FILE)
  groups = groups_from_ldif(GROUP_FILE)

  database = Sequel.connect(DATABASE_URL)
  connected = database.test_connection

  database.transaction do
    add_groups(groups, database)
    add_users(users, database)
    add_group_members(groups, database)
  end
rescue => e
  $stderr.puts e
  $stderr.puts 'Reverted database to previous state.' if connected
  exit false
end
