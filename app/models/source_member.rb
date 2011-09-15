class SourceMember < ActiveRecord::Base
  include SecondDatabase
    set_table_name :members

      belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
      belongs_to :principal, :class_name => 'SourceUser', :foreign_key => 'user_id' 
      belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'  
      has_many :role, :class_name => 'SourceRole', :join_table => :member_roles, :association_foreign_key => :role_id

        def self.migrate
             Group.establish_connection :source_redmine            
             User.establish_connection :source_redmine
             Project.establish_connection :source_redmine
             Role.establish_connection :source_redmine
             MemberRole.establish_connection :source_redmine
             Member.establish_connection :source_redmine
             groups_old=Group.all
             users_old=User.all
             projects=Project.all
             roles=Role.all
             member=Member.all
             member_roles=MemberRole.all
             hash_mr={}
             hash_member={}
             member.each { |m|
                  hash_member[m.id][:user]=User.find_by_id(m.user_id).login
                  hash_member[m.id][:project]=Project.find_by_id(m.project_id).name                  
                  hash_member[m.id][:details]=m
                  hash_member[m.id][:role]=Role.find_by_id(MemberRole.find_by_member_id(m.id).role_id).name
             }    
                   
             all.each do |source_member|
                      puts ".. " << source_tracker.name
                            next unless Member.find_by_name(source_member.name).nil?
                                  m=Member.create!(source_member.attributes)
                                  old_user_id=m.user_id
                                  m.user_id=
                            end
             end
        end

end
