def set_min_max_value_commands(dbtype, min, max)
  case dbtype
  when :postgres
    options = "start #{min} restart #{min} minvalue #{min} maxvalue #{max}"
    ["alter sequence users_id_seq #{options};",
     "alter sequence groups_id_seq #{options};"]
  when :sqlite
    id = min-1
    name = '#dummyname#'
    dir = '#dummydir#'
    ["insert into users(id, name, homedir) values(#{id}, '#{name}', '#{dir}');",
     "delete from users where id = #{id};",
     "insert into groups(id, name) values(#{id}, '#{name}');",
     "delete from groups where id = #{id};"]
  when :mysql
    ["alter table users auto_increment = #{min};",
     "alter table groups auto_increment = #{min};"]
  else
    raise Sequel::Error, "database type '#{dbtype}' not supported"
  end
end

def reset_min_max_value_commands(dbtype, next_uid, next_gid)
  case dbtype
  when :postgres
    ["alter sequence users_id_seq start #{next_uid} restart #{next_uid} \
       no minvalue no maxvalue;",
     "alter sequence groups_id_seq start #{next_gid} restart #{next_gid} \
       no minvalue no maxvalue;"]
  when :sqlite
    ["delete from sqlite_sequence where name = 'users';",
     "delete from sqlite_sequence where name = 'groups';"]
  when :mysql
    ["alter table users auto_increment = #{next_uid};",
     "alter table groups auto_increment = #{next_gid};"]
  else
    raise Sequel::Error, "database type '#{dbtype}' not supported"
  end
end

Sequel.migration do
  dbtype = DB.database_type
  min_id = 100_000
  max_id = 200_000

  up do
    set_min_max_value_commands(dbtype, min_id, max_id).each do |command|
      run command
    end
  end

  down do
    next_uid = self[:users].max(:id).to_i + 1
    next_gid = self[:groups].max(:id).to_i + 1
    reset_min_max_value_commands(dbtype, next_uid, next_gid).each do |command|
      run command
    end
  end
end
