class SourceGroup < ActiveRecord::Base
  include SecondDatabase
  set_table_name :users

  def self.migrate
    Group.establish_connection :source_redmine
    User.establish_connection :source_redmine
    all = Group.all
    hash1 = {}
    hash2 = {}

    all.each {|sg|
      hash1[sg.lastname] = sg.user_ids
    }

    hash1.each {|k,v|
       v.map {|u| hash2[u] = User.find(u).login}
    }

    puts "there are #{hash1.count} elements in hash" 

    Group.establish_connection :production
    User.establish_connection :production

    all.each do |source_group|
       puts "- Migrating group #{source_group}..."
      if group = Group.find_by_lastname(source_group.lastname) 
        puts "-- Found"
      else
        group = Group.create!(source_group.attributes) do |g|
          hash1[source_group.lastname].each {|x| # x is a user id
            puts "adding user #{x}"
            user_id = RedmineMerge::Mapper.get_new_user_id(x)
            if user_id.nil? && User.find_by_login(hash2[x]) 
              user_id = User.find_by_login(hash2[x])
            end
            if user_id.nil?
              puts "no good in here..."
            else
              g.users << User.find(user_id)
            end
          }
        end
        puts "-- Not found, created"
      end
    end
  end
end
